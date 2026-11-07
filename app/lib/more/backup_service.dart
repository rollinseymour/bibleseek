import 'dart:convert';

import '../data/prefs.dart';

/// Export and import every stored value as the iOS app's backup document:
/// `{"app":"BibleSeek","version":1,"keys":{"flutter.<key>": value}}`.
/// A backup made on an iPhone restores here, and the reverse.
class BackupService {
  static String export(Prefs prefs) {
    final keys = <String, Object?>{};
    for (final k in prefs.keys.toList()..sort()) {
      final v = prefs.raw(k);
      if (v is bool || v is num || v is String || v is List) {
        keys['${Prefs.prefix}$k'] = v;
      }
    }
    return const JsonEncoder.withIndent(
      '  ',
    ).convert({'app': 'BibleSeek', 'version': 1, 'keys': keys});
  }

  /// The `flutter.`-prefixed entries of a backup, or null if it isn't one.
  static Map<String, Object?>? parse(String text) {
    try {
      final obj = jsonDecode(text);
      if (obj is! Map || obj['keys'] is! Map) return null;
      final keys = <String, Object?>{
        for (final e in (obj['keys'] as Map).entries)
          if (e.key is String && (e.key as String).startsWith(Prefs.prefix))
            e.key as String: e.value,
      };
      return keys.isEmpty ? null : keys;
    } catch (_) {
      return null;
    }
  }

  /// Writes the entries; returns how many were stored.
  static int restore(Prefs prefs, Map<String, Object?> keys) {
    var n = 0;
    keys.forEach((k, v) {
      final key = k.substring(Prefs.prefix.length);
      switch (v) {
        case final bool b:
          prefs.setBool(key, b);
        case final int i:
          prefs.setInt(key, i);
        case final double d:
          prefs.setDouble(key, d);
        case final String s:
          prefs.setString(key, s);
        case final List<Object?> l when l.every((x) => x is String):
          prefs.setStringList(key, l.cast<String>());
        default:
          return;
      }
      n++;
    });
    return n;
  }
}
