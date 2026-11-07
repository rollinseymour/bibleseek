import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app_model.dart';
import '../bible/bible_library.dart';
import '../bible/bible_store.dart';
import '../design/reader_fonts.dart';
import '../settings/settings_model.dart';
import '../widgets/mouse_drag_scroll.dart';
import 'lexicon.dart';

/// Opens a verse in the KJV reader (the text the lexicon's renderings are
/// drawn from) and closes any sheets and pages stacked over the tabs.
void openVerseRef(BuildContext context, VerseRef ref) {
  context.read<AppModel>().open(
    ReaderTarget(
      bookCode: ref.book,
      chapter: ref.chapter,
      verse: ref.verse,
      version: 'KJV',
    ),
  );
  Navigator.of(context, rootNavigator: true).popUntil((r) => r.isFirst);
}

String verseRefLabel(BuildContext context, VerseRef r) =>
    '${context.read<BibleLibrary>().name(r.book)} ${r.chapter}:${r.verse}';

Color strongsTint(String code) =>
    code.startsWith('G') ? const Color(0xFF6EA8FE) : const Color(0xFFC68A3E);

String renderingText(String text) => text.isEmpty ? 'not translated' : text;

class _Label extends StatelessWidget {
  const _Label(this.text, {this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
      color:
          color ??
          Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
    ),
  );
}

/// A Strong's number in full: the word and sense, how the KJV translates it
/// (each rendering opens its verses), Strong's own entry with root links, and
/// the way into the concordance. `detailed: false` is the compact form.
class StrongsCard extends StatelessWidget {
  const StrongsCard({
    super.key,
    required this.code,
    this.detailed = true,
    this.contextual = false,
    this.examples = const [],
  });

  final String code;
  final bool detailed;

  /// The entry this verse actually uses, tinted to stand out.
  final bool contextual;
  final List<WordExample> examples;

  @override
  Widget build(BuildContext context) {
    final data = context.read<WordStudyData>();
    final entry = data.entry(code);
    final scheme = Theme.of(context).colorScheme;
    final tint = strongsTint(code);
    final muted = scheme.onSurface.withValues(alpha: 0.6);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: contextual
            ? scheme.primary.withValues(alpha: 0.08)
            : scheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: contextual
              ? scheme.primary.withValues(alpha: 0.4)
              : tint.withValues(alpha: 0.25),
        ),
      ),
      child: FutureBuilder(
        future: data.detail(code),
        initialData: data.cachedDetail(code),
        builder: (context, snap) {
          final detail = snap.data;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: tint.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: _Label(
                      code.startsWith('G') ? 'GREEK' : 'HEBREW',
                      color: tint,
                    ),
                  ),
                  if (entry?.pos case final pos? when pos.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(pos, style: TextStyle(fontSize: 11, color: muted)),
                  ],
                  const Spacer(),
                  Text(
                    code,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
              if (entry != null) ...[
                const SizedBox(height: 10),
                Text(
                  entry.lemma,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.end,
                  spacing: 6,
                  children: [
                    if (entry.translit.isNotEmpty)
                      Text(
                        entry.translit,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.italic,
                          color: scheme.primary,
                        ),
                      ),
                    if (detail?.pronunciation case final p? when p.isNotEmpty)
                      Text(
                        entry.translit.isEmpty ? p : '· $p',
                        style: TextStyle(fontSize: 13, color: muted),
                      ),
                  ],
                ),
              ],
              const Divider(height: 24),
              if (entry != null && entry.gloss.isNotEmpty)
                Text(
                  entry.gloss,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.45,
                    color: scheme.onSurface.withValues(alpha: 0.85),
                  ),
                ),
              if (detail != null) ..._renderings(context, detail),
              if (detail != null && detailed) ..._strongsEntry(context, detail),
              if (examples.isNotEmpty) ...[
                const SizedBox(height: 12),
                const _Label('IN SCRIPTURE'),
                const SizedBox(height: 6),
                for (final ex in examples)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: ExampleRow(example: ex),
                  ),
              ],
              if (detail != null && detail.verses.isNotEmpty) ...[
                const SizedBox(height: 12),
                Material(
                  color: scheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _push(context, ConcordanceScreen(code: code)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.format_list_bulleted,
                            size: 18,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              detail.occurrenceLabel,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: scheme.primary,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: scheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              if (!detailed)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: TextButton(
                    onPressed: () =>
                        _push(context, LexiconEntryScreen(code: code)),
                    child: const Text('Full Strong’s entry ›'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  static void _push(BuildContext context, Widget page) =>
      Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));

  List<Widget> _renderings(BuildContext context, LexiconDetail d) {
    final scheme = Theme.of(context).colorScheme;
    if (d.renderings.isNotEmpty) {
      final limit = detailed ? 8 : 4;
      return [
        const SizedBox(height: 12),
        const _Label('KJV TRANSLATES IT'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final (i, r) in d.renderings.take(limit).indexed)
              _Chip(
                text: renderingText(r.text),
                count: r.count,
                muted: r.text.isEmpty,
                onTap: () =>
                    _push(context, ConcordanceScreen(code: code, rendering: i)),
              ),
            if (d.renderings.length > limit)
              _Chip(
                text: '+${d.renderings.length - limit} more',
                muted: true,
                onTap: () => _push(context, ConcordanceScreen(code: code)),
              ),
          ],
        ),
      ];
    }
    if (d.usage case final usage? when usage.isNotEmpty) {
      return [
        const SizedBox(height: 12),
        const _Label('KJV USAGE'),
        const SizedBox(height: 4),
        Text(
          usage,
          style: TextStyle(
            fontSize: 14,
            color: scheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
      ];
    }
    return const [];
  }

  List<Widget> _strongsEntry(BuildContext context, LexiconDetail d) {
    if (d.derivation == null && d.definition == null && d.related.isEmpty) {
      return const [];
    }
    final scheme = Theme.of(context).colorScheme;
    final data = context.read<WordStudyData>();
    return [
      const SizedBox(height: 14),
      const _Label("STRONG'S DEFINITION"),
      const SizedBox(height: 6),
      if (d.derivation != null)
        Text(
          _sentenceCase(_namingCodes(data, d.derivation!)),
          style: TextStyle(
            fontSize: 14,
            fontStyle: FontStyle.italic,
            color: scheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      if (d.definition != null)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            _sentenceCase(d.definition!),
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: scheme.onSurface.withValues(alpha: 0.85),
            ),
          ),
        ),
      if (d.related.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final c in d.related)
                ActionChip(
                  avatar: null,
                  label: Text.rich(
                    TextSpan(
                      children: [
                        if (data.entry(c)?.lemma case final l?
                            when l.isNotEmpty)
                          TextSpan(
                            text: '$l  ',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        TextSpan(
                          text: c,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: strongsTint(c),
                          ),
                        ),
                      ],
                    ),
                  ),
                  backgroundColor: strongsTint(c).withValues(alpha: 0.12),
                  side: BorderSide.none,
                  shape: const StadiumBorder(),
                  onPressed: () => _push(context, LexiconEntryScreen(code: c)),
                ),
            ],
          ),
        ),
    ];
  }

  /// "from G25" → "from ἀγάπη (G25)": Strong's cites roots by number only.
  static String _namingCodes(WordStudyData data, String text) =>
      text.replaceAllMapped(RegExp(r'\b[GH]\d{1,5}\b'), (m) {
        final lemma = data.entry(m[0]!)?.lemma ?? '';
        return lemma.isEmpty ? m[0]! : '\u2068$lemma\u2069 (${m[0]})';
      });

  static String _sentenceCase(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

/// One KJV rendering with how often it's used: "charity 27".
class _Chip extends StatelessWidget {
  const _Chip({
    required this.text,
    this.count,
    this.muted = false,
    required this.onTap,
  });
  final String text;
  final int? count;
  final bool muted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = muted
        ? scheme.onSurface.withValues(alpha: 0.55)
        : scheme.onSurface;
    return Material(
      color: scheme.onSurface.withValues(alpha: 0.06),
      shape: StadiumBorder(
        side: BorderSide(color: scheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: fg,
                  fontStyle: muted ? FontStyle.italic : null,
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 5),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface.withValues(alpha: 0.55),
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

/// [text] with whole-word, case-insensitive matches of [word] bold in [color].
TextSpan highlightWord(String text, String word, Color color) {
  if (word.isEmpty) return TextSpan(text: text);
  final re = RegExp('\\b${RegExp.escape(word)}\\b', caseSensitive: false);
  final spans = <TextSpan>[];
  var last = 0;
  for (final m in re.allMatches(text)) {
    if (m.start > last) {
      spans.add(TextSpan(text: text.substring(last, m.start)));
    }
    spans.add(
      TextSpan(
        text: m[0],
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
    last = m.end;
  }
  if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
  return TextSpan(children: spans);
}

/// An example verse with the rendering word highlighted; opens the verse.
class ExampleRow extends StatelessWidget {
  const ExampleRow({super.key, required this.example});
  final WordExample example;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.onSurface.withValues(alpha: 0.03),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: scheme.onSurface.withValues(alpha: 0.06)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => openVerseRef(context, example.ref),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text.rich(
                highlightWord(example.text, example.word, scheme.primary),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: scheme.onSurface.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${verseRefLabel(context, example.ref)} ›',
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Waits for the word-study data before building [builder].
class WordStudyReady extends StatelessWidget {
  const WordStudyReady({super.key, required this.builder});
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: context.read<WordStudyData>().ready(),
    builder: (context, snap) {
      if (snap.connectionState == ConnectionState.done && !snap.hasError) {
        return builder(context);
      }
      return Center(
        child: snap.hasError
            ? const Text('Couldn’t load the lexicon. Check your connection.')
            : const CircularProgressIndicator(),
      );
    },
  );
}

/// A Strong's entry on its own page, where a root or related word leads.
class LexiconEntryScreen extends StatelessWidget {
  const LexiconEntryScreen({super.key, required this.code});
  final String code;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(code)),
    body: WordStudyReady(
      builder: (context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: FutureBuilder(
            future: context.read<WordStudyData>().examples(code),
            builder: (context, snap) => ListView(
              padding: const EdgeInsets.all(20),
              children: [
                StrongsCard(code: code, examples: snap.data ?? const []),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Every verse where a Strong's number occurs, grouped by book, with the KJV
/// words that render it highlighted. Chips narrow it to one rendering.
class ConcordanceScreen extends StatefulWidget {
  const ConcordanceScreen({super.key, required this.code, this.rendering});
  final String code;
  final int? rendering;

  @override
  State<ConcordanceScreen> createState() => _ConcordanceScreenState();
}

class _ConcordanceScreenState extends State<ConcordanceScreen> {
  late int? _filter = widget.rendering;
  String? _book;
  final _aligned = <String, Future<List<AlignedWord>>>{};

  Future<List<AlignedWord>> _words(VerseRef ref) =>
      _aligned.putIfAbsent(ref.id, () async {
        final data = context.read<WordStudyData>();
        final text = await context.read<BibleStore>().verseText(
          'KJV',
          ref.book,
          ref.chapter,
          ref.verse,
        );
        return data.alignKjv(text, ref.book, ref.chapter, ref.verse);
      });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Concordance')),
    body: WordStudyReady(
      builder: (context) => FutureBuilder(
        future: context.read<WordStudyData>().detail(widget.code),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final d = snap.data;
          if (d == null || d.verses.isEmpty) {
            return Center(
              child: Text(
                'The bundled concordance has no verses for ${widget.code}.',
              ),
            );
          }
          return _list(context, d);
        },
      ),
    ),
  );

  Widget _list(BuildContext context, LexiconDetail d) {
    final scheme = Theme.of(context).colorScheme;
    final library = context.read<BibleLibrary>();
    final all = _filter == null ? d.verses : d.versesWithRendering(_filter!);
    final books = <String>[];
    for (final r in all) {
      if (books.isEmpty || books.last != r.book) books.add(r.book);
    }
    final refs = _book == null
        ? all
        : all.where((r) => r.book == _book).toList();
    final items = <Object>[];
    for (final r in refs) {
      if (items.isEmpty ||
          (items.last is VerseRef && (items.last as VerseRef).book != r.book)) {
        items.add(r.book);
      }
      items.add(r);
    }
    final highlight = {widget.code, ...d.foldedFrom};
    final entry = context.read<WordStudyData>().entry(widget.code);

    String summary() {
      final i = _filter;
      if (i == null || i >= d.renderings.length) return d.occurrenceLabel;
      final r = d.renderings[i];
      final times = r.count == 1 ? 'once' : '${r.count} times';
      final verses = all.length == 1 ? '1 verse' : '${all.length} verses';
      return r.text.isEmpty
          ? 'Not translated $times, in $verses'
          : 'Translated “${r.text}” $times, in $verses';
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    entry?.lemma ?? widget.code,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (entry != null && entry.translit.isNotEmpty)
                    Text(
                      entry.translit,
                      style: TextStyle(
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        color: scheme.primary,
                      ),
                    ),
                  const Spacer(),
                  if (books.length > 1)
                    PopupMenuButton<String?>(
                      tooltip: 'Book',
                      initialValue: _book,
                      onSelected: (b) => setState(() => _book = b),
                      itemBuilder: (_) => [
                        PopupMenuItem<String?>(
                          value: null,
                          child: Text('All books (${all.length})'),
                        ),
                        for (final b in books)
                          PopupMenuItem<String?>(
                            value: b,
                            child: Text(
                              '${library.name(b)} (${all.where((r) => r.book == b).length})',
                            ),
                          ),
                      ],
                      child: Chip(
                        avatar: const Icon(Icons.menu_book_outlined, size: 16),
                        label: Text(
                          _book == null ? 'All books' : library.name(_book!),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
              child: Text(
                summary(),
                style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
            if (d.renderings.length > 1)
              SizedBox(
                height: 44,
                child: MouseDragScroll(
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _filterChip(
                        'All',
                        d.occurrences,
                        _filter == null,
                        () => setState(() => _filter = null),
                      ),
                      for (final (i, r) in d.renderings.indexed)
                        _filterChip(
                          renderingText(r.text),
                          r.count,
                          _filter == i,
                          () => setState(() => _filter = i),
                        ),
                    ],
                  ),
                ),
              ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final item = items[i];
                  if (item is String) {
                    return Container(
                      color: scheme.onSurface.withValues(alpha: 0.04),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 7,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              library.name(item).toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                                color: scheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                          Text(
                            '${refs.where((r) => r.book == item).length}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return _row(context, item as VerseRef, highlight);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(
    String text,
    int count,
    bool selected,
    VoidCallback onTap,
  ) => Padding(
    padding: const EdgeInsets.only(right: 6, top: 4, bottom: 4),
    child: ChoiceChip(
      label: Text('$text  $count'),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
    ),
  );

  Widget _row(BuildContext context, VerseRef ref, Set<String> highlight) {
    final scheme = Theme.of(context).colorScheme;
    final font = context.read<SettingsModel>().readerFont;
    return InkWell(
      onTap: () => openVerseRef(context, ref),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 52,
              child: Text(
                '${ref.chapter}:${ref.verse}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: scheme.primary,
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder(
                future: _words(ref),
                builder: (context, snap) {
                  final words = snap.data;
                  if (words == null) return const SizedBox(height: 20);
                  return Text.rich(
                    TextSpan(
                      children: [
                        for (final w in words) ...[
                          if (w.id > 0) const TextSpan(text: ' '),
                          TextSpan(
                            text: w.display,
                            style: highlight.contains(w.code)
                                ? TextStyle(
                                    color: scheme.primary,
                                    fontWeight: FontWeight.w700,
                                  )
                                : null,
                          ),
                        ],
                      ],
                    ),
                    style: readerTextStyle(
                      font,
                      fontSize: 15,
                      height: 1.45,
                      color: scheme.onSurface.withValues(alpha: 0.85),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
