import '../bible/bible_library.dart';
import '../bible/bible_store.dart';
import '../wordstudy/lexicon.dart';

class VerseHit {
  const VerseHit({
    required this.reference,
    required this.text,
    required this.version,
    required this.bookCode,
    required this.bookIndex,
    required this.chapter,
    required this.verse,
  });

  final String reference;
  final String text;
  final String version;
  final String bookCode;
  final int bookIndex;
  final int chapter;
  final int verse;
}

class _Row {
  const _Row(this.book, this.chapter, this.verse, this.text, this.lower);
  final int book;
  final int chapter;
  final int verse;
  final String text;
  final String lower;
}

/// Keyword search over every verse, one translation file at a time
/// (`content/search/<version>.json`), fetched the first time it's searched.
class VerseSearch {
  VerseSearch(this._library);
  final BibleLibrary _library;
  final _loaded = <String, Future<(List<String>, List<_Row>)>>{};

  bool isLoaded(String version) => _loaded.containsKey(version);

  Future<(List<String>, List<_Row>)> _rows(String version) =>
      _loaded.putIfAbsent(version, () async {
        try {
          final raw =
              await BibleStore.getJson(
                    'content/search/${version.toLowerCase()}.json',
                  )
                  as Map<String, Object?>;
          final books = (raw['b'] as List).cast<String>();
          return (
            books,
            [
              for (final r in (raw['v'] as List).cast<List>())
                _Row(
                  (r[0] as num).toInt(),
                  (r[1] as num).toInt(),
                  (r[2] as num).toInt(),
                  r[3] as String,
                  (r[3] as String).toLowerCase(),
                ),
            ],
          );
        } catch (_) {
          _loaded.remove(version);
          rethrow;
        }
      });

  /// [versions] empty means all. [testament] is all, old or new. [exact]
  /// matches whole words; otherwise any substring. Results run Genesis to
  /// Revelation, translations interleaved within each chapter.
  Future<List<VerseHit>> search(
    String query, {
    Set<String> versions = const {},
    String testament = 'all',
    bool exact = true,
    int? limit,
  }) async {
    final q = query.trim().toLowerCase();
    if (q.length < 3) return const [];
    final wanted = versions.isEmpty
        ? BibleStore.versions
        : BibleStore.versions.where(versions.contains).toList();
    final re = exact
        ? RegExp('(?:^|\\W)${RegExp.escape(q)}(?:\$|\\W)', caseSensitive: false)
        : null;
    final hits = <(int, VerseHit)>[];
    for (final (vi, version) in wanted.indexed) {
      final (books, rows) = await _rows(version);
      for (final r in rows) {
        final code = books[r.book];
        final nt = WordStudyData.isNewTestament(code);
        if (testament == 'new' && !nt) continue;
        if (testament == 'old' && nt) continue;
        if (!(re == null ? r.lower.contains(q) : re.hasMatch(r.text))) continue;
        hits.add((
          vi,
          VerseHit(
            reference: '${_library.name(code)} ${r.chapter}:${r.verse}',
            text: r.text,
            version: version,
            bookCode: code,
            bookIndex: r.book,
            chapter: r.chapter,
            verse: r.verse,
          ),
        ));
      }
    }
    hits.sort((a, b) {
      final x = a.$2, y = b.$2;
      if (x.bookIndex != y.bookIndex) return x.bookIndex.compareTo(y.bookIndex);
      if (x.chapter != y.chapter) return x.chapter.compareTo(y.chapter);
      if (a.$1 != b.$1) return a.$1.compareTo(b.$1);
      return x.verse.compareTo(y.verse);
    });
    final out = [for (final h in hits) h.$2];
    return limit == null || out.length <= limit ? out : out.sublist(0, limit);
  }
}
