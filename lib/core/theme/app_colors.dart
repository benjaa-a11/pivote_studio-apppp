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

  // ── Neutros modo oscuro (CSS: --bg: #0B0D12, --bg2: #12151D, --glass, --line) ─
  static const Color darkBg = Color(0xFF0B0D12); // --bg: Fondo profundo
  static const Color darkBg1 = Color(0xFF12151D); // --bg2: Superficie nivel 1
  static const Color darkBg2 = Color(0xFF161A24); // Superficie nivel 2 (tarjetas)
  static const Color darkBg3 = Color(0xFF1C212E); // Superficie nivel 3 (elevado)
  static const Color darkBg4 = Color(0xFF232938); // Presionado / track
  static const Color darkBorder = Color(0x17FFFFFF); // --line: rgba(255,255,255,.09)
  static const Color darkBorder2 = Color(0x26FFFFFF); // Borde enfatizado
  static const Color darkText = Color(0xFFEEF1F6); // --tx: Texto principal
  static const Color darkText2 = Color(0xFFC8D0DC); // Texto secundario
  static const Color darkText3 = Color(0xFF8A93A6); // --mut: Texto terciario / silenciado

  // ── Neutros modo claro ───────────────────────────────────────────────────
  static const Color lightBg = Color(0xFFF3F5F9);
  static const Color lightBg1 = Color(0xFFFFFFFF);
  static const Color lightBg2 = Color(0xFFEAEEF5);
  static const Color lightBg3 = Color(0xFFDEE4EE);
  static const Color lightBg4 = Color(0xFFCED6E2);
  static const Color lightBorder = Color(0xFFD6DCE6);
  static const Color lightBorder2 = Color(0xFFBFC7D5);
  static const Color lightText = Color(0xFF0B0D12);
  static const Color lightText2 = Color(0xFF4A5568);
  static const Color lightText3 = Color(0xFF718096);

  // ── Acento de marca (CSS: --lime: #C8FF47) ──────────────────────────────────
  static const Color darkAccent = Color(0xFFC8FF47); // --lime: Lima eléctrico
  static const Color lightAccent = Color(0xFF4D7C0F);
  static const Color onDarkAccent = Color(0xFF0B0D12);
  static const Color onLightAccent = Color(0xFFFFFFFF);

  /// Alias de acento principal.
  static const Color accent = darkAccent;
  static const Color accentStrong = Color(0xFFB3EB30);
  static const Color accentTint = Color(0xFFD9FF7A);
  static const Color accentBg = Color(0x1FC8FF47); // rgba(200,255,71,.12)

  /// Tono secundario complementario de marca.
  static const Color violet = Color(0xFFB3EB30);
  static const Color secondary = violet;

  // ── Semánticos (CSS: --red: #FF4D5E, --amber: #FFC247, --win: #35D07F) ──────
  static const Color darkDanger = Color(0xFFFF4D5E); // --red: Rojo en vivo
  static const Color darkWarning = Color(0xFFFFC247); // --amber: Ámbar / advertencia
  static const Color darkSuccess = Color(0xFF35D07F); // --win: Verde victoria
  static const Color darkInfo = Color(0xFFD9FF7A);

  static const Color lightDanger = Color(0xFFD92B43);
  static const Color lightWarning = Color(0xFFB58000);
  static const Color lightSuccess = Color(0xFF1E8752);
  static const Color lightInfo = Color(0xFF3F6B0C);

  // ── Tokens Glassmorphic (CSS: --glass: rgba(255,255,255,.045), --line) ──────
  static const Color glass = Color(0x0BFFFFFF); // --glass: rgba(255,255,255,.045)
  static const Color glass2 = Color(0x14FFFFFF); // --glass2: rgba(255,255,255,.08)
  static const Color glassBorder = Color(0x17FFFFFF); // --line: rgba(255,255,255,.09)
  static const Color glassBorderSubtle = Color(0x12FFFFFF);
  static const Color glassPanel = Color(0xD10E1118); // rgba(14,17,24,.82)

  // ── Constantes agnósticas al tema (superficies audiovisuales oscuras) ───────
  /// Rojo "EN VIVO" y errores.
  static const Color live = Color(0xFFFF4D5E); // --red
  static const Color liveTint = Color(0xFFFF8591);
  static const Color danger = live;
  static const Color error = live;

  /// Verde positivo / disponible.
  static const Color positive = Color(0xFF35D07F); // --win
  static const Color success = positive;

  /// Ámbar de advertencia / eventos.
  static const Color warning = Color(0xFFFFC247); // --amber
  static const Color gold = Color(0xFFFFC247);

  /// Azul informativo.
  static const Color info = Color(0xFFD9FF7A);

  /// Superficie clara alternativa.
  static const Color lightSurface2 = lightBg2;
  static const Color darkText1 = darkText;

  /// Gris azulado para texto secundario sobre superficies siempre oscuras.
  static const Color slate = Color(0xFF8A93A6);
  static const Color slate400 = Color(0xFFC8D0DC);
  static const Color slate200 = Color(0xFFEEF1F6);
  static const Color slate50 = Color(0xFFF3F5F9);

  /// Escala de superficies siempre oscuras (hero, reproductores).
  static const Color ink0 = Color(0xFF07090D);
  static const Color ink1 = Color(0xFF0B0D12);
  static const Color ink2 = Color(0xFF12151D);
  static const Color ink3 = Color(0xFF161A24);
}

