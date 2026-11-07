import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../bible/bible_library.dart';
import '../bible/bible_store.dart';
import '../bible/models.dart';
import '../data/prefs.dart';
import '../settings/settings_model.dart';

/// The last reading position, under the iOS app's `last_reading_position` key:
/// {"version":"KJV","bookCode":"GEN","bookName":"Genesis","chapter":1}
class ReadingPosition {
  const ReadingPosition(
    this.version,
    this.bookCode,
    this.bookName,
    this.chapter,
  );

  static const key = 'last_reading_position';
  static const fallback = ReadingPosition('KJV', 'GEN', 'Genesis', 1);

  final String version;
  final String bookCode;
  final String bookName;
  final int chapter;

  static ReadingPosition? load(Prefs prefs) {
    final raw = prefs.getString(key);
    if (raw == null) return null;
    try {
      final o = jsonDecode(raw) as Map<String, Object?>;
      return ReadingPosition(
        o['version'] as String? ?? 'KJV',
        o['bookCode'] as String? ?? 'GEN',
        o['bookName'] as String? ?? 'Genesis',
        (o['chapter'] as num?)?.toInt() ?? 1,
      );
    } catch (_) {
      return null;
    }
  }

  void save(Prefs prefs) => prefs.setString(
    key,
    jsonEncode({
      'version': version,
      'bookCode': bookCode,
      'bookName': bookName,
      'chapter': chapter,
    }),
  );
}

/// Reader state: the position, loaded verses and the verse selection.
class ReaderModel extends ChangeNotifier {
  ReaderModel({
    required this.library,
    required this.store,
    required this.settings,
    required this.prefs,
  }) {
    final p = ReadingPosition.load(prefs) ?? ReadingPosition.fallback;
    version = BibleStore.versions.contains(p.version.toUpperCase())
        ? p.version.toUpperCase()
        : 'KJV';
    bookCode = library.book(p.bookCode) == null ? 'GEN' : p.bookCode;
    chapter = p.chapter.clamp(1, library.chapterCount(bookCode));
    _redLetter = settings.redLetter;
    settings.addListener(_onSettings);
    reload();
  }

  final BibleLibrary library;
  final BibleStore store;
  final SettingsModel settings;
  final Prefs prefs;

  late String version;
  late String bookCode;
  late int chapter;
  late bool _redLetter;

  List<Verse> verses = const [];
  bool loading = true;
  Object? error;
  final Set<int> selected = {};

  /// A verse to scroll to after the chapter loads (deep link / go to verse).
  int? scrollTarget;
  int? scrollTargetEnd;

  int _loadToken = 0;

  String get bookName => library.name(bookCode);
  String get reference => '$bookName $chapter';
  String get positionKey => '$version|$bookCode|$chapter';

  bool get canGoPrevious => library.previous(bookCode, chapter) != null;
  bool get canGoNext => library.next(bookCode, chapter) != null;

  String? get previousReference {
    final p = library.previous(bookCode, chapter);
    return p == null ? null : '${library.name(p.book)} ${p.chapter}';
  }

  String? get nextReference {
    final n = library.next(bookCode, chapter);
    return n == null ? null : '${library.name(n.book)} ${n.chapter}';
  }

  void _onSettings() {
    if (settings.redLetter != _redLetter) {
      _redLetter = settings.redLetter;
      reload();
    }
  }

  Future<void> reload() async {
    final token = ++_loadToken;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final result = await store.chapter(
        version,
        bookCode,
        chapter,
        redLetter: _redLetter,
      );
      if (token != _loadToken) return;
      verses = result;
      loading = false;
      notifyListeners();
      final n = library.next(bookCode, chapter);
      if (n != null) {
        store
            .chapter(version, n.book, n.chapter, redLetter: _redLetter)
            .ignore();
      }
    } catch (e) {
      if (token != _loadToken) return;
      error = e;
      loading = false;
      notifyListeners();
    }
  }

  void _persist() =>
      ReadingPosition(version, bookCode, bookName, chapter).save(prefs);

  void goPrevious() {
    final p = library.previous(bookCode, chapter);
    if (p != null) move(p.book, p.chapter);
  }

  void goNext() {
    final n = library.next(bookCode, chapter);
    if (n != null) move(n.book, n.chapter);
  }

  void move(
    String book,
    int chapter, {
    int? verse,
    int? endVerse,
    String? version,
  }) {
    if (version != null &&
        BibleStore.versions.contains(version.toUpperCase())) {
      this.version = version.toUpperCase();
    }
    bookCode = book;
    // Clamped so an out-of-range link can't land on a blank page.
    this.chapter = chapter.clamp(1, max(1, library.chapterCount(book)));
    selected.clear();
    scrollTarget = verse;
    scrollTargetEnd = endVerse;
    _persist();
    reload();
  }

  void switchVersion(String v) {
    if (v == version) return;
    version = v;
    _persist();
    reload();
  }

  void toggleSelect(int verse) {
    if (!selected.remove(verse)) selected.add(verse);
    notifyListeners();
  }

  void clearSelection() {
    if (selected.isEmpty) return;
    selected.clear();
    notifyListeners();
  }

  /// "Genesis 1:1-4" / "Genesis 1:7-9, 14, 16-26".
  String get selectedReference =>
      selected.isEmpty ? '' : '$bookName $chapter:${collapsedRanges(selected)}';

  static String collapsedRanges(Iterable<int> nums) {
    final sorted = nums.toList()..sort();
    final parts = <String>[];
    var i = 0;
    while (i < sorted.length) {
      var j = i;
      while (j + 1 < sorted.length && sorted[j + 1] == sorted[j] + 1) {
        j++;
      }
      parts.add(i == j ? '${sorted[i]}' : '${sorted[i]}-${sorted[j]}');
      i = j + 1;
    }
    return parts.join(', ');
  }

  /// Contiguous runs of the selection, e.g. 1-3 and 7.
  List<({int start, int end})> get selectedRuns {
    final runs = <({int start, int end})>[];
    for (final v in selected.toList()..sort()) {
      if (runs.isNotEmpty && v == runs.last.end + 1) {
        runs[runs.length - 1] = (start: runs.last.start, end: v);
      } else {
        runs.add((start: v, end: v));
      }
    }
    return runs;
  }

  String textOf(int verse) {
    for (final v in verses) {
      if (v.number == verse) return v.plainText;
    }
    return '';
  }

  /// The selected verses' text; a skipped gap gets an ellipsis so the quote
  /// doesn't read as one continuous passage.
  String selectedPlainText() {
    final out = StringBuffer();
    int? prev;
    for (final n in selected.toList()..sort()) {
      final t = textOf(n);
      if (t.isEmpty) continue;
      if (out.isNotEmpty) out.write(prev != null && n > prev + 1 ? ' … ' : ' ');
      out.write(t);
      prev = n;
    }
    return out.toString();
  }

  /// Copy/share text: the verses in quotation marks, then the reference.
  String selectedText() =>
      '“${selectedPlainText()}”\n— $selectedReference ($version)';

  @override
  void dispose() {
    settings.removeListener(_onSettings);
    super.dispose();
  }
}
