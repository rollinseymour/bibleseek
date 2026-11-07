import 'package:shared_preferences/shared_preferences.dart';

/// The single persistence point. shared_preferences keeps each key in the
/// browser's localStorage as `flutter.<key>`, the same names the iOS app
/// keeps in UserDefaults, so a backup from either app restores into the other.
class Prefs {
  Prefs(this._p);
  final SharedPreferences _p;

  static const prefix = 'flutter.';

  bool getBool(String key, bool fallback) => switch (_p.get(key)) {
    final bool b => b,
    _ => fallback,
  };

  int getInt(String key, int fallback) => switch (_p.get(key)) {
    final num n => n.toInt(),
    _ => fallback,
  };

  double getDouble(String key, double fallback) => switch (_p.get(key)) {
    final num n => n.toDouble(),
    _ => fallback,
  };

  String? getString(String key) => switch (_p.get(key)) {
    final String s => s,
    _ => null,
  };

  List<String>? getStringList(String key) => switch (_p.get(key)) {
    final List<Object?> l => l.whereType<String>().toList(),
    _ => null,
  };

  void setBool(String key, bool v) => _p.setBool(key, v);
  void setInt(String key, int v) => _p.setInt(key, v);
  void setDouble(String key, double v) => _p.setDouble(key, v);
  void setString(String key, String v) => _p.setString(key, v);
  void setStringList(String key, List<String> v) => _p.setStringList(key, v);
  void remove(String key) => _p.remove(key);

  Set<String> get keys => _p.getKeys();
  Object? raw(String key) => _p.get(key);
}
