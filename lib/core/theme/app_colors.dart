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

  // ── Neutros modo oscuro (CSS: --bg, --s1, --s2, --s3, --line, --line2) ───────
  static const Color darkBg = Color(0xFF0A0D14); // --bg: Fondo profundo
  static const Color darkBg1 = Color(0xFF11151F); // --s1: Superficie nivel 1
  static const Color darkBg2 = Color(0xFF171C28); // --s2: Superficie nivel 2 (tarjetas)
  static const Color darkBg3 = Color(0xFF1E2433); // --s3: Superficie nivel 3 (elevado)
  static const Color darkBg4 = Color(0xFF242B3B); // --line: Bordes y separadores
  static const Color darkBorder = Color(0xFF242B3B); // --line: Borde principal
  static const Color darkBorder2 = Color(0xFF2A3142); // --line2: Borde enfatizado
  static const Color darkText = Color(0xFFEAEEF7); // --tx: Texto principal
  static const Color darkText2 = Color(0xFFC9D0E2); // --tx2: Texto secundario
  static const Color darkText3 = Color(0xFF98A1B8); // --mut: Texto terciario / silenciado

  // ── Neutros modo claro ───────────────────────────────────────────────────
  static const Color lightBg = Color(0xFFF3F5F9);
  static const Color lightBg1 = Color(0xFFFFFFFF);
  static const Color lightBg2 = Color(0xFFEAEEF5);
  static const Color lightBg3 = Color(0xFFDEE4EE);
  static const Color lightBg4 = Color(0xFFCED6E2);
  static const Color lightBorder = Color(0xFFD6DCE6);
  static const Color lightBorder2 = Color(0xFFBFC7D5);
  static const Color lightText = Color(0xFF0E131E);
  static const Color lightText2 = Color(0xFF4A5568);
  static const Color lightText3 = Color(0xFF718096);

  // ── Acento de marca (CSS: --acc: #2A6FF0, --accT: #7DB0FF, --accBg: #1B2A4D) ──
  static const Color darkAccent = Color(0xFF2A6FF0); // --acc: Azul zafiro eléctrico
  static const Color lightAccent = Color(0xFF1D5AD0);
  static const Color onDarkAccent = Color(0xFFFFFFFF);
  static const Color onLightAccent = Color(0xFFFFFFFF);

  /// Alias de acento principal.
  static const Color accent = darkAccent;
  static const Color accentStrong = Color(0xFF1652C7);
  static const Color accentTint = Color(0xFF7DB0FF); // --accT
  static const Color accentBg = Color(0xFF1B2A4D); // --accBg

  /// Tono secundario complementario de marca (CSS mesh: rgba(150,95,255,.2)).
  static const Color violet = Color(0xFF965FFF);
  static const Color secondary = violet;

  // ── Semánticos (CSS: --live: #D92B43, --liveT: #FF7A8C, --ok: #9AD9B4, --warn: #E6D28A)
  static const Color darkDanger = Color(0xFFD92B43); // --live: Rojo en vivo
  static const Color darkWarning = Color(0xFFE6D28A); // --warn: Dorado / advertencia
  static const Color darkSuccess = Color(0xFF9AD9B4); // --ok: Verde menta suave
  static const Color darkInfo = Color(0xFF7DB0FF); // --accT: Azul informativo

  static const Color lightDanger = Color(0xFFC72138);
  static const Color lightWarning = Color(0xFFB59325);
  static const Color lightSuccess = Color(0xFF1E8752);
  static const Color lightInfo = Color(0xFF1D5AD0);

  // ── Tokens Glassmorphic (CSS: --gl, --gl2, --glb, --gld, --glp) ───────────
  static const Color glass = Color(0x11FFFFFF); // --gl: rgba(255,255,255, 0.065)
  static const Color glass2 = Color(0x1CFFFFFF); // --gl2: rgba(255,255,255, 0.11)
  static const Color glassBorder = Color(0x21FFFFFF); // --glb: rgba(255,255,255, 0.13)
  static const Color glassBorderSubtle = Color(0x12FFFFFF); // --gld: rgba(255,255,255, 0.07)
  static const Color glassPanel = Color(0x9E121622); // --glp: rgba(18,22,34, 0.62)

  // ── Constantes agnósticas al tema (superficies audiovisuales oscuras) ───────
  /// Rojo "EN VIVO" y errores.
  static const Color live = Color(0xFFD92B43); // --live
  static const Color liveTint = Color(0xFFFF7A8C); // --liveT
  static const Color danger = live;
  static const Color error = live;

  /// Verde positivo / disponible.
  static const Color positive = Color(0xFF9AD9B4); // --ok
  static const Color success = positive;

  /// Ámbar de advertencia / eventos.
  static const Color warning = Color(0xFFE6D28A); // --warn
  static const Color gold = Color(0xFFE6D28A);

  /// Azul informativo.
  static const Color info = Color(0xFF7DB0FF);

  /// Superficie clara alternativa.
  static const Color lightSurface2 = lightBg2;
  static const Color darkText1 = darkText;

  /// Gris azulado para texto secundario sobre superficies siempre oscuras.
  static const Color slate = Color(0xFF98A1B8);
  static const Color slate400 = Color(0xFFC9D0E2);
  static const Color slate200 = Color(0xFFEAEEF7);
  static const Color slate50 = Color(0xFFF3F5F9);

  /// Escala de superficies siempre oscuras (hero, reproductores).
  static const Color ink0 = Color(0xFF07090E);
  static const Color ink1 = Color(0xFF0A0D14);
  static const Color ink2 = Color(0xFF11151F);
  static const Color ink3 = Color(0xFF171C28);
}

