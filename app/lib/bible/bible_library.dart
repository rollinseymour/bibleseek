import '../app/app_model.dart';
import 'bible_store.dart';
import 'models.dart';

/// The 66-book index (codes, names, chapter counts) plus reference parsing
/// and canon-aware chapter navigation.
class BibleLibrary {
  BibleLibrary(this.books) : _byCode = {for (final b in books) b.id: b};

  final List<BibleBook> books;
  final Map<String, BibleBook> _byCode;

  static Future<BibleLibrary> load() async {
    final raw =
        await BibleStore.getJson('content/bible/books.json') as List<Object?>;
    var order = 0;
    return BibleLibrary([
      for (final b in raw.cast<Map<String, Object?>>())
        // "Psalms" reads as "Psalm" everywhere the app shows a book name.
        BibleBook(
          id: b['id'] as String,
          name: b['id'] == 'PSA' ? 'Psalm' : b['name'] as String,
          commonName: b['id'] == 'PSA' ? 'Psalm' : b['commonName'] as String,
          order: ++order,
          chapters: b['chapters'] as int,
        ),
    ]);
  }

  BibleBook? book(String code) => _byCode[code];
  int chapterCount(String code) => _byCode[code]?.chapters ?? 0;
  String name(String code) => _byCode[code]?.commonName ?? code;

  ({String book, int chapter})? previous(String code, int chapter) {
    if (chapter > 1) return (book: code, chapter: chapter - 1);
    final i = books.indexWhere((b) => b.id == code);
    if (i <= 0) return null;
    return (book: books[i - 1].id, chapter: books[i - 1].chapters);
  }

  ({String book, int chapter})? next(String code, int chapter) {
    final b = book(code);
    if (b == null) return null;
    if (chapter < b.chapters) return (book: code, chapter: chapter + 1);
    final i = books.indexWhere((x) => x.id == code);
    if (i < 0 || i >= books.length - 1) return null;
    return (book: books[i + 1].id, chapter: 1);
  }

  /// "Genesis 1:1", "1 Cor 13:4", "Ps 23", "Jn 1:1", "John3:16", "Romans 8:28-30".
  /// The verse is null when the reference names none.
  ReaderTarget? parseReference(String raw) {
    final p = parse(raw);
    if (p == null) return null;
    return ReaderTarget(
      bookCode: p.book.id,
      chapter: p.chapter,
      verse: p.start,
      endVerse: p.end,
    );
  }

  ({BibleBook book, int chapter, int? start, int? end})? parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final spaced = trimmed.toLowerCase().replaceAllMapped(
      _letterDigit,
      (m) => '${m[1]} ${m[2]}',
    );
    final m = _refPattern.firstMatch(spaced);
    if (m != null) {
      final book = _matchBook(m[1]!);
      final ch = int.tryParse(m[2]!);
      if (book == null || ch == null || ch < 1 || ch > book.chapters) {
        return null;
      }
      return (
        book: book,
        chapter: ch,
        start: m[3] == null ? null : int.tryParse(m[3]!),
        end: m[4] == null ? null : int.tryParse(m[4]!),
      );
    }
    final book = _matchBook(spaced);
    if (book != null) return (book: book, chapter: 1, start: null, end: null);
    return null;
  }

  /// Alias, then exact name, then a unique prefix, then a unique substring.
  BibleBook? _matchBook(String raw) {
    final p0 = raw.trim().toLowerCase();
    if (p0.isEmpty) return null;
    final p = _aliases[p0] ?? p0;
    List<String> names(BibleBook b) => [
      b.commonName.toLowerCase(),
      b.name.toLowerCase(),
    ];
    for (final b in books) {
      if (names(b).contains(p)) return b;
    }
    final starts = books
        .where((b) => names(b).any((n) => n.startsWith(p)))
        .toList();
    if (starts.length == 1) return starts.first;
    final contains = books
        .where((b) => names(b).any((n) => n.contains(p)))
        .toList();
    if (contains.length == 1) return contains.first;
    return null;
  }

  static final _refPattern = RegExp(
    r'^(.+?)\s+(\d+)(?::(\d+))?(?:\s*[-–]\s*(\d+))?$',
  );
  static final _letterDigit = RegExp(r'([a-z])(\d)');

  static const _aliases = {
    'psalms': 'psalm',
    'ps': 'psalm',
    'song': 'song of solomon',
    'songs': 'song of solomon',
    'sos': 'song of solomon',
    'mt': 'matthew',
    'matt': 'matthew',
    'mk': 'mark',
    'mrk': 'mark',
    'lk': 'luke',
    'luk': 'luke',
    'jn': 'john',
    'jhn': 'john',
    'rom': 'romans',
    'phil': 'philippians',
    'php': 'philippians',
    'col': 'colossians',
    'heb': 'hebrews',
    'jas': 'james',
    'jms': 'james',
    'rev': 'revelation',
    'gen': 'genesis',
    'exo': 'exodus',
    'ex': 'exodus',
    'lev': 'leviticus',
    'num': 'numbers',
    'deut': 'deuteronomy',
    'deu': 'deuteronomy',
    'josh': 'joshua',
    'jos': 'joshua',
    'jud': 'jude',
    'judg': 'judges',
    'jdg': 'judges',
    'eccl': 'ecclesiastes',
    'ecc': 'ecclesiastes',
    'isa': 'isaiah',
    'jer': 'jeremiah',
    'lam': 'lamentations',
    'ezek': 'ezekiel',
    'ezk': 'ezekiel',
    'dan': 'daniel',
    'hos': 'hosea',
    'obad': 'obadiah',
    'oba': 'obadiah',
    'jon': 'jonah',
    'mic': 'micah',
    'nah': 'nahum',
    'nam': 'nahum',
    'hab': 'habakkuk',
    'zeph': 'zephaniah',
    'zep': 'zephaniah',
    'hag': 'haggai',
    'zech': 'zechariah',
    'zec': 'zechariah',
    'mal': 'malachi',
    'phm': 'philemon',
    'i corinthians': '1 corinthians',
    'i cor': '1 corinthians',
    'ii corinthians': '2 corinthians',
    'ii cor': '2 corinthians',
    '1 cor': '1 corinthians',
    '2 cor': '2 corinthians',
    '1cor': '1 corinthians',
    '2cor': '2 corinthians',
    '1 thess': '1 thessalonians',
    '2 thess': '2 thessalonians',
    '1 tim': '1 timothy',
    '2 tim': '2 timothy',
    '1 sam': '1 samuel',
    '2 sam': '2 samuel',
    '1 kgs': '1 kings',
    '2 kgs': '2 kings',
    '1 chron': '1 chronicles',
    '2 chron': '2 chronicles',
    '1 chr': '1 chronicles',
    '2 chr': '2 chronicles',
    '1 pet': '1 peter',
    '2 pet': '2 peter',
    '1 jn': '1 john',
    '2 jn': '2 john',
    '3 jn': '3 john',
  };
}
