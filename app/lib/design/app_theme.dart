import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App-wide theme, distinct from the reader-only palettes. Values match the
/// iOS app, except Light, which is a softer off-white here because a white
/// page on a computer screen is glaring. The brand green is tone-shifted per
/// theme for text contrast.
enum AppThemeKind {
  light(
    'Light',
    AppPalette(
      scaffold: Color(0xFFEDEBE5),
      surface: Color(0xFFF6F5F1),
      onSurface: Color(0xFF1B1B1B),
      primary: Color(0xFF0B7355),
      onPrimary: Color(0xFFFFFFFF),
    ),
  ),
  dark(
    'Dark',
    AppPalette(
      scaffold: Color(0xFF0F0F0F),
      surface: Color(0xFF1A1A1A),
      onSurface: Color(0xFFFFFFFF),
      primary: Color(0xFF53DFB8),
      onPrimary: Color(0xFF00261B),
    ),
  ),
  sanctuary(
    'Sanctuary',
    AppPalette(
      scaffold: Color(0xFF15120E),
      surface: Color(0xFF211B14),
      onSurface: Color(0xFFF2EDE4),
      primary: Color(0xFF7FB69E),
      onPrimary: Color(0xFF0E241C),
    ),
  ),
  evergreen(
    'Evergreen',
    AppPalette(
      scaffold: Color(0xFF0D1714),
      surface: Color(0xFF14211C),
      onSurface: Color(0xFFEAF2ED),
      primary: Color(0xFF53DFB8),
      onPrimary: Color(0xFF00261B),
    ),
  );

  const AppThemeKind(this.label, this.palette);
  final String label;
  final AppPalette palette;

  Brightness get brightness =>
      this == light ? Brightness.light : Brightness.dark;

  static AppThemeKind parse(String? raw) =>
      values.firstWhere((t) => t.name == raw, orElse: () => dark);
}

class AppPalette {
  const AppPalette({
    required this.scaffold,
    required this.surface,
    required this.onSurface,
    required this.primary,
    required this.onPrimary,
  });
  final Color scaffold;
  final Color surface;
  final Color onSurface;
  final Color primary;
  final Color onPrimary;
}

ThemeData buildAppTheme(AppThemeKind kind) {
  final p = kind.palette;
  final dark = kind.brightness == Brightness.dark;
  final scheme = ColorScheme(
    brightness: kind.brightness,
    primary: p.primary,
    onPrimary: p.onPrimary,
    secondary: p.primary,
    onSecondary: p.onPrimary,
    error: dark ? const Color(0xFFFF8A80) : const Color(0xFFB3261E),
    onError: dark ? const Color(0xFF370B0B) : Colors.white,
    surface: p.surface,
    onSurface: p.onSurface,
    // Without these, progress tracks and tonal buttons fall back to the accent itself.
    primaryContainer: Color.lerp(p.surface, p.primary, 0.28),
    onPrimaryContainer: p.onSurface,
    secondaryContainer: Color.lerp(p.surface, p.primary, 0.2),
    onSecondaryContainer: p.onSurface,
    surfaceContainerLowest: p.scaffold,
    surfaceContainerLow: Color.lerp(p.scaffold, p.surface, 0.5),
    surfaceContainer: p.surface,
    surfaceContainerHigh: Color.lerp(p.surface, p.onSurface, 0.05),
    surfaceContainerHighest: Color.lerp(p.surface, p.onSurface, 0.09),
    outline: p.onSurface.withValues(alpha: 0.3),
    outlineVariant: p.onSurface.withValues(alpha: 0.12),
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.scaffold,
    canvasColor: p.scaffold,
    dividerColor: p.onSurface.withValues(alpha: 0.1),
  );
  return base.copyWith(
    textTheme: GoogleFonts.interTextTheme(base.textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: p.scaffold,
      surfaceTintColor: Colors.transparent,
      foregroundColor: p.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.surface,
      indicatorColor: p.primary.withValues(alpha: 0.18),
      surfaceTintColor: Colors.transparent,
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          color: s.contains(WidgetState.selected)
              ? p.primary
              : p.onSurface.withValues(alpha: 0.6),
        ),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: p.surface,
      indicatorColor: p.primary.withValues(alpha: 0.18),
      selectedIconTheme: IconThemeData(color: p.primary),
      unselectedIconTheme: IconThemeData(
        color: p.onSurface.withValues(alpha: 0.6),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: p.surface,
      surfaceTintColor: Colors.transparent,
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
