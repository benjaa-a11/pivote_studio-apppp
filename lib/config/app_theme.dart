import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ==================== TEMA OSCURO (Midnight Indigo Pro) ====================
  static const Color darkBackground =
      Color(0xFF020408); // Ultra Dark Blue/Black
  static const Color darkSurface = Color(0xFF0B1121); // Rich Deep Blue
  static const Color darkCard = Color(0xFF151E32); // Lighter Deep Blue
  static const Color darkPrimary = Color(0xFF5C6BC0); // Indigo 400 (Softer)
  static const Color darkSecondary = Color(0xFF26A69A); // Teal 400
  static const Color darkAccent = Color(0xFF7E57C2); // Deep Purple 400
  static const Color darkError = Color(0xFFE57373); // Red 300
  static const Color darkTextPrimary = Color(0xFFECEFF1); // Blue Grey 50
  static const Color darkTextSecondary = Color(0xFFB0BEC5); // Blue Grey 200
  static const Color darkBorder = Color(0xFF273546); // Muted Blue Border

  // ==================== TEMA CLARO (Clean Slate) ====================
  static const Color lightBackground = Color(0xFFF8F9FA); // Off White
  static const Color lightSurface = Color(0xFFFFFFFF); // Pure White
  static const Color lightCard = Color(0xFFFFFFFF); // White Cards
  static const Color lightPrimary = Color(0xFF3F51B5); // Indigo 500
  static const Color lightSecondary = Color(0xFF00897B); // Teal 600
  static const Color lightTextPrimary = Color(0xFF263238); // Blue Grey 900
  static const Color lightTextSecondary = Color(0xFF546E7A); // Blue Grey 600
  static const Color lightBorder = Color(0xFFE0E0E0); // Grey 300

  // ==================== TEMA OSCURO ====================
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: darkPrimary,
      secondary: darkSecondary,
      surface: darkSurface,
      onSurface: darkTextPrimary,
      error: darkError,
      tertiary: darkAccent,
      inverseSurface: darkTextPrimary, // For contrast on some widgets
      outline: darkBorder,
    ),
    scaffoldBackgroundColor: darkBackground,
    cardColor: darkCard,
    dividerColor: darkBorder,

    // Tipografía optimizada (Solo Montserrat)
    textTheme:
        GoogleFonts.montserratTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge: GoogleFonts.montserrat(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.0,
          color: darkTextPrimary),
      displayMedium: GoogleFonts.montserrat(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: darkTextPrimary),
      headlineMedium: GoogleFonts.montserrat(
          fontSize: 24, fontWeight: FontWeight.w700, color: darkTextPrimary),
      headlineSmall: GoogleFonts.montserrat(
          fontSize: 20, fontWeight: FontWeight.w600, color: darkTextPrimary),
      titleLarge: GoogleFonts.montserrat(
          fontSize: 18, fontWeight: FontWeight.w600, color: darkTextPrimary),
      titleMedium: GoogleFonts.montserrat(
          fontSize: 16, fontWeight: FontWeight.w600, color: darkTextPrimary),
      bodyLarge: GoogleFonts.montserrat(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: darkTextSecondary,
          height: 1.5),
      bodyMedium: GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: darkTextSecondary,
          height: 1.5),
      labelLarge: GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: darkTextPrimary),
    ),

    cardTheme: CardThemeData(
      elevation: 0,
      color: darkCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: darkBorder.withValues(alpha: 0.5)),
      ),
      margin: EdgeInsets.zero,
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: darkBackground,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      iconTheme: const IconThemeData(color: darkTextPrimary),
      titleTextStyle: GoogleFonts.montserrat(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: darkTextPrimary,
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: darkBorder.withValues(alpha: 0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: darkPrimary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.all(20),
      hintStyle: GoogleFonts.montserrat(
          color: darkTextSecondary.withValues(alpha: 0.6)),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: darkPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle:
            GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    ),
    dialogTheme: const DialogThemeData(backgroundColor: darkSurface),
  );

  // ==================== TEMA CLARO ====================
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: lightPrimary,
      secondary: lightSecondary,
      surface: lightSurface,
      onSurface: lightTextPrimary,
      error: Color(0xFFD32F2F),
      tertiary: Color(0xFF0097A7),
      outline: lightBorder,
    ),
    scaffoldBackgroundColor: lightBackground,
    cardColor: lightCard,
    dialogTheme: const DialogThemeData(backgroundColor: lightSurface),
    dividerColor: lightBorder,
    textTheme:
        GoogleFonts.montserratTextTheme(ThemeData.light().textTheme).copyWith(
      displayLarge: GoogleFonts.montserrat(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.0,
          color: lightTextPrimary),
      displayMedium: GoogleFonts.montserrat(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: lightTextPrimary),
      headlineMedium: GoogleFonts.montserrat(
          fontSize: 24, fontWeight: FontWeight.w700, color: lightTextPrimary),
      headlineSmall: GoogleFonts.montserrat(
          fontSize: 20, fontWeight: FontWeight.w600, color: lightTextPrimary),
      titleLarge: GoogleFonts.montserrat(
          fontSize: 18, fontWeight: FontWeight.w600, color: lightTextPrimary),
      titleMedium: GoogleFonts.montserrat(
          fontSize: 16, fontWeight: FontWeight.w600, color: lightTextPrimary),
      bodyLarge: GoogleFonts.montserrat(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: lightTextSecondary,
          height: 1.5),
      bodyMedium: GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: lightTextSecondary,
          height: 1.5),
      labelLarge: GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: Colors.white),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: lightBorder),
      ),
      margin: EdgeInsets.zero,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: lightBackground,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      iconTheme: const IconThemeData(color: lightTextPrimary),
      titleTextStyle: GoogleFonts.montserrat(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: lightTextPrimary,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: lightPrimary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.all(20),
      hintStyle: GoogleFonts.montserrat(
          color: lightTextSecondary.withValues(alpha: 0.6)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: lightPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle:
            GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    ),
  );
}
