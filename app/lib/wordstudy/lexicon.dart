import 'dart:math';

import '../bible/bible_store.dart';

class StrongsEntry {
  const StrongsEntry({
    required this.number,
    required this.lemma,
    required this.translit,
    required this.gloss,
    this.pos,
  });

  /// "G2316" / "H430".
  final String number;
  final String lemma;
  final String translit;
  final String gloss;
  final String? pos;

  bool get isGreek => number.startsWith('G');
}

class VerseRef {
  const VerseRef(this.book, this.chapter, this.verse);
  final String book;
  final int chapter;
  final int verse;

  String get id => '$book.$chapter.$verse';

  @override
  bool operator ==(Object other) => other is VerseRef && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Everything the lexicon shards know about one Strong's number: occurrences,
/// how the KJV rendered it, and Strong's own entry.
class LexiconDetail {
  const LexiconDetail({
    required this.code,
    required this.occurrences,
    required this.verses,
    required this.renderings,
    required this.renderingsByVerse,
    this.pronunciation,
    this.derivation,
    this.definition,
    this.usage,
    this.related = const [],
    this.foldedFrom = const [],
  });

  final String code;

  /// Total occurrences; a verse can hold several.
  final int occurrences;
  final List<VerseRef> verses;

  /// How the KJV rendered it, most frequent first. "" = not translated.
  final List<({String text, int count})> renderings;

  /// For each entry of [verses], the rendering indices it uses.
  final List<List<int>> renderingsByVerse;
  final String? pronunciation;
  final String? derivation;
  final String? definition;
  final String? usage;

  /// Strong's numbers this one derives from or points to.
  final List<String> related;

  /// Classic numbers counted under this lemma (G2258 under G1510).
  final List<String> foldedFrom;

  List<VerseRef> versesWithRendering(int index) => [
    for (var i = 0; i < verses.length; i++)
      if (renderingsByVerse[i].contains(index)) verses[i],
  ];

  /// "116 occurrences in 106 verses".
  String get occurrenceLabel {
    final times = occurrences == 1
        ? '1 occurrence'
        : '${_n(occurrences)} occurrences';
    return occurrences == verses.length
        ? times
        : '$times in ${_n(verses.length)} verses';
  }
}

String _n(int n) =>
    n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

/// One example occurrence with its KJV verse text, the rendering word marked.
class WordExample {
  const WordExample({
    required this.ref,
    required this.word,
    required this.text,
  });
  final VerseRef ref;
  final String word;
  final String text;
}

/// A person or place sharing one Hebrew/Greek root.
class NameSense {
  const NameSense(this.raw);
  final Map<String, Object?> raw;

  String _s(String k) => raw[k] as String? ?? '';
  String get kind => _s('kind');
  String get name => _s('name');
  String get heb => _s('heb');
  String get hebT => _s('hebT');
  String get hebM => _s('hebM');
  String get hebS => _s('hebS');
  String get grk => _s('grk');
  String get grkT => _s('grkT');
  String get grkM => _s('grkM');
  String get grkS => _s('grkS');
  List<String> get bios =>
      (raw['bios'] as List? ?? const []).whereType<String>().toList();
  int get more => (raw['more'] as num?)?.toInt() ?? 0;
  bool get hasHeb => heb.isNotEmpty || hebS.isNotEmpty;
  bool get hasGrk => grk.isNotEmpty || grkS.isNotEmpty;
}

/// A name's meaning: rich BibleData senses, or Hitchcock one-liners.
class NameStudy {
  const NameStudy({
    required this.name,
    this.senses = const [],
    this.simpleMeanings = const [],
    required this.rich,
  });
  final String name;
  final List<NameSense> senses;
  final List<String> simpleMeanings;
  final bool rich;
}

/// One original-language word of a verse (STEPBible TAGNT/TAHOT, CC BY 4.0).
class InterlinearWord {
  const InterlinearWord({
    required this.index,
    required this.original,
    required this.translit,
    required this.english,
    required this.strongs,
    required this.grammar,
    required this.gloss,
  });

  final int index;
  final String original;
  final String translit;
  final String english;
  final String strongs;
  final String grammar;
  final String gloss;
}

class InterlinearChapter {
  const InterlinearChapter(this.rtl, this.verses);
  static const empty = InterlinearChapter(false, {});

  /// Hebrew chapters.
  final bool rtl;
  final Map<int, List<InterlinearWord>> verses;
}

/// One KJV word in English order with its Strong's number (BibleForge,
/// public domain). Supplied words were added by the translators.
class ReverseWord {
  const ReverseWord(this.index, this.english, this.strongs, this.supplied);
  final int index;
  final String english;
  final String strongs;
  final bool supplied;
}

/// A word of a verse as printed, with the Strong's number behind it in the KJV.
class AlignedWord {
  const AlignedWord({
    required this.id,
    required this.display,
    required this.key,
    this.code = '',
    this.supplied = false,
  });
  final int id;
  final String display;

  /// Letters only, lowercased.
  final String key;

  /// "" when none.
  final String code;
  final bool supplied;
}

/// Strong's lexicon, Bible names, interlinear and KJV tagging, fetched on
/// first use. Call [ready] before the synchronous lookups.
class WordStudyData {
  WordStudyData(this._store);
  final BibleStore _store;

  Map<String, Object?> _seed = const {};
  Map<String, Object?> _names = const {};
  Map<String, Object?> _hitchcock = const {};
  Future<void>? _ready;

  Future<void> ready() => _ready ??= () async {
    try {
      final results = await Future.wait([
        _store.data('strongs_seed.json'),
        _store.data('bible_names.json'),
        _store.data('hitchcock_names.json'),
      ]);
      _seed = results[0] as Map<String, Object?>;
      _names = results[1] as Map<String, Object?>;
      _hitchcock = results[2] as Map<String, Object?>;
    } catch (_) {
      _ready = null;
      rethrow;
    }
  }();

  bool get isReady => _seed.isNotEmpty;

  /// Canonical book order of the lexicon's verse numbers.
  static const books = [
    'GEN',
    'EXO',
    'LEV',
    'NUM',
    'DEU',
    'JOS',
    'JDG',
    'RUT',
    '1SA',
    '2SA',
    '1KI',
    '2KI',
    '1CH',
    '2CH',
    'EZR',
    'NEH',
    'EST',
    'JOB',
    'PSA',
    'PRO',
    'ECC',
    'SNG',
    'ISA',
    'JER',
    'LAM',
    'EZK',
    'DAN',
    'HOS',
    'JOL',
    'AMO',
    'OBA',
    'JON',
    'MIC',
    'NAM',
    'HAB',
    'ZEP',
    'HAG',
    'ZEC',
    'MAL',
    'MAT',
    'MRK',
    'LUK',
    'JHN',
    'ACT',
    'ROM',
    '1CO',
    '2CO',
    'GAL',
    'EPH',
    'PHP',
    'COL',
    '1TH',
    '2TH',
    '1TI',
    '2TI',
    'TIT',
    'PHM',
    'HEB',
    'JAS',
    '1PE',
    '2PE',
    '1JN',
    '2JN',
    '3JN',
    'JUD',
    'REV',
  ];

  static bool isNewTestament(String book) => books.indexOf(book) >= 39;

  /// "g26", "G 26", "H0430" → "G26" / "H430"; null if not a code.
  static String? normalizeCode(String raw) {
    final s = raw.toUpperCase().replaceAll(RegExp(r'\s'), '');
    if (s.isEmpty || (s[0] != 'G' && s[0] != 'H')) return null;
    final n = int.tryParse(s.substring(1));
    if (n == null || n <= 0) return null;
    return '${s[0]}$n';
  }

  static String _letters(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^\p{L}]', unicode: true), '');

  // MARK: Strong's

  StrongsEntry? entry(String code) {
    final o = _seed[code];
    if (o is! Map) return null;
    return StrongsEntry(
      number: o['number'] as String? ?? code,
      lemma: o['lemma'] as String? ?? '',
      translit: o['translit'] as String? ?? '',
      gloss: o['gloss'] as String? ?? '',
      pos: o['pos'] as String?,
    );
  }

  /// Entries for an English word (with singular/plural fallbacks), or the one
  /// entry for a Strong's number typed as "G26".
  List<StrongsEntry> lookup(String word) {
    final code = normalizeCode(word);
    if (code != null) {
      final e = entry(code);
      if (e != null) return [e];
    }
    final cleaned = _letters(word);
    if (cleaned.isEmpty) return const [];
    final words = _seed['_words'];
    if (words is! Map) return const [];
    for (final form in _inflections(cleaned)) {
      final codes = words[form];
      if (codes is List) {
        final seen = <String>{};
        return [
          for (final c in codes.whereType<String>())
            if (seen.add(c)) ?entry(c),
        ];
      }
    }
    return const [];
  }

  static List<String> _inflections(String w) => [
    w,
    if (w.length >= 4 && w.endsWith('ies')) '${w.substring(0, w.length - 3)}y',
    if (w.length >= 4 && w.endsWith('es')) w.substring(0, w.length - 2),
    if (w.length >= 4 && w.endsWith('s') && !w.endsWith('ss'))
      w.substring(0, w.length - 1),
    if (w.length >= 3 && w.endsWith('y')) '${w.substring(0, w.length - 1)}ies',
    if (w.length >= 3) '${w}s',
    if (w.length >= 3) '${w}es',
  ];

  List<String> words() =>
      (_seed['_words'] as Map?)?.keys.whereType<String>().toList() ?? const [];

  // MARK: lexicon shards

  final _shards = <String, Future<Map<String, Object?>>>{};
  final _details = <String, LexiconDetail?>{};

  LexiconDetail? cachedDetail(String code) => _details[code];

  Future<LexiconDetail?> detail(String raw) async {
    final code = normalizeCode(raw);
    if (code == null) return null;
    if (_details.containsKey(code)) return _details[code];
    final name = '${code[0]}${int.parse(code.substring(1)) ~/ 100}';
    final shard = await _shards.putIfAbsent(name, () async {
      try {
        return await BibleStore.getJson('content/lexicon/$name.json')
            as Map<String, Object?>;
      } catch (_) {
        _shards.remove(name);
        rethrow;
      }
    });
    final o = shard[code];
    return _details[code] = o is Map<String, Object?> ? _decode(code, o) : null;
  }

  static LexiconDetail _decode(String code, Map<String, Object?> raw) {
    final refs = <VerseRef>[
      for (final n in (raw['r'] as List? ?? const []).whereType<num>())
        if (n.toInt() ~/ 1000000 < books.length)
          VerseRef(
            books[n.toInt() ~/ 1000000],
            n.toInt() ~/ 1000 % 1000,
            n.toInt() % 1000,
          ),
    ];
    final renderings = [
      for (final p in (raw['k'] as List? ?? const []).whereType<List>())
        if (p.length == 2 && p[0] is String && p[1] is num)
          (text: p[0] as String, count: (p[1] as num).toInt()),
    ];
    final byVerse = [
      for (final item in raw['kr'] as List? ?? const [])
        item is num
            ? (item >= 0 ? [item.toInt()] : <int>[])
            : [for (final i in (item as List).whereType<num>()) i.toInt()],
    ];
    return LexiconDetail(
      code: code,
      occurrences: (raw['n'] as num?)?.toInt() ?? refs.length,
      verses: refs,
      renderings: renderings,
      renderingsByVerse: byVerse.length == refs.length
          ? byVerse
          : [for (final _ in refs) <int>[]],
      pronunciation: raw['p'] as String?,
      derivation: raw['d'] as String?,
      definition: raw['f'] as String?,
      usage: raw['u'] as String?,
      related: (raw['x'] as List? ?? const []).whereType<String>().toList(),
      foldedFrom: (raw['fo'] as List? ?? const []).whereType<String>().toList(),
    );
  }

  // MARK: names

  static const _nameAliases = {
    'jonas': 'jonah',
    'elias': 'elijah',
    'eliseus': 'elisha',
    'esaias': 'isaiah',
    'jeremias': 'jeremiah',
    'jeremy': 'jeremiah',
    'noe': 'noah',
    'osee': 'hosea',
    'core': 'korah',
    'agar': 'hagar',
    'ezekias': 'hezekiah',
    'josias': 'josiah',
    'ozias': 'uzziah',
    'jechonias': 'jeconiah',
    'roboam': 'rehoboam',
    'naasson': 'nahshon',
    'booz': 'boaz',
    'zorobabel': 'zerubbabel',
    'juda': 'judah',
    'thara': 'terah',
    'phalec': 'peleg',
    'ragau': 'reu',
    'saruch': 'serug',
    'nachor': 'nahor',
    'sala': 'shelah',
    'cainan': 'kenan',
    'henoch': 'enoch',
    'mathusala': 'methuselah',
    'marcus': 'mark',
    'lucas': 'luke',
    'timotheus': 'timothy',
    'silvanus': 'silas',
    'cis': 'kish',
    'melchisedec': 'melchizedek',
    'zacharias': 'zechariah',
    'abia': 'abijah',
    'manasses': 'manasseh',
    'josaphat': 'jehoshaphat',
    'joram': 'jehoram',
    'salathiel': 'shealtiel',
    'sadoc': 'zadok',
    'sychem': 'shechem',
    'jude': 'judas',
  };

  NameStudy? name(String word) {
    final key = _letters(word);
    if (key.isEmpty) return null;
    final lookupKey = _names.containsKey(key)
        ? key
        : (_nameAliases[key] ?? key);
    final rich = _names[lookupKey];
    if (rich is List && rich.isNotEmpty) {
      final senses = [
        for (final s in rich.whereType<Map<String, Object?>>()) NameSense(s),
      ];
      if (senses.isNotEmpty) {
        final n = senses.first.name;
        return NameStudy(
          name: n.isNotEmpty ? n : _capitalized(word),
          senses: senses,
          rich: true,
        );
      }
    }
    final simple = _hitchcock[lookupKey];
    if (simple is List && simple.isNotEmpty) {
      final meanings = [
        for (final m in simple.whereType<Map>())
          if (m['meaning'] is String && (m['meaning'] as String).isNotEmpty)
            m['meaning'] as String,
      ];
      if (meanings.isNotEmpty) {
        final first = simple.first;
        final n = first is Map ? first['name'] as String? : null;
        return NameStudy(
          name: n ?? _capitalized(word),
          simpleMeanings: meanings,
          rich: false,
        );
      }
    }
    return null;
  }

  List<String> nameKeys() => _names.keys.toList();

  static String _capitalized(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

  // MARK: interlinear & KJV tagging

  final _interlinear = <String, Future<InterlinearChapter>>{};
  final _reverse = <String, Future<Map<int, List<ReverseWord>>>>{};

  Future<InterlinearChapter> interlinear(
    String book,
    int chapter,
  ) => _interlinear.putIfAbsent('$book:$chapter', () async {
    try {
      final root =
          await BibleStore.getJson('content/interlinear/$book/$chapter.json')
              as Map<String, Object?>;
      final v = root['v'] as Map<String, Object?>? ?? const {};
      return InterlinearChapter(root['rtl'] == true, {
        for (final e in v.entries)
          ?int.tryParse(e.key): [
            for (final (i, r) in (e.value as List).whereType<List>().indexed)
              InterlinearWord(
                index: i,
                original: _at(r, 0),
                translit: cleanTranslit(_at(r, 1), _at(r, 0)),
                english: _at(r, 2),
                strongs: _at(r, 3),
                grammar: _at(r, 4),
                gloss: cleanGloss(_at(r, 5)),
              ),
          ],
      });
    } catch (_) {
      _interlinear.remove('$book:$chapter');
      return InterlinearChapter.empty;
    }
  });

  Future<Map<int, List<ReverseWord>>> reverse(String book, int chapter) =>
      _reverse.putIfAbsent('$book:$chapter', () async {
        try {
          final root =
              await BibleStore.getJson('content/reverse/$book/$chapter.json')
                  as Map<String, Object?>;
          final v = root['v'] as Map<String, Object?>? ?? const {};
          return {
            for (final e in v.entries)
              ?int.tryParse(e.key): [
                for (final (i, r)
                    in (e.value as List).whereType<List>().indexed)
                  ReverseWord(i, _at(r, 0), _at(r, 1), r.length > 2),
              ],
          };
        } catch (_) {
          _reverse.remove('$book:$chapter');
          return const {};
        }
      });

  static String _at(List r, int i) =>
      i < r.length && r[i] is String ? r[i] as String : '';

  /// A combining iota subscript transliterates as a stray "a" after the eta
  /// ("tēa" for τῇ); drop it.
  static String cleanTranslit(String translit, String original) {
    if (!original.contains('ͅ')) return translit;
    final i = translit.lastIndexOf('ēa');
    return i < 0 ? translit : translit.replaceRange(i, i + 2, 'ē');
  }

  /// The Hebrew source's gloss is lexicon markup ("and/H9009=ה=the/{H0776G=אֶרֶץ=: country;_planet");
  /// keep the last lexical segment's gloss and tidy sense separators.
  static String cleanGloss(String raw) {
    var text = raw;
    if (text.contains('=') || text.contains('{')) {
      final segments = text.split('/');
      final lexical = segments.lastWhere(
        (s) => s.contains('='),
        orElse: () => segments.last,
      );
      final eq = lexical.lastIndexOf('=');
      text = eq < 0 ? lexical : lexical.substring(eq + 1);
    }
    text = text.replaceAll(RegExp(r'^[{}: ]+|[{}: ]+$'), '');
    text = text
        .replaceAll(';_', ', ')
        .replaceAll('_', ' ')
        .replaceAll(';', ', ');
    return text.trim();
  }

  static List<AlignedWord> plainWords(String verseText) => [
    for (final (i, s)
        in verseText.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).indexed)
      AlignedWord(id: i, display: s, key: _letters(s)),
  ];

  /// Lines the KJV text up with BibleForge's KJV-order Strong's tags word by
  /// word; a short lookahead absorbs spelling variants and split words.
  Future<List<AlignedWord>> alignKjv(
    String verseText,
    String book,
    int chapter,
    int verse,
  ) async {
    final raw = verseText
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();
    final keys = [for (final s in raw) _letters(s)];
    final tags = <({String key, String code, bool supplied})>[];
    for (final w
        in (await reverse(book, chapter))[verse] ?? const <ReverseWord>[]) {
      if (w.english.isEmpty) continue;
      for (final piece in w.english.split(RegExp(r'\s+'))) {
        final k = _letters(piece);
        if (k.isNotEmpty) {
          tags.add((
            key: k,
            code: w.supplied ? '' : w.strongs,
            supplied: w.supplied,
          ));
        }
      }
    }
    final codes = List.filled(raw.length, '');
    final supplied = List.filled(raw.length, false);
    var i = 0, j = 0;
    while (i < raw.length && j < tags.length) {
      if (keys[i].isEmpty) {
        i++;
        continue;
      }
      if (keys[i] != tags[j].key) {
        int? ahead;
        for (var a = j + 1; a < min(j + 5, tags.length); a++) {
          if (tags[a].key == keys[i]) {
            ahead = a;
            break;
          }
        }
        int? behind;
        for (var b = i + 1; b < min(i + 5, raw.length); b++) {
          if (keys[b] == tags[j].key) {
            behind = b;
            break;
          }
        }
        if (ahead != null && (behind == null || ahead - j <= behind - i)) {
          j = ahead;
          continue;
        }
        if (behind != null) {
          i = behind;
          continue;
        }
      }
      codes[i] = tags[j].code;
      supplied[i] = tags[j].supplied;
      i++;
      j++;
    }
    return [
      for (var k = 0; k < raw.length; k++)
        AlignedWord(
          id: k,
          display: raw[k],
          key: keys[k],
          code: codes[k],
          supplied: supplied[k],
        ),
    ];
  }

  /// Up to [limit] example verses spread across a number's occurrences, each
  /// with the KJV words that render it.
  Future<List<WordExample>> examples(String code, {int limit = 3}) async {
    final d = await detail(code);
    if (d == null || d.verses.isEmpty || limit <= 0) return const [];
    final codes = {d.code, ...d.foldedFrom};
    final slices = min(limit, d.verses.length);
    final out = <WordExample>[];
    for (var k = 0; k < slices; k++) {
      final slice = d.verses.sublist(
        k * d.verses.length ~/ slices,
        (k + 1) * d.verses.length ~/ slices,
      );
      for (final ref in slice.take(6)) {
        final ex = await _example(ref, codes);
        if (ex != null) {
          out.add(ex);
          break;
        }
      }
    }
    return out;
  }

  Future<WordExample?> _example(VerseRef ref, Set<String> codes) async {
    final String text;
    try {
      text = (await _store.verseText(
        'KJV',
        ref.book,
        ref.chapter,
        ref.verse,
      )).trim();
    } catch (_) {
      return null;
    }
    if (text.isEmpty) return null;
    final words = await alignKjv(text, ref.book, ref.chapter, ref.verse);
    final start = words.indexWhere((w) => codes.contains(w.code));
    if (start < 0) return null;
    final word = words
        .skip(start)
        .takeWhile((w) => codes.contains(w.code))
        .map((w) => w.display)
        .join(' ')
        .replaceAll(
          RegExp(r'^[^\p{L}\p{N}]+|[^\p{L}\p{N}]+$', unicode: true),
          '',
        );
    if (word.isEmpty) return null;
    return WordExample(ref: ref, word: word, text: text);
  }
}
