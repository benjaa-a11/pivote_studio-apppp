import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/shared/widgets/common/apple_pressable.dart';

/// Fondo ambiental con difuminación radial inspirada en `MatchesHero`.
///
/// Aplica un halo de luz ultra sutil en la esquina superior derecha y una
/// contra-difuminación discreta en la zona inferior izquierda, unificando la
/// atmósfera de todas las pantallas en modo claro y modo oscuro sin ruido visual.
class PivoteAmbientBackdrop extends StatelessWidget {
  final Widget child;
  final Color? accentColor;
  final double intensity;

  const PivoteAmbientBackdrop({
    super.key,
    required this.child,
    this.accentColor,
    this.intensity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final accent = accentColor ?? AppTheme.accent(context);
    final bg = AppTheme.bg(context);

    final primaryAlpha = (isDark ? 0.11 : 0.075) * intensity;
    final secondaryAlpha = (isDark ? 0.05 : 0.04) * intensity;

    return ColoredBox(
      color: bg,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Halo radial superior derecho (identidad de marca)
          Positioned(
            top: -130,
            right: -95,
            child: IgnorePointer(
              child: Container(
                width: 340,
                height: 340,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      accent.withValues(alpha: primaryAlpha.clamp(0.0, 0.35)),
                      accent.withValues(alpha: 0.0),
                    ],
                    stops: const [0.0, 0.72],
                  ),
                ),
              ),
            ),
          ),
          // Halo sutil inferior izquierdo para profundidad equilibrada
          Positioned(
            bottom: -140,
            left: -110,
            child: IgnorePointer(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      accent.withValues(alpha: secondaryAlpha.clamp(0.0, 0.25)),
                      accent.withValues(alpha: 0.0),
                    ],
                    stops: const [0.0, 0.75],
                  ),
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// Tarjeta insignia de Pivote inspirada directamente en la estética de
/// difuminación radial del `MatchesHero` (`MatchCard`).
///
/// Combina:
/// - Superficie limpia adaptativa al tema (`darkBg1` / `lightBg1`)
/// - Borde hairline de 1px con acento opcional
/// - Difuminación radial suave (1 o 2 focos cromáticos)
/// - Elevación natural + respuesta táctil opcional con `ApplePressable`
class PivoteDiffusedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? glowColor;
  final Color? secondaryGlowColor;
  final Alignment glowAlignment;
  final Alignment secondaryGlowAlignment;
  final double glowRadius;
  final double glowOpacity;
  final bool highlighted;
  final Color? borderColor;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final bool showGlow;

  const PivoteDiffusedCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = AppRadius.lg,
    this.glowColor,
    this.secondaryGlowColor,
    this.glowAlignment = const Alignment(-0.85, -0.75),
    this.secondaryGlowAlignment = const Alignment(0.85, 0.75),
    this.glowRadius = 1.05,
    this.glowOpacity = 1.0,
    this.highlighted = false,
    this.borderColor,
    this.backgroundColor,
    this.onTap,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final accent = AppTheme.accent(context);
    final effectiveGlow = glowColor ?? accent;
    final radius = BorderRadius.circular(borderRadius);

    final baseAlpha = (isDark ? 0.14 : 0.08) * glowOpacity;
    final secondAlpha = (isDark ? 0.12 : 0.07) * glowOpacity;

    final effectiveBorderColor = borderColor ??
        (highlighted
            ? effectiveGlow.withValues(alpha: isDark ? 0.45 : 0.36)
            : AppTheme.border(context));

    Widget card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.surface1(context),
        borderRadius: radius,
        border: Border.all(
          color: effectiveBorderColor,
          width: highlighted ? 1.3 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: highlighted
                ? effectiveGlow.withValues(alpha: isDark ? 0.16 : 0.10)
                : Colors.black.withValues(alpha: isDark ? 0.34 : 0.055),
            blurRadius: highlighted ? 22 : 16,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius - 0.5),
        child: Stack(
          children: [
            if (showGlow)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: glowAlignment,
                        radius: glowRadius,
                        colors: [
                          effectiveGlow.withValues(
                            alpha: baseAlpha.clamp(0.0, 0.36),
                          ),
                          effectiveGlow.withValues(alpha: 0.0),
                        ],
                        stops: const [0.0, 0.74],
                      ),
                    ),
                  ),
                ),
              ),
            if (showGlow && secondaryGlowColor != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: secondaryGlowAlignment,
                        radius: glowRadius,
                        colors: [
                          secondaryGlowColor!.withValues(
                            alpha: secondAlpha.clamp(0.0, 0.36),
                          ),
                          secondaryGlowColor!.withValues(alpha: 0.0),
                        ],
                        stops: const [0.0, 0.74],
                      ),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: padding ?? EdgeInsets.zero,
              child: child,
            ),
          ],
        ),
      ),
    );

    if (onTap != null) {
      return ApplePressable(
        scaleDownFactor: 0.975,
        borderRadius: radius,
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }
}

/// Superficie de cristal esmerilado con difuminación ambiental para paneles
/// flotantes, barras de control, bottom sheets y encabezados translúcidos.
class PivoteGlassSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final double blurSigma;
  final Color? tintColor;
  final double? opacity;
  final Color? glowColor;
  final bool showBorder;

  const PivoteGlassSurface({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.blurSigma = AppMaterials.blurRegular,
    this.tintColor,
    this.opacity,
    this.glowColor,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final radius = borderRadius ?? BorderRadius.circular(AppRadius.xl);
    final baseColor = tintColor ?? AppTheme.surface1(context);
    final alpha = opacity ?? (isDark ? 0.86 : 0.92);
    final glow = glowColor ?? AppTheme.accent(context);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.50 : 0.10),
            blurRadius: 28,
            spreadRadius: -6,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            decoration: BoxDecoration(
              color: baseColor.withValues(alpha: alpha),
              borderRadius: radius,
              border: showBorder
                  ? Border.all(
                      color: isDark
                          ? AppColors.darkBorder2
                          : AppColors.lightBorder,
                      width: 1.0,
                    )
                  : null,
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0.0, -1.1),
                          radius: 1.15,
                          colors: [
                            glow.withValues(alpha: isDark ? 0.10 : 0.06),
                            glow.withValues(alpha: 0.0),
                          ],
                          stops: const [0.0, 0.72],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: padding ?? EdgeInsets.zero,
                  child: child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Encabezado de sección unificado en toda la app (misma identidad exacta
/// que el encabezado de `MatchesHero`: barra vertical con brillo + título +
/// contador opcional + acción derecha opcional).
class PivoteSectionHeader extends StatelessWidget {
  final String title;
  final String? badgeText;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final Widget? trailing;
  final bool isLive;
  final EdgeInsetsGeometry padding;

  const PivoteSectionHeader({
    super.key,
    required this.title,
    this.badgeText,
    this.actionLabel,
    this.onActionTap,
    this.trailing,
    this.isLive = false,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final accent = isLive ? AppTheme.danger(context) : AppTheme.accent(context);

    return Padding(
      padding: padding,
      child: Row(
        children: [
          Container(
            width: 3.5,
            height: 18,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                if (isDark || isLive)
                  BoxShadow(
                    color: accent.withValues(alpha: 0.42),
                    blurRadius: 8,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFont.primary(
                      fontSize: 17.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.35,
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                ),
                if (badgeText != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2.5,
                    ),
                    decoration: BoxDecoration(
                      color: isLive
                          ? AppTheme.dangerDim(context)
                          : AppTheme.surface2(context),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: isLive
                            ? accent.withValues(alpha: 0.30)
                            : AppTheme.border(context),
                      ),
                    ),
                    child: Text(
                      badgeText!,
                      style: AppFont.mono(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: isLive ? accent : AppTheme.textTertiary(context),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null)
            trailing!
          else if (actionLabel != null && onActionTap != null)
            ApplePressable(
              scaleDownFactor: 0.94,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              onTap: onActionTap,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.surface2(context),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: AppTheme.border(context)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionLabel!,
                      style: AppFont.primary(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.accent(context),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 15,
                      color: AppTheme.accent(context),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Botón de icono cuadrado-redondeado unificado (42x42) para cabeceras y acciones.
class PivoteIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final double iconSize;
  final bool active;
  final bool danger;
  final String? tooltip;
  final String? heroTag;

  const PivoteIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 42,
    this.iconSize = 20,
    this.active = false,
    this.danger = false,
    this.tooltip,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final accent = danger ? AppTheme.danger(context) : AppTheme.accent(context);
    final bg = danger
        ? AppTheme.dangerDim(context)
        : active
            ? AppTheme.accentDim(context)
            : AppTheme.surface1(context);
    final borderCol = danger
        ? accent.withValues(alpha: 0.35)
        : active
            ? accent.withValues(alpha: 0.45)
            : AppTheme.border(context);
    final iconCol = danger
        ? accent
        : active
            ? accent
            : AppTheme.textPrimary(context);

    Widget iconWidget = Icon(icon, size: iconSize, color: iconCol);
    if (heroTag != null) {
      iconWidget = Hero(tag: heroTag!, child: iconWidget);
    }

    final btn = ApplePressable(
      scaleDownFactor: 0.92,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: borderCol, width: 1.0),
          boxShadow: AppShadows.card(context),
        ),
        alignment: Alignment.center,
        child: iconWidget,
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: btn);
    }
    return btn;
  }
}

/// Píldora de filtro/categoría unificada para Home, Search, Radio y Fútbol.
class PivoteFilterPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;
  final int? count;
  final bool liveIcon;

  const PivoteFilterPill({
    super.key,
    required this.label,
    this.icon,
    required this.selected,
    required this.onTap,
    this.count,
    this.liveIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final accent = AppTheme.accent(context);
    final onAccent = AppTheme.onAccent(context);

    return ApplePressable(
      scaleDownFactor: 0.95,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? accent : AppTheme.surface1(context),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: selected ? accent : AppTheme.border(context),
            width: 1.0,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: isDark ? 0.22 : 0.16),
                    blurRadius: 14,
                    spreadRadius: -3,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14.5,
                color: selected
                    ? onAccent
                    : (liveIcon
                        ? AppTheme.danger(context)
                        : AppTheme.textTertiary(context)),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppFont.primary(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                letterSpacing: -0.15,
                color: selected ? onAccent : AppTheme.textSecondary(context),
              ),
            ),
            if (count != null && count! > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: selected
                      ? onAccent.withValues(alpha: 0.15)
                      : AppTheme.surface2(context),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '$count',
                  style: AppFont.mono(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: selected ? onAccent : AppTheme.textTertiary(context),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Control segmentado moderno (estilo Apple/Linear) con indicador sólido en acento.
class PivoteSegmentedBar extends StatelessWidget {
  final List<PivoteSegmentItem> items;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const PivoteSegmentedBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.accent(context);
    final onAccent = AppTheme.onAccent(context);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surface1(context),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          final item = items[i];
          final selected = i == selectedIndex;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(i);
              },
              child: AnimatedContainer(
                duration: AppMotion.fast,
                curve: Curves.easeOutCubic,
                padding:
                    const EdgeInsets.symmetric(vertical: 9.5, horizontal: 6),
                decoration: BoxDecoration(
                  color: selected ? accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item.icon != null) ...[
                      Icon(
                        item.icon,
                        size: 13.5,
                        color: selected
                            ? onAccent
                            : AppTheme.textTertiary(context),
                      ),
                      const SizedBox(width: 5),
                    ],
                    Flexible(
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFont.primary(
                          fontSize: 12.8,
                          fontWeight:
                              selected ? FontWeight.w800 : FontWeight.w600,
                          color: selected
                              ? onAccent
                              : AppTheme.textSecondary(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class PivoteSegmentItem {
  final String label;
  final IconData? icon;

  const PivoteSegmentItem({required this.label, this.icon});
}

/// Encabezado estándar para pantallas secundarias empujadas en el stack.
class PivoteSubHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final Widget? trailing;
  final bool showBackButton;

  const PivoteSubHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.trailing,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 16),
      child: Row(
        children: [
          if (showBackButton)
            PivoteIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              iconSize: 17,
              onTap: onBack ?? () => Navigator.of(context).maybePop(),
            )
          else
            const SizedBox(width: 42, height: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFont.primary(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: AppTheme.textPrimary(context),
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFont.primary(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textTertiary(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing ?? const SizedBox(width: 42, height: 42),
        ],
      ),
    );
  }
}

/// Encabezado estándar para el interior de un Bottom Sheet (`AppDialogs.showModal`).
class PivoteSheetHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool isDanger;
  final Widget? trailing;

  const PivoteSheetHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.isDanger = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final accent =
        isDanger ? AppTheme.danger(context) : AppTheme.accent(context);
    final badgeBg =
        isDanger ? AppTheme.dangerDim(context) : AppTheme.accentDim(context);

    return Row(
      children: [
        if (icon != null) ...[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: accent.withValues(alpha: 0.28)),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: accent),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFont.primary(
                  fontSize: 18.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.35,
                  color: AppTheme.textPrimary(context),
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppFont.primary(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textTertiary(context),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
