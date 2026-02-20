import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ==================== COLORES OSCUROS (Basado en CSS) ====================
  static const Color darkBg = Color(0xFF090909); // --bg
  static const Color darkBg1 = Color(0xFF101010); // --bg1
  static const Color darkBg2 = Color(0xFF161616); // --bg2
  static const Color darkBg3 = Color(0xFF1E1E1E); // --bg3
  static const Color darkBg4 = Color(0xFF252525); // --bg4
  static const Color darkBorder = Color(0xFF2A2A2A); // --border
  static const Color darkBorder2 = Color(0xFF333333); // --border2

  // Accent principal - Verde lima brillante
  static const Color darkAccent = Color(0xFFC8FF47); // --accent
  static const Color darkAccentDim = Color(0x1AC8FF47); // --accent-dim (10%)
  static const Color darkAccentGlow = Color(0x38C8FF47); // --accent-glow (22%)

  // Estados
  static const Color darkDanger = Color(0xFFFF4757); // --danger
  static const Color darkDangerDim = Color(0x1FFF4757); // --danger-dim
  static const Color darkWarning = Color(0xFFFFA502); // --warning
  static const Color darkWarningDim = Color(0x1FFFA502); // --warning-dim
  static const Color darkSuccess = Color(0xFF2ED573); // --success
  static const Color darkSuccessDim = Color(0x1F2ED573); // --success-dim
  static const Color darkInfo = Color(0xFF1E90FF); // --info
  static const Color darkInfoDim = Color(0x1F1E90FF); // --info-dim

  // Textos
  static const Color darkText = Color(0xFFF0F0F0); // --text
  static const Color darkText2 = Color(0xFF999999); // --text2
  static const Color darkText3 = Color(0xFF555555); // --text3

  // Alias helpers
  static const Color darkCard = darkBg2;
  static const Color lightCard = lightBg1;

  // ==================== COLORES CLAROS (Refinado y Profesional) ====================
  static const Color lightBg = Color(0xFFFAFAFA); // Fondo principal suave
  static const Color lightBg1 = Color(0xFFFFFFFF); // Superficie principal
  static const Color lightBg2 = Color(0xFFF5F5F5); // Superficie secundaria
  static const Color lightBg3 = Color(0xFFEEEEEE); // Superficie terciaria
  static const Color lightBg4 = Color(0xFFE0E0E0); // Superficie hover
  static const Color lightBorder = Color(0xFFE0E0E0); // Borde principal
  static const Color lightBorder2 = Color(0xFFBDBDBD); // Borde secundario

  // Accent para modo claro - Verde lima más oscuro para mejor contraste
  static const Color lightAccent =
      Color(0xFF9FCC00); // Versión más oscura del accent
  static const Color lightAccentDim = Color(0x1A9FCC00); // Dim version
  static const Color lightAccentGlow = Color(0x389FCC00); // Glow version

  // Estados modo claro
  static const Color lightDanger = Color(0xFFD32F2F); // Danger más oscuro
  static const Color lightDangerDim = Color(0x1FD32F2F);
  static const Color lightWarning = Color(0xFFF57C00); // Warning más oscuro
  static const Color lightWarningDim = Color(0x1FF57C00);
  static const Color lightSuccess = Color(0xFF388E3C); // Success más oscuro
  static const Color lightSuccessDim = Color(0x1F388E3C);
  static const Color lightInfo = Color(0xFF1976D2); // Info más oscuro
  static const Color lightInfoDim = Color(0x1F1976D2);

  // Textos modo claro
  static const Color lightText = Color(0xFF212121); // Texto principal
  static const Color lightText2 = Color(0xFF757575); // Texto secundario
  static const Color lightText3 = Color(0xFFBDBDBD); // Texto terciario

  // ==================== TEMA OSCURO ====================
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: darkAccent,
      secondary: darkSuccess,
      surface: darkBg1,
      onSurface: darkText,
      error: darkDanger,
      tertiary: darkInfo,
      inverseSurface: darkText,
      outline: darkBorder,
      surfaceContainerHighest: darkBg3,
    ),
    scaffoldBackgroundColor: darkBg,
    cardColor: darkBg2,
    dividerColor: darkBorder,

    // Tipografía con DM Sans (similar al CSS)
    textTheme: GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme).copyWith(
      // Títulos con Syne (como en el CSS: --font-head: 'Syne')
      displayLarge: GoogleFonts.syne(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.02 * 32, // -0.02em
        color: darkText,
      ),
      displayMedium: GoogleFonts.syne(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02 * 28,
        color: darkText,
      ),
      headlineMedium: GoogleFonts.syne(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02 * 24,
        color: darkText,
      ),
      headlineSmall: GoogleFonts.syne(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02 * 20,
        color: darkText,
      ),
      titleLarge: GoogleFonts.syne(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02 * 18,
        color: darkText,
      ),
      titleMedium: GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: darkText,
      ),
      bodyLarge: GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: darkText2,
        height: 1.6,
      ),
      bodyMedium: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: darkText2,
        height: 1.6,
      ),
      bodySmall: GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: darkText3,
        height: 1.6,
      ),
      labelLarge: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: darkText,
      ),
      labelMedium: GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: darkText2,
      ),
      labelSmall: GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: darkText3,
      ),
    ),

    cardTheme: CardThemeData(
      elevation: 0,
      color: darkBg2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10), // --radius: 10px
        side: const BorderSide(color: darkBorder, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: darkBg1,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      iconTheme: const IconThemeData(color: darkText),
      titleTextStyle: GoogleFonts.syne(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02 * 22,
        color: darkText,
      ),
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: darkBg1,
      indicatorColor: darkAccentDim,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: darkAccent,
          );
        }
        return GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: darkText2,
        );
      }),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkBg3,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6), // --radius-sm: 6px
        borderSide: const BorderSide(color: darkBorder2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: darkBorder2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: darkAccent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: darkDanger),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      hintStyle: GoogleFonts.dmSans(color: darkText3, fontSize: 13.5),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: darkAccent,
        foregroundColor: darkBg,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: GoogleFonts.dmSans(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: darkText2,
        side: const BorderSide(color: darkBorder2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: GoogleFonts.dmSans(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: darkBg2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: darkBorder2),
      ),
    ),

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: darkBg2,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),

    popupMenuTheme: PopupMenuThemeData(
      color: darkBg2,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: darkBorder),
      ),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: darkBg3,
      contentTextStyle: GoogleFonts.dmSans(
        color: darkText,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      behavior: SnackBarBehavior.floating,
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: darkAccent,
      linearTrackColor: darkBg4,
    ),

    iconTheme: const IconThemeData(color: darkText),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return darkAccent;
        }
        return darkText3;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return darkAccentDim;
        }
        return darkBg4;
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return darkAccent;
        }
        return darkBorder2;
      }),
    ),
  );

  // ==================== TEMA CLARO ====================
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: lightAccent,
      secondary: lightSuccess,
      surface: lightBg1,
      onSurface: lightText,
      error: lightDanger,
      tertiary: lightInfo,
      inverseSurface: lightText,
      outline: lightBorder,
      surfaceContainerHighest: lightBg3,
    ),
    scaffoldBackgroundColor: lightBg,
    cardColor: lightBg1,
    dividerColor: lightBorder,
    dialogTheme: DialogThemeData(
      backgroundColor: lightBg1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: lightBorder),
      ),
    ),

    // Tipografía con DM Sans
    textTheme:
        GoogleFonts.dmSansTextTheme(ThemeData.light().textTheme).copyWith(
      // Títulos con Syne
      displayLarge: GoogleFonts.syne(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.02 * 32,
        color: lightText,
      ),
      displayMedium: GoogleFonts.syne(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02 * 28,
        color: lightText,
      ),
      headlineMedium: GoogleFonts.syne(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02 * 24,
        color: lightText,
      ),
      headlineSmall: GoogleFonts.syne(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02 * 20,
        color: lightText,
      ),
      titleLarge: GoogleFonts.syne(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02 * 18,
        color: lightText,
      ),
      titleMedium: GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: lightText,
      ),
      bodyLarge: GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: lightText2,
        height: 1.6,
      ),
      bodyMedium: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: lightText2,
        height: 1.6,
      ),
      bodySmall: GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: lightText3,
        height: 1.6,
      ),
      labelLarge: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: lightText,
      ),
      labelMedium: GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: lightText2,
      ),
      labelSmall: GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: lightText3,
      ),
    ),

    cardTheme: CardThemeData(
      elevation: 0,
      color: lightBg1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: lightBorder, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: lightBg1,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      iconTheme: const IconThemeData(color: lightText),
      titleTextStyle: GoogleFonts.syne(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02 * 22,
        color: lightText,
      ),
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: lightBg1,
      indicatorColor: lightAccentDim,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: lightAccent,
          );
        }
        return GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: lightText2,
        );
      }),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightBg1,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: lightAccent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: lightDanger),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      hintStyle: GoogleFonts.dmSans(color: lightText3, fontSize: 13.5),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: lightAccent,
        foregroundColor: darkBg,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: GoogleFonts.dmSans(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    ),

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: lightBg1,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),

    popupMenuTheme: PopupMenuThemeData(
      color: lightBg1,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: lightBorder),
      ),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: lightBg3,
      contentTextStyle: GoogleFonts.dmSans(
        color: lightText,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      behavior: SnackBarBehavior.floating,
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: lightAccent,
      linearTrackColor: lightBg4,
    ),

    iconTheme: const IconThemeData(color: lightText),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: lightText,
        side: const BorderSide(color: lightBg3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );
}
