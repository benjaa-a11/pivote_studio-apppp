import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:pivote/core/theme/app_tokens.dart';

/// Apple-style frosted glass container.
///
/// Features:
/// - Real-time Gaussian blur with [ImageFilter.blur]
/// - Specular highlight border (subtle light reflection at top edge)
/// - Ambient + contact depth shadows
/// - Support for custom blur strength (ultraThin, thin, regular, heavy)
class AppleGlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final double blurSigma;
  final Color? backgroundColor;
  final double? backgroundOpacity;
  final Border? customBorder;
  final bool showSpecularBorder;
  final List<BoxShadow>? shadows;
  final Clip clipBehavior;

  const AppleGlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.blurSigma = AppMaterials.blurRegular,
    this.backgroundColor,
    this.backgroundOpacity,
    this.customBorder,
    this.showSpecularBorder = true,
    this.shadows,
    this.clipBehavior = Clip.antiAlias,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.isDark;
    final effectiveRadius = borderRadius ?? AppRadius.lAll;

    final effectiveBgColor = backgroundColor ??
        AppMaterials.glassBg(context, alphaOverride: backgroundOpacity);

    Widget glassCard = ClipRRect(
      borderRadius: effectiveRadius,
      clipBehavior: clipBehavior,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: effectiveBgColor,
            borderRadius: effectiveRadius,
            border: customBorder ??
                (showSpecularBorder
                    ? Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.10)
                            : Colors.white.withValues(alpha: 0.65),
                        width: 1.0,
                      )
                    : Border.all(
                        color: theme.colorScheme.outline
                            .withValues(alpha: isDark ? 0.12 : 0.08),
                        width: 1.0,
                      )),
          ),
          child: child,
        ),
      ),
    );

    if (shadows != null || margin != null) {
      return Container(
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: effectiveRadius,
          boxShadow: shadows ?? AppShadows.appleDepth(context, elevation: 0.8),
        ),
        child: glassCard,
      );
    }

    return glassCard;
  }
}
