import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ==================== TEMA OSCURO (Midnight Indigo) ====================
  // Inspirado en interfaces modernas de alto rendimiento como Vercel, Linear, Framer
  static const Color darkBackground = Color(0xFF030712); // Negro ultra profundo
  static const Color darkSurface = Color(0xFF0F172A); // Slate 900
  static const Color darkCard = Color(0xFF1E293B); // Slate 800
  static const Color darkPrimary = Color(0xFF6366F1); // Indigo 500
  static const Color darkSecondary = Color(0xFF10B981); // Emerald 500
  static const Color darkAccent = Color(0xFF8B5CF6); // Violet 500
  static const Color darkError = Color(0xFFEF4444); // Red 500
  static const Color darkForeground = Color(0xFFF8FAFC); // Slate 50
  static const Color darkSecondaryForeground = Color(0xFFE2E8F0); // Slate 200
  static const Color darkMutedForeground = Color(0xFF94A3B8); // Slate 400
  static const Color darkBorder = Color(0xFF334155); // Slate 700
  static const Color darkRing = Color(0xFF6366F1); // Indigo 500 (Primary)

  static const Color chart1 = Color(0xFF6366F1);
  static const Color chart2 = Color(0xFF10B981);

  // ==================== TEMA CLARO ====================
  // Inspirado en Apple, Google, interfaces modernas
  static const Color lightBackground = Color(0xFFFEFFFF); // Gris muy claro
  static const Color lightSurface = Color(0xFFFFFFFF); // Blanco puro
  static const Color lightCard = Color(0xFFEBF1FD); // Blanco con tinte
  static const Color lightPrimary = Color(0xFF0066FF); // Azul moderno
  static const Color lightSecondary = Color(0xFF0052CC); // Azul profundo
  static const Color lightAccent = Color(0xFF00B8D4); // Cyan
  static const Color lightError = Color(0xFFDC3545); // Rojo error

  // ==================== TEMA OSCURO ====================
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: darkPrimary,
      secondary: darkSecondary,
      surface: darkBackground,
      onSurface: darkForeground,
      error: darkError,
      tertiary: darkAccent,
      inverseSurface: darkSurface,
      outline: darkBorder,
    ),
    splashFactory: InkRipple.splashFactory,
    primaryColor: darkPrimary,
    scaffoldBackgroundColor: darkBackground,
    canvasColor: darkBackground,
    cardColor: darkCard,

    // Tipografía premium con Ubuntu
    textTheme: GoogleFonts.ubuntuTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge: GoogleFonts.ubuntu(
        fontSize: 34,
        fontWeight: FontWeight.w900,
        letterSpacing: -1.5,
        height: 1.1,
        color: darkForeground,
      ),
      displayMedium: GoogleFonts.ubuntu(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -1,
        height: 1.2,
        color: darkForeground,
      ),
      displaySmall: GoogleFonts.ubuntu(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        height: 1.2,
        color: darkForeground,
      ),
      headlineMedium: GoogleFonts.ubuntu(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: darkForeground,
      ),
      headlineSmall: GoogleFonts.ubuntu(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: darkForeground,
      ),
      titleLarge: GoogleFonts.ubuntu(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: darkForeground,
      ),
      titleMedium: GoogleFonts.ubuntu(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: darkSecondaryForeground,
      ),
      bodyLarge: GoogleFonts.ubuntu(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: darkSecondaryForeground,
      ),
      bodyMedium: GoogleFonts.ubuntu(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: darkMutedForeground,
      ),
      labelLarge: GoogleFonts.ubuntu(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: darkForeground,
      ),
    ),

    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: darkBorder.withValues(alpha: 0.5), width: 1),
      ),
      color: darkSurface,
      surfaceTintColor: Colors.transparent,
    ),

    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: darkBackground,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      iconTheme: const IconThemeData(color: darkForeground),
      titleTextStyle: GoogleFonts.ubuntu(
        fontSize: 22,
        fontWeight: FontWeight.w900,
        color: darkForeground,
        letterSpacing: -0.8,
      ),
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: darkBackground,
      indicatorColor: darkPrimary.withValues(alpha: 0.15),
      elevation: 0,
      height: 70,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.ubuntu(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: darkPrimary,
            letterSpacing: 0.2,
          );
        }
        return GoogleFonts.ubuntu(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: darkMutedForeground,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: darkPrimary, size: 26, weight: 800);
        }
        return const IconThemeData(color: darkMutedForeground, size: 24);
      }),
    ),

    iconTheme: const IconThemeData(color: darkForeground, size: 24),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: darkBorder.withValues(alpha: 0.5)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: darkBorder.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: darkPrimary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      hintStyle: GoogleFonts.ubuntu(
        color: darkMutedForeground.withValues(alpha: 0.7),
        fontSize: 15,
      ),
    ),

    dividerTheme: DividerThemeData(
      color: darkBorder.withValues(alpha: 0.4),
      thickness: 1,
      space: 1,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: darkPrimary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: GoogleFonts.ubuntu(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ).copyWith(
        overlayColor:
            WidgetStateProperty.all(Colors.white.withValues(alpha: 0.1)),
        splashFactory: InkRipple.splashFactory,
      ),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: darkPrimary,
      foregroundColor: Colors.white,
      elevation: 12,
      // shadowColor no existe directamente en FloatingActionButtonThemeData, se usa elevation
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: darkSurface,
      elevation: 0,
      titleTextStyle: GoogleFonts.ubuntu(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: darkForeground,
      ),
      contentTextStyle: GoogleFonts.ubuntu(
        fontSize: 16,
        color: darkSecondaryForeground,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: darkBorder.withValues(alpha: 0.5)),
      ),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: darkSurface,
      contentTextStyle: GoogleFonts.ubuntu(
        color: darkForeground,
        fontWeight: FontWeight.w600,
      ),
      actionTextColor: darkPrimary,
      behavior: SnackBarBehavior.floating,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: darkBorder.withValues(alpha: 0.5)),
      ),
    ),
  );

  // ==================== TEMA CLARO ====================
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: lightPrimary,
      secondary: lightSecondary,
      surface: lightBackground,
      onSurface: Colors.black87,
      error: lightError,
      tertiary: lightAccent,
    ),
    splashFactory: InkRipple.splashFactory,
    primaryColor: lightPrimary,
    scaffoldBackgroundColor: lightBackground,
    canvasColor: lightBackground,
    cardColor: lightCard,
    textTheme:
        GoogleFonts.ubuntuTextTheme(ThemeData.light().textTheme).copyWith(
      displayLarge: GoogleFonts.ubuntu(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        letterSpacing: -1,
        height: 1.2,
        color: Colors.black87,
      ),
      displayMedium: GoogleFonts.ubuntu(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.2,
        color: Colors.black87,
      ),
      displaySmall: GoogleFonts.ubuntu(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.3,
        color: Colors.black87,
      ),
      headlineMedium: GoogleFonts.ubuntu(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: Colors.black87,
      ),
      headlineSmall: GoogleFonts.ubuntu(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: Colors.black87,
      ),
      titleLarge: GoogleFonts.ubuntu(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: Colors.black87,
      ),
      titleMedium: GoogleFonts.ubuntu(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: Colors.black54,
      ),
      bodyLarge: GoogleFonts.ubuntu(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: Colors.black54,
      ),
      bodyMedium: GoogleFonts.ubuntu(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: Colors.black45,
      ),
      labelLarge: GoogleFonts.ubuntu(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: Colors.black87,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: lightCard,
      surfaceTintColor: Colors.transparent,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: lightBackground,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: GoogleFonts.ubuntu(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
        letterSpacing: -0.5,
      ),
      iconTheme: const IconThemeData(color: Colors.black87),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: lightSurface,
      indicatorColor: lightPrimary.withValues(alpha: 0.15),
      elevation: 8,
      height: 72,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.ubuntu(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: lightPrimary,
            letterSpacing: 0.5,
          );
        }
        return GoogleFonts.ubuntu(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.grey[600],
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: lightPrimary, size: 26);
        }
        return IconThemeData(color: Colors.grey[600], size: 24);
      }),
    ),
    iconTheme: const IconThemeData(color: Colors.black87, size: 24),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      hintStyle: GoogleFonts.ubuntu(color: Colors.grey[500], fontSize: 15),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: lightPrimary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.ubuntu(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: lightPrimary,
      foregroundColor: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: lightSurface,
      titleTextStyle: GoogleFonts.ubuntu(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
      ),
      contentTextStyle: GoogleFonts.ubuntu(
        fontSize: 15,
        color: Colors.black54,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: lightCard,
      contentTextStyle: GoogleFonts.ubuntu(
        color: Colors.black87,
      ),
      actionTextColor: lightPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
}
