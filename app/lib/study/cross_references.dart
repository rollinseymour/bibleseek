import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app_model.dart';
import '../bible/bible_library.dart';
import '../bible/bible_store.dart';
import '../bible/models.dart';
import '../reader/reader_model.dart';
import '../settings/settings_model.dart';
import '../widgets/verse_text.dart';

/// Cross-references from `content/crossrefs/<BOOK>.json`
/// (`{"CH:V": ["BOOK:CH:V", "BOOK:CH:V-END", …]}`): the app's hand-picked
/// list first, then OpenBible.info's by readers' votes (tool/pack_content.dart).
class CrossReferences {
  static final _books = <String, Future<Map<String, Object?>>>{};

  static Future<Map<String, Object?>> _load(String book) =>
      _books.putIfAbsent(book, () async {
        try {
          return await BibleStore.getJson('content/crossrefs/$book.json')
              as Map<String, Object?>;
        } catch (_) {
          _books.remove(book);
          rethrow;
        }
      });

  static Future<List<String>> related(
    String book,
    int chapter,
    int verse,
  ) async =>
      ((await _load(book))['$chapter:$verse'] as List?)
          ?.whereType<String>()
          .toList() ??
      const [];
}

class RelatedVerse {
  const RelatedVerse(this.reference, this.verse, this.target);
  final String reference;

  /// The first verse of a range.
  final Verse? verse;
  final ReaderTarget target;
}

/// Resolves "BOOK:CH:V" and "BOOK:CH:V-END" references to their names and
/// verse text in [version], all at once.
Future<List<RelatedVerse>> resolveTriples(
  BuildContext context,
  List<String> refs,
  String version,
) async {
  final library = context.read<BibleLibrary>();
  final store = context.read<BibleStore>();
  final redLetter = context.read<SettingsModel>().redLetter;
  Future<RelatedVerse?> resolve(String ref) async {
    final p = ref.split(':');
    if (p.length != 3) return null;
    final span = p[2].split('-');
    final ch = int.tryParse(p[1]);
    final v = int.tryParse(span[0]);
    final end = span.length == 2 ? int.tryParse(span[1]) : null;
    if (ch == null || v == null) return null;
    Verse? verse;
    try {
      verse = await store.verse(version, p[0], ch, v, redLetter: redLetter);
    } catch (_) {}
    return RelatedVerse(
      '${library.name(p[0])} $ch:$v${end == null ? '' : '–$end'}',
      verse,
      ReaderTarget(
        bookCode: p[0],
        chapter: ch,
        verse: v,
        endVerse: end,
        version: version,
      ),
    );
  }

  return (await Future.wait(refs.map(resolve))).nonNulls.toList();
}

class _RelatedTile extends StatelessWidget {
  const _RelatedTile(this.r, {this.onOpened});
  final RelatedVerse r;
  final VoidCallback? onOpened;

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: () {
      context.read<AppModel>().open(r.target);
      onOpened?.call();
    },
    title: Text(
      r.reference,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
    subtitle: Padding(
      padding: const EdgeInsets.only(top: 4),
      child: VerseText(r.verse, maxLines: 3, fontSize: 15),
    ),
  );
}

/// Look up a verse's cross-references; tap any result to read it.
class CrossReferencesScreen extends StatefulWidget {
  const CrossReferencesScreen({super.key});

  @override
  State<CrossReferencesScreen> createState() => _CrossReferencesScreenState();
}

class _CrossReferencesScreenState extends State<CrossReferencesScreen> {
  final _input = TextEditingController();
  Timer? _debounce;
  String _source = '';
  List<RelatedVerse> _results = const [];
  bool _failed = false;
  int _token = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _input.dispose();
    super.dispose();
  }

  void _changed(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _lookup);
  }

  Future<void> _lookup() async {
    final token = ++_token;
    final library = context.read<BibleLibrary>();
    final t = library.parseReference(_input.text);
    if (t == null || t.verse == null) {
      setState(() {
        _source = '';
        _results = const [];
        _failed = false;
      });
      return;
    }
    final version = ReadingPosition.load(context.read())?.version ?? 'KJV';
    final List<String> triples;
    try {
      triples = await CrossReferences.related(t.bookCode, t.chapter, t.verse!);
    } catch (_) {
      if (!mounted || token != _token) return;
      setState(() {
        _source = '${library.name(t.bookCode)} ${t.chapter}:${t.verse}';
        _results = const [];
        _failed = true;
      });
      return;
    }
    if (!mounted) return;
    final results = await resolveTriples(context, triples, version);
    if (!mounted || token != _token) return;
    setState(() {
      _source = '${library.name(t.bookCode)} ${t.chapter}:${t.verse}';
      _results = results;
      _failed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.6);
    return Scaffold(
      appBar: AppBar(title: const Text('Cross-References')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _input,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  onChanged: _changed,
                  decoration: const InputDecoration(
                    labelText: 'Verse',
                    hintText: 'e.g. John 3:16, 1 Cor 13:4, Ps 23:1',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              if (_source.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: Text(
                    _results.isEmpty
                        ? 'Cross-references for $_source'
                        : '${_results.length} cross-reference${_results.length == 1 ? '' : 's'} for $_source',
                    style: TextStyle(fontWeight: FontWeight.w600, color: muted),
                  ),
                ),
                if (_results.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _failed
                          ? 'Couldn’t load cross-references. Check your connection and try again.'
                          : 'No cross-references for $_source.',
                      style: TextStyle(color: muted),
                    ),
                  ),
                for (final r in _results) _RelatedTile(r),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

Future<T?> _sheet<T>(BuildContext context, String title, Widget body) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
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
            Expanded(child: body),
          ],
        ),
      ),
    );

/// Cross-references for one verse, from the reader's selection.
Future<void> showVerseRelated(
  BuildContext context, {
  required String book,
  required int chapter,
  required int verse,
  required String version,
}) => _sheet(
  context,
  '${context.read<BibleLibrary>().name(book)} $chapter:$verse',
  _RelatedList(
    load: (ctx) async {
      final refs = await CrossReferences.related(book, chapter, verse);
      if (!ctx.mounted) return const [];
      return [_Group(items: await resolveTriples(ctx, refs, version))];
    },
    empty: 'No cross-references for this verse.',
  ),
);

/// How many of each verse's cross-references the chapter view lists; the
/// verse's own sheet has the rest.
const _perVerseInChapter = 3;

/// The strongest cross-references for every verse in a chapter, grouped by
/// source verse.
Future<void> showChapterRelated(
  BuildContext context, {
  required String book,
  required int chapter,
  required String version,
  required List<int> verses,
}) {
  final name = context.read<BibleLibrary>().name(book);
  return _sheet(
    context,
    'Related · $name $chapter',
    _RelatedList(
      load: (ctx) async {
        Future<_Group?> group(int v) async {
          final refs = await CrossReferences.related(book, chapter, v);
          if (refs.isEmpty || !ctx.mounted) return null;
          return _Group(
            heading: '$name $chapter:$v',
            items: await resolveTriples(
              ctx,
              refs.take(_perVerseInChapter).toList(),
              version,
            ),
            total: refs.length,
            showAll: (c) => showVerseRelated(
              c,
              book: book,
              chapter: chapter,
              verse: v,
              version: version,
            ),
          );
        }

        return (await Future.wait(verses.map(group))).nonNulls.toList();
      },
      empty: 'No cross-references for this chapter.',
    ),
  );
}

class _Group {
  const _Group({
    required this.items,
    this.heading,
    this.total = 0,
    this.showAll,
  });
  final String? heading;
  final List<RelatedVerse> items;

  /// The verse's full count, when [items] is only the first few.
  final int total;
  final void Function(BuildContext)? showAll;
}

class _RelatedList extends StatefulWidget {
  const _RelatedList({required this.load, required this.empty});
  final Future<List<_Group>> Function(BuildContext) load;
  final String empty;

  @override
  State<_RelatedList> createState() => _RelatedListState();
}

class _RelatedListState extends State<_RelatedList> {
  late final _future = widget.load(context);

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _future,
    builder: (context, snap) {
      if (!snap.hasData) {
        return Center(
          child: snap.hasError
              ? const Text('Couldn’t load cross-references.')
              : const CircularProgressIndicator(),
        );
      }
      final groups = snap.data!.where((g) => g.items.isNotEmpty).toList();
      if (groups.isEmpty) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Text(widget.empty, textAlign: TextAlign.center),
        );
      }
      return ListView(
        children: [
          for (final g in groups) ...[
            if (g.heading != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        g.heading!,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (g.showAll != null && g.total > g.items.length)
                      TextButton(
                        onPressed: () => g.showAll!(context),
                        child: Text('All ${g.total}'),
                      ),
                  ],
                ),
              ),
            for (final r in g.items)
              _RelatedTile(
                r,
                // Closes this sheet and the chapter sheet under an "All" list.
                onOpened: () => Navigator.of(
                  context,
                ).popUntil((route) => route is! ModalBottomSheetRoute),
              ),
          ],
        ],
      );
    },
  );
}
