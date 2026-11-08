import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Identidad tipográfica ÚNICA de Pivote.
///
/// Familia principal: **Space Grotesk** — la tipografía geométrica que define
/// la identidad visual de las referencias principales (Matches Hero y
/// Tarjetas de Canales), ahora unificada en todas las pantallas, textos,
/// etiquetas, botones y formularios de la aplicación.
///
/// Única excepción justificada: [AppFont.score] (**Big Shoulders Display**)
/// reservada exclusivamente para los dígitos del marcador deportivo.
class AppFont {
  AppFont._();

  /// Estilo tipográfico principal unificado para toda la aplicación.
  static TextStyle primary({
    TextStyle? textStyle,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    List<ui.FontFeature>? fontFeatures,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
  }) {
    return GoogleFonts.spaceGrotesk(
      textStyle: textStyle,
      color: color,
      backgroundColor: backgroundColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      textBaseline: textBaseline,
      height: height,
      locale: locale,
      foreground: foreground,
      background: background,
      shadows: shadows,
      fontFeatures: fontFeatures,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      decorationThickness: decorationThickness,
    );
  }

  /// Alias semántico de [primary] para migración limpia en toda la app.
  static TextStyle text({
    TextStyle? textStyle,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    List<ui.FontFeature>? fontFeatures,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
  }) =>
      primary(
        textStyle: textStyle,
        color: color,
        backgroundColor: backgroundColor,
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        letterSpacing: letterSpacing,
        wordSpacing: wordSpacing,
        textBaseline: textBaseline,
        height: height,
        locale: locale,
        foreground: foreground,
        background: background,
        shadows: shadows,
        fontFeatures: fontFeatures,
        decoration: decoration,
        decorationColor: decorationColor,
        decorationStyle: decorationStyle,
        decorationThickness: decorationThickness,
      );

  /// Marcadores numéricos del Matches Hero y agenda deportiva.
  static TextStyle score({
    TextStyle? textStyle,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    List<ui.FontFeature>? fontFeatures,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
  }) {
    return GoogleFonts.bigShouldersDisplay(
      textStyle: textStyle,
      color: color,
      backgroundColor: backgroundColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      textBaseline: textBaseline,
      height: height,
      locale: locale,
      foreground: foreground,
      background: background,
      shadows: shadows,
      fontFeatures: fontFeatures,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      decorationThickness: decorationThickness,
    );
  }
}

/// Escala tipográfica centralizada del Design System.
///
/// Jerarquía definida:
/// - Display / Títulos principales: 28–32px, w800, tracking negativo
/// - Headlines / Encabezados de pantalla: 20–24px, w700–w800
/// - Titles / Encabezados de sección y tarjetas: 14–18px, w600–w700
/// - Body / Texto general y secundario: 12.5–16px, w400–w500
/// - Labels / Botones, badges, chips y textos pequeños: 10.5–14px, w600–w700
class AppTypography {
  AppTypography._();

  static TextTheme textTheme({
    required Color primary,
    required Color secondary,
    required Color tertiary,
  }) {
    TextStyle s(
      double size,
      FontWeight weight,
      Color color, {
      double? ls,
      double h = 1.3,
    }) =>
        AppFont.primary(
          fontSize: size,
          fontWeight: weight,
          color: color,
          letterSpacing: ls,
          height: h,
        );

    return TextTheme(
      // Títulos principales / Hero
      displayLarge: s(32, FontWeight.w800, primary, ls: -0.8, h: 1.12),
      displayMedium: s(28, FontWeight.w800, primary, ls: -0.6, h: 1.15),
      displaySmall: s(24, FontWeight.w700, primary, ls: -0.5, h: 1.18),

      // Encabezados de pantalla
      headlineLarge: s(24, FontWeight.w800, primary, ls: -0.5, h: 1.2),
      headlineMedium: s(21, FontWeight.w700, primary, ls: -0.4, h: 1.22),
      headlineSmall: s(18, FontWeight.w700, primary, ls: -0.3, h: 1.25),

      // Encabezados de sección y títulos de tarjeta
      titleLarge: s(17, FontWeight.w700, primary, ls: -0.25, h: 1.28),
      titleMedium: s(15, FontWeight.w700, primary, ls: -0.15, h: 1.32),
      titleSmall: s(13.5, FontWeight.w600, primary, ls: -0.1, h: 1.32),

      // Texto general y secundario
      bodyLarge: s(15.5, FontWeight.w400, secondary, h: 1.5),
      bodyMedium: s(13.5, FontWeight.w400, secondary, h: 1.48),
      bodySmall: s(12, FontWeight.w500, tertiary, h: 1.42),

      // Botones, etiquetas, badges y metadatos
      labelLarge: s(14, FontWeight.w700, primary, ls: -0.1, h: 1.2),
      labelMedium: s(12, FontWeight.w600, secondary, ls: 0.1, h: 1.2),
      labelSmall: s(10.5, FontWeight.w700, tertiary, ls: 0.4, h: 1.15),
    );
  }
}

/// Extensiones rápidas para acceder al sistema de diseño desde `BuildContext`.
extension AppThemeContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get text => Theme.of(this).textTheme;
  ColorScheme get colors => Theme.of(this).colorScheme;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
