import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../bible/bible_library.dart';
import '../data/prefs.dart';

/// One day's assignment: a chapter range in one book.
class DailyReading {
  const DailyReading(
    this.bookCode,
    this.bookName,
    this.startChapter,
    this.endChapter,
  );
  final String bookCode;
  final String bookName;
  final int startChapter;
  final int endChapter;

  String get label => startChapter == endChapter
      ? '$bookName $startChapter'
      : '$bookName $startChapter–$endChapter';
}

class ReadingPlan {
  const ReadingPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.totalDays,
    required this.dailyReadings,
    this.isCustom = false,
  });

  final String id;
  final String name;
  final String description;
  final int totalDays;

  /// Index = day − 1.
  final List<List<DailyReading>> dailyReadings;
  final bool isCustom;

  List<DailyReading> readingsFor(int day) =>
      day >= 0 && day < dailyReadings.length ? dailyReadings[day] : const [];
}

/// A stored custom plan (regenerated into a [ReadingPlan] on load), in the
/// iOS app's `reading_plan_custom` shape.
class CustomPlanDef {
  const CustomPlanDef({
    required this.id,
    required this.name,
    required this.description,
    required this.books,
    required this.totalDays,
  });

  factory CustomPlanDef.fromJson(Map<String, Object?> j) => CustomPlanDef(
    id:
        j['id'] as String? ??
        '${PlanStore.customIdPrefix}${DateTime.now().microsecondsSinceEpoch}',
    name: j['name'] as String? ?? 'Custom plan',
    description: j['description'] as String? ?? 'Custom plan',
    books: (j['books'] as List? ?? const []).whereType<String>().toList(),
    totalDays: (j['totalDays'] as num?)?.toInt() ?? 1,
  );

  final String id;
  final String name;
  final String description;
  final List<String> books;
  final int totalDays;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'books': books,
    'totalDays': totalDays,
  };
}

/// The three built-in plans plus custom ones, built by spreading chapters
/// evenly across days.
class ReadingPlanCatalog {
  static List<ReadingPlan> builtIns(BibleLibrary library) {
    final all = library.books;
    final gospels = all
        .where((b) => const {'MAT', 'MRK', 'LUK', 'JHN'}.contains(b.id))
        .toList();
    final nt = all.skipWhile((b) => b.id != 'MAT').toList();
    return [
      ReadingPlan(
        id: 'bible_in_a_year',
        name: 'Bible in a Year',
        description:
            'Read through the entire Bible in 365 days — about 3 chapters a day.',
        totalDays: 365,
        dailyReadings: distribute([
          for (final b in all) (b.id, b.commonName, b.chapters),
        ], 365),
      ),
      ReadingPlan(
        id: 'gospels_30',
        name: 'Gospels in 30 Days',
        description: 'Walk through Matthew, Mark, Luke, and John in a month.',
        totalDays: 30,
        dailyReadings: distribute([
          for (final b in gospels) (b.id, b.commonName, b.chapters),
        ], 30),
      ),
      ReadingPlan(
        id: 'nt_90',
        name: 'New Testament in 90 Days',
        description: 'Cover the entire New Testament in three months.',
        totalDays: 90,
        dailyReadings: distribute([
          for (final b in nt) (b.id, b.commonName, b.chapters),
        ], 90),
      ),
    ];
  }

  static ReadingPlan inflate(CustomPlanDef def, BibleLibrary library) {
    final picked = [
      for (final b in library.books)
        if (def.books.contains(b.id)) (b.id, b.commonName, b.chapters),
    ];
    return ReadingPlan(
      id: def.id,
      name: def.name,
      description: def.description,
      totalDays: def.totalDays,
      dailyReadings: picked.isEmpty || def.totalDays < 1
          ? const []
          : distribute(picked, def.totalDays),
      isCustom: true,
    );
  }

  /// Each day takes ceil(chapters left / days left), so the load stays even
  /// and the plan ends exactly on its last day.
  static List<List<DailyReading>> distribute(
    List<(String, String, int)> books,
    int days,
  ) {
    if (days <= 0) return const [];
    final chapters = [
      for (final (code, name, count) in books)
        for (var c = 1; c <= count; c++) (code, name, c),
    ];
    final result = <List<DailyReading>>[];
    var cursor = 0;
    for (var d = 0; d < days; d++) {
      final remaining = days - d;
      final left = chapters.length - cursor;
      final today = (left / remaining).ceil();
      final end = (cursor + today).clamp(0, chapters.length);
      final day = <DailyReading>[];
      for (final (code, name, ch) in chapters.sublist(cursor, end)) {
        if (day.isNotEmpty &&
            day.last.bookCode == code &&
            day.last.endChapter == ch - 1) {
          day[day.length - 1] = DailyReading(
            code,
            name,
            day.last.startChapter,
            ch,
          );
        } else {
          day.add(DailyReading(code, name, ch, ch));
        }
      }
      cursor = end;
      result.add(day);
    }
    return result;
  }
}

/// Active plans and per-plan day completion under the iOS app's keys:
/// `reading_plan_active_ids` (JSON id list), `reading_plan_progress`
/// (`{planId: [completedDayIndices]}`), `reading_plan_custom`.
class PlanStore extends ChangeNotifier {
  PlanStore(this._prefs) {
    reload();
  }

  final Prefs _prefs;
  static const activeIdsKey = 'reading_plan_active_ids';
  static const progressKey = 'reading_plan_progress';
  static const customKey = 'reading_plan_custom';
  static const reminderPrefix = 'reading_plan_reminder_';
  static const customIdPrefix = 'custom-';

  Set<String> _active = {};
  Map<String, Set<int>> _progress = {};
  List<CustomPlanDef> _custom = [];

  Set<String> get activeIds => Set.unmodifiable(_active);
  List<CustomPlanDef> get customDefs => List.unmodifiable(_custom);

  Object? _json(String key) {
    try {
      return jsonDecode(_prefs.getString(key) ?? 'null');
    } catch (_) {
      return null;
    }
  }

  void reload() {
    final active = _json(activeIdsKey);
    _active = active is List ? active.whereType<String>().toSet() : {};
    final progress = _json(progressKey);
    _progress = progress is Map
        ? {
            for (final e in progress.entries)
              if (e.key is String && e.value is List)
                e.key as String: (e.value as List)
                    .whereType<num>()
                    .map((n) => n.toInt())
                    .toSet(),
          }
        : {};
    final custom = _json(customKey);
    _custom = custom is List
        ? [
            for (final c in custom.whereType<Map<String, Object?>>())
              CustomPlanDef.fromJson(c),
          ]
        : [];
    notifyListeners();
  }

  void _saveActive() =>
      _prefs.setString(activeIdsKey, jsonEncode(_active.toList()..sort()));
  void _saveProgress() => _prefs.setString(
    progressKey,
    jsonEncode({
      for (final e in _progress.entries) e.key: e.value.toList()..sort(),
    }),
  );
  void _saveCustom() => _prefs.setString(
    customKey,
    jsonEncode([for (final c in _custom) c.toJson()]),
  );

  bool isActive(String id) => _active.contains(id);

  void toggleActive(String id) {
    if (!_active.remove(id)) _active.add(id);
    _saveActive();
    notifyListeners();
  }

  Set<int> completed(String id) => _progress[id] ?? const {};
  bool isDone(String id, int day) => completed(id).contains(day);

  void toggleDay(String id, int day) {
    final s = {...completed(id)};
    if (!s.remove(day)) s.add(day);
    _progress[id] = s;
    _saveProgress();
    notifyListeners();
  }

  int? nextDay(ReadingPlan plan) {
    final done = completed(plan.id);
    for (var i = 0; i < plan.totalDays; i++) {
      if (!done.contains(i)) return i;
    }
    return null;
  }

  bool isComplete(ReadingPlan plan) =>
      plan.totalDays > 0 && completed(plan.id).length >= plan.totalDays;

  CustomPlanDef? customDef(String id) =>
      _custom.where((c) => c.id == id).firstOrNull;

  CustomPlanDef _def(
    String id,
    String name,
    String description,
    List<String> books,
    int days,
  ) => CustomPlanDef(
    id: id,
    name: name.trim().isEmpty ? 'Custom plan' : name.trim(),
    description: description.trim().isEmpty
        ? 'Custom plan'
        : description.trim(),
    books: books,
    totalDays: days < 1 ? 1 : days,
  );

  String saveCustomPlan({
    required String name,
    required String description,
    required List<String> books,
    required int totalDays,
  }) {
    final id = '$customIdPrefix${DateTime.now().millisecondsSinceEpoch}';
    _custom.add(_def(id, name, description, books, totalDays));
    _saveCustom();
    notifyListeners();
    return id;
  }

  void updateCustomPlan(
    String id, {
    required String name,
    required String description,
    required List<String> books,
    required int totalDays,
  }) {
    final i = _custom.indexWhere((c) => c.id == id);
    if (i < 0) return;
    _custom[i] = _def(id, name, description, books, totalDays);
    _saveCustom();
    notifyListeners();
  }

  void deleteCustomPlan(String id) {
    _custom.removeWhere((c) => c.id == id);
    _active.remove(id);
    _progress.remove(id);
    _prefs.remove('$reminderPrefix$id');
    _saveCustom();
    _saveActive();
    _saveProgress();
    notifyListeners();
  }

  /// Built-in and custom plans, built-ins first.
  List<ReadingPlan> allPlans(BibleLibrary library) => [
    ...ReadingPlanCatalog.builtIns(library),
    for (final d in _custom) ReadingPlanCatalog.inflate(d, library),
  ];
}
