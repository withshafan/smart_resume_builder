import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// All design token colors defined explicitly.
/// Uses HSL-derived values for precision — no fromSeed() Material defaults.
abstract final class AppColors {
  // ── Primary: Ink Navy ────────────────────────────────────────────────────
  static const Color navyLight = Color(0xFF1F2A44);
  static const Color navyDark = Color(0xFF8FA3C7);

  // ── Accent: Muted Gold (icons only, never body text on light bg) ─────────
  static const Color goldLight = Color(0xFFC79A3D);
  static const Color goldDark = Color(0xFFD9B45C);

  // ── Backgrounds ──────────────────────────────────────────────────────────
  static const Color backgroundLight = Color(0xFFFAF8F4);
  static const Color backgroundDark = Color(0xFF14161B);

  // ── Surfaces (cards, sheets) ─────────────────────────────────────────────
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E2128);

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimaryLight = Color(0xFF1B1F27);
  static const Color textPrimaryDark = Color(0xFFEDEEF0);
  static const Color textSecondaryLight = Color(0xFF5B6270);
  static const Color textSecondaryDark = Color(0xFF9BA1AC);

  // ── Semantic ─────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF2E8B57);
  static const Color warning = Color(0xFFD98E2B);
  static const Color error = Color(0xFFC13B3B);

  // ── Resume category tab colors ────────────────────────────────────────────
  static const Color catTech = Color(0xFF3B6FD4);
  static const Color catDesign = Color(0xFF9B59B6);
  static const Color catMarketing = Color(0xFF27AE60);
  static const Color catFinance = Color(0xFF2E8B57);
  static const Color catOther = Color(0xFF7F8C8D);

  static Color categoryColor(String category) {
    return switch (category.toLowerCase()) {
      'tech' || 'technology' => catTech,
      'design' => catDesign,
      'marketing' => catMarketing,
      'finance' => catFinance,
      _ => catOther,
    };
  }
}

/// App-wide theme configuration.
abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: isLight ? AppColors.navyLight : AppColors.navyDark,
      onPrimary: isLight ? Colors.white : AppColors.backgroundDark,
      primaryContainer:
          isLight ? const Color(0xFFD6E0F5) : const Color(0xFF2D3A55),
      onPrimaryContainer:
          isLight ? AppColors.navyLight : AppColors.navyDark,
      secondary: isLight ? AppColors.goldLight : AppColors.goldDark,
      onSecondary: isLight ? Colors.white : AppColors.backgroundDark,
      secondaryContainer:
          isLight ? const Color(0xFFF5E9CC) : const Color(0xFF4A3A1A),
      onSecondaryContainer:
          isLight ? AppColors.goldLight : AppColors.goldDark,
      surface: isLight ? AppColors.surfaceLight : AppColors.surfaceDark,
      onSurface:
          isLight ? AppColors.textPrimaryLight : AppColors.textPrimaryDark,
      onSurfaceVariant:
          isLight ? AppColors.textSecondaryLight : AppColors.textSecondaryDark,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: const Color(0xFFFCE4E4),
      onErrorContainer: AppColors.error,
      outline: isLight ? const Color(0xFFCBCDD2) : const Color(0xFF3A3D45),
    );

    final textTheme = GoogleFonts.interTextTheme(
      TextTheme(
        displayLarge: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 57),
        displayMedium: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 45),
        headlineLarge: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 32),
        headlineMedium: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 28),
        headlineSmall: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 24),
        titleLarge: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 22),
        titleMedium: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w500,
            fontSize: 16),
        titleSmall: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w500,
            fontSize: 14),
        bodyLarge:
            TextStyle(color: colorScheme.onSurface, fontSize: 16),
        bodyMedium:
            TextStyle(color: colorScheme.onSurface, fontSize: 14),
        bodySmall:
            TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
        labelLarge: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w500,
            fontSize: 14),
        labelSmall: TextStyle(
            color: colorScheme.onSurfaceVariant, fontSize: 11),
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor:
          isLight ? AppColors.backgroundLight : AppColors.backgroundDark,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor:
            isLight ? AppColors.navyLight : AppColors.surfaceDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isLight ? AppColors.navyLight : AppColors.navyDark,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.inter(
              fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor:
              isLight ? AppColors.navyLight : AppColors.navyDark,
          side: BorderSide(
              color: isLight ? AppColors.navyLight : AppColors.navyDark),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.inter(
              fontWeight: FontWeight.w500, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor:
            isLight ? Colors.white : AppColors.surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
              color: isLight
                  ? const Color(0xFFCBCDD2)
                  : const Color(0xFF3A3D45)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
              color: isLight
                  ? const Color(0xFFCBCDD2)
                  : const Color(0xFF3A3D45)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
              color: isLight ? AppColors.navyLight : AppColors.navyDark,
              width: 2),
        ),
        labelStyle: GoogleFonts.inter(
            color: isLight
                ? AppColors.textSecondaryLight
                : AppColors.textSecondaryDark),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      cardTheme: CardThemeData(
        color: isLight ? AppColors.surfaceLight : AppColors.surfaceDark,
        elevation: isLight ? 1 : 2,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isLight
            ? AppColors.navyLight.withAlpha(20)
            : AppColors.navyDark.withAlpha(40),
        labelStyle: GoogleFonts.inter(
            fontSize: 12,
            color: isLight ? AppColors.navyLight : AppColors.navyDark),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      dividerTheme: DividerThemeData(
        color: isLight
            ? const Color(0xFFE5E7EB)
            : const Color(0xFF2E3138),
        thickness: 1,
        space: 1,
      ),
    );
  }
}
