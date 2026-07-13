import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
/// MediAssist design system (Step 1: visual consistency).
///
/// One central place for colours, spacing, radii and component styling, so
/// every screen looks coherent. Baseline sizes are intentionally MODERATE: the
/// adaptive engine enlarges text/buttons and raises contrast FROM this baseline,
/// so the static control condition stays a fair, unmodified starting point.
/// ---------------------------------------------------------------------------

class AppSpacing {
  static const double xs = 4, sm = 8, md = 16, lg = 24, xl = 32;
}

class AppRadius {
  static const double card = 16, button = 12, field = 12;
}

/// Per-feature accent colours (consistent icon/colour language app-wide).
class AppColors {
  static const Color teal = Color(0xFF00897B);
  static const Color ink = Color(0xFF1A2327);

  /// Readable secondary text — darker & more legible than black54, while
  /// staying clearly lighter than primary ink (preserves hierarchy). Improves
  /// baseline readability without enlarging text or triggering high-contrast.
  static const Color textSecondary = Color(0xFF4F5B62);

  static const Color background = Color(0xFFF4F7F6);

  static const Color today = Color(0xFFEF6C00);        // orange
  static const Color medications = Color(0xFF00897B);  // teal
  static const Color appointments = Color(0xFF3949AB); // indigo
  static const Color history = Color(0xFF8E24AA);      // purple
  static const Color caregiver = Color(0xFF00838F);    // cyan (clearer than brown)
}

/// The standard (control-condition) theme.
ThemeData buildAppTheme() {
  final ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: AppColors.teal,
    primary: AppColors.teal,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,

    // Clean white app bars; a subtle line appears when content scrolls under.
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
      titleTextStyle: TextStyle(
          fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.ink),
    ),

    // Clean WHITE cards (removes the M3 grey tint) with a consistent shape.
    cardTheme: CardThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 1.5,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card)),
    ),

    // Strong, SOLID teal primary buttons — a clear primary action for elders.
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
        elevation: 1,
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button)),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.teal,
        side: const BorderSide(color: AppColors.teal, width: 1.5),
        minimumSize: const Size(0, 50),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button)),
      ),
    ),

    // Consistent, clearly-bordered input fields.
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
        borderSide: const BorderSide(color: AppColors.teal, width: 2),
      ),
    ),

    // Consistent, friendly snackbars for confirmations (used in later steps).
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      contentTextStyle: const TextStyle(fontSize: 15, color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}

/// High-contrast variant (used by the accessibility setting and by the adaptive
/// engine at strong load). Same shapes for consistency; maximum contrast.
ThemeData buildHighContrastTheme() {
  final base = buildAppTheme();
  final scheme = ColorScheme.fromSeed(
    seedColor: Colors.black,
    brightness: Brightness.light,
  ).copyWith(
    primary: Colors.black,
    onPrimary: Colors.white,
    surface: Colors.white,
    onSurface: Colors.black,
  );
  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
      titleTextStyle: TextStyle(
          fontSize: 22, fontWeight: FontWeight.w700, color: Colors.black),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button)),
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: const BorderSide(color: Colors.black, width: 1.5),
      ),
    ),
  );
}
