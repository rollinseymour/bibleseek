import 'package:flutter/material.dart';

import 'app_theme.dart';

/// One reader-page palette, independent of the app theme so the reading
/// surface can differ from the chrome. Values match the iOS app.
class ReaderPalette {
  const ReaderPalette({
    required this.key,
    required this.label,
    required this.background,
    required this.text,
    required this.accent,
    required this.redLetter,
  });

  final String key;
  final String label;
  final Color background;
  final Color text;
  final Color accent;
  final Color redLetter;

  static const all = [
    ReaderPalette(
      key: 'paper',
      label: 'Paper',
      background: Color(0xFFFFFFFF),
      text: Color(0xFF1A1A1A),
      accent: Color(0xFF5F451F),
      redLetter: Color(0xFF8F1616),
    ),
    ReaderPalette(
      key: 'parchment',
      label: 'Parchment',
      background: Color(0xFFF6EDD8),
      text: Color(0xFF2E1C0C),
      accent: Color(0xFF59401C),
      redLetter: Color(0xFF8F1616),
    ),
    ReaderPalette(
      key: 'sepia',
      label: 'Sepia',
      background: Color(0xFFEFE5D2),
      text: Color(0xFF40280F),
      accent: Color(0xFF523618),
      redLetter: Color(0xFF8A1818),
    ),
    ReaderPalette(
      key: 'slate',
      label: 'Slate',
      background: Color(0xFF1F2630),
      text: Color(0xFFE7ECF2),
      accent: Color(0xFF7DB6FF),
      redLetter: Color(0xFFFF9E95),
    ),
    ReaderPalette(
      key: 'midnight',
      label: 'Midnight',
      background: Color(0xFF0E0F12),
      text: Color(0xFFE5E7EB),
      accent: Color(0xFFA0A9B7),
      redLetter: Color(0xFFFF9E95),
    ),
  ];

  /// The chosen palette, or the app theme's colors for `system`.
  static ReaderPalette resolve(String key, AppThemeKind theme) {
    for (final p in all) {
      if (p.key == key) return p;
    }
    final app = theme.palette;
    return ReaderPalette(
      key: 'system',
      label: 'System',
      background: app.scaffold,
      text: app.onSurface,
      accent: app.primary,
      redLetter: theme.brightness == Brightness.dark
          ? const Color(0xFFFF9E95)
          : const Color(0xFF701A1A),
    );
  }

  bool get isDark => background.computeLuminance() < 0.4;

  /// Floating panels over the page: a little lighter than the page itself,
  /// rather than pure white on a toned-down background.
  Color get panel => isDark
      ? const Color(0xFF2A2A2E)
      : Color.lerp(background, Colors.white, 0.5)!;
}
