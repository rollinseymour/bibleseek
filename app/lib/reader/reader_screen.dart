import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../annotations/annotation_store.dart';
import '../app/app_model.dart';
import '../bible/bible_library.dart';
import '../bible/bible_store.dart';
import '../data/prefs.dart';
import '../design/reader_palette.dart';
import '../memory/memory_store.dart';
import '../settings/settings_model.dart';
import '../share/share_card.dart';
import '../study/cross_references.dart';
import '../web/browser.dart';
import '../web/offline.dart';
import '../wordstudy/lexicon.dart';
import '../wordstudy/word_study_screen.dart';
import 'chapter_body.dart';
import 'read_aloud.dart';
import 'reader_header.dart';
import 'reader_model.dart';
import 'reader_sheets.dart';
import 'selection_panel.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late final ReaderModel model;
  late final AppModel app;
  late final AnnotationStore store;
  late final BibleLibrary library;
  final _scroll = ScrollController();
  final _anchors = VerseAnchors();
  Set<int> _flash = const {};
  String? _shownChapter;
  bool _wasPicking = false;
  late final ReadAloudService audio;
  int? _followedVerse;
  final _scrollKey = GlobalKey();
  late final SettingsModel _settings;
  bool _interlinearOn = false;
  bool? _loadedReverse;
  InterlinearChapter? _interlinear;
  Map<int, List<ReverseWord>>? _reverse;
  int _interlinearToken = 0;
  String? _toast;
  Timer? _toastTimer;

  @override
  void initState() {
    super.initState();
    app = context.read<AppModel>();
    store = context.read<AnnotationStore>();
    library = context.read<BibleLibrary>();
    model = ReaderModel(
      library: library,
      store: context.read<BibleStore>(),
      settings: context.read<SettingsModel>(),
      prefs: context.read<Prefs>(),
    )..addListener(_onModel);
    _settings = context.read<SettingsModel>()..addListener(_onSettings);
    audio = context.read<ReadAloudService>()..addListener(_onAudio);
    app.addListener(_onApp);
    HardwareKeyboard.instance.addHandler(_onKey);
    _onApp();
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    app.removeListener(_onApp);
    _settings.removeListener(_onSettings);
    audio.removeListener(_onAudio);
    model
      ..removeListener(_onModel)
      ..dispose();
    _scroll.dispose();
    _toastTimer?.cancel();
    super.dispose();
  }

  void _onApp() {
    final t = app.takePendingOpen();
    if (t != null) {
      model.move(
        t.bookCode,
        t.chapter,
        verse: t.verse,
        endVerse: t.endVerse,
        version: t.version,
      );
    }
    // "Add other verses" starts on the books page with a clean selection.
    if (app.sharePicking && !_wasPicking) {
      model.clearSelection();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && app.sharePicking) _pickChapter();
      });
    }
    _wasPicking = app.sharePicking;
    final resume = app.takeShareResume();
    if (resume != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showShareCard(context, resume.passages, style: resume.style);
        }
      });
    }
  }

  Future<void> _finishPick({required bool confirmed}) async {
    SharePassage? added;
    if (confirmed && model.selected.isNotEmpty) {
      final runs = await ShareRun.forPassage(
        context.read<BibleStore>(),
        model.version,
        model.bookCode,
        model.chapter,
        model.selected.toList(),
      );
      added = SharePassage(model.selectedReference, runs);
    }
    model.clearSelection();
    app.finishSharePick(added);
  }

  /// A new chapter lands at the top, unless a deep link asked for a verse.
  void _onModel() {
    if (model.loading || model.error != null) return;
    audio.readerMoved(model);
    final chapter = '${model.bookCode}#${model.chapter}';
    final target = model.scrollTarget;
    if (chapter != _shownChapter) {
      _shownChapter = chapter;
      _anchors.clear();
      if (target == null && _scroll.hasClients) _scroll.jumpTo(0);
      if (_interlinearOn) _loadInterlinear();
    }
    if (target != null) {
      final end = max(model.scrollTargetEnd ?? target, target);
      model.scrollTarget = null;
      model.scrollTargetEnd = null;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _scrollTo(target, end),
      );
    }
  }

  void _onSettings() {
    if (_interlinearOn && _settings.interlinearReverse != _loadedReverse) {
      _loadInterlinear();
    }
  }

  /// Fetches the chapter's interlinear (and, for English order, its KJV
  /// tagging); the reader shows plain verses until it arrives.
  Future<void> _loadInterlinear() async {
    final token = ++_interlinearToken;
    if (!_interlinearOn) {
      setState(() {
        _interlinear = null;
        _reverse = null;
      });
      return;
    }
    final data = context.read<WordStudyData>();
    final reverseOrder = _settings.interlinearReverse;
    final il = await data.interlinear(model.bookCode, model.chapter);
    final rev = reverseOrder
        ? await data.reverse(model.bookCode, model.chapter)
        : null;
    if (!mounted || token != _interlinearToken) return;
    setState(() {
      _interlinear = il;
      _reverse = rev;
      _loadedReverse = reverseOrder;
    });
  }

  /// The verse at the top of the reading area.
  int? _topVerse() {
    final viewport = _scrollKey.currentContext?.findRenderObject();
    if (viewport is! RenderBox) return null;
    final top = viewport.localToGlobal(Offset.zero).dy + 8;
    int? best;
    for (final v in model.verses) {
      final box = _anchors.contextFor(v.number)?.findRenderObject();
      if (box is! RenderBox || !box.attached) continue;
      if (box.localToGlobal(Offset.zero).dy <= top) {
        best = v.number;
      } else {
        break;
      }
    }
    return best ?? model.verses.firstOrNull?.number;
  }

  /// Interlinear cards change every row's height; keep the verse being read in place.
  Future<void> _toggleInterlinear() async {
    final anchor = _topVerse();
    _interlinearOn = !_interlinearOn;
    model.clearSelection();
    await _loadInterlinear();
    if (anchor == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _anchors.contextFor(anchor);
      if (ctx != null && ctx.mounted) Scrollable.ensureVisible(ctx);
    });
  }

  /// Follow-along: keeps the verse being read on screen.
  void _onAudio() {
    final v = audio.verse;
    if (!audio.follow ||
        !audio.isReading(model) ||
        v == null ||
        v == _followedVerse) {
      return;
    }
    _followedVerse = v;
    if (model.selected.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _reveal(v, onlyIfHidden: true),
      );
    }
  }

  Future<void> _scrollTo(int start, int end) async {
    await _reveal(start);
    if (!mounted) return;
    setState(() => _flash = {for (var v = start; v <= end; v++) v});
    await Future<void>.delayed(const Duration(milliseconds: 1300));
    if (mounted) setState(() => _flash = const {});
  }

  /// Scrolls [verse] to 30% down the reading area; with [onlyIfHidden], only
  /// when its start isn't already comfortably on screen.
  Future<void> _reveal(int verse, {bool onlyIfHidden = false}) async {
    const duration = Duration(milliseconds: 350);
    final start = verse;
    final ctx = _anchors.contextFor(start);
    final box = ctx != null && ctx.mounted ? ctx.findRenderObject() : null;
    final textOffset = _anchors.textOffsetFor(start);
    if (box is RenderParagraph && textOffset != null && _scroll.hasClients) {
      // Paragraph mode: land on the verse's own line, not its section's top.
      final caret = box.getOffsetForCaret(
        TextPosition(offset: textOffset),
        Rect.zero,
      );
      final sectionTop = RenderAbstractViewport.of(
        box,
      ).getOffsetToReveal(box, 0).offset;
      final p = _scroll.position;
      final lineTop = sectionTop + caret.dy;
      if (onlyIfHidden &&
          lineTop >= p.pixels &&
          lineTop <= p.pixels + p.viewportDimension - 160) {
        return;
      }
      final target = (lineTop - p.viewportDimension * 0.3).clamp(
        p.minScrollExtent,
        p.maxScrollExtent,
      );
      await _scroll.animateTo(
        target,
        duration: duration,
        curve: Curves.easeInOut,
      );
    } else if (ctx != null && ctx.mounted) {
      if (onlyIfHidden && box is RenderBox && _scroll.hasClients) {
        final top = RenderAbstractViewport.of(
          box,
        ).getOffsetToReveal(box, 0).offset;
        final p = _scroll.position;
        if (top >= p.pixels && top <= p.pixels + p.viewportDimension - 160) {
          return;
        }
      }
      await Scrollable.ensureVisible(
        ctx,
        alignment: 0.3,
        duration: duration,
        curve: Curves.easeInOut,
      );
    }
  }

  void _showToast(String message) {
    _toastTimer?.cancel();
    setState(() => _toast = message);
    _toastTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  /// ← / → turn chapters and Esc clears the selection, while the reader is
  /// the visible tab with no sheet or dialog over it and no text field focused.
  /// App-wide, because clicking the page doesn't give the reader focus.
  bool _onKey(KeyEvent e) {
    if (e is! KeyDownEvent || !mounted || app.tab != AppTab.bible) return false;
    if (ModalRoute.isCurrentOf(context) == false) return false;
    if (FocusManager.instance.primaryFocus?.context?.widget is EditableText) {
      return false;
    }
    switch (e.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        model.goPrevious();
      case LogicalKeyboardKey.arrowRight:
        model.goNext();
      case LogicalKeyboardKey.escape:
        model.clearSelection();
      default:
        return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsModel>();
    context.watch<AnnotationStore>();
    final picking = context.select<AppModel, bool>((a) => a.sharePicking);
    context.watch<ReadAloudService>();
    final palette = settings.readerPalette;
    return ColoredBox(
      color: palette.background,
      child: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: model,
          builder: (context, _) => Column(
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: ReaderHeader(
                    model: model,
                    palette: palette,
                    onReference: _pickChapter,
                    onGoToVerse: _goToVerse,
                    onSettings: () => showReaderSettings(context),
                    interlinearOn: _interlinearOn,
                    onInterlinear: _toggleInterlinear,
                    interlinearReverse: settings.interlinearReverse,
                    onInterlinearOrder: (v) => settings.interlinearReverse = v,
                    picking: picking,
                    onCancelPick: () => _finishPick(confirmed: false),
                    onConfirmPick: () => _finishPick(confirmed: true),
                    onListen: ReadAloudService.supported
                        ? () => audio.play(model)
                        : null,
                    onChapterRelated: () => showChapterRelated(
                      context,
                      book: model.bookCode,
                      chapter: model.chapter,
                      version: model.version,
                      verses: [for (final v in model.verses) v.number],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(child: _page(palette, settings)),
                    Positioned(
                      left: 10,
                      right: 10,
                      bottom: 10,
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          transitionBuilder: (child, a) => SlideTransition(
                            position: Tween(
                              begin: const Offset(0, 0.4),
                              end: Offset.zero,
                            ).animate(a),
                            child: FadeTransition(opacity: a, child: child),
                          ),
                          child: model.selected.isNotEmpty && !picking
                              ? _panel(palette)
                              : !picking && audio.isReading(model)
                              ? ReadAloudBar(
                                  key: const ValueKey('audio'),
                                  palette: palette,
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ),
                    if (ReadAloudService.supported &&
                        !audio.isActive &&
                        !picking &&
                        model.selected.isEmpty &&
                        model.verses.isNotEmpty)
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: ListenButton(
                          palette: palette,
                          onTap: () => audio.play(model),
                        ),
                      ),
                    if (_toast != null)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: model.selected.isEmpty ? 24 : 120,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0B5C45),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _toast!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _page(ReaderPalette palette, SettingsModel settings) {
    if (model.error != null && model.verses.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, color: palette.accent, size: 36),
            const SizedBox(height: 12),
            Text(
              'Couldn’t load ${model.reference}.',
              style: TextStyle(color: palette.text),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 8, 32, 0),
              child: Text(
                [
                  isOnline
                      ? 'Check your connection and try again.'
                      : 'You’re offline, and this chapter isn’t saved on this device.',
                  if (OfflineBibles.supported)
                    'To read without a connection, save a Bible in More › Settings › Offline reading.',
                ].join(' '),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: palette.text.withValues(alpha: 0.65),
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: model.reload,
              child: const Text('Try again'),
            ),
          ],
        ),
      );
    }
    if (model.verses.isEmpty) {
      return Center(child: CircularProgressIndicator(color: palette.accent));
    }
    return Scrollbar(
      key: _scrollKey,
      controller: _scroll,
      child: SingleChildScrollView(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 150),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: AnimatedOpacity(
              opacity: model.loading ? 0.5 : 1,
              duration: const Duration(milliseconds: 150),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ChapterBody(
                    model: model,
                    palette: palette,
                    settings: settings,
                    store: store,
                    anchors: _anchors,
                    flash: _flash,
                    interlinear: _interlinearOn ? _interlinear : null,
                    spoken: audio.isReading(model) && audio.verse != null
                        ? (verse: audio.verse!, word: audio.word)
                        : null,
                    reverse: _interlinearOn && settings.interlinearReverse
                        ? _reverse
                        : null,
                  ),
                  const SizedBox(height: 28),
                  _chapterNav(palette),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _chapterNav(ReaderPalette palette) {
    final style = OutlinedButton.styleFrom(
      foregroundColor: palette.accent,
      side: BorderSide(color: palette.accent.withValues(alpha: 0.35)),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          if (model.previousReference case final prev?)
            Tooltip(
              message: 'Previous chapter (←)',
              child: OutlinedButton.icon(
                style: style,
                onPressed: model.goPrevious,
                icon: const Icon(Icons.chevron_left),
                label: Text(prev),
              ),
            ),
          const Spacer(),
          if (model.nextReference case final next?)
            Tooltip(
              message: 'Next chapter (→)',
              child: OutlinedButton(
                style: style,
                onPressed: model.goNext,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [Text(next), const Icon(Icons.chevron_right)],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _panel(ReaderPalette palette) {
    final runs = model.selectedRuns;
    final favorite =
        runs.isNotEmpty &&
        runs.every(
          (r) => store.isFavorite(
            model.bookCode,
            model.chapter,
            r.start,
            r.end == r.start ? null : r.end,
          ),
        );
    final refs = [
      for (final v in model.selected) '${model.bookName} ${model.chapter}:$v',
    ];
    final bookmarked = refs.isNotEmpty && refs.every(store.isBookmarked);
    return SelectionPanel(
      key: const ValueKey('panel'),
      palette: palette,
      single: model.selected.length == 1,
      favorite: favorite,
      bookmarked: bookmarked,
      onHighlight: _applyHighlight,
      onMoreColors: _moreColors,
      onMemorize: _memorize,
      onCompare: _compare,
      onRelated: () => showVerseRelated(
        context,
        book: model.bookCode,
        chapter: model.chapter,
        verse: model.selected.first,
        version: model.version,
      ),
      onListen: ReadAloudService.supported
          ? () {
              final from = (model.selected.toList()..sort()).first;
              model.clearSelection();
              audio.play(model, from: from);
            }
          : null,
      onWords: () {
        final v = model.selected.first;
        showWordInVerse(
          context,
          reference: '${model.bookName} ${model.chapter}:$v',
          verseText: model.textOf(v),
          book: model.bookCode,
          chapter: model.chapter,
          verse: v,
          version: model.version,
        );
      },
      onFavorite: () => _toggleFavorite(favorite),
      onBookmark: () => _toggleBookmark(bookmarked),
      onNote: _editNote,
      onCopy: _copy,
      onShare: _share,
      onDismiss: model.clearSelection,
    );
  }

  // MARK: actions

  Future<void> _pickChapter() async {
    final picked = await showBookChapterPicker(
      context,
      library: library,
      currentBook: model.bookCode,
      currentChapter: model.chapter,
    );
    if (picked != null) model.move(picked.book, picked.chapter);
  }

  Future<void> _goToVerse() async {
    final controller = TextEditingController();
    String? error;
    final target = await showDialog<ReaderTarget>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) {
          void go() {
            final entered = controller.text.trim();
            final t = library.parseReference(entered);
            if (t == null) {
              setLocal(
                () => error =
                    'Couldn’t find “$entered”. Try a reference like “John 3:16”.',
              );
            } else {
              Navigator.pop(context, t);
            }
          }

          return AlertDialog(
            title: const Text('Go to verse'),
            content: TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'e.g. John 3:16',
                helperText:
                    'Enter a book, chapter, and verse — e.g. “John 3:16”, “1 Cor 13:4”.',
                helperMaxLines: 2,
                errorText: error,
                errorMaxLines: 2,
              ),
              onSubmitted: (_) => go(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(onPressed: go, child: const Text('Go')),
            ],
          );
        },
      ),
    );
    controller.dispose();
    if (target != null) {
      model.clearSelection();
      model.move(
        target.bookCode,
        target.chapter,
        verse: target.verse,
        endVerse: target.endVerse,
      );
    }
  }

  void _applyHighlight(String? hex) {
    for (final v in model.selected) {
      store.setHighlight(hex, model.version, model.bookCode, model.chapter, v);
    }
  }

  Future<void> _moreColors() async {
    final single = model.selected.length == 1
        ? store.highlightHex(
            model.version,
            model.bookCode,
            model.chapter,
            model.selected.first,
          )
        : null;
    final hex = await showHighlightPicker(context, current: single);
    if (hex != null) _applyHighlight(hex.isEmpty ? null : hex);
  }

  Future<void> _compare() async {
    final v = model.selected.first;
    final picked = await showVerseCompare(
      context,
      bookCode: model.bookCode,
      reference: '${model.bookName} ${model.chapter}:$v',
      chapter: model.chapter,
      verse: v,
      currentVersion: model.version,
    );
    if (picked != null) model.switchVersion(picked);
  }

  void _memorize() {
    final memory = context.read<MemoryVerseStore>();
    for (final v in model.selected.toList()..sort()) {
      final text = model.textOf(v);
      if (text.isNotEmpty) {
        memory.add(
          version: model.version,
          bookCode: model.bookCode,
          chapter: model.chapter,
          verse: v,
          text: text,
        );
      }
    }
    final n = model.selected.length;
    model.clearSelection();
    _showToast(
      n == 1 ? 'Added to Memory Verses' : 'Added $n verses to Memory Verses',
    );
  }

  void _toggleFavorite(bool remove) {
    for (final r in model.selectedRuns) {
      final end = r.end == r.start ? null : r.end;
      if (remove) {
        store.removeFavorite(model.bookCode, model.chapter, r.start, end);
      } else if (!store.isFavorite(
        model.bookCode,
        model.chapter,
        r.start,
        end,
      )) {
        store.addFavorite(
          book: model.bookCode,
          chapter: model.chapter,
          verse: r.start,
          endVerse: end,
          version: model.version,
          reference:
              '${model.bookName} ${model.chapter}:${r.start}${end == null ? '' : '-$end'}',
          text: end == null
              ? model.textOf(r.start)
              : [for (var v = r.start; v <= r.end; v++) '$v ${model.textOf(v)}']
                    .join('  '),
        );
      }
    }
  }

  void _toggleBookmark(bool remove) {
    for (final v in model.selected.toList()..sort()) {
      final ref = '${model.bookName} ${model.chapter}:$v';
      if (remove) {
        store.removeBookmark(ref);
      } else if (!store.isBookmarked(ref)) {
        store.addBookmark(ref, model.textOf(v));
      }
    }
  }

  Future<void> _editNote() async {
    final single = model.selected.length == 1 ? model.selected.first : null;
    final distinct = {
      for (final v in model.selected)
        ?store.noteText(model.version, model.bookCode, model.chapter, v),
    };
    final result = await showNoteEditor(
      context,
      reference: model.selectedReference,
      initialText: single == null
          ? ''
          : store.noteText(
                  model.version,
                  model.bookCode,
                  model.chapter,
                  single,
                ) ??
                '',
      initialTags: single == null
          ? const []
          : store.noteTags(
              model.version,
              model.bookCode,
              model.chapter,
              single,
            ),
      conflictWarning: distinct.length > 1,
      canDelete:
          single != null &&
          store.hasNote(model.version, model.bookCode, model.chapter, single),
    );
    if (result == null) return;
    for (final v in model.selected) {
      store.setNote(
        result.text,
        model.version,
        model.bookCode,
        model.chapter,
        v,
        tags: result.tags,
      );
    }
  }

  Future<void> _copy() async {
    try {
      await Clipboard.setData(ClipboardData(text: model.selectedText()));
      _showToast('Copied to clipboard');
    } on PlatformException {
      _showToast('Your browser didn’t allow copying');
    }
  }

  Future<void> _share() => shareVerses(
    context,
    reference: model.selectedReference,
    version: model.version,
    book: model.bookCode,
    chapter: model.chapter,
    verses: model.selected.toList(),
  );
}
