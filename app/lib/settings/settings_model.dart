import 'package:flutter/foundation.dart';

import '../data/prefs.dart';
import '../design/app_theme.dart';
import '../design/reader_fonts.dart';
import '../design/reader_palette.dart';

/// User preferences under the same `pref_*` keys and defaults as the iOS app.
/// Keys this build doesn't use (read aloud, reminders) stay untouched in
/// storage, so they survive a backup round trip.
class SettingsModel extends ChangeNotifier {
  SettingsModel(this._prefs) {
    reload();
  }

  final Prefs _prefs;

  static const fontSizeDefault = 16.0;
  static const fontSizeMin = 12.0;
  static const fontSizeMax = 28.0;
  static const readerThemeOptions = [
    'system',
    'paper',
    'parchment',
    'sepia',
    'slate',
    'midnight',
  ];

  static const _kFontSize = 'pref_font_size';
  static const _kTheme = 'pref_theme';
  static const _kRedLetter = 'pref_red_letter';
  static const _kParagraph = 'pref_paragraph_mode';
  static const _kCrossVersion = 'pref_show_cross_version_annotations';
  static const _kReaderFont = 'pref_reader_font_family';
  static const _kReaderTheme = 'pref_reader_theme';
  static const _kInterlinearReverse = 'pref_interlinear_reverse';

  late double _fontSize;
  late AppThemeKind _theme;
  late bool _redLetter;
  late bool _paragraphMode;
  late bool _showCrossVersionAnnotations;
  late String _readerFont;
  late String _readerTheme;
  late bool _interlinearReverse;

  double get fontSize => _fontSize;
  AppThemeKind get theme => _theme;
  bool get redLetter => _redLetter;
  bool get paragraphMode => _paragraphMode;
  bool get showCrossVersionAnnotations => _showCrossVersionAnnotations;
  String get readerFont => _readerFont;
  String get readerTheme => _readerTheme;

  /// Interlinear word order: false = original (Greek/Hebrew), true = KJV.
  bool get interlinearReverse => _interlinearReverse;

  ReaderPalette get readerPalette =>
      ReaderPalette.resolve(_readerTheme, _theme);

  /// Re-reads every preference, e.g. after restoring a backup.
  void reload() {
    _fontSize = _prefs
        .getDouble(_kFontSize, fontSizeDefault)
        .clamp(fontSizeMin, fontSizeMax);
    _theme = AppThemeKind.parse(_prefs.getString(_kTheme));
    _redLetter = _prefs.getBool(_kRedLetter, true);
    _paragraphMode = _prefs.getBool(_kParagraph, false);
    _showCrossVersionAnnotations = _prefs.getBool(_kCrossVersion, true);
    final font = _prefs.getString(_kReaderFont);
    _readerFont = readerFontOptions.contains(font) ? font! : readerFontDefault;
    final readerTheme = _prefs.getString(_kReaderTheme);
    _readerTheme = readerThemeOptions.contains(readerTheme)
        ? readerTheme!
        : 'system';
    _interlinearReverse = _prefs.getBool(_kInterlinearReverse, false);
    notifyListeners();
  }

  set fontSize(double v) {
    _fontSize = v.clamp(fontSizeMin, fontSizeMax);
    _prefs.setDouble(_kFontSize, _fontSize);
    notifyListeners();
  }

  set theme(AppThemeKind v) {
    _theme = v;
    _prefs.setString(_kTheme, v.name);
    notifyListeners();
  }

  set redLetter(bool v) {
    _redLetter = v;
    _prefs.setBool(_kRedLetter, v);
    notifyListeners();
  }

  set paragraphMode(bool v) {
    _paragraphMode = v;
    _prefs.setBool(_kParagraph, v);
    notifyListeners();
  }

  set showCrossVersionAnnotations(bool v) {
    _showCrossVersionAnnotations = v;
    _prefs.setBool(_kCrossVersion, v);
    notifyListeners();
  }

  set readerFont(String v) {
    _readerFont = v;
    _prefs.setString(_kReaderFont, v);
    notifyListeners();
  }

  set readerTheme(String v) {
    _readerTheme = v;
    _prefs.setString(_kReaderTheme, v);
    notifyListeners();
  }

  set interlinearReverse(bool v) {
    _interlinearReverse = v;
    _prefs.setBool(_kInterlinearReverse, v);
    notifyListeners();
  }
}
