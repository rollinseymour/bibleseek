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

/// Treasury of Scripture Knowledge cross-references from `cross_refs.json`
/// (`{"BOOK:CH:V": ["BOOK:CH:V", …]}`).
class CrossReferences {
  static Future<Map<String, List<String>>>? _loaded;

  static Future<Map<String, List<String>>> _load(BibleStore store) =>
      _loaded ??= () async {
        try {
          final raw =
              await store.data('cross_refs.json') as Map<String, Object?>;
          return {
            for (final e in raw.entries)
              e.key: (e.value as List).whereType<String>().toList(),
          };
        } catch (_) {
          _loaded = null;
          rethrow;
        }
      }();

  static Future<List<String>> related(
    BibleStore store,
    String book,
    int chapter,
    int verse,
  ) async => (await _load(store))['$book:$chapter:$verse'] ?? const [];
}

class RelatedVerse {
  const RelatedVerse(this.reference, this.verse, this.target);
  final String reference;
  final Verse? verse;
  final ReaderTarget target;
}

/// Resolves "BOOK:CH:V" triples to references and verse text in [version].
Future<List<RelatedVerse>> resolveTriples(
  BuildContext context,
  List<String> triples,
  String version,
) async {
  final library = context.read<BibleLibrary>();
  final store = context.read<BibleStore>();
  final redLetter = context.read<SettingsModel>().redLetter;
  final out = <RelatedVerse>[];
  for (final triple in triples) {
    final p = triple.split(':');
    final ch = p.length == 3 ? int.tryParse(p[1]) : null;
    final v = p.length == 3 ? int.tryParse(p[2]) : null;
    if (ch == null || v == null) continue;
    Verse? verse;
    try {
      verse = await store.verse(version, p[0], ch, v, redLetter: redLetter);
    } catch (_) {}
    out.add(
      RelatedVerse(
        '${library.name(p[0])} $ch:$v',
        verse,
        ReaderTarget(bookCode: p[0], chapter: ch, verse: v, version: version),
      ),
    );
  }
  return out;
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
      });
      return;
    }
    final version = ReadingPosition.load(context.read())?.version ?? 'KJV';
    final triples = await CrossReferences.related(
      context.read<BibleStore>(),
      t.bookCode,
      t.chapter,
      t.verse!,
    );
    if (!mounted) return;
    final results = await resolveTriples(context, triples, version);
    if (!mounted || token != _token) return;
    setState(() {
      _source = '${library.name(t.bookCode)} ${t.chapter}:${t.verse}';
      _results = results;
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
                      'No bundled cross-references for $_source yet. Try a verse from the Gospels or Romans.',
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
      final triples = await CrossReferences.related(
        ctx.read<BibleStore>(),
        book,
        chapter,
        verse,
      );
      if (!ctx.mounted) return const [];
      return [
        (heading: null, items: await resolveTriples(ctx, triples, version)),
      ];
    },
    empty: 'No cross-references for this verse.',
  ),
);

/// Cross-references for every verse in a chapter, grouped by source verse.
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
        final store = ctx.read<BibleStore>();
        final groups = <({String? heading, List<RelatedVerse> items})>[];
        for (final v in verses) {
          final triples = await CrossReferences.related(
            store,
            book,
            chapter,
            v,
          );
          if (triples.isEmpty || !ctx.mounted) continue;
          groups.add((
            heading: '$name $chapter:$v',
            items: await resolveTriples(ctx, triples, version),
          ));
        }
        return groups;
      },
      empty:
          'No bundled cross-references for this chapter. Try a chapter in the Gospels or Romans.',
    ),
  );
}

class _RelatedList extends StatefulWidget {
  const _RelatedList({required this.load, required this.empty});
  final Future<List<({String? heading, List<RelatedVerse> items})>> Function(
    BuildContext,
  )
  load;
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
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(
                  g.heading!,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            for (final r in g.items)
              _RelatedTile(r, onOpened: () => Navigator.pop(context)),
          ],
        ],
      );
    },
  );
}
