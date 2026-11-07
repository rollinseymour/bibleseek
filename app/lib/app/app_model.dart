import 'package:flutter/foundation.dart';

enum AppTab { home, bible, journal, more }

/// A request to open the reader at a place (from the Journal, search, Home…).
class ReaderTarget {
  const ReaderTarget({
    required this.bookCode,
    required this.chapter,
    this.verse,
    this.endVerse,
    this.version,
  });

  final String bookCode;
  final int chapter;
  final int? verse;

  /// Last verse of a range ("Psalm 121:1-2"); the whole span glows on arrival.
  final int? endVerse;
  final String? version;
}

/// Global state: the selected tab, so any screen can switch tabs, and a
/// pending reader deep link.
class AppModel extends ChangeNotifier {
  AppTab _tab = AppTab.home;
  ReaderTarget? _pendingOpen;
  String? _pendingJournalFilter;
  int _homeReset = 0;
  int _moreReset = 0;

  AppTab get tab => _tab;
  ReaderTarget? get pendingOpen => _pendingOpen;

  /// Bumped when Home is tapped while already on Home: it clears search and
  /// pops back to its root.
  int get homeReset => _homeReset;

  /// Bumped when More is tapped while already on More, so it pops to its root.
  int get moreReset => _moreReset;

  void selectTab(AppTab t) {
    if (t == _tab && t == AppTab.home) _homeReset++;
    if (t == _tab && t == AppTab.more) _moreReset++;
    _tab = t;
    notifyListeners();
  }

  void open(ReaderTarget target) {
    _pendingOpen = target;
    _tab = AppTab.bible;
    notifyListeners();
  }

  ReaderTarget? takePendingOpen() {
    final t = _pendingOpen;
    _pendingOpen = null;
    return t;
  }

  /// Opens the Journal on a filter, e.g. "Favorites" from Home.
  void openJournal(String filter) {
    _pendingJournalFilter = filter;
    _tab = AppTab.journal;
    notifyListeners();
  }

  String? takePendingJournalFilter() {
    final f = _pendingJournalFilter;
    _pendingJournalFilter = null;
    return f;
  }
}
