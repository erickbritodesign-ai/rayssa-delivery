import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTheme {
  static const Color primaryRed = Color(0xFF7B2E1F);
  static const Color deepRed = Color(0xFFB6462F);
  static const Color blush = Color(0xFFF2D8CF);
  static const Color cream = Color(0xFFF8F3EC);
  static const Color warmWhite = Color(0xFFFFFBF6);
  static const Color gold = Color(0xFFD7A552);
  static const Color caramel = Color(0xFFC7772E);
  static const Color chocolate = Color(0xFF7B2E1F);
  static const Color ink = Color(0xFF2B1D18);
  static const Color muted = Color(0xFF7D6B61);
  static const Color line = Color(0xFFEADCCB);
  static const Color black = Color(0xFF121212);
  static const Color white = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF8F3EC);
  static const Color success = Color(0xFF2E7D4F);
  static const Color warning = Color(0xFFE6A12A);
  static const Color darkSurface = Color(0xFF1D120F);
  static const Color darkCard = Color(0xFF2A1A16);
  static const Color darkCardSoft = Color(0xFF34211C);
  static const Color darkText = Color(0xFFF8F3EC);
  static const Color darkMuted = Color(0xFFD8C6B8);
  static const Color darkLine = Color(0xFF4A312A);

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
        headlineLarge: GoogleFonts.playfairDisplay(
          fontWeight: FontWeight.w900,
          color: ink,
          height: 1.05,
        ),
        headlineMedium: GoogleFonts.playfairDisplay(
          fontWeight: FontWeight.w900,
          color: ink,
          height: 1.08,
        ),
        titleLarge: GoogleFonts.playfairDisplay(
          fontWeight: FontWeight.w800,
          color: ink,
          height: 1.1,
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
          shadowColor: primaryRed.withOpacity(0.18),
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
        color: warmWhite,
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

  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: gold,
        brightness: Brightness.dark,
        primary: deepRed,
        secondary: gold,
        surface: darkSurface,
        onPrimary: warmWhite,
        onSurface: darkText,
      ),
      scaffoldBackgroundColor: darkSurface,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        headlineLarge: GoogleFonts.playfairDisplay(
          fontWeight: FontWeight.w900,
          color: darkText,
          height: 1.05,
        ),
        headlineMedium: GoogleFonts.playfairDisplay(
          fontWeight: FontWeight.w900,
          color: darkText,
          height: 1.08,
        ),
        titleLarge: GoogleFonts.playfairDisplay(
          fontWeight: FontWeight.w800,
          color: darkText,
          height: 1.1,
        ),
        titleMedium: GoogleFonts.inter(
          fontWeight: FontWeight.w800,
          color: darkText,
        ),
        bodyMedium: GoogleFonts.inter(color: darkText, height: 1.35),
        bodySmall: GoogleFonts.inter(color: darkMuted, height: 1.35),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: darkText,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: deepRed,
          foregroundColor: warmWhite,
          disabledBackgroundColor: darkLine,
          disabledForegroundColor: darkMuted,
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
          foregroundColor: gold,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: darkLine),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        labelStyle: const TextStyle(color: darkMuted),
        hintStyle: const TextStyle(color: darkMuted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkLine),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkLine),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: gold, width: 1.4),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: darkCard,
        selectedColor: deepRed,
        side: const BorderSide(color: darkLine),
        labelStyle: const TextStyle(
          color: darkText,
          fontWeight: FontWeight.w700,
        ),
        secondaryLabelStyle: const TextStyle(
          color: warmWhite,
          fontWeight: FontWeight.w800,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: deepRed,
        foregroundColor: warmWhite,
        elevation: 8,
      ),
      dividerTheme: const DividerThemeData(
        color: darkLine,
        thickness: 1,
        space: 32,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: darkCardSoft,
        contentTextStyle: const TextStyle(color: darkText),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: darkCard,
          selectedBackgroundColor: darkCardSoft,
          selectedForegroundColor: gold,
          foregroundColor: darkMuted,
          side: const BorderSide(color: darkLine),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.18),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: darkLine),
        ),
      ),
    );
  }
}
