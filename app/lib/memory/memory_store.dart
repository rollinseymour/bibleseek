import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../data/prefs.dart';

class MemoryVerse {
  const MemoryVerse({
    required this.version,
    required this.bookCode,
    required this.chapter,
    required this.verse,
    required this.text,
    this.addedAt = 0,
    this.memorizedAt,
  });

  factory MemoryVerse.fromJson(Map<String, Object?> j) => MemoryVerse(
    version: j['version'] as String? ?? '',
    bookCode: j['bookCode'] as String? ?? '',
    chapter: (j['chapter'] as num?)?.toInt() ?? 0,
    verse: (j['verse'] as num?)?.toInt() ?? 0,
    text: j['text'] as String? ?? '',
    addedAt: (j['addedAt'] as num?)?.toInt() ?? 0,
    memorizedAt: (j['memorizedAt'] as num?)?.toInt(),
  );

  final String version;
  final String bookCode;
  final int chapter;
  final int verse;
  final String text;

  /// Epoch milliseconds.
  final int addedAt;
  final int? memorizedAt;

  String get id => '$version:$bookCode:$chapter:$verse';

  MemoryVerse copyWith({required int? memorizedAt}) => MemoryVerse(
    version: version,
    bookCode: bookCode,
    chapter: chapter,
    verse: verse,
    text: text,
    addedAt: addedAt,
    memorizedAt: memorizedAt,
  );

  Map<String, Object?> toJson() => {
    'version': version,
    'bookCode': bookCode,
    'chapter': chapter,
    'verse': verse,
    'text': text,
    'addedAt': addedAt,
    if (memorizedAt != null) 'memorizedAt': memorizedAt,
  };
}

/// Active and memorized verses under the iOS app's
/// `memory_verses_active` / `memory_verses_archived` keys.
class MemoryVerseStore extends ChangeNotifier {
  MemoryVerseStore(this._prefs) {
    reload();
  }

  final Prefs _prefs;
  static const activeKey = 'memory_verses_active';
  static const archivedKey = 'memory_verses_archived';

  List<MemoryVerse> _active = [];
  List<MemoryVerse> _archived = [];

  List<MemoryVerse> get active => List.unmodifiable(_active);
  List<MemoryVerse> get archived => List.unmodifiable(_archived);

  void reload() {
    _active = _decode(activeKey);
    _archived = _decode(archivedKey);
    notifyListeners();
  }

  List<MemoryVerse> _decode(String key) {
    try {
      final raw = jsonDecode(_prefs.getString(key) ?? '[]');
      return [
        for (final o in (raw as List).whereType<Map<String, Object?>>())
          MemoryVerse.fromJson(o),
      ];
    } catch (_) {
      return [];
    }
  }

  void _save() {
    _prefs.setString(
      activeKey,
      jsonEncode([for (final v in _active) v.toJson()]),
    );
    _prefs.setString(
      archivedKey,
      jsonEncode([for (final v in _archived) v.toJson()]),
    );
    notifyListeners();
  }

  bool isActive(String id) => _active.any((v) => v.id == id);

  void add({
    required String version,
    required String bookCode,
    required int chapter,
    required int verse,
    required String text,
  }) {
    final v = MemoryVerse(
      version: version,
      bookCode: bookCode,
      chapter: chapter,
      verse: verse,
      text: text,
      addedAt: DateTime.now().millisecondsSinceEpoch,
    );
    if (isActive(v.id)) return;
    _active.add(v);
    _save();
  }

  void removeActive(String id) {
    _active.removeWhere((v) => v.id == id);
    _save();
  }

  void removeArchived(String id) {
    _archived.removeWhere((v) => v.id == id);
    _save();
  }

  void markMemorized(String id) {
    final i = _active.indexWhere((v) => v.id == id);
    if (i < 0) return;
    _archived.add(
      _active
          .removeAt(i)
          .copyWith(memorizedAt: DateTime.now().millisecondsSinceEpoch),
    );
    _save();
  }

  void relearn(String id) {
    final i = _archived.indexWhere((v) => v.id == id);
    if (i < 0) return;
    _active.add(_archived.removeAt(i).copyWith(memorizedAt: null));
    _save();
  }
}
