import 'package:flutter/material.dart';
import 'package:pivote/core/theme/app_theme.dart';

/// Design tokens for PivoPro — single source of truth for radii, spacing,
/// shadows and gradients so every screen speaks the same visual language.
///
/// Goal: stop re-declaring `BorderRadius.circular(20)` or ad-hoc
/// `LinearGradient(...)` blocks inside individual screens. Pull from here
/// instead, so a future tweak to "how rounded are our cards" only touches
/// one file.
class AppRadius {
  AppRadius._();

  static const double xs = 6; // inputs, chips
  static const double sm = 10; // base card radius (matches CardTheme)
  static const double md = 14; // buttons, small containers
  static const double lg = 20; // sections, banners
  static const double xl = 28; // hero containers, bottom sheets
  static const double xxl = 32; // headers (e.g. UnifiedHomeHeader)
  static const double pill = 999;

  static BorderRadius get sAll => BorderRadius.circular(sm);
  static BorderRadius get mAll => BorderRadius.circular(md);
  static BorderRadius get lAll => BorderRadius.circular(lg);
  static BorderRadius get xlAll => BorderRadius.circular(xl);

  static const BorderRadius topXl = BorderRadius.vertical(
    top: Radius.circular(xl),
  );
  static const BorderRadius bottomXxl = BorderRadius.vertical(
    bottom: Radius.circular(xxl),
  );
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  /// Standard horizontal screen padding used across Inicio/Fútbol/Películas.
  static const EdgeInsets screenH = EdgeInsets.symmetric(horizontal: lg);
}

class AppShadows {
  AppShadows._();

  /// Soft elevation for cards resting on the background. Intensity adapts
  /// to brightness automatically.
  static List<BoxShadow> card(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.06),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ];
  }

  /// Stronger elevation for floating elements (FABs, sticky headers, sheets).
  static List<BoxShadow> floating(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
        blurRadius: 24,
        offset: const Offset(0, 10),
      ),
    ];
  }

  /// Colored glow behind accent elements (live badges, primary CTAs).
  static List<BoxShadow> glow(Color color, {double alpha = 0.35}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: alpha),
        blurRadius: 20,
        spreadRadius: -4,
        offset: const Offset(0, 6),
      ),
    ];
  }

  /// Apple-style layered shadow (ambient diffuse + contact depth)
  static List<BoxShadow> appleDepth(BuildContext context, {double elevation = 1.0}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      // Ambient shadow
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.25 * elevation : 0.04 * elevation),
        blurRadius: 18 * elevation,
        spreadRadius: 0,
        offset: Offset(0, 4 * elevation),
      ),
      // Direct contact shadow
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.15 * elevation : 0.03 * elevation),
        blurRadius: 6 * elevation,
        spreadRadius: -2 * elevation,
        offset: Offset(0, 2 * elevation),
      ),
    ];
  }
}

class AppGradients {
  AppGradients._();

  /// Apple specular border highlight: top edge catches light, bottom softens.
  static LinearGradient specularBorder(bool isDark) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isDark
          ? [
              Colors.white.withValues(alpha: 0.16),
              Colors.white.withValues(alpha: 0.03),
            ]
          : [
              Colors.white.withValues(alpha: 0.70),
              Colors.black.withValues(alpha: 0.06),
            ],
    );
  }

  /// The deep violet-to-obsidian backdrop used by UnifiedHomeHeader.
  /// Reused here so Fútbol / Perfil headers can match it instead of
  /// inventing their own dark gradient each time.
  static LinearGradient backdrop(bool isDark) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isDark
          ? const [Color(0xFF0F0E1B), Color(0xFF07060F)]
          : const [Color(0xFFF8FAFC), Color(0xFFE8EEF5)],
    );
  }

  /// Accent-tinted glass panel — primary color fading into transparent.
  /// Used for banners, highlighted cards, CTA surfaces.
  static LinearGradient accentGlass(BuildContext context, {bool isDark = false}) {
    final scheme = Theme.of(context).colorScheme;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        scheme.primary.withValues(alpha: isDark ? 0.14 : 0.07),
        scheme.secondary.withValues(alpha: isDark ? 0.05 : 0.02),
      ],
    );
  }

  /// Diagonal sheen used on hero/featured cards to add depth without
  /// relying on an image.
  static const LinearGradient sheen = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Colors.white24, Colors.transparent],
  );

  /// Bottom-fade used over poster/banner images so titles stay legible.
  static LinearGradient posterFade(bool isDark) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.transparent,
        (isDark ? AppTheme.darkBg : Colors.black).withValues(alpha: 0.85),
      ],
      stops: const [0.4, 1.0],
    );
  }
}

/// Apple Material tokens (frosted glass, blur sigma, specular overlays)
class AppMaterials {
  AppMaterials._();

  static const double blurUltraThin = 10.0;
  static const double blurThin = 16.0;
  static const double blurRegular = 24.0;
  static const double blurHeavy = 32.0;

  static Color glassBg(BuildContext context, {double? alphaOverride}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final alpha = alphaOverride ?? (isDark ? 0.75 : 0.82);
    return (isDark ? AppTheme.darkBg1 : Colors.white).withValues(alpha: alpha);
  }
}

/// Convenience extension so call sites read naturally:
/// `Theme.of(context).isDark`
extension ThemeBrightnessX on ThemeData {
  bool get isDark => brightness == Brightness.dark;
}
