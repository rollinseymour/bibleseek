import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../annotations/annotation_store.dart';
import '../annotations/highlight_palette.dart';
import '../app/app_model.dart';
import '../bible/bible_library.dart';
import '../bible/bible_store.dart';
import '../widgets/page_header.dart';

enum _Kind { highlight, note, bookmark, favorite }

enum _Filter {
  all('All'),
  favorites('Favorites'),
  highlights('Highlights'),
  notes('Notes'),
  bookmarks('Bookmarks');

  const _Filter(this.label);
  final String label;

  bool matches(_Kind k) => switch (this) {
    all => true,
    favorites => k == _Kind.favorite,
    highlights => k == _Kind.highlight,
    notes => k == _Kind.note,
    bookmarks => k == _Kind.bookmark,
  };
}

class _Entry {
  const _Entry({
    required this.kind,
    required this.reference,
    required this.snippet,
    required this.target,
    required this.book,
    required this.chapter,
    required this.verse,
    this.version = '',
    this.hex,
    this.bookmarkRefs = const [],
    this.highlightVerses = const [],
  });

  final _Kind kind;
  final String reference;
  final String snippet;
  final ReaderTarget? target;
  final String book;
  final int chapter;
  final int verse;
  final String version;
  final String? hex;

  /// Every bookmark behind a grouped range, removed together.
  final List<String> bookmarkRefs;

  /// Every verse in a grouped highlight run, removed together.
  final List<int> highlightVerses;
}

/// Favorites, highlights, notes and bookmarks together, with type filters.
/// Tap an entry to open it in the reader.
class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  late final AnnotationStore store;
  late final BibleLibrary library;
  late final BibleStore bible;
  late final AppModel app;
  List<_Entry> _entries = const [];
  _Filter _filter = _Filter.all;
  int _token = 0;

  @override
  void initState() {
    super.initState();
    store = context.read<AnnotationStore>()..addListener(_rebuild);
    library = context.read<BibleLibrary>();
    bible = context.read<BibleStore>();
    app = context.read<AppModel>()..addListener(_onApp);
    _filter = _filterFor(app.takePendingJournalFilter()) ?? _filter;
    _rebuild();
  }

  @override
  void dispose() {
    store.removeListener(_rebuild);
    app.removeListener(_onApp);
    super.dispose();
  }

  static _Filter? _filterFor(String? name) => name == null
      ? null
      : _Filter.values
            .where((f) => f.label.toLowerCase() == name.toLowerCase())
            .firstOrNull;

  void _onApp() {
    final f = _filterFor(app.takePendingJournalFilter());
    if (f != null) setState(() => _filter = f);
  }

  /// Strips pilcrows from stored text; older bookmarks saved the raw reader text.
  static String _clean(String s) => s.contains('¶')
      ? s.replaceAll('¶', ' ').split(' ').where((w) => w.isNotEmpty).join(' ')
      : s;

  int _order(String book) => library.book(book)?.order ?? 999;

  Future<void> _rebuild() async {
    final token = ++_token;
    final out = <_Entry>[];

    // Highlights: consecutive verses of the same version, chapter and color
    // read as one ranged entry.
    final hls = store.allHighlightEntries()
      ..sort((a, b) {
        final o = _order(a.book).compareTo(_order(b.book));
        if (o != 0) return o;
        if (a.version != b.version) return a.version.compareTo(b.version);
        if (a.chapter != b.chapter) return a.chapter.compareTo(b.chapter);
        return a.verse.compareTo(b.verse);
      });
    for (var i = 0; i < hls.length;) {
      var j = i;
      while (j + 1 < hls.length &&
          hls[j + 1].version == hls[i].version &&
          hls[j + 1].book == hls[i].book &&
          hls[j + 1].chapter == hls[i].chapter &&
          hls[j + 1].hex == hls[i].hex &&
          hls[j + 1].verse == hls[j].verse + 1) {
        j++;
      }
      final group = hls.sublist(i, j + 1);
      final first = group.first, last = group.last;
      final name = library.name(first.book);
      final texts = <String>[];
      for (final h in group) {
        try {
          texts.add(
            await bible.verseText(h.version, h.book, h.chapter, h.verse),
          );
        } catch (_) {
          texts.add('');
        }
      }
      if (token != _token) return;
      out.add(
        _Entry(
          kind: _Kind.highlight,
          reference: group.length == 1
              ? '$name ${first.chapter}:${first.verse}'
              : '$name ${first.chapter}:${first.verse}-${last.verse}',
          snippet: group.length == 1
              ? texts.first
              : [
                  for (final (k, h) in group.indexed) '${h.verse} ${texts[k]}',
                ].join('  '),
          hex: first.hex,
          target: ReaderTarget(
            bookCode: first.book,
            chapter: first.chapter,
            verse: first.verse,
            endVerse: group.length > 1 ? last.verse : null,
            version: first.version,
          ),
          version: first.version,
          book: first.book,
          chapter: first.chapter,
          verse: first.verse,
          highlightVerses: [for (final h in group) h.verse],
        ),
      );
      i = j + 1;
    }

    for (final n in store.allNoteEntries()) {
      out.add(
        _Entry(
          kind: _Kind.note,
          reference: '${library.name(n.book)} ${n.chapter}:${n.verse}',
          snippet: n.note,
          target: ReaderTarget(
            bookCode: n.book,
            chapter: n.chapter,
            verse: n.verse,
            version: n.version,
          ),
          version: n.version,
          book: n.book,
          chapter: n.chapter,
          verse: n.verse,
        ),
      );
    }

    // Bookmarks: consecutive verses in one chapter group into one entry.
    final marks = <({Bookmark b, ReaderTarget t})>[];
    for (final b in store.bookmarks) {
      final t = library.parseReference(b.reference);
      if (t == null || t.verse == null) {
        out.add(
          _Entry(
            kind: _Kind.bookmark,
            reference: b.reference,
            snippet: _clean(b.text),
            target: t,
            book: t?.bookCode ?? '',
            chapter: t?.chapter ?? 0,
            verse: 0,
            bookmarkRefs: [b.reference],
          ),
        );
      } else {
        marks.add((b: b, t: t));
      }
    }
    marks.sort((a, b) {
      final o = _order(a.t.bookCode).compareTo(_order(b.t.bookCode));
      if (o != 0) return o;
      if (a.t.chapter != b.t.chapter) return a.t.chapter.compareTo(b.t.chapter);
      return a.t.verse!.compareTo(b.t.verse!);
    });
    for (var i = 0; i < marks.length;) {
      var j = i;
      while (j + 1 < marks.length &&
          marks[j + 1].t.bookCode == marks[i].t.bookCode &&
          marks[j + 1].t.chapter == marks[i].t.chapter &&
          marks[j + 1].t.verse == marks[j].t.verse! + 1) {
        j++;
      }
      final group = marks.sublist(i, j + 1);
      final first = group.first.t, last = group.last.t;
      final name = library.name(first.bookCode);
      out.add(
        _Entry(
          kind: _Kind.bookmark,
          reference: group.length == 1
              ? '$name ${first.chapter}:${first.verse}'
              : '$name ${first.chapter}:${first.verse}-${last.verse}',
          snippet: group.length == 1
              ? _clean(group.first.b.text)
              : [
                  for (final g in group) '${g.t.verse} ${_clean(g.b.text)}',
                ].join('  '),
          target: ReaderTarget(
            bookCode: first.bookCode,
            chapter: first.chapter,
            verse: first.verse,
          ),
          book: first.bookCode,
          chapter: first.chapter,
          verse: first.verse!,
          bookmarkRefs: [for (final g in group) g.b.reference],
        ),
      );
      i = j + 1;
    }

    for (final f in store.favorites) {
      out.add(
        _Entry(
          kind: _Kind.favorite,
          reference: f.reference,
          snippet: _clean(f.text),
          target: ReaderTarget(
            bookCode: f.bookCode,
            chapter: f.chapter,
            verse: f.verse,
            endVerse: f.endVerse,
            version: f.version.isEmpty ? null : f.version,
          ),
          book: f.bookCode,
          chapter: f.chapter,
          verse: f.verse,
        ),
      );
    }

    out.sort((a, b) {
      final o = _order(a.book).compareTo(_order(b.book));
      if (o != 0) return o;
      if (a.chapter != b.chapter) return a.chapter.compareTo(b.chapter);
      return a.verse.compareTo(b.verse);
    });
    if (token == _token && mounted) setState(() => _entries = out);
  }

  void _delete(_Entry e) {
    final newestBefore = store.trash.isEmpty ? 0 : store.trash.first.deletedAt;
    switch (e.kind) {
      case _Kind.highlight:
        for (final v in e.highlightVerses) {
          store.setHighlight(null, e.version, e.book, e.chapter, v);
        }
      case _Kind.note:
        store.setNote(null, e.version, e.book, e.chapter, e.verse);
      case _Kind.bookmark:
        e.bookmarkRefs.forEach(store.removeBookmark);
      case _Kind.favorite:
        store.removeFavorite(e.book, e.chapter, e.verse, e.target?.endVerse);
    }
    final removed = [
      for (final t in store.trash)
        if (t.deletedAt > newestBefore) t,
    ];
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Removed ${e.reference}'),
          action: removed.isEmpty
              ? null
              : SnackBarAction(
                  label: 'Undo',
                  onPressed: () => removed.forEach(store.restoreTrash),
                ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = [
      for (final e in _entries)
        if (_filter.matches(e.kind)) e,
    ];
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PageHeader('Journal'),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    for (final f in _Filter.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                            '${f.label}  ${_entries.where((e) => f.matches(e.kind)).length}',
                          ),
                          selected: _filter == f,
                          showCheckmark: false,
                          onSelected: (_) => setState(() => _filter = f),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? _empty(scheme)
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 1, indent: 52),
                        itemBuilder: (context, i) => _row(filtered[i], scheme),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(_Entry e, ColorScheme scheme) => ListTile(
    onTap: e.target == null ? null : () => app.open(e.target!),
    leading: SizedBox(
      width: 20,
      child: Center(
        child: switch (e.kind) {
          _Kind.highlight => Container(
            width: 5,
            height: 36,
            decoration: BoxDecoration(
              color: colorFromHex(e.hex ?? 'FFD700'),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          _Kind.note => Icon(
            Icons.sticky_note_2_outlined,
            color: scheme.primary,
            size: 20,
          ),
          _Kind.bookmark => Icon(
            Icons.bookmark,
            color: scheme.primary,
            size: 20,
          ),
          _Kind.favorite => const Icon(
            Icons.favorite,
            color: Colors.red,
            size: 20,
          ),
        },
      ),
    ),
    title: Text(
      e.reference,
      style: const TextStyle(fontWeight: FontWeight.w600),
    ),
    subtitle: e.snippet.isEmpty
        ? null
        : Text(e.snippet, maxLines: 3, overflow: TextOverflow.ellipsis),
    trailing: IconButton(
      tooltip: 'Remove',
      icon: Icon(
        Icons.delete_outline,
        color: scheme.onSurface.withValues(alpha: 0.5),
      ),
      onPressed: () => _delete(e),
    ),
  );

  Widget _empty(ColorScheme scheme) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _filter == _Filter.favorites
                ? Icons.favorite_border
                : Icons.bookmark_border,
            size: 44,
            color: scheme.onSurface.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            _filter == _Filter.all
                ? 'Nothing saved yet'
                : 'No ${_filter.label.toLowerCase()}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Highlight, note, bookmark, or favorite verses in the reader and they’ll show up here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.6)),
          ),
        ],
      ),
    ),
  );
}
