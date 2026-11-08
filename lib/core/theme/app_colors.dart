import 'package:flutter/material.dart';

/// Paleta base de Pivote — ÚNICA fuente de verdad de colores.
///
/// Reglas:
///  * Las pantallas NO declaran `Color(0xFF...)`: usan `Theme.of(context)`,
///    `AppTheme.*` (tokens por modo) o las constantes de esta clase.
///  * Un acento (lima) usado con moderación + colores semánticos desaturados.
///  * Ambos modos comparten identidad: mismos matices, distinta luminosidad.
class AppColors {
  AppColors._();

  // ── Neutros modo oscuro (profundidad por niveles) ────────────────────────
  static const Color darkBg = Color(0xFF090B0F);
  static const Color darkBg1 = Color(0xFF0E1116);
  static const Color darkBg2 = Color(0xFF13171D);
  static const Color darkBg3 = Color(0xFF1A1F26);
  static const Color darkBg4 = Color(0xFF222831);
  static const Color darkBorder = Color(0xFF262C36);
  static const Color darkBorder2 = Color(0xFF333A45);
  static const Color darkText = Color(0xFFF0F4F8);
  static const Color darkText2 = Color(0xFFA1AAB5);
  static const Color darkText3 = Color(0xFF6E7885);

  // ── Neutros modo claro ───────────────────────────────────────────────────
  static const Color lightBg = Color(0xFFF4F6F8);
  static const Color lightBg1 = Color(0xFFFFFFFF);
  static const Color lightBg2 = Color(0xFFEDF1F5);
  static const Color lightBg3 = Color(0xFFE3E8ED);
  static const Color lightBg4 = Color(0xFFD3DCE6);
  static const Color lightBorder = Color(0xFFDCE2E8);
  static const Color lightBorder2 = Color(0xFFC4CDD5);
  static const Color lightText = Color(0xFF1C222B);
  static const Color lightText2 = Color(0xFF5A6675);
  static const Color lightText3 = Color(0xFF7A8797);

  // ── Acento de marca ──────────────────────────────────────────────────────
  static const Color darkAccent = Color(0xFFC8FF47);
  static const Color lightAccent = Color(0xFF4E7A00);
  static const Color onDarkAccent = Color(0xFF0B1200);
  static const Color onLightAccent = Color(0xFFFFFFFF);

  /// Alias de acento principal (defecto oscuro).
  static const Color accent = darkAccent;
  static const Color accentStrong = Color(0xFFA6E015);
  /// Tono secundario complementario de marca.
  static const Color secondary = violet;

  // ── Semánticos (desaturados, un solo matiz por significado) ──────────────
  static const Color darkDanger = Color(0xFFFF5468);
  static const Color darkWarning = Color(0xFFF0B429);
  static const Color darkSuccess = Color(0xFF3DC98F);
  static const Color darkInfo = Color(0xFF4F9BF0);

  static const Color lightDanger = Color(0xFFD92D45);
  static const Color lightWarning = Color(0xFFB86E00);
  static const Color lightSuccess = Color(0xFF1B9A62);
  static const Color lightInfo = Color(0xFF2563C9);

  // ── Constantes agnósticas al tema (se usan dentro de superficies que son
  //    siempre oscuras: Matches Hero, reproductores, overlays) ──────────────
  /// Rojo "EN VIVO" y errores.
  static const Color live = Color(0xFFFF5468);
  static const Color danger = live;
  static const Color error = live;

  /// Verde positivo / disponible.
  static const Color positive = Color(0xFF34C38F);
  static const Color success = positive;

  /// Ámbar de advertencia.
  static const Color warning = Color(0xFFF0B429);

  /// Azul informativo.
  static const Color info = Color(0xFF4F9BF0);

  /// Violeta secundario (categorías, etiquetas).
  static const Color violet = Color(0xFF9B6BE6);

  /// Superficie clara alternativa.
  static const Color lightSurface2 = lightBg2;
  static const Color darkText1 = darkText;

  /// Dorado de eventos especiales (conservado: identidad de tarjetas de evento).
  static const Color gold = Color(0xFFD4AF37);

  /// Gris azulado para texto secundario sobre superficies siempre oscuras.
  static const Color slate = Color(0xFF7C879B);
  static const Color slate400 = Color(0xFFAAB3C5);
  static const Color slate200 = Color(0xFFCBD5E1);
  static const Color slate50 = Color(0xFFEEF1F6);

  /// Escala de superficies siempre oscuras (hero, reproductores).
  static const Color ink0 = Color(0xFF080B11);
  static const Color ink1 = Color(0xFF0F131C);
  static const Color ink2 = Color(0xFF131722);
  static const Color ink3 = Color(0xFF1E2533);
}

