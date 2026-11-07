import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'lexicon.dart';
import 'strongs_card.dart';

/// Look up the Hebrew or Greek behind any English word (or a Strong's number):
/// a name-meaning card when the query is a biblical name, then the Strong's
/// entries with example verses.
class WordStudyScreen extends StatefulWidget {
  const WordStudyScreen({super.key, this.initialQuery = ''});
  final String initialQuery;

  @override
  State<WordStudyScreen> createState() => _WordStudyScreenState();
}

class _WordStudyScreenState extends State<WordStudyScreen> {
  late final _query = TextEditingController(text: widget.initialQuery);
  Timer? _debounce;
  String? _last;
  bool _loading = false;
  NameStudy? _name;
  List<({StrongsEntry entry, List<WordExample> examples})> _entries = const [];
  int _token = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery.isNotEmpty) _search();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _changed(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _search);
  }

  Future<void> _search() async {
    final q = _query.text.trim();
    final token = ++_token;
    if (q.isEmpty) {
      setState(() {
        _entries = const [];
        _name = null;
        _last = null;
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    final data = context.read<WordStudyData>();
    await data.ready();
    final name = data.name(q);
    final entries = <({StrongsEntry entry, List<WordExample> examples})>[];
    for (final e in data.lookup(q)) {
      entries.add((entry: e, examples: await data.examples(e.number)));
      if (token != _token) return;
    }
    if (!mounted || token != _token) return;
    setState(() {
      _name = name;
      _entries = entries;
      _last = q;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.6);
    Widget placeholder(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(8, 48, 8, 0),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, height: 1.5, color: muted),
      ),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Word Study')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Text(
                'Look up the Hebrew or Greek behind any English word, or a Strong’s number like G26.',
                style: TextStyle(fontSize: 13, color: muted),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _query,
                autofocus: widget.initialQuery.isEmpty,
                autocorrect: false,
                onChanged: _changed,
                onSubmitted: (_) => _search(),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'A word or number — e.g. love, faith, H430',
                  filled: true,
                  fillColor: scheme.onSurface.withValues(alpha: 0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: _query.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _query.clear();
                            _search();
                          },
                        ),
                ),
              ),
              const SizedBox(height: 16),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_last == null)
                placeholder(
                  'Type a word above to see its underlying Hebrew and Greek root(s) along with their original meaning.',
                )
              else if (_entries.isEmpty && _name == null)
                placeholder(
                  '“$_last” isn’t in the bundled lexicon yet.\nTry a related word or a different form.',
                )
              else ...[
                if (_name != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: NameStudyCard(study: _name!),
                  ),
                for (final w in _entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: StrongsCard(
                      code: w.entry.number,
                      detailed: _entries.length == 1,
                      examples: w.examples,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.text, this.fg, this.bg, {this.icon});
  final String text;
  final Color fg;
  final Color bg;
  final IconData? icon;

  static Color tintFg(bool greek) =>
      greek ? const Color(0xFF6EA8FE) : const Color(0xFFC68A3E);
  static Color tintBg(bool greek) =>
      (greek ? const Color(0xFF6EA8FE) : const Color(0xFFE0A458)).withValues(
        alpha: 0.18,
      );

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
        ],
        Text(
          text,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: fg,
          ),
        ),
      ],
    ),
  );
}

/// A biblical name's meaning: Hebrew/Greek roots, Strong's numbers and the
/// people or places that bore it.
class NameStudyCard extends StatelessWidget {
  const NameStudyCard({super.key, required this.study, this.showName = true});
  final NameStudy study;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final body = scheme.onSurface.withValues(alpha: 0.82);
    final muted = scheme.onSurface.withValues(alpha: 0.55);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Pill(
            'NAME MEANING',
            scheme.primary,
            scheme.primary.withValues(alpha: 0.18),
            icon: Icons.badge_outlined,
          ),
          if (showName) ...[
            const SizedBox(height: 8),
            Text(
              study.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 8),
          if (study.rich)
            for (final (i, s) in study.senses.indexed) ...[
              if (i > 0) const Divider(height: 24),
              if (s.kind == 'place')
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    'PLACE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: muted,
                    ),
                  ),
                ),
              if (s.hasHeb)
                _lang(
                  context,
                  'HEBREW',
                  s.hebS,
                  s.heb,
                  s.hebT,
                  s.hebM,
                  greek: false,
                ),
              if (s.hasGrk)
                _lang(
                  context,
                  'GREEK',
                  s.grkS,
                  s.grk,
                  s.grkT,
                  s.grkM,
                  greek: true,
                ),
              if (s.bios.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'In Scripture',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: muted,
                  ),
                ),
                for (final b in s.bios)
                  Text(
                    '•  $b',
                    style: TextStyle(fontSize: 13, height: 1.4, color: body),
                  ),
                if (s.more > 0)
                  Text(
                    '…and ${s.more} more',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: muted,
                    ),
                  ),
              ],
            ]
          else
            for (final m in study.simpleMeanings)
              Text(
                study.simpleMeanings.length == 1 ? m : '•  $m',
                style: TextStyle(fontSize: 15, height: 1.45, color: body),
              ),
          const SizedBox(height: 8),
          Text(
            study.rich
                ? 'Source: BibleData (CC BY 4.0)'
                : 'Source: Hitchcock’s Bible Names Dictionary',
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _lang(
    BuildContext context,
    String label,
    String strongs,
    String word,
    String translit,
    String meaning, {
    required bool greek,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Pill(
            strongs.isEmpty ? label : '$label • $strongs',
            _Pill.tintFg(greek),
            _Pill.tintBg(greek),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              if (word.isNotEmpty)
                Text(
                  word,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (translit.isNotEmpty)
                Text(
                  translit,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                    color: scheme.primary,
                  ),
                ),
            ],
          ),
          if (meaning.isNotEmpty)
            Text(
              meaning,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: scheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
        ],
      ),
    );
  }
}

/// Tap a word of a verse to see the Hebrew or Greek behind it: the entry used
/// in this verse above, the verse in the middle, other senses below. In the
/// KJV every word carries its exact Strong's number.
Future<void> showWordInVerse(
  BuildContext context, {
  required String reference,
  required String verseText,
  required String book,
  required int chapter,
  required int verse,
  required String version,
}) => showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => FractionallySizedBox(
    heightFactor: 0.92,
    child: _WordInVerse(reference, verseText, book, chapter, verse, version),
  ),
);

class _WordInVerse extends StatefulWidget {
  const _WordInVerse(
    this.reference,
    this.verseText,
    this.book,
    this.chapter,
    this.verse,
    this.version,
  );
  final String reference;
  final String verseText;
  final String book;
  final int chapter;
  final int verse;
  final String version;

  @override
  State<_WordInVerse> createState() => _WordInVerseState();
}

class _WordInVerseState extends State<_WordInVerse> {
  List<AlignedWord> _words = const [];
  bool _exact = false;
  Set<int> _tappable = const {};
  bool _scanning = true;
  AlignedWord? _selected;
  List<String> _inVerse = const [];
  List<String> _others = const [];
  NameStudy? _name;

  @override
  void initState() {
    super.initState();
    _words = WordStudyData.plainWords(widget.verseText);
    _prepare();
  }

  /// Aligns the verse (KJV) and marks which words have entries, so no tap dead-ends.
  Future<void> _prepare() async {
    final data = context.read<WordStudyData>();
    await data.ready();
    var words = widget.version.toUpperCase() == 'KJV'
        ? await data.alignKjv(
            widget.verseText,
            widget.book,
            widget.chapter,
            widget.verse,
          )
        : const <AlignedWord>[];
    final exact = words.any((w) => w.code.isNotEmpty);
    if (!exact) words = WordStudyData.plainWords(widget.verseText);
    final known = <String, bool>{};
    bool inDictionary(String k) => known[k] ??=
        k.length >= 2 && (data.lookup(k).isNotEmpty || data.name(k) != null);
    final tappable = {
      for (final w in words)
        if (!(exact && w.supplied) &&
            ((exact && w.code.isNotEmpty && data.entry(w.code) != null) ||
                inDictionary(w.key)))
          w.id,
    };
    if (!mounted) return;
    setState(() {
      _words = words;
      _exact = exact;
      _tappable = tappable;
      _scanning = false;
    });
  }

  Future<void> _lookup(AlignedWord t) async {
    final data = context.read<WordStudyData>();
    final all = [for (final e in data.lookup(t.key)) e.number];
    var used = <String>[];
    var rest = <String>[];
    if (_exact && t.code.isNotEmpty && data.entry(t.code) != null) {
      used = [t.code];
      rest = [
        for (final c in all)
          if (c != t.code) c,
      ];
    } else {
      // No tagging: pin an entry only when the concordance has it in this verse,
      // or it's the single entry in the verse's own language.
      final nt = WordStudyData.isNewTestament(widget.book);
      final here = VerseRef(widget.book, widget.chapter, widget.verse);
      final confirmed = <String>[];
      for (final c in all) {
        if ((await data.detail(c))?.verses.contains(here) ?? false) {
          confirmed.add(c);
        }
      }
      final sameLanguage = [
        for (final c in all)
          if (c.startsWith('G') == nt) c,
      ];
      if (confirmed.isNotEmpty) {
        used = confirmed;
      } else if (sameLanguage.length == 1) {
        used = sameLanguage;
      }
      rest = [
        for (final c in sameLanguage)
          if (!used.contains(c)) c,
        for (final c in all)
          if (c.startsWith('G') != nt && !used.contains(c)) c,
      ];
    }
    if (!mounted) return;
    setState(() {
      _selected = t;
      _inVerse = used;
      _others = rest;
      _name = data.name(t.key);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.6);
    Widget label(String text, Color color) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: color,
        ),
      ),
    );
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.reference,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              if (_inVerse.isNotEmpty) ...[
                label('IN THIS VERSE', scheme.primary),
                for (final c in _inVerse)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: StrongsCard(code: c, contextual: true),
                  ),
              ],
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scheme.onSurface.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 10,
                  children: [for (final w in _words) _word(w)],
                ),
              ),
              const SizedBox(height: 10),
              if (_scanning)
                Row(
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Finding words with Hebrew and Greek roots…',
                      style: TextStyle(fontSize: 13, color: muted),
                    ),
                  ],
                )
              else if (_tappable.isEmpty)
                Text(
                  'No words in this verse are in the bundled lexicon.',
                  style: TextStyle(fontSize: 13, color: muted),
                )
              else if (_selected == null)
                Text(
                  _exact
                      ? 'Tap any underlined word for the exact Hebrew or Greek behind it.'
                      : 'Tap any underlined word for its Hebrew or Greek root.',
                  style: TextStyle(fontSize: 13, color: muted),
                ),
              if (_exact && !_scanning && _words.any((w) => w.supplied))
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Words in italics were supplied by the KJV translators — no Hebrew or Greek word stands behind them.',
                    style: TextStyle(fontSize: 13, color: muted),
                  ),
                ),
              if (_selected != null &&
                  (_name != null || _others.isNotEmpty)) ...[
                const SizedBox(height: 16),
                label(
                  _inVerse.isEmpty
                      ? 'ABOUT “${_selected!.key.toUpperCase()}”'
                      : 'MORE ON “${_selected!.key.toUpperCase()}”',
                  muted,
                ),
                if (_name != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: NameStudyCard(study: _name!),
                  ),
                for (final c in _others)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: StrongsCard(code: c, detailed: false),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _word(AlignedWord w) {
    final scheme = Theme.of(context).colorScheme;
    final selected = _selected?.id == w.id;
    final tappable = _tappable.contains(w.id);
    final supplied = _exact && w.supplied;
    final text = Container(
      padding: selected
          ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
          : EdgeInsets.zero,
      decoration: selected
          ? BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(20),
            )
          : null,
      child: Text(
        w.display,
        style: TextStyle(
          fontSize: 19,
          fontStyle: supplied ? FontStyle.italic : null,
          color: selected
              ? scheme.primary
              : (supplied
                    ? scheme.onSurface.withValues(alpha: 0.55)
                    : scheme.onSurface),
          decoration: tappable && !selected ? TextDecoration.underline : null,
          decorationStyle: TextDecorationStyle.dotted,
          decorationColor: scheme.primary.withValues(alpha: 0.6),
        ),
      ),
    );
    if (!tappable) return text;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: () => _lookup(w), child: text),
    );
  }
}
