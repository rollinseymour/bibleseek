import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../annotations/highlight_palette.dart';
import '../bible/bible_library.dart';
import '../bible/bible_store.dart';
import '../data/prefs.dart';
import '../design/reader_fonts.dart';
import '../design/reader_palette.dart';
import '../settings/settings_model.dart';

Future<T?> _sheet<T>(
  BuildContext context,
  WidgetBuilder builder, {
  double heightFactor = 0.85,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (context) =>
      FractionallySizedBox(heightFactor: heightFactor, child: builder(context)),
);

class _SheetTitle extends StatelessWidget {
  const _SheetTitle(this.title, {this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 12, 8),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        trailing ??
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
      ],
    ),
  );
}

// MARK: book & chapter picker

/// Books list whose current book opens already expanded and scrolled into view;
/// opening a book collapses the others. Returns (bookCode, chapter).
Future<({String book, int chapter})?> showBookChapterPicker(
  BuildContext context, {
  required BibleLibrary library,
  required String currentBook,
  required int currentChapter,
}) => _sheet(
  context,
  (_) => _BookChapterPicker(library, currentBook, currentChapter),
);

class _BookChapterPicker extends StatefulWidget {
  const _BookChapterPicker(this.library, this.currentBook, this.currentChapter);
  final BibleLibrary library;
  final String currentBook;
  final int currentChapter;

  @override
  State<_BookChapterPicker> createState() => _BookChapterPickerState();
}

class _BookChapterPickerState extends State<_BookChapterPicker> {
  late String? _expanded = widget.currentBook;
  final _currentKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _currentKey.currentContext;
      if (ctx != null) Scrollable.ensureVisible(ctx, alignment: 0.15);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        const _SheetTitle('Books'),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                for (final b in widget.library.books) ...[
                  ListTile(
                    key: b.id == widget.currentBook ? _currentKey : null,
                    title: Text(b.commonName),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (b.id == widget.currentBook)
                          Icon(
                            Icons.check,
                            size: 18,
                            color: scheme.onSurface.withValues(alpha: 0.5),
                          ),
                        Icon(
                          _expanded == b.id
                              ? Icons.expand_less
                              : Icons.expand_more,
                        ),
                      ],
                    ),
                    onTap: () => setState(
                      () => _expanded = _expanded == b.id ? null : b.id,
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: _expanded == b.id
                        ? Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                            child: GridView(
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 76,
                                    mainAxisExtent: 44,
                                    mainAxisSpacing: 10,
                                    crossAxisSpacing: 10,
                                  ),
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              children: [
                                for (var ch = 1; ch <= b.chapters; ch++)
                                  Material(
                                    color:
                                        b.id == widget.currentBook &&
                                            ch == widget.currentChapter
                                        ? scheme.primary.withValues(alpha: 0.22)
                                        : scheme.onSurface.withValues(
                                            alpha: 0.08,
                                          ),
                                    borderRadius: BorderRadius.circular(10),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(10),
                                      onTap: () => Navigator.pop(context, (
                                        book: b.id,
                                        chapter: ch,
                                      )),
                                      child: Center(
                                        child: Text(
                                          '$ch',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          )
                        : const SizedBox(width: double.infinity),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// MARK: reader settings

/// Text size, font, reading theme and display toggles, without leaving the page.
Future<void> showReaderSettings(BuildContext context) =>
    _sheet(context, (_) => const _ReaderSettings(), heightFactor: 0.75);

class _ReaderSettings extends StatelessWidget {
  const _ReaderSettings();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsModel>();
    final scheme = Theme.of(context).colorScheme;
    Widget section(String title) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: scheme.onSurface.withValues(alpha: 0.55),
        ),
      ),
    );
    Widget stepper(double size, bool enabled, VoidCallback onTap) => Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Material(
        color: scheme.onSurface.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: enabled ? onTap : null,
          child: SizedBox(
            width: 44,
            height: 36,
            child: Center(
              child: Text(
                'A',
                style: TextStyle(fontSize: size, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
    return Column(
      children: [
        _SheetTitle(
          'Fonts & Settings',
          trailing: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ),
        Expanded(
          child: ListView(
            children: [
              section('Text size'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    stepper(
                      14,
                      s.fontSize > SettingsModel.fontSizeMin,
                      () => s.fontSize = s.fontSize - 1,
                    ),
                    Expanded(
                      child: Text(
                        '${s.fontSize.round()} pt',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: scheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    stepper(
                      24,
                      s.fontSize < SettingsModel.fontSizeMax,
                      () => s.fontSize = s.fontSize + 1,
                    ),
                  ],
                ),
              ),
              section('Font'),
              for (final f in readerFontOptions)
                ListTile(
                  title: Text(
                    readerFontLabel(f),
                    style: readerTextStyle(f, fontSize: 17),
                  ),
                  trailing: f == s.readerFont
                      ? Icon(Icons.check, color: scheme.primary)
                      : null,
                  onTap: () => s.readerFont = f,
                ),
              section('Reading theme'),
              SizedBox(
                height: 82,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    for (final key in SettingsModel.readerThemeOptions)
                      _ThemeSwatch(
                        palette: ReaderPalette.resolve(key, s.theme),
                        selected: s.readerTheme == key,
                        onTap: () => s.readerTheme = key,
                      ),
                  ],
                ),
              ),
              section('Display'),
              SwitchListTile(
                title: const Text('Paragraph mode'),
                value: s.paragraphMode,
                onChanged: (v) => s.paragraphMode = v,
              ),
              SwitchListTile(
                title: const Text('Red-letter words of Jesus'),
                value: s.redLetter,
                onChanged: (v) => s.redLetter = v,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}

class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({
    required this.palette,
    required this.selected,
    required this.onTap,
  });
  final ReaderPalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Column(
            children: [
              Container(
                width: 58,
                height: 52,
                decoration: BoxDecoration(
                  color: palette.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected
                        ? scheme.primary
                        : scheme.onSurface.withValues(alpha: 0.15),
                    width: selected ? 2.5 : 1,
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        'Aa',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: palette.text,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: palette.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                palette.label,
                style: TextStyle(
                  fontSize: 11,
                  color: selected
                      ? scheme.primary
                      : scheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// MARK: highlight picker

/// Presets, recent customs and a wider custom palette. Returns the picked hex,
/// or an empty string for "remove".
Future<String?> showHighlightPicker(BuildContext context, {String? current}) =>
    _sheet(context, (_) => _HighlightPicker(current), heightFactor: 0.7);

class _HighlightPicker extends StatefulWidget {
  const _HighlightPicker(this.current);
  final String? current;

  @override
  State<_HighlightPicker> createState() => _HighlightPickerState();
}

class _HighlightPickerState extends State<_HighlightPicker> {
  final _hex = TextEditingController();
  String? _hexError;

  /// A spread of soft highlighter shades across the hue wheel.
  static final _custom = [
    for (final l in [0.82, 0.72, 0.62])
      for (var h = 0; h < 360; h += 30)
        HSLColor.fromAHSL(1, h.toDouble(), 0.85, l).toColor(),
  ];

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  void _applyHex() {
    final norm = HighlightPalette.normalize(_hex.text);
    if (norm == null) {
      setState(() => _hexError = 'Enter 6 hex digits, like FFD700');
      return;
    }
    Navigator.pop(context, norm);
  }

  @override
  Widget build(BuildContext context) {
    final recents = HighlightPalette.recents(context.read<Prefs>());
    Widget grid(String title, List<String> hexes) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final hex in hexes)
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, hex),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colorFromHex(hex),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.12),
                        ),
                      ),
                      child: widget.current?.toUpperCase() == hex.toUpperCase()
                          ? Icon(
                              Icons.check,
                              color: Colors.black.withValues(alpha: 0.7),
                            )
                          : null,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
    return Column(
      children: [
        const _SheetTitle('Highlight'),
        Expanded(
          child: ListView(
            children: [
              grid('Colors', [for (final s in HighlightPalette.presets) s.hex]),
              if (recents.isNotEmpty) grid('Recent', recents),
              grid('Custom', [for (final c in _custom) hexFromColor(c)]),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _hex,
                        decoration: InputDecoration(
                          labelText: 'Hex color',
                          prefixText: '#',
                          errorText: _hexError,
                          isDense: true,
                        ),
                        onSubmitted: (_) => _applyHex(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.tonal(
                      onPressed: _applyHex,
                      child: const Text('Use'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                    onPressed: () => Navigator.pop(context, ''),
                    icon: const Icon(Icons.highlight_off),
                    label: const Text('Remove highlight'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// MARK: note editor

/// Add or edit a note with free-form tags. Returns (text, tags), or null when
/// cancelled; an empty text means delete.
Future<({String text, List<String> tags})?> showNoteEditor(
  BuildContext context, {
  required String reference,
  required String initialText,
  required List<String> initialTags,
  required bool conflictWarning,
  required bool canDelete,
}) => _sheet(
  context,
  (_) => _NoteEditor(
    reference,
    initialText,
    initialTags,
    conflictWarning,
    canDelete,
  ),
  heightFactor: 0.75,
);

class _NoteEditor extends StatefulWidget {
  const _NoteEditor(
    this.reference,
    this.initialText,
    this.initialTags,
    this.conflictWarning,
    this.canDelete,
  );
  final String reference;
  final String initialText;
  final List<String> initialTags;
  final bool conflictWarning;
  final bool canDelete;

  @override
  State<_NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<_NoteEditor> {
  late final _text = TextEditingController(text: widget.initialText);
  final _tagInput = TextEditingController();
  late final _tags = [...widget.initialTags];

  @override
  void dispose() {
    _text.dispose();
    _tagInput.dispose();
    super.dispose();
  }

  void _commitTag() {
    final t = _tagInput.text.trim();
    if (t.isNotEmpty && !_tags.any((x) => x.toLowerCase() == t.toLowerCase())) {
      setState(() => _tags.add(t));
    }
    _tagInput.clear();
  }

  void _save() {
    _commitTag();
    Navigator.pop(context, (text: _text.text, tags: _tags));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Row(
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              Expanded(
                child: Text(
                  widget.reference,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: _save,
                child: const Text(
                  'Save',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              if (widget.conflictWarning)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'These verses have different notes — saving will replace them all.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade300,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              TextField(
                controller: _text,
                autofocus: true,
                minLines: 3,
                maxLines: 12,
                decoration: const InputDecoration(
                  hintText: 'Add a note…',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'TAGS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: scheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 8),
              if (_tags.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in _tags)
                      InputChip(
                        label: Text(t),
                        onDeleted: () => setState(() => _tags.remove(t)),
                      ),
                  ],
                ),
              TextField(
                controller: _tagInput,
                decoration: InputDecoration(
                  hintText: 'Add a tag',
                  suffixIcon: IconButton(
                    onPressed: _commitTag,
                    icon: const Icon(Icons.add_circle),
                  ),
                ),
                onSubmitted: (_) => _commitTag(),
              ),
              if (widget.canDelete)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: scheme.error,
                      ),
                      onPressed: () => Navigator.pop(context, (
                        text: '',
                        tags: const <String>[],
                      )),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete note'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// MARK: compare

/// One verse in every translation; tapping one switches the reader to it.
Future<String?> showVerseCompare(
  BuildContext context, {
  required String bookCode,
  required String reference,
  required int chapter,
  required int verse,
  required String currentVersion,
}) => _sheet(
  context,
  (_) => _Compare(bookCode, reference, chapter, verse, currentVersion),
  heightFactor: 0.7,
);

class _Compare extends StatelessWidget {
  const _Compare(
    this.bookCode,
    this.reference,
    this.chapter,
    this.verse,
    this.currentVersion,
  );
  final String bookCode;
  final String reference;
  final int chapter;
  final int verse;
  final String currentVersion;

  @override
  Widget build(BuildContext context) {
    final store = context.read<BibleStore>();
    final settings = context.read<SettingsModel>();
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        _SheetTitle('Compare $reference'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (final v in BibleStore.versions)
                Card(
                  elevation: 0,
                  color: v == currentVersion
                      ? scheme.primary.withValues(alpha: 0.1)
                      : scheme.onSurface.withValues(alpha: 0.04),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.pop(context, v),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                v,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: scheme.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  BibleStore.versionName(v),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: scheme.onSurface.withValues(
                                      alpha: 0.55,
                                    ),
                                  ),
                                ),
                              ),
                              if (v == currentVersion)
                                Icon(
                                  Icons.check,
                                  size: 16,
                                  color: scheme.primary,
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          FutureBuilder(
                            future: store.verseText(
                              v,
                              bookCode,
                              chapter,
                              verse,
                            ),
                            builder: (context, snap) => Text(
                              snap.hasError
                                  ? 'Couldn’t load this translation.'
                                  : (snap.data ?? '…'),
                              style: readerTextStyle(
                                settings.readerFont,
                                fontSize: 16,
                                height: 1.5,
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }
}
