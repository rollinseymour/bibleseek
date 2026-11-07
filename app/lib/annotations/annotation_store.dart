import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../bible/bible_store.dart';
import '../data/prefs.dart';
import 'highlight_palette.dart';

class Bookmark {
  const Bookmark(this.reference, this.text);
  final String reference;
  final String text;
}

/// A hearted passage, kept apart from bookmarks.
class Favorite {
  const Favorite({
    required this.bookCode,
    required this.chapter,
    required this.verse,
    required this.endVerse,
    required this.version,
    required this.reference,
    required this.text,
    required this.addedAt,
  });

  final String bookCode;
  final int chapter;
  final int verse;

  /// Null for a single verse; greater than [verse] for a range.
  final int? endVerse;
  final String version;
  final String reference;
  final String text;

  /// Epoch milliseconds.
  final int addedAt;

  String get id =>
      AnnotationStore.favoriteKey(bookCode, chapter, verse, endVerse);

  Map<String, Object?> toJson() => {
    'bookCode': bookCode,
    'chapter': chapter,
    'verse': verse,
    if (endVerse != null) 'endVerse': endVerse,
    'version': version,
    'reference': reference,
    'text': text,
    'addedAt': addedAt,
  };

  /// Null only when the passage itself is missing; other fields fall back.
  static Favorite? fromJson(Map<String, Object?> o) {
    final book = o['bookCode'];
    final ch = _int(o['chapter']);
    final v = _int(o['verse']);
    if (book is! String || book.isEmpty || ch == null || v == null) return null;
    final rawEnd = _int(o['endVerse']);
    final end = rawEnd != null && rawEnd > v ? rawEnd : null;
    return Favorite(
      bookCode: book,
      chapter: ch,
      verse: v,
      endVerse: end,
      version: o['version'] as String? ?? '',
      reference:
          o['reference'] as String? ??
          '$book $ch:$v${end == null ? '' : '-$end'}',
      text: o['text'] as String? ?? '',
      addedAt: _int(o['addedAt']) ?? 0,
    );
  }
}

/// A recoverable deleted item (7-day retention).
class TrashItem {
  const TrashItem(this.deletedAt, this.kind, this.label, this.payload);

  /// Epoch milliseconds; unique per item.
  final int deletedAt;

  /// "annotation" | "bookmark" | "favorite".
  final String kind;
  final String label;
  final Object? payload;
}

int? _int(Object? v) => v is num ? v.toInt() : null;

/// Highlights, notes, bookmarks and favorites, under the iOS app's keys and
/// JSON shapes:
///
/// - `verse_annotations`: {"VERSION:BOOK:CH:V": {highlight, highlights, note, notes, noteTags, noteCreatedAt}}
/// - `saved_scriptures`: [{reference, text}]
/// - `favorite_scriptures`: [{bookCode, chapter, verse, endVerse?, version, reference, text, addedAt}]
///
/// Entries are kept as raw JSON maps so fields this build doesn't edit
/// (phrase-level `highlights`/`notes`) survive every write.
class AnnotationStore extends ChangeNotifier {
  AnnotationStore(this._prefs) {
    reload();
  }

  final Prefs _prefs;

  static const annotationsKey = 'verse_annotations';
  static const bookmarksKey = 'saved_scriptures';
  static const favoritesKey = 'favorite_scriptures';
  static const recentlyDeletedKey = 'verse_annotations.recently_deleted';
  static const _trashTtlMs = 7 * 24 * 60 * 60 * 1000;
  static const _trashCap = 200;

  Map<String, Map<String, Object?>> _entries = {};
  List<Bookmark> _bookmarks = [];
  List<Favorite> _favorites = [];
  List<TrashItem> _trash = [];

  List<Bookmark> get bookmarks => List.unmodifiable(_bookmarks);
  List<Favorite> get favorites => List.unmodifiable(_favorites);
  List<TrashItem> get trash => List.unmodifiable(_trash);

  void reload() {
    _trash = _loadAndPruneTrash();
    _entries = {};
    final raw = _decode(_prefs.getString(annotationsKey));
    if (raw is Map<String, Object?>) {
      raw.forEach((k, v) {
        if (v is Map<String, Object?>) _entries[k] = Map.of(v);
      });
    }
    final marks = _decode(_prefs.getString(bookmarksKey));
    _bookmarks = [
      if (marks is List)
        for (final m in marks.whereType<Map<String, Object?>>())
          if (m['reference'] is String)
            Bookmark(m['reference'] as String, m['text'] as String? ?? ''),
    ];
    final favs = _decode(_prefs.getString(favoritesKey));
    _favorites = [
      if (favs is List)
        for (final f in favs.whereType<Map<String, Object?>>())
          ?Favorite.fromJson(f),
    ];
    notifyListeners();
  }

  static Object? _decode(String? raw) {
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  static String key(String version, String book, int chapter, int verse) =>
      '$version:$book:$chapter:$verse';

  static int get _now => DateTime.now().millisecondsSinceEpoch;

  Map<String, Object?>? _entry(
    String version,
    String book,
    int chapter,
    int verse,
  ) => _entries[key(version, book, chapter, verse)];

  // MARK: highlights

  /// The explicit whole-verse `highlight`, else the first phrase highlight's color.
  String? highlightHex(String version, String book, int chapter, int verse) {
    final e = _entry(version, book, chapter, verse);
    final h = e?['highlight'];
    if (h is String && h.isNotEmpty) return h;
    final arr = e?['highlights'];
    if (arr is List &&
        arr.isNotEmpty &&
        arr.first is Map &&
        (arr.first as Map)['color'] is String) {
      return (arr.first as Map)['color'] as String;
    }
    return null;
  }

  /// Sets (or clears, with null) the whole-verse highlight. Phrase-level
  /// `highlights` are left untouched; the whole-verse one takes precedence.
  void setHighlight(
    String? hex,
    String version,
    String book,
    int chapter,
    int verse,
  ) {
    final k = key(version, book, chapter, verse);
    final e = Map<String, Object?>.of(_entries[k] ?? {});
    if (hex != null && hex.isNotEmpty) {
      e['highlight'] = hex;
      HighlightPalette.recordRecentIfCustom(_prefs, hex);
    } else {
      final old = e['highlight'];
      if (old is String && old.isNotEmpty) {
        _recordTrash('annotation', '$book $chapter:$verse', [
          {
            'key': k,
            'version': version,
            'bookCode': book,
            'chapter': chapter,
            'verse': verse,
            'highlight': old,
          },
        ]);
      }
      e.remove('highlight');
    }
    _put(k, e);
  }

  // MARK: notes

  String? noteText(String version, String book, int chapter, int verse) {
    final n = _entry(version, book, chapter, verse)?['note'];
    if (n is String && n.isNotEmpty) return n;
    if (n is List) {
      final texts = [
        for (final o in n)
          if (o is Map && o['text'] is String) o['text'] as String,
      ];
      return texts.isEmpty ? null : texts.join('\n');
    }
    return null;
  }

  bool hasNote(String version, String book, int chapter, int verse) =>
      noteText(version, book, chapter, verse) != null;

  /// Phrase-level highlight ranges `highlights:[{color,start,end}]` (UTF-16 offsets).
  List<({String color, int start, int end})> phraseHighlights(
    String version,
    String book,
    int chapter,
    int verse,
  ) {
    final arr = _entry(version, book, chapter, verse)?['highlights'];
    if (arr is! List) return const [];
    return [
      for (final o in arr.whereType<Map>())
        if (o['color'] is String &&
            _int(o['start']) != null &&
            _int(o['end']) != null &&
            _int(o['end'])! > _int(o['start'])!)
          (
            color: o['color'] as String,
            start: _int(o['start'])!,
            end: _int(o['end'])!,
          ),
    ];
  }

  /// Phrase-level notes `notes:[{start,end,text}]`.
  List<({int start, int end, String text})> phraseNotes(
    String version,
    String book,
    int chapter,
    int verse,
  ) {
    final arr = _entry(version, book, chapter, verse)?['notes'];
    if (arr is! List) return const [];
    return [
      for (final o in arr.whereType<Map>())
        if (o['text'] is String &&
            _int(o['start']) != null &&
            _int(o['end']) != null &&
            _int(o['end'])! > _int(o['start'])!)
          (
            start: _int(o['start'])!,
            end: _int(o['end'])!,
            text: o['text'] as String,
          ),
    ];
  }

  bool hasAnyNote(String version, String book, int chapter, int verse) =>
      hasNote(version, book, chapter, verse) ||
      phraseNotes(version, book, chapter, verse).isNotEmpty;

  List<String> noteTags(String version, String book, int chapter, int verse) {
    final t = _entry(version, book, chapter, verse)?['noteTags'];
    return t is List ? t.whereType<String>().toList() : const [];
  }

  /// Sets (or clears, with empty/null) the whole-verse note and its tags,
  /// stamping `noteCreatedAt` so the "a year ago" card can find it.
  void setNote(
    String? text,
    String version,
    String book,
    int chapter,
    int verse, {
    List<String> tags = const [],
  }) {
    final k = key(version, book, chapter, verse);
    final e = Map<String, Object?>.of(_entries[k] ?? {});
    final t = (text ?? '').trim();
    final cleanTags = [
      for (final tag in tags)
        if (tag.trim().isNotEmpty) tag.trim(),
    ];
    if (t.isEmpty) {
      final old = e['note'];
      if (old is String && old.isNotEmpty) {
        _recordTrash('annotation', '$book $chapter:$verse', [
          {
            'key': k,
            'version': version,
            'bookCode': book,
            'chapter': chapter,
            'verse': verse,
            'note': old,
            if (e['noteCreatedAt'] != null) 'noteCreatedAt': e['noteCreatedAt'],
            if (e['noteTags'] != null) 'noteTags': e['noteTags'],
          },
        ]);
      }
      e
        ..remove('note')
        ..remove('noteCreatedAt')
        ..remove('noteTags');
    } else {
      e['note'] = t;
      e['noteCreatedAt'] = _now;
      if (cleanTags.isEmpty) {
        e.remove('noteTags');
      } else {
        e['noteTags'] = cleanTags;
      }
    }
    _put(k, e);
  }

  /// The first other translation, in [BibleStore.versions] order, holding
  /// annotations on this verse, and how many.
  ({String version, int count})? siblingAnnotations(
    String version,
    String book,
    int chapter,
    int verse,
  ) {
    for (final other in BibleStore.versions) {
      if (other == version.toUpperCase()) continue;
      final e = _entries[key(other, book, chapter, verse)];
      if (e == null) continue;
      var count = 0;
      if (e['highlight'] is String && (e['highlight'] as String).isNotEmpty) {
        count++;
      }
      if (e['highlights'] is List) count += (e['highlights'] as List).length;
      if (e['note'] is String && (e['note'] as String).isNotEmpty) count++;
      if (e['notes'] is List) count += (e['notes'] as List).length;
      if (count > 0) return (version: other, count: count);
    }
    return null;
  }

  Iterable<({String version, String book, int chapter, int verse})>
  _keys() sync* {
    for (final k in _entries.keys) {
      final p = k.split(':');
      if (p.length != 4) continue;
      final ch = int.tryParse(p[2]);
      final v = int.tryParse(p[3]);
      if (ch == null || v == null) continue;
      yield (version: p[0], book: p[1], chapter: ch, verse: v);
    }
  }

  List<({String version, String book, int chapter, int verse, String note})>
  allNoteEntries() => [
    for (final k in _keys())
      if (noteText(k.version, k.book, k.chapter, k.verse) case final note?)
        (
          version: k.version,
          book: k.book,
          chapter: k.chapter,
          verse: k.verse,
          note: note,
        ),
  ];

  List<({String version, String book, int chapter, int verse, String hex})>
  allHighlightEntries() => [
    for (final k in _keys())
      if (highlightHex(k.version, k.book, k.chapter, k.verse) case final hex?)
        (
          version: k.version,
          book: k.book,
          chapter: k.chapter,
          verse: k.verse,
          hex: hex,
        ),
  ];

  /// Notes with their creation time (epoch ms), phrase notes included, for
  /// the "a year ago" card.
  List<
    ({
      String version,
      String book,
      int chapter,
      int verse,
      String text,
      int createdAt,
    })
  >
  datedNotes() => [
    for (final k in _keys())
      if (_entries[key(k.version, k.book, k.chapter, k.verse)]
          case final e?) ...[
        if (e['note'] case final String note when note.isNotEmpty)
          if (_int(e['noteCreatedAt']) case final ms?)
            (
              version: k.version,
              book: k.book,
              chapter: k.chapter,
              verse: k.verse,
              text: note,
              createdAt: ms,
            ),
        if (e['notes'] case final List notes)
          for (final n in notes.whereType<Map>())
            if (n['text'] case final String text)
              if (_int(n['createdAt']) case final ms?)
                (
                  version: k.version,
                  book: k.book,
                  chapter: k.chapter,
                  verse: k.verse,
                  text: text,
                  createdAt: ms,
                ),
      ],
  ];

  void _put(String k, Map<String, Object?> e) {
    if (e.isEmpty) {
      _entries.remove(k);
    } else {
      _entries[k] = e;
    }
    _prefs.setString(annotationsKey, jsonEncode(_entries));
    notifyListeners();
  }

  // MARK: bookmarks

  bool isBookmarked(String reference) =>
      _bookmarks.any((b) => b.reference == reference);

  void addBookmark(String reference, String text) {
    if (isBookmarked(reference)) return;
    _bookmarks.add(Bookmark(reference, text));
    _saveBookmarks();
  }

  void removeBookmark(String reference) {
    for (final b in _bookmarks) {
      if (b.reference == reference) {
        _recordTrash('bookmark', b.reference, {
          'reference': b.reference,
          'text': b.text,
        });
        break;
      }
    }
    _bookmarks.removeWhere((b) => b.reference == reference);
    _saveBookmarks();
  }

  void _saveBookmarks() {
    _prefs.setString(
      bookmarksKey,
      jsonEncode([
        for (final b in _bookmarks) {'reference': b.reference, 'text': b.text},
      ]),
    );
    notifyListeners();
  }

  // MARK: favorites

  /// "JHN:3:16-16": identity is the passage, independent of translation.
  static String favoriteKey(
    String book,
    int chapter,
    int verse,
    int? endVerse,
  ) {
    final end = (endVerse ?? verse) > verse ? endVerse! : verse;
    return '$book:$chapter:$verse-$end';
  }

  bool isFavorite(String book, int chapter, int verse, int? endVerse) {
    final k = favoriteKey(book, chapter, verse, endVerse);
    return _favorites.any((f) => f.id == k);
  }

  void addFavorite({
    required String book,
    required int chapter,
    required int verse,
    required int? endVerse,
    required String version,
    required String reference,
    required String text,
  }) {
    if (isFavorite(book, chapter, verse, endVerse)) return;
    _favorites.add(
      Favorite(
        bookCode: book,
        chapter: chapter,
        verse: verse,
        endVerse: (endVerse ?? verse) > verse ? endVerse : null,
        version: version,
        reference: reference,
        text: text,
        addedAt: _now,
      ),
    );
    _saveFavorites();
  }

  void removeFavorite(String book, int chapter, int verse, int? endVerse) {
    final k = favoriteKey(book, chapter, verse, endVerse);
    for (final f in _favorites) {
      if (f.id == k) {
        _recordTrash('favorite', f.reference, f.toJson());
        break;
      }
    }
    _favorites.removeWhere((f) => f.id == k);
    _saveFavorites();
  }

  void _saveFavorites() {
    _prefs.setString(
      favoritesKey,
      jsonEncode([for (final f in _favorites) f.toJson()]),
    );
    notifyListeners();
  }

  // MARK: recently deleted

  List<TrashItem> _loadAndPruneTrash() {
    final arr = _decode(_prefs.getString(recentlyDeletedKey));
    if (arr is! List) return [];
    final cutoff = _now - _trashTtlMs;
    final items = [
      for (final o in arr.whereType<Map<String, Object?>>())
        if (_int(o['deletedAt']) case final at?
            when at >= cutoff &&
                o['kind'] is String &&
                o.containsKey('payload'))
          TrashItem(
            at,
            o['kind'] as String,
            o['label'] as String? ?? '',
            o['payload'],
          ),
    ]..sort((a, b) => b.deletedAt.compareTo(a.deletedAt));
    return items;
  }

  void _saveTrash() {
    _prefs.setString(
      recentlyDeletedKey,
      jsonEncode([
        for (final t in _trash)
          {
            'deletedAt': t.deletedAt,
            'kind': t.kind,
            'label': t.label,
            'payload': t.payload,
          },
      ]),
    );
  }

  void _recordTrash(String kind, String label, Object payload) {
    var ms = _now;
    while (_trash.any((t) => t.deletedAt == ms)) {
      ms++;
    }
    _trash.insert(0, TrashItem(ms, kind, label, payload));
    if (_trash.length > _trashCap) _trash.removeRange(_trashCap, _trash.length);
    _saveTrash();
  }

  /// Re-applies a trashed snapshot and removes it from the trash.
  void restoreTrash(TrashItem item) {
    switch (item.kind) {
      case 'annotation':
        for (final snap
            in (item.payload as List? ?? const [])
                .whereType<Map<String, Object?>>()) {
          final k = snap['key'];
          if (k is! String) continue;
          final e = Map<String, Object?>.of(_entries[k] ?? {});
          for (final f in const [
            'highlight',
            'note',
            'noteCreatedAt',
            'noteTags',
            'highlights',
            'notes',
          ]) {
            if (snap.containsKey(f)) e[f] = snap[f];
          }
          if (e.isEmpty) {
            _entries.remove(k);
          } else {
            _entries[k] = e;
          }
        }
        _prefs.setString(annotationsKey, jsonEncode(_entries));
      case 'bookmark':
        final o = item.payload;
        if (o is Map && o['reference'] is String) {
          addBookmark(o['reference'] as String, o['text'] as String? ?? '');
        }
      case 'favorite':
        final o = item.payload;
        // Re-inserted as-is (not via addFavorite) so it keeps its addedAt.
        final f = o is Map<String, Object?> ? Favorite.fromJson(o) : null;
        if (f != null && !_favorites.any((x) => x.id == f.id)) {
          _favorites.add(f);
          _prefs.setString(
            favoritesKey,
            jsonEncode([for (final f in _favorites) f.toJson()]),
          );
        }
    }
    _trash.removeWhere((t) => t.deletedAt == item.deletedAt);
    _saveTrash();
    notifyListeners();
  }

  void purgeTrash(TrashItem item) {
    _trash.removeWhere((t) => t.deletedAt == item.deletedAt);
    _saveTrash();
    notifyListeners();
  }
}
