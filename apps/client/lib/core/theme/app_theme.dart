import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTheme {
  static const Color primaryRed = Color(0xFFE53935);
  static const Color deepRed = Color(0xFFB91C1C);
  static const Color blush = Color(0xFFFFE8E4);
  static const Color ink = Color(0xFF1D1D1F);
  static const Color muted = Color(0xFF6E6E73);
  static const Color line = Color(0xFFE8E2DF);
  static const Color cream = Color(0xFFFFFBF8);
  static const Color black = Color(0xFF121212);
  static const Color white = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFF7F3);
  static const Color success = Color(0xFF138A4A);
  static const Color warning = Color(0xFFFFB020);

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryRed,
        primary: primaryRed,
        secondary: deepRed,
        surface: surface,
        onPrimary: white,
        onSurface: ink,
      ),
      scaffoldBackgroundColor: surface,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        headlineLarge: GoogleFonts.inter(
          fontWeight: FontWeight.w900,
          color: ink,
          height: 1.05,
        ),
        headlineMedium: GoogleFonts.inter(
          fontWeight: FontWeight.w900,
          color: ink,
          height: 1.08,
        ),
        titleLarge: GoogleFonts.inter(
          fontWeight: FontWeight.w800,
          color: ink,
        ),
        titleMedium: GoogleFonts.inter(
          fontWeight: FontWeight.w800,
          color: ink,
        ),
        bodyMedium: GoogleFonts.inter(color: ink, height: 1.35),
        bodySmall: GoogleFonts.inter(color: muted, height: 1.35),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: ink,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryRed,
          foregroundColor: white,
          disabledBackgroundColor: line,
          disabledForegroundColor: muted,
          minimumSize: const Size.fromHeight(54),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryRed,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: line),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        labelStyle: const TextStyle(color: muted),
        hintStyle: const TextStyle(color: muted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryRed, width: 1.4),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: white,
        selectedColor: primaryRed,
        side: const BorderSide(color: line),
        labelStyle: const TextStyle(
          color: ink,
          fontWeight: FontWeight.w700,
        ),
        secondaryLabelStyle: const TextStyle(
          color: white,
          fontWeight: FontWeight.w800,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryRed,
        foregroundColor: white,
        elevation: 8,
      ),
      dividerTheme: const DividerThemeData(
        color: line,
        thickness: 1,
        space: 32,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ink,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: white,
          selectedBackgroundColor: blush,
          selectedForegroundColor: deepRed,
          foregroundColor: muted,
          side: const BorderSide(color: line),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: white,
        elevation: 0,
        shadowColor: primaryRed.withOpacity(0.08),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: line),
        ),
      ),
    );
  }
}
