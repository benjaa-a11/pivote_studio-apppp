import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ==================== COLORES OSCUROS (Premium Tint) ====================
  static const Color darkBg = Color(0xFF090B0F); // Fondo profundo
  static const Color darkBg1 = Color(0xFF0E1116); // Superficie principal
  static const Color darkBg2 = Color(0xFF13171D); // Tarjetas / modales
  static const Color darkBg3 = Color(0xFF1A1F26); // Hover / elementos elevados
  static const Color darkBg4 = Color(0xFF222831); // Presionado / destacado
  static const Color darkBorder = Color(0xFF262C36); // Borde sutil
  static const Color darkBorder2 = Color(0xFF333A45); // Borde fuerte

  // Accent principal - Verde lima brillante (se mantiene)
  static const Color darkAccent = Color(0xFFC8FF47); // --accent
  static const Color darkAccentDim = Color(0x1AC8FF47); // --accent-dim (10%)
  static const Color darkAccentGlow = Color(0x38C8FF47); // --accent-glow (22%)

  // Estados
  static const Color darkDanger = Color(0xFFFF4D4F); // Rojo suave premium
  static const Color darkDangerDim = Color(0x1FFF4D4F); // --danger-dim
  static const Color darkWarning = Color(0xFFFAAD14); // Naranja premium
  static const Color darkWarningDim = Color(0x1FFAAD14); // --warning-dim
  static const Color darkSuccess = Color(0xFF52C41A); // Verde premium
  static const Color darkSuccessDim = Color(0x1F52C41A); // --success-dim
  static const Color darkInfo = Color(0xFF1677FF); // Azul premium
  static const Color darkInfoDim = Color(0x1F1677FF); // --info-dim

  // Textos
  static const Color darkText = Color(0xFFF0F4F8); // Texto puro
  static const Color darkText2 = Color(0xFFA1AAB5); // Texto secundario
  static const Color darkText3 = Color(0xFF6E7885); // Texto terciario

  // Alias helpers
  static const Color darkCard = darkBg2;
  static const Color lightCard = lightBg1;

  // ==================== COLORES CLAROS (Refinado y Profesional) ====================
  static const Color lightBg =
      Color(0xFFF4F6F8); // Fondo principal suave (cool gray)
  static const Color lightBg1 = Color(0xFFFFFFFF); // Superficie principal
  static const Color lightBg2 = Color(0xFFEDF1F5); // Superficie secundaria
  static const Color lightBg3 = Color(0xFFE3E8ED); // Superficie terciaria
  static const Color lightBg4 = Color(0xFFD3DCE6); // Superficie hover
  static const Color lightBorder = Color(0xFFDCE2E8); // Borde principal
  static const Color lightBorder2 = Color(0xFFC4CDD5); // Borde secundario

  // Accent para modo claro - Verde lima más oscuro para mejor contraste
  static const Color lightAccent =
      Color(0xFF557700); // Versión más oscura y legible
  static const Color lightAccentDim = Color(0x1A557700); // Dim version
  static const Color lightAccentGlow = Color(0x38557700); // Glow version

  // Estados modo claro
  static const Color lightDanger = Color(0xFFCF1322); // Danger más oscuro
  static const Color lightDangerDim = Color(0x1FCF1322);
  static const Color lightWarning = Color(0xFFD4380D); // Warning más oscuro
  static const Color lightWarningDim = Color(0x1FD4380D);
  static const Color lightSuccess = Color(0xFF389E0D); // Success más oscuro
  static const Color lightSuccessDim = Color(0x1F389E0D);
  static const Color lightInfo = Color(0xFF0958D9); // Info más oscuro
  static const Color lightInfoDim = Color(0x1F0958D9);

  // Textos modo claro
  static const Color lightText = Color(0xFF1C222B); // Texto principal
  static const Color lightText2 = Color(0xFF5A6675); // Texto secundario
  static const Color lightText3 = Color(0xFF8C9BAA); // Texto terciario

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
    textTheme:
        GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
      // Títulos con Syne (como en el CSS: --font-head: 'Syne')
      displayLarge: GoogleFonts.spaceGrotesk(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.02 * 32, // -0.02em
        color: darkText,
      ),
      displayMedium: GoogleFonts.spaceGrotesk(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02 * 28,
        color: darkText,
      ),
      headlineMedium: GoogleFonts.spaceGrotesk(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02 * 24,
        color: darkText,
      ),
      headlineSmall: GoogleFonts.spaceGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02 * 20,
        color: darkText,
      ),
      titleLarge: GoogleFonts.spaceGrotesk(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02 * 18,
        color: darkText,
      ),
      titleMedium: GoogleFonts.spaceGrotesk(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: darkText,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: darkText2,
        height: 1.6,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: darkText2,
        height: 1.6,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: darkText3,
        height: 1.6,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: darkText,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: darkText2,
      ),
      labelSmall: GoogleFonts.inter(
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
        borderRadius: BorderRadius.circular(16), // --radius: 10px
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
      titleTextStyle: GoogleFonts.spaceGrotesk(
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
          return GoogleFonts.spaceGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: darkAccent,
          );
        }
        return GoogleFonts.spaceGrotesk(
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
        borderRadius: BorderRadius.circular(14), // --radius-sm: 6px
        borderSide: const BorderSide(color: darkBorder2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: darkBorder2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: darkAccent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: darkDanger),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      hintStyle: GoogleFonts.inter(color: darkText3, fontSize: 13.5),
      labelStyle: GoogleFonts.inter(color: darkText2, fontSize: 14),
      floatingLabelStyle: GoogleFonts.inter(color: darkAccent, fontSize: 14, fontWeight: FontWeight.w600),
      prefixIconColor: darkText3,
      suffixIconColor: darkText3,
      errorStyle: GoogleFonts.inter(color: darkDanger, fontSize: 12),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: darkAccent,
        foregroundColor: darkBg,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        minimumSize: const Size(0, 48),
        animationDuration: const Duration(milliseconds: 180),
        tapTargetSize: MaterialTapTargetSize.padded,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: GoogleFonts.spaceGrotesk(
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: darkText2,
        side: const BorderSide(color: darkBorder2),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        minimumSize: const Size(0, 48),
        animationDuration: const Duration(milliseconds: 180),
        tapTargetSize: MaterialTapTargetSize.padded,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: GoogleFonts.spaceGrotesk(
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: darkBg2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: darkBorder2),
      ),
    ),

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: darkBg2,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      showDragHandle: true,
      dragHandleColor: darkText3,
      dragHandleSize: Size(36, 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),

    popupMenuTheme: PopupMenuThemeData(
      color: darkBg2,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: darkBorder),
      ),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: darkBg3,
      contentTextStyle: GoogleFonts.spaceGrotesk(
        color: darkText,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
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

    dividerTheme: const DividerThemeData(color: darkBorder, thickness: 1, space: 1),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: darkAccent,
        foregroundColor: darkBg,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        minimumSize: const Size(0, 48),
        animationDuration: const Duration(milliseconds: 180),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: darkAccent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        minimumSize: const Size(44, 44),
        animationDuration: const Duration(milliseconds: 180),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: darkText2,
        minimumSize: const Size(44, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: darkBg3,
      selectedColor: darkAccentDim,
      disabledColor: darkBg2,
      checkmarkColor: darkAccent,
      showCheckmark: false,
      side: const BorderSide(color: darkBorder),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: darkText2),
      secondaryLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: darkText),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: darkText2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      horizontalTitleGap: 12,
      minVerticalPadding: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      titleTextStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: darkText),
      subtitleTextStyle: GoogleFonts.inter(fontSize: 13, color: darkText2, height: 1.4),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: darkBg2,
      surfaceTintColor: Colors.transparent,
      headerBackgroundColor: darkBg3,
      headerForegroundColor: darkText,
      dividerColor: darkBorder,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      todayForegroundColor: const WidgetStatePropertyAll<Color?>(darkAccent),
      todayBackgroundColor: const WidgetStatePropertyAll<Color?>(darkAccentDim),
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: darkBg2,
      dialBackgroundColor: darkBg3,
      dialHandColor: darkAccent,
      hourMinuteColor: darkBg3,
      hourMinuteTextColor: darkText,
      entryModeIconColor: darkAccent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      side: const BorderSide(color: darkBorder2, width: 1.4),
      fillColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? darkAccent : null),
      checkColor: const WidgetStatePropertyAll<Color?>(darkBg),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? darkAccent : darkText3),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: darkAccent,
      inactiveTrackColor: darkBg4,
      thumbColor: darkAccent,
      overlayColor: darkAccentDim,
      trackHeight: 3,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: darkAccent,
      foregroundColor: darkBg,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    tooltipTheme: TooltipThemeData(
      waitDuration: const Duration(milliseconds: 350),
      showDuration: const Duration(seconds: 3),
      decoration: BoxDecoration(color: darkBg4, borderRadius: BorderRadius.circular(10), border: Border.all(color: darkBorder)),
      textStyle: GoogleFonts.inter(fontSize: 12, color: darkText),
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: darkAccent,
      selectionColor: darkAccentDim,
      selectionHandleColor: darkAccent,
    ),
    pageTransitionsTheme: _pageTransitionsTheme,
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
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: lightBorder),
      ),
    ),

    // Tipografía con DM Sans
    textTheme:
        GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
      // Títulos con Syne
      displayLarge: GoogleFonts.spaceGrotesk(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.02 * 32,
        color: lightText,
      ),
      displayMedium: GoogleFonts.spaceGrotesk(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02 * 28,
        color: lightText,
      ),
      headlineMedium: GoogleFonts.spaceGrotesk(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02 * 24,
        color: lightText,
      ),
      headlineSmall: GoogleFonts.spaceGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02 * 20,
        color: lightText,
      ),
      titleLarge: GoogleFonts.spaceGrotesk(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02 * 18,
        color: lightText,
      ),
      titleMedium: GoogleFonts.spaceGrotesk(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: lightText,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: lightText2,
        height: 1.6,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: lightText2,
        height: 1.6,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: lightText3,
        height: 1.6,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: lightText,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: lightText2,
      ),
      labelSmall: GoogleFonts.inter(
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
        borderRadius: BorderRadius.circular(16),
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
      titleTextStyle: GoogleFonts.spaceGrotesk(
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
          return GoogleFonts.spaceGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: lightAccent,
          );
        }
        return GoogleFonts.spaceGrotesk(
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
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: lightAccent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: lightDanger),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      hintStyle: GoogleFonts.inter(color: lightText3, fontSize: 13.5),
      labelStyle: GoogleFonts.inter(color: lightText2, fontSize: 14),
      floatingLabelStyle: GoogleFonts.inter(color: lightAccent, fontSize: 14, fontWeight: FontWeight.w600),
      prefixIconColor: lightText3,
      suffixIconColor: lightText3,
      errorStyle: GoogleFonts.inter(color: lightDanger, fontSize: 12),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: lightAccent,
        foregroundColor: darkBg,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        minimumSize: const Size(0, 48),
        animationDuration: const Duration(milliseconds: 180),
        tapTargetSize: MaterialTapTargetSize.padded,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: GoogleFonts.spaceGrotesk(
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    ),

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: lightBg1,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      showDragHandle: true,
      dragHandleColor: lightText3,
      dragHandleSize: Size(36, 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),

    popupMenuTheme: PopupMenuThemeData(
      color: lightBg1,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: lightBorder),
      ),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: lightBg3,
      contentTextStyle: GoogleFonts.spaceGrotesk(
        color: lightText,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
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
        side: const BorderSide(color: lightBorder2),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        minimumSize: const Size(0, 48),
        animationDuration: const Duration(milliseconds: 180),
        tapTargetSize: MaterialTapTargetSize.padded,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),

    dividerTheme: const DividerThemeData(color: lightBorder, thickness: 1, space: 1),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: lightAccent,
        foregroundColor: darkBg,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        minimumSize: const Size(0, 48),
        animationDuration: const Duration(milliseconds: 180),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: lightAccent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        minimumSize: const Size(44, 44),
        animationDuration: const Duration(milliseconds: 180),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: lightText2,
        minimumSize: const Size(44, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: lightBg2,
      selectedColor: lightAccentDim,
      disabledColor: lightBg2,
      checkmarkColor: lightAccent,
      showCheckmark: false,
      side: const BorderSide(color: lightBorder),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: lightText2),
      secondaryLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: lightText),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: lightText2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      horizontalTitleGap: 12,
      minVerticalPadding: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      titleTextStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: lightText),
      subtitleTextStyle: GoogleFonts.inter(fontSize: 13, color: lightText2, height: 1.4),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: lightBg1,
      surfaceTintColor: Colors.transparent,
      headerBackgroundColor: lightBg2,
      headerForegroundColor: lightText,
      dividerColor: lightBorder,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      todayForegroundColor: const WidgetStatePropertyAll<Color?>(lightAccent),
      todayBackgroundColor: const WidgetStatePropertyAll<Color?>(lightAccentDim),
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: lightBg1,
      dialBackgroundColor: lightBg2,
      dialHandColor: lightAccent,
      hourMinuteColor: lightBg2,
      hourMinuteTextColor: lightText,
      entryModeIconColor: lightAccent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      side: const BorderSide(color: lightBorder2, width: 1.4),
      fillColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? lightAccent : null),
      checkColor: const WidgetStatePropertyAll<Color?>(Colors.white),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? lightAccent : lightText3),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: lightAccent,
      inactiveTrackColor: lightBg3,
      thumbColor: lightAccent,
      overlayColor: lightAccentDim,
      trackHeight: 3,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: lightAccent,
      foregroundColor: darkBg,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    tooltipTheme: TooltipThemeData(
      waitDuration: const Duration(milliseconds: 350),
      showDuration: const Duration(seconds: 3),
      decoration: BoxDecoration(color: lightText, borderRadius: BorderRadius.circular(10)),
      textStyle: GoogleFonts.inter(fontSize: 12, color: Colors.white),
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: lightAccent,
      selectionColor: lightAccentDim,
      selectionHandleColor: lightAccent,
    ),
    pageTransitionsTheme: _pageTransitionsTheme,
  );

  static const PageTransitionsTheme _pageTransitionsTheme =
      PageTransitionsTheme(
    builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
    },
  );
}
