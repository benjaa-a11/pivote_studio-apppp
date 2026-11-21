import 'package:flutter/material.dart';

/// Paleta base de Pivote — ÚNICA fuente de verdad cromática.
///
/// Regla estricta de 3 colores por tema:
///  1. **Neutros** (Obsidiana en Oscuro / Porcelana en Claro): fondo, tarjetas,
///     divisores, textos y superficies translúcidas.
///  2. **Acento de marca** (Lima Eléctrico `#C8FF47` en Oscuro / Lima Profundo
///     `#4D7C0F` en Claro): acciones primarias, estados activos, selecciones y
///     difuminaciones ambientales.
///  3. **Señal / En vivo** (Carmesí `#FF4D5E` en Oscuro / `#E11D48` en Claro):
///     indicadores EN VIVO, favoritos, alertas y acciones destructivas.
///
/// Las pantallas nunca declaran `Color(0xFF...)` arbitrarios: consumen
/// exclusivamente `AppTheme.*`, `Theme.of(context)` o los tokens de esta clase.
class AppColors {
  AppColors._();

  // ── 1. Neutros — Modo Oscuro (Obsidiana cinematográfica) ──────────────────
  static const Color darkBg = Color(0xFF0A0C10); // Fondo profundo principal
  static const Color darkBg1 = Color(0xFF11141C); // Superficie nivel 1 (cards)
  static const Color darkBg2 = Color(0xFF171B26); // Superficie nivel 2 (inputs/tiles)
  static const Color darkBg3 = Color(0xFF1F2433); // Superficie nivel 3 (elevado/pressed)
  static const Color darkBg4 = Color(0xFF282F42); // Tracks / controles inactivos
  static const Color darkBorder = Color(0x15FFFFFF); // Hairline 1px sutil (~8%)
  static const Color darkBorder2 = Color(0x24FFFFFF); // Borde enfatizado (~14%)
  static const Color darkText = Color(0xFFF2F4F8); // Texto principal
  static const Color darkText2 = Color(0xFFB4BDCB); // Texto secundario
  static const Color darkText3 = Color(0xFF7B8498); // Texto terciario / silenciado

  // ── 1. Neutros — Modo Claro (Porcelana de estudio) ────────────────────────
  static const Color lightBg = Color(0xFFF4F6FA); // Fondo suave frío
  static const Color lightBg1 = Color(0xFFFFFFFF); // Superficie blanca elevada
  static const Color lightBg2 = Color(0xFFECEFF6); // Superficie anidada / inputs
  static const Color lightBg3 = Color(0xFFE1E6F0); // Superficie presionada
  static const Color lightBg4 = Color(0xFFCED6E4); // Tracks / controles inactivos
  static const Color lightBorder = Color(0xFFDFE4EE); // Hairline 1px sutil
  static const Color lightBorder2 = Color(0xFFC8D0DF); // Borde enfatizado
  static const Color lightText = Color(0xFF0B0D12); // Texto principal
  static const Color lightText2 = Color(0xFF475467); // Texto secundario
  static const Color lightText3 = Color(0xFF7B8598); // Texto terciario / silenciado

  // ── 2. Acento de marca (Lima Eléctrico / Lima Botánico) ───────────────────
  static const Color darkAccent = Color(0xFFC8FF47);
  static const Color lightAccent = Color(0xFF4D7C0F);
  static const Color onDarkAccent = Color(0xFF0A0C10);
  static const Color onLightAccent = Color(0xFFFFFFFF);

  /// Variantes tonales del acento (misma familia cromática, sin colores extra).
  static const Color accent = darkAccent;
  static const Color accentStrong = Color(0xFFB3EB30);
  static const Color accentTint = Color(0xFFDCFF85);
  static const Color lightAccentTint = Color(0xFF65A30D);
  static const Color accentBg = Color(0x1FC8FF47);

  /// Alias históricos mapeados estrictamente al acento de marca.
  static const Color violet = accentStrong;
  static const Color secondary = darkAccent;

  // ── 3. Señal / En vivo / Destructivo (Carmesí) ────────────────────────────
  static const Color darkDanger = Color(0xFFFF4D5E);
  static const Color lightDanger = Color(0xFFE11D48);

  // Estados semánticos unificados dentro de la paleta de 3 colores
  // (Éxito/Info derivan del acento; advertencias usan ámbar sobrio solo en
  // tarjetas deportivas o avisos puntuales).
  static const Color darkSuccess = Color(0xFFC8FF47);
  static const Color lightSuccess = Color(0xFF4D7C0F);
  static const Color darkInfo = Color(0xFFDCFF85);
  static const Color lightInfo = Color(0xFF4D7C0F);
  static const Color darkWarning = Color(0xFFFFC247);
  static const Color lightWarning = Color(0xFFB45309);

  // ── Superficies Glassmorphic / Difuminadas ────────────────────────────────
  static const Color glass = Color(0x0BFFFFFF);
  static const Color glass2 = Color(0x14FFFFFF);
  static const Color glassBorder = Color(0x17FFFFFF);
  static const Color glassBorderSubtle = Color(0x12FFFFFF);
  static const Color glassPanel = Color(0xD80E1118);
  static const Color lightGlassPanel = Color(0xEBFFFFFF);

  // ── Constantes agnósticas (compatibilidad con MatchesHero & reproductores) ─
  static const Color live = Color(0xFFFF4D5E);
  static const Color liveTint = Color(0xFFFF8591);
  static const Color danger = live;
  static const Color error = live;

  static const Color positive = darkSuccess;
  static const Color success = darkSuccess;

  static const Color warning = darkWarning;
  static const Color gold = darkAccent;

  static const Color info = darkInfo;

  static const Color lightSurface2 = lightBg2;
  static const Color darkText1 = darkText;

  static const Color slate = Color(0xFF7B8498);
  static const Color slate400 = Color(0xFFB4BDCB);
  static const Color slate200 = Color(0xFFF2F4F8);
  static const Color slate50 = Color(0xFFF4F6FA);

  static const Color ink0 = Color(0xFF07090D);
  static const Color ink1 = Color(0xFF0B0D12);
  static const Color ink2 = Color(0xFF11141C);
  static const Color ink3 = Color(0xFF171B26);
}
