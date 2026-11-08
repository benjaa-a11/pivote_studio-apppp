import 'package:flutter/material.dart';
import 'package:pivote/core/theme/app_colors.dart';

/// Tokens de diseño de Pivote — única fuente de verdad para radios, espaciados,
/// bordes, sombras, gradientes, materiales y grillas adaptativas.
class AppRadius {
  AppRadius._();

  static const double xxs = 6; // micro-badges
  static const double xs = 8; // controles compactos, badges en vivo
  static const double sm = 12; // botones secundarios, chips, inputs compactos
  static const double md = 16; // inputs estándar, tarjetas compactas, diálogos
  static const double card = 18; // referencia: ChannelCard
  static const double lg = 22; // contenedores destacados, tarjetas grandes
  static const double hero = 24; // referencia: MatchCard / MatchesHero
  static const double sheet = 24; // referencia: bottom sheets
  static const double xl = 28; // bottom sheets, contenedores modales
  static const double xxl = 32; // headers principales
  static const double pill = 999;

  static BorderRadius get xsAll => BorderRadius.circular(xs);
  static BorderRadius get sAll => BorderRadius.circular(sm);
  static BorderRadius get mAll => BorderRadius.circular(md);
  static BorderRadius get cardAll => BorderRadius.circular(card);
  static BorderRadius get lAll => BorderRadius.circular(lg);
  static BorderRadius get heroAll => BorderRadius.circular(hero);
  static BorderRadius get sheetAll => const BorderRadius.vertical(top: Radius.circular(sheet));
  static BorderRadius get xlAll => BorderRadius.circular(xl);
  static BorderRadius get pillAll => BorderRadius.circular(pill);

  static const BorderRadius topXl = BorderRadius.vertical(
    top: Radius.circular(xl),
  );
  static const BorderRadius bottomXxl = BorderRadius.vertical(
    bottom: Radius.circular(xxl),
  );
}

class AppSpacing {
  AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double section = 28;

  /// Padding horizontal estándar para pantallas.
  static const EdgeInsets screenH = EdgeInsets.symmetric(horizontal: lg);

  /// Padding de tarjeta estándar.
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
}

class AppBorders {
  AppBorders._();

  /// Borde estándar para tarjetas y contenedores (inspirado en ChannelCard).
  static Border card(BuildContext context, {bool highlighted = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (highlighted) {
      final accent =
          isDark ? AppColors.darkAccent : AppColors.lightAccent;
      return Border.all(
        color: accent.withValues(alpha: isDark ? 0.55 : 0.45),
        width: 1.3,
      );
    }
    return Border.all(
      color: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : AppColors.lightBorder,
      width: 1.0,
    );
  }

  /// Borde sutil para contenedores secundarios y chips inactivos.
  static Border subtle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Border.all(
      color: isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.black.withValues(alpha: 0.06),
      width: 1.0,
    );
  }

  /// Color de divisor consistente en ambos modos.
  static Color dividerColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? Colors.white.withValues(alpha: 0.07)
        : AppColors.lightBorder;
  }
}

class AppShadows {
  AppShadows._();

  /// Elevación suave para tarjetas (misma firma visual que ChannelCard).
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

  /// Elevación para elementos flotantes (barra inferior, modales, headers).
  static List<BoxShadow> floating(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.42 : 0.12),
        blurRadius: 24,
        offset: const Offset(0, 10),
      ),
    ];
  }

  /// Resplandor cromático controlado para acentos o indicadores en vivo.
  static List<BoxShadow> glow(Color color, {double alpha = 0.30}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: alpha),
        blurRadius: 18,
        spreadRadius: -3,
        offset: const Offset(0, 6),
      ),
    ];
  }

  /// Sombra multicapa con profundidad natural (estilo ChannelCard).
  static List<BoxShadow> appleDepth(
    BuildContext context, {
    double elevation = 1.0,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: Colors.black
            .withValues(alpha: isDark ? 0.25 * elevation : 0.045 * elevation),
        blurRadius: 18 * elevation,
        spreadRadius: 0,
        offset: Offset(0, 4 * elevation),
      ),
      BoxShadow(
        color: Colors.black
            .withValues(alpha: isDark ? 0.14 * elevation : 0.025 * elevation),
        blurRadius: 6 * elevation,
        spreadRadius: -2 * elevation,
        offset: Offset(0, 2 * elevation),
      ),
    ];
  }
}

class AppGradients {
  AppGradients._();

  /// Borde especular sutil.
  static LinearGradient specularBorder(bool isDark) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isDark
          ? [
              Colors.white.withValues(alpha: 0.14),
              Colors.white.withValues(alpha: 0.03),
            ]
          : [
              Colors.white.withValues(alpha: 0.75),
              Colors.black.withValues(alpha: 0.06),
            ],
    );
  }

  /// Fondo de cabeceras principales unificado en ambos temas.
  static LinearGradient backdrop(bool isDark) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isDark
          ? const [AppColors.darkBg2, AppColors.darkBg]
          : const [AppColors.lightBg1, AppColors.lightBg],
    );
  }

  /// Superficie de tarjeta con ligera profundidad vertical.
  static LinearGradient cardSurface(bool isDark) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? const [AppColors.darkBg2, AppColors.darkBg1]
          : const [AppColors.lightBg1, AppColors.lightBg2],
    );
  }

  /// Panel translúcido con tinte de acento.
  static LinearGradient accentGlass(
    BuildContext context, {
    bool isDark = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        scheme.primary.withValues(alpha: isDark ? 0.14 : 0.08),
        scheme.secondary.withValues(alpha: isDark ? 0.05 : 0.02),
      ],
    );
  }

  static const LinearGradient sheen = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Colors.white24, Colors.transparent],
  );

  /// Degradado inferior para pósters y banners.
  static LinearGradient posterFade(bool isDark) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.transparent,
        (isDark ? AppColors.darkBg : Colors.black).withValues(alpha: 0.86),
      ],
      stops: const [0.38, 1.0],
    );
  }
}

/// Tokens de cristal esmerilado y superficies translúcidas.
class AppMaterials {
  AppMaterials._();

  static const double blurUltraThin = 10.0;
  static const double blurThin = 16.0;
  static const double blurRegular = 24.0;
  static const double blurHeavy = 32.0;

  static Color glassBg(BuildContext context, {double? alphaOverride}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final alpha = alphaOverride ?? (isDark ? 0.78 : 0.86);
    return (isDark ? AppColors.darkBg1 : AppColors.lightBg1)
        .withValues(alpha: alpha);
  }
}

/// Sistema de diseño adaptable (Responsive) para teléfonos compactos,
/// teléfonos grandes, orientación horizontal y tablets.
class AppResponsive {
  AppResponsive._();

  static double widthOf(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static bool isCompact(BuildContext context) => widthOf(context) < 600;
  static bool isMedium(BuildContext context) {
    final w = widthOf(context);
    return w >= 600 && w < 900;
  }

  static bool isExpanded(BuildContext context) => widthOf(context) >= 900;

  static bool isLandscape(BuildContext context) =>
      MediaQuery.orientationOf(context) == Orientation.landscape;

  /// Padding horizontal adaptativo para pantallas.
  static EdgeInsets screenHorizontalPadding(BuildContext context) {
    final w = widthOf(context);
    if (w >= 900) return const EdgeInsets.symmetric(horizontal: 28);
    if (w >= 600) return const EdgeInsets.symmetric(horizontal: 20);
    return const EdgeInsets.symmetric(horizontal: 16);
  }

  /// Valor numérico double del padding horizontal adaptativo.
  static double horizontalPadding(BuildContext context) {
    final w = widthOf(context);
    if (w >= 900) return 28.0;
    if (w >= 600) return 20.0;
    return 16.0;
  }

  /// Ancho óptimo para las tarjetas del Matches Hero según el tamaño de pantalla.
  static double heroCardWidth(BuildContext context) {
    final w = widthOf(context);
    if (w >= 900) return 390.0;
    if (w >= 600) return 360.0;
    return (w * 0.88).clamp(296.0, 400.0);
  }

  /// Número de columnas para grillas de canales y radios.
  static int channelColumns(BuildContext context) {
    final w = widthOf(context);
    if (w >= 1100) return 5;
    if (w >= 840) return 4;
    if (w >= 560) return 3;
    return 2;
  }

  /// Grilla adaptativa para tarjetas de canales y emisoras de radio.
  static SliverGridDelegateWithFixedCrossAxisCount channelGridDelegate(
    BuildContext context, {
    double aspectRatio = 1.28,
    double spacing = 12,
  }) {
    final cols = channelColumns(context);
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: cols,
      childAspectRatio: aspectRatio,
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
    );
  }

  /// Número de columnas para pósters de películas.
  static int posterColumns(BuildContext context) {
    final w = widthOf(context);
    if (w >= 1100) return 6;
    if (w >= 840) return 5;
    if (w >= 600) return 4;
    if (w >= 430) return 3;
    return 2;
  }

  /// Grilla adaptativa para tarjetas verticales de películas.
  static SliverGridDelegateWithFixedCrossAxisCount posterGridDelegate(
    BuildContext context, {
    double aspectRatio = 0.64,
    double spacing = 14,
  }) {
    final cols = posterColumns(context);
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: cols,
      childAspectRatio: aspectRatio,
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
    );
  }
}

class AppMotion {
  AppMotion._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 350);

  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeInOut = Curves.easeInOutCubic;
  static const Curve curveOut = Curves.easeOutCubic;
  static const Curve springSnappy = Curves.easeOutCubic;
  static const Curve springBouncy = Curves.easeOutBack;
}

extension ThemeBrightnessX on ThemeData {
  bool get isDark => brightness == Brightness.dark;
}
