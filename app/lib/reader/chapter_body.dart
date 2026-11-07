import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../annotations/annotation_store.dart';
import '../annotations/highlight_palette.dart';
import '../bible/models.dart';
import '../design/reader_fonts.dart';
import '../design/reader_palette.dart';
import '../settings/settings_model.dart';
import '../wordstudy/lexicon.dart';
import 'interlinear_words.dart';
import 'reader_model.dart';

/// Scroll anchors for the rendered verses: a row per verse in verse mode, a
/// section per heading in paragraph mode.
class VerseAnchors {
  final _keys = <int, GlobalKey>{};
  final _textOffsets = <int, int>{};

  GlobalKey keyFor(int verse) => _keys.putIfAbsent(verse, GlobalKey.new);
  BuildContext? contextFor(int verse) => _keys[verse]?.currentContext;

  /// In paragraph mode a verse shares its section's key; this is where the
  /// verse starts inside that section's text.
  void placeInSection(int verse, GlobalKey section, int textOffset) {
    _keys[verse] = section;
    _textOffsets[verse] = textOffset;
  }

  int? textOffsetFor(int verse) => _textOffsets[verse];

  void clear() {
    _keys.clear();
    _textOffsets.clear();
  }
}

class ChapterBody extends StatefulWidget {
  const ChapterBody({
    super.key,
    required this.model,
    required this.palette,
    required this.settings,
    required this.store,
    required this.anchors,
    this.flash = const {},
    this.interlinear,
    this.reverse,
    this.spoken,
  });

  final ReaderModel model;
  final ReaderPalette palette;
  final SettingsModel settings;
  final AnnotationStore store;
  final VerseAnchors anchors;
  final Set<int> flash;

  /// When set, each verse shows its original-language words beneath it.
  final InterlinearChapter? interlinear;

  /// KJV-order words, for the English-order interlinear.
  final Map<int, List<ReverseWord>>? reverse;

  /// The verse being read aloud, and the word within it when the browser reports one.
  final ({int verse, ({int start, int end})? word})? spoken;

  @override
  State<ChapterBody> createState() => _ChapterBodyState();
}

class _ChapterBodyState extends State<ChapterBody> {
  final _taps = <int, TapGestureRecognizer>{};
  bool? _paragraphMode;

  TapGestureRecognizer _tap(int verse) => _taps.putIfAbsent(
    verse,
    () =>
        TapGestureRecognizer()..onTap = () => widget.model.toggleSelect(verse),
  );

  @override
  void dispose() {
    for (final t in _taps.values) {
      t.dispose();
    }
    super.dispose();
  }

  ReaderModel get m => widget.model;
  ReaderPalette get p => widget.palette;
  SettingsModel get s => widget.settings;
  AnnotationStore get store => widget.store;

  TextStyle get _base => readerTextStyle(
    s.readerFont,
    fontSize: s.fontSize,
    color: p.text,
    height: 1.62,
  );

  TextStyle get _headingStyle => readerTextStyle(
    s.readerFont,
    fontSize: s.fontSize * 0.76 + 7.5,
    color: p.accent,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  @override
  Widget build(BuildContext context) {
    // Interlinear needs a row per verse, so it overrides paragraph mode.
    final paragraphs = s.paragraphMode && widget.interlinear == null;
    if (_paragraphMode != paragraphs) {
      _paragraphMode = paragraphs;
      widget.anchors.clear();
    }
    return paragraphs ? _paragraphs() : _verseRows();
  }

  // MARK: verse mode

  Widget _verseRows() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [for (final v in m.verses) _verseRow(v)],
  );

  Widget _verseRow(Verse v) {
    final noted = store.hasAnyNote(m.version, m.bookCode, m.chapter, v.number);
    final sibling = s.showCrossVersionAnnotations
        ? store.siblingAnnotations(m.version, m.bookCode, m.chapter, v.number)
        : null;
    final selected = m.selected.contains(v.number);
    return Column(
      key: widget.anchors.keyFor(v.number),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (v.heading != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 4),
            child: Text(v.heading!, style: _headingStyle),
          ),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => m.toggleSelect(v.number),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
              padding: EdgeInsets.fromLTRB(8, 5, noted ? 22 : 8, 5),
              decoration: BoxDecoration(
                color: widget.flash.contains(v.number)
                    ? p.accent.withValues(alpha: 0.28)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        _number(v.number),
                        ..._body(v, selected: selected),
                      ],
                    ),
                    style: _base,
                  ),
                  if (noted)
                    Positioned(
                      top: 2,
                      right: -16,
                      child: Icon(
                        Icons.sticky_note_2_outlined,
                        size: 13,
                        color: p.accent,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (widget.interlinear case final il?)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 3, 8, 0),
            child: _interlinearWords(il, v.number),
          ),
        if (sibling != null)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: TextButton.icon(
              onPressed: () => m.switchVersion(sibling.version),
              style: TextButton.styleFrom(
                foregroundColor: p.accent.withValues(alpha: 0.85),
                visualDensity: VisualDensity.compact,
                textStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              icon: const Icon(Icons.layers_outlined, size: 14),
              label: Text('Also in ${sibling.version} · ${sibling.count}'),
            ),
          ),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _interlinearWords(InterlinearChapter il, int verse) {
    final words = il.verses[verse] ?? const <InterlinearWord>[];
    if (words.isEmpty) {
      return Text(
        'No interlinear data for this verse.',
        style: TextStyle(fontSize: 11, color: p.text.withValues(alpha: 0.4)),
      );
    }
    if (widget.reverse case final rev?) {
      return ReverseWords(
        words: rev[verse] ?? const [],
        originals: words,
        palette: p,
        fontSize: s.fontSize,
      );
    }
    return InterlinearWords(words: words, palette: p, fontSize: s.fontSize);
  }

  // MARK: paragraph mode

  /// Flowing prose, broken only at section headings, with each verse still
  /// tappable to select it.
  Widget _paragraphs() {
    final sections = <({String? heading, List<Verse> verses})>[];
    for (final v in m.verses) {
      if (sections.isEmpty || v.heading != null) {
        sections.add((heading: v.heading, verses: [v]));
      } else {
        sections.last.verses.add(v);
      }
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, section) in sections.indexed) ...[
            if (section.heading != null)
              Padding(
                padding: EdgeInsets.only(top: i == 0 ? 4 : 20, bottom: 6),
                child: Text(section.heading!, style: _headingStyle),
              ),
            _section(section.verses),
          ],
        ],
      ),
    );
  }

  Widget _section(List<Verse> verses) {
    final key = widget.anchors.keyFor(verses.first.number);
    final spans = <InlineSpan>[];
    var offset = 0;
    for (final v in verses) {
      widget.anchors.placeInSection(v.number, key, offset);
      final body = _body(
        v,
        selected: m.selected.contains(v.number),
        flash: widget.flash.contains(v.number),
        recognizer: _tap(v.number),
      );
      spans
        ..add(
          _number(
            v.number,
            underline: store.hasAnyNote(
              m.version,
              m.bookCode,
              m.chapter,
              v.number,
            ),
            onTap: () => m.toggleSelect(v.number),
          ),
        )
        ..addAll(body)
        ..add(const TextSpan(text: ' '));
      // The number placeholder counts as one character, then the body, then the space.
      offset +=
          1 +
          body.fold<int>(0, (n, s) => n + ((s as TextSpan).text?.length ?? 0)) +
          1;
    }
    return Text.rich(
      TextSpan(children: spans),
      key: key,
      style: _base,
    );
  }

  // MARK: spans

  /// Superscript verse number; underlined in paragraph mode when the verse has a note.
  InlineSpan _number(int n, {bool underline = false, VoidCallback? onTap}) {
    Widget label = Text(
      '$n',
      style: TextStyle(
        fontSize: s.fontSize * 0.62,
        fontWeight: FontWeight.w700,
        color: p.accent,
        height: 1,
        decoration: underline ? TextDecoration.underline : null,
        decorationColor: p.accent,
      ),
    );
    if (onTap != null) {
      label = MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(onTap: onTap, child: label),
      );
    }
    return WidgetSpan(
      alignment: PlaceholderAlignment.aboveBaseline,
      baseline: TextBaseline.alphabetic,
      child: Transform.translate(
        offset: Offset(0, -s.fontSize * 0.28),
        child: Padding(
          padding: EdgeInsets.only(right: s.fontSize * 0.28),
          child: label,
        ),
      ),
    );
  }

  /// The verse body as styled runs: red letter, editorial notes, whole-verse or
  /// phrase highlights, phrase-note underlines, the dotted selection mark
  /// (never under pilcrows), and the deep-link flash.
  List<InlineSpan> _body(
    Verse v, {
    required bool selected,
    bool flash = false,
    GestureRecognizer? recognizer,
  }) {
    final runs = <({int start, int end, VersePart? part})>[];
    final buf = StringBuffer();
    var last = '';
    for (final part in v.parts) {
      final seg = part.text;
      if (seg.isEmpty) continue;
      if (last.isNotEmpty && !last.endsWith(' ') && !seg.startsWith(' ')) {
        runs.add((start: buf.length, end: buf.length + 1, part: null));
        buf.write(' ');
      }
      runs.add((start: buf.length, end: buf.length + seg.length, part: part));
      buf.write(seg);
      last = seg;
    }
    final body = buf.toString();
    final len = body.length;

    final phrases = store.phraseHighlights(
      m.version,
      m.bookCode,
      m.chapter,
      v.number,
    );
    final notes = store.phraseNotes(m.version, m.bookCode, m.chapter, v.number);
    final wholeHex = phrases.isEmpty
        ? store.highlightHex(m.version, m.bookCode, m.chapter, v.number)
        : null;
    final pilcrows = <({int start, int end})>[];
    if (selected) {
      for (var i = body.indexOf('¶'); i >= 0; i = body.indexOf('¶', i + 1)) {
        var j = i + 1;
        while (j < len && body[j] == ' ') {
          j++;
        }
        pilcrows.add((start: i, end: j));
      }
    }

    final cuts = <int>{0, len};
    for (final r in runs) {
      cuts.addAll([r.start, r.end]);
    }
    for (final h in phrases) {
      cuts.addAll([h.start.clamp(0, len), h.end.clamp(0, len)]);
    }
    for (final n in notes) {
      cuts.addAll([n.start.clamp(0, len), n.end.clamp(0, len)]);
    }
    for (final pc in pilcrows) {
      cuts.addAll([pc.start, pc.end]);
    }
    final reading = widget.spoken?.verse == v.number;
    final word = reading ? widget.spoken!.word : null;
    if (word != null) {
      cuts.addAll([word.start.clamp(0, len), word.end.clamp(0, len)]);
    }
    final sorted = cuts.toList()..sort();

    bool within(int i, int start, int end) => i >= start && i < end;
    final noteColor = p.text.withValues(alpha: 0.6);
    final spans = <InlineSpan>[];
    var ri = 0;
    for (var k = 0; k + 1 < sorted.length; k++) {
      final a = sorted[k], b = sorted[k + 1];
      if (a >= b) continue;
      while (ri < runs.length - 1 && runs[ri].end <= a) {
        ri++;
      }
      final part = runs.isEmpty ? null : runs[ri].part;

      Color? bg;
      for (final h in phrases) {
        if (within(a, h.start, h.end)) {
          bg = colorFromHex(h.color).withValues(alpha: 0.4);
        }
      }
      if (wholeHex != null) bg = colorFromHex(wholeHex).withValues(alpha: 0.35);
      if (flash) bg = p.accent.withValues(alpha: 0.3);
      if (reading && word == null) bg ??= p.accent.withValues(alpha: 0.12);
      final spokenWord = word != null && within(a, word.start, word.end);
      if (spokenWord) bg = const Color(0xFFFFE14D);

      final dotted =
          selected && !pilcrows.any((pc) => within(a, pc.start, pc.end));
      final noted = notes.any((n) => within(a, n.start, n.end));

      spans.add(
        TextSpan(
          text: body.substring(a, b),
          recognizer: recognizer,
          mouseCursor: recognizer == null ? null : SystemMouseCursors.click,
          style: TextStyle(
            color: spokenWord
                ? const Color(0xFF1A1A1A)
                : part == null
                ? null
                : part.isNote
                ? noteColor
                : (part.wordsOfJesus && s.redLetter)
                ? p.redLetter
                : null,
            fontStyle: part?.isNote == true ? FontStyle.italic : null,
            backgroundColor: bg,
            decoration: (dotted || noted) ? TextDecoration.underline : null,
            decorationStyle: dotted
                ? TextDecorationStyle.dotted
                : TextDecorationStyle.solid,
            decorationColor: dotted
                ? p.text.withValues(alpha: 0.75)
                : p.text.withValues(alpha: 0.6),
            decorationThickness: dotted ? 2.2 : 1,
          ),
        ),
      );
    }
    return spans;
  }
}
