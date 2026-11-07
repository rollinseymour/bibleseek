import 'package:flutter/material.dart';

import '../data/prefs.dart';

class HighlightSwatch {
  const HighlightSwatch(this.hex, this.name);

  /// 6-char hex, no `#`.
  final String hex;
  final String name;
  Color get color => colorFromHex(hex);
}

Color colorFromHex(String hex) {
  final s = hex.startsWith('#') ? hex.substring(1) : hex;
  return Color(0xFF000000 | (int.tryParse(s, radix: 16) ?? 0));
}

String hexFromColor(Color c) {
  String two(double v) =>
      (v * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
  return '${two(c.r)}${two(c.g)}${two(c.b)}'.toUpperCase();
}

/// The base highlight palette plus the person's recent custom colors
/// (`custom_highlight_colours`, newest first, at most 6).
class HighlightPalette {
  static const presets = [
    HighlightSwatch('FFD700', 'Yellow'),
    HighlightSwatch('FF8C42', 'Orange'),
    HighlightSwatch('90EE90', 'Green'),
    HighlightSwatch('87CEEB', 'Blue'),
    HighlightSwatch('FFB6C1', 'Pink'),
    HighlightSwatch('DDA0DD', 'Purple'),
  ];

  static const recentsKey = 'custom_highlight_colours';
  static const maxRecents = 6;

  static List<String> recents(Prefs prefs) =>
      prefs.getStringList(recentsKey) ?? const [];

  static void recordRecentIfCustom(Prefs prefs, String hex) {
    final norm = normalize(hex);
    if (norm == null || presets.any((p) => p.hex == norm)) return;
    final cur = [...recents(prefs)]
      ..removeWhere((h) => h.toUpperCase() == norm);
    cur.insert(0, norm);
    prefs.setStringList(recentsKey, cur.take(maxRecents).toList());
  }

  /// Upper-case 6-char hex without `#`, or null if invalid.
  static String? normalize(String hex) {
    final s = (hex.startsWith('#') ? hex.substring(1) : hex).trim();
    if (s.length != 6 || int.tryParse(s, radix: 16) == null) return null;
    return s.toUpperCase();
  }
}
