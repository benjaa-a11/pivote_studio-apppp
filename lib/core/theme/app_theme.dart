import 'package:flutter/material.dart';
import 'package:pivote/core/theme/app_colors.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/core/theme/app_typography.dart';

export 'package:pivote/core/theme/app_colors.dart';
export 'package:pivote/core/theme/app_typography.dart';

/// Sistema de temas centralizado de Pivote (Modo Oscuro y Modo Claro).
///
/// Centraliza la paleta cromática, la tipografía única (`Space Grotesk` +
/// `Big Shoulders Display` para marcadores), radios de borde, botones,
/// inputs, tarjetas, diálogos, hojas inferiores y componentes interactivos.
class AppTheme {
  AppTheme._();

  // ==================== COLORES OSCUROS (Niveles de profundidad) ====================
  static const Color darkBg = AppColors.darkBg; // Fondo principal profundo (#090B0F)
  static const Color darkBg1 = AppColors.darkBg1; // Superficie nivel 1 (#0E1116)
  static const Color darkBg2 = AppColors.darkBg2; // Tarjetas / contenedores (#13171D)
  static const Color darkBg3 = AppColors.darkBg3; // Elementos elevados / inputs (#1A1F26)
  static const Color darkBg4 = AppColors.darkBg4; // Presionado / track (#222831)
  static const Color darkBorder = AppColors.darkBorder; // Borde discreto (#262C36)
  static const Color darkBorder2 = AppColors.darkBorder2; // Borde enfatizado (#333A45)

  // Acento principal modo oscuro
  static const Color darkAccent = AppColors.darkAccent;
  static const Color darkAccentDim = Color(0x1FC8FF47);
  static const Color darkAccentGlow = Color(0x38C8FF47);

  // Estados semánticos modo oscuro
  static const Color darkDanger = AppColors.darkDanger;
  static const Color darkDangerDim = Color(0x1FFF5468);
  static const Color darkWarning = AppColors.darkWarning;
  static const Color darkWarningDim = Color(0x1FF0B429);
  static const Color darkSuccess = AppColors.darkSuccess;
  static const Color darkSuccessDim = Color(0x1F3DC98F);
  static const Color darkInfo = AppColors.darkInfo;
  static const Color darkInfoDim = Color(0x1F4F9BF0);

  // Textos modo oscuro
  static const Color darkText = AppColors.darkText;
  static const Color darkText2 = AppColors.darkText2;
  static const Color darkText3 = AppColors.darkText3;

  // Alias de tarjetas
  static const Color darkCard = darkBg2;
  static const Color lightCard = lightBg1;

  // ==================== COLORES CLAROS (Limpio y Profesional) ====================
  static const Color lightBg = AppColors.lightBg; // Fondo claro suave (#F4F6F8)
  static const Color lightBg1 = AppColors.lightBg1; // Superficie blanca (#FFFFFF)
  static const Color lightBg2 = AppColors.lightBg2; // Superficie secundaria (#EDF1F5)
  static const Color lightBg3 = AppColors.lightBg3; // Superficie terciaria (#E3E8ED)
  static const Color lightBg4 = AppColors.lightBg4; // Superficie activa (#D3DCE6)
  static const Color lightBorder = AppColors.lightBorder; // Borde discreto (#DCE2E8)
  static const Color lightBorder2 = AppColors.lightBorder2; // Borde enfatizado (#C4CDD5)

  // Acento modo claro (equilibrado y con contraste óptimo sobre fondos claros)
  static const Color lightAccent = AppColors.lightAccent;
  static const Color lightAccentDim = Color(0x1A4E7A00);
  static const Color lightAccentGlow = Color(0x334E7A00);

  // Estados semánticos modo claro
  static const Color lightDanger = AppColors.lightDanger;
  static const Color lightDangerDim = Color(0x1AD92D45);
  static const Color lightWarning = AppColors.lightWarning;
  static const Color lightWarningDim = Color(0x1AB86E00);
  static const Color lightSuccess = AppColors.lightSuccess;
  static const Color lightSuccessDim = Color(0x1A1B9A62);
  static const Color lightInfo = AppColors.lightInfo;
  static const Color lightInfoDim = Color(0x1A2563C9);

  // Textos modo claro
  static const Color lightText = AppColors.lightText;
  static const Color lightText2 = AppColors.lightText2;
  static const Color lightText3 = AppColors.lightText3;

  // ==================== HELPERS CONTEXTUALES POR TEMA ====================
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color bg(BuildContext context) =>
      isDark(context) ? darkBg : lightBg;

  static Color surface1(BuildContext context) =>
      isDark(context) ? darkBg1 : lightBg1;

  static Color surface2(BuildContext context) =>
      isDark(context) ? darkBg2 : lightBg2;

  static Color surface3(BuildContext context) =>
      isDark(context) ? darkBg3 : lightBg3;

  static Color cardSurface(BuildContext context) =>
      isDark(context) ? darkBg2 : lightBg1;

  static Color border(BuildContext context) =>
      isDark(context) ? darkBorder : lightBorder;

  static Color borderStrong(BuildContext context) =>
      isDark(context) ? darkBorder2 : lightBorder2;

  static Color textPrimary(BuildContext context) =>
      isDark(context) ? darkText : lightText;

  static Color textSecondary(BuildContext context) =>
      isDark(context) ? darkText2 : lightText2;

  static Color textTertiary(BuildContext context) =>
      isDark(context) ? darkText3 : lightText3;

  static Color accent(BuildContext context) =>
      isDark(context) ? darkAccent : lightAccent;

  static Color onAccent(BuildContext context) =>
      isDark(context) ? AppColors.onDarkAccent : AppColors.onLightAccent;

  static Color danger(BuildContext context) =>
      isDark(context) ? darkDanger : lightDanger;

  static Color success(BuildContext context) =>
      isDark(context) ? darkSuccess : lightSuccess;

  static Color warning(BuildContext context) =>
      isDark(context) ? darkWarning : lightWarning;

  static Color info(BuildContext context) =>
      isDark(context) ? darkInfo : lightInfo;

  // ==================== TEMA OSCURO ====================
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: darkAccent,
      onPrimary: AppColors.onDarkAccent,
      secondary: darkSuccess,
      onSecondary: darkBg,
      surface: darkBg1,
      onSurface: darkText,
      error: darkDanger,
      onError: Colors.white,
      tertiary: darkInfo,
      inverseSurface: darkText,
      outline: darkBorder,
      outlineVariant: darkBorder2,
      surfaceContainerHighest: darkBg3,
    ),
    scaffoldBackgroundColor: darkBg,
    cardColor: darkBg2,
    dividerColor: darkBorder,
    hintColor: darkText3,
    textTheme: AppTypography.textTheme(
      primary: darkText,
      secondary: darkText2,
      tertiary: darkText3,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: darkBg2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
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
      titleTextStyle: AppFont.primary(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        color: darkText,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: darkBg1,
      indicatorColor: darkAccentDim,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppFont.primary(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: darkAccent,
          );
        }
        return AppFont.primary(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: darkText2,
        );
      }),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkBg2,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: darkAccent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: darkDanger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: darkDanger, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: AppFont.primary(color: darkText3, fontSize: 13.5, fontWeight: FontWeight.w500),
      labelStyle: AppFont.primary(color: darkText2, fontSize: 14, fontWeight: FontWeight.w500),
      floatingLabelStyle: AppFont.primary(
        color: darkAccent,
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
      ),
      prefixIconColor: darkText3,
      suffixIconColor: darkText3,
      errorStyle: AppFont.primary(color: darkDanger, fontSize: 12, fontWeight: FontWeight.w600),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: darkAccent,
        foregroundColor: AppColors.onDarkAccent,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        minimumSize: const Size(0, 48),
        animationDuration: const Duration(milliseconds: 180),
        tapTargetSize: MaterialTapTargetSize.padded,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        textStyle: AppFont.primary(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          letterSpacing: -0.1,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: darkText,
        side: const BorderSide(color: darkBorder2),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        minimumSize: const Size(0, 48),
        animationDuration: const Duration(milliseconds: 180),
        tapTargetSize: MaterialTapTargetSize.padded,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        textStyle: AppFont.primary(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          letterSpacing: -0.1,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: darkAccent,
        foregroundColor: AppColors.onDarkAccent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        minimumSize: const Size(0, 48),
        animationDuration: const Duration(milliseconds: 180),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        textStyle: AppFont.primary(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.1,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: darkAccent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        minimumSize: const Size(44, 44),
        animationDuration: const Duration(milliseconds: 180),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        textStyle: AppFont.primary(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.1,
        ),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: darkText2,
        minimumSize: const Size(42, 42),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: darkBg2,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: darkBorder),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: darkBg1,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      showDragHandle: true,
      dragHandleColor: darkText3,
      dragHandleSize: Size(36, 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: darkBg2,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: darkBorder),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: darkBg3,
      contentTextStyle: AppFont.primary(
        color: darkText,
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: darkBorder),
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
        if (states.contains(WidgetState.selected)) return darkAccent;
        return darkText3;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return darkAccentDim;
        return darkBg4;
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return darkAccent;
        return darkBorder2;
      }),
    ),
    dividerTheme: const DividerThemeData(
      color: darkBorder,
      thickness: 1,
      space: 1,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: darkBg2,
      selectedColor: darkAccentDim,
      disabledColor: darkBg1,
      checkmarkColor: darkAccent,
      showCheckmark: false,
      side: const BorderSide(color: darkBorder),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      labelStyle: AppFont.primary(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: darkText2,
      ),
      secondaryLabelStyle: AppFont.primary(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: darkText,
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: darkText2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      horizontalTitleGap: 12,
      minVerticalPadding: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      titleTextStyle: AppFont.primary(
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
        color: darkText,
      ),
      subtitleTextStyle: AppFont.primary(
        fontSize: 12.5,
        fontWeight: FontWeight.w500,
        color: darkText2,
        height: 1.4,
      ),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: darkBg2,
      surfaceTintColor: Colors.transparent,
      headerBackgroundColor: darkBg3,
      headerForegroundColor: darkText,
      dividerColor: darkBorder,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      side: const BorderSide(color: darkBorder2, width: 1.4),
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? darkAccent : null,
      ),
      checkColor: const WidgetStatePropertyAll<Color?>(darkBg),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? darkAccent : darkText3,
      ),
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
      foregroundColor: AppColors.onDarkAccent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      waitDuration: const Duration(milliseconds: 350),
      showDuration: const Duration(seconds: 3),
      decoration: BoxDecoration(
        color: darkBg3,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: darkBorder),
      ),
      textStyle: AppFont.primary(fontSize: 12, color: darkText, fontWeight: FontWeight.w500),
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
      onPrimary: AppColors.onLightAccent,
      secondary: lightSuccess,
      onSecondary: Colors.white,
      surface: lightBg1,
      onSurface: lightText,
      error: lightDanger,
      onError: Colors.white,
      tertiary: lightInfo,
      inverseSurface: lightText,
      outline: lightBorder,
      outlineVariant: lightBorder2,
      surfaceContainerHighest: lightBg3,
    ),
    scaffoldBackgroundColor: lightBg,
    cardColor: lightBg1,
    dividerColor: lightBorder,
    hintColor: lightText3,
    textTheme: AppTypography.textTheme(
      primary: lightText,
      secondary: lightText2,
      tertiary: lightText3,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: lightBg1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
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
      titleTextStyle: AppFont.primary(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        color: lightText,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: lightBg1,
      indicatorColor: lightAccentDim,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppFont.primary(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: lightAccent,
          );
        }
        return AppFont.primary(
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
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: lightAccent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: lightDanger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: lightDanger, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: AppFont.primary(color: lightText3, fontSize: 13.5, fontWeight: FontWeight.w500),
      labelStyle: AppFont.primary(color: lightText2, fontSize: 14, fontWeight: FontWeight.w500),
      floatingLabelStyle: AppFont.primary(
        color: lightAccent,
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
      ),
      prefixIconColor: lightText3,
      suffixIconColor: lightText3,
      errorStyle: AppFont.primary(color: lightDanger, fontSize: 12, fontWeight: FontWeight.w600),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: lightAccent,
        foregroundColor: AppColors.onLightAccent,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        minimumSize: const Size(0, 48),
        animationDuration: const Duration(milliseconds: 180),
        tapTargetSize: MaterialTapTargetSize.padded,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        textStyle: AppFont.primary(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          letterSpacing: -0.1,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: lightText,
        side: const BorderSide(color: lightBorder2),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        minimumSize: const Size(0, 48),
        animationDuration: const Duration(milliseconds: 180),
        tapTargetSize: MaterialTapTargetSize.padded,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        textStyle: AppFont.primary(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          letterSpacing: -0.1,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: lightAccent,
        foregroundColor: AppColors.onLightAccent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        minimumSize: const Size(0, 48),
        animationDuration: const Duration(milliseconds: 180),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        textStyle: AppFont.primary(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.1,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: lightAccent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        minimumSize: const Size(44, 44),
        animationDuration: const Duration(milliseconds: 180),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        textStyle: AppFont.primary(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.1,
        ),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: lightText2,
        minimumSize: const Size(42, 42),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: lightBg1,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: lightBorder),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: lightBg1,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: lightBorder),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: lightBg1,
      contentTextStyle: AppFont.primary(
        color: lightText,
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: lightBorder),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: lightAccent,
      linearTrackColor: lightBg3,
    ),
    iconTheme: const IconThemeData(color: lightText),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return lightAccent;
        return lightText3;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return lightAccentDim;
        return lightBg3;
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return lightAccent;
        return lightBorder2;
      }),
    ),
    dividerTheme: const DividerThemeData(
      color: lightBorder,
      thickness: 1,
      space: 1,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: lightBg2,
      selectedColor: lightAccentDim,
      disabledColor: lightBg2,
      checkmarkColor: lightAccent,
      showCheckmark: false,
      side: const BorderSide(color: lightBorder),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      labelStyle: AppFont.primary(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: lightText2,
      ),
      secondaryLabelStyle: AppFont.primary(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: lightText,
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: lightText2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      horizontalTitleGap: 12,
      minVerticalPadding: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      titleTextStyle: AppFont.primary(
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
        color: lightText,
      ),
      subtitleTextStyle: AppFont.primary(
        fontSize: 12.5,
        fontWeight: FontWeight.w500,
        color: lightText2,
        height: 1.4,
      ),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: lightBg1,
      surfaceTintColor: Colors.transparent,
      headerBackgroundColor: lightBg2,
      headerForegroundColor: lightText,
      dividerColor: lightBorder,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      side: const BorderSide(color: lightBorder2, width: 1.4),
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? lightAccent : null,
      ),
      checkColor: const WidgetStatePropertyAll<Color?>(Colors.white),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? lightAccent : lightText3,
      ),
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
      foregroundColor: AppColors.onLightAccent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      waitDuration: const Duration(milliseconds: 350),
      showDuration: const Duration(seconds: 3),
      decoration: BoxDecoration(
        color: lightText,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      textStyle: AppFont.primary(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
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
