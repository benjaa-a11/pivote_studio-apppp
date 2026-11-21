import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/core/theme/theme_provider.dart';
import 'package:pivote/shared/widgets/common/apple_pressable.dart';
import 'package:pivote/shared/widgets/common/pivote_loader.dart';
import 'package:pivote/shared/widgets/common/pivote_surfaces.dart';

/// Adaptador delgado conectado directamente a `AppTheme` (paleta estricta de 3 colores).
class ProfilePalette {
  final bool isDark;
  final Color bg;
  final Color card;
  final Color cardPressed;
  final Color border;
  final Color iconBox;
  final Color text;
  final Color muted;
  final Color chevron;
  final Color switchOff;
  final Color switchOn;
  final Color switchThumbOn;
  final Color accent;
  final Color primaryBtnBg;
  final Color primaryBtnText;
  final Color danger;
  final Color dangerBg;
  final Color dangerBorder;
  final Color avatarPlaceholderBg;
  final List<BoxShadow> cardShadow;

  const ProfilePalette({
    required this.isDark,
    required this.bg,
    required this.card,
    required this.cardPressed,
    required this.border,
    required this.iconBox,
    required this.text,
    required this.muted,
    required this.chevron,
    required this.switchOff,
    required this.switchOn,
    required this.switchThumbOn,
    required this.accent,
    required this.primaryBtnBg,
    required this.primaryBtnText,
    required this.danger,
    required this.dangerBg,
    required this.dangerBorder,
    required this.avatarPlaceholderBg,
    required this.cardShadow,
  });

  factory ProfilePalette.of(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final accent = AppTheme.accent(context);
    final onAccent = AppTheme.onAccent(context);
    final danger = AppTheme.danger(context);

    return ProfilePalette(
      isDark: isDark,
      bg: AppTheme.bg(context),
      card: AppTheme.surface1(context),
      cardPressed: AppTheme.surface2(context),
      border: AppTheme.border(context),
      iconBox: AppTheme.surface2(context),
      text: AppTheme.textPrimary(context),
      muted: AppTheme.textSecondary(context),
      chevron: AppTheme.textTertiary(context),
      switchOff: AppTheme.surface4(context),
      switchOn: accent,
      switchThumbOn: onAccent,
      accent: accent,
      primaryBtnBg: accent,
      primaryBtnText: onAccent,
      danger: danger,
      dangerBg: AppTheme.dangerDim(context),
      dangerBorder: danger.withValues(alpha: isDark ? 0.35 : 0.28),
      avatarPlaceholderBg: AppTheme.surface3(context),
      cardShadow: AppShadows.card(context),
    );
  }
}

/// Iconos vectoriales del sistema de perfil y ajustes.
class ProfileSvgIcons {
  static const String crown =
      '<svg viewBox="0 0 24 24"><path d="M3 8l4.5 4L12 5l4.5 7L21 8l-2 11H5L3 8z"/></svg>';

  static const String appearance =
      '<svg viewBox="0 0 24 24"><path d="M20 14.5A8 8 0 0 1 9.5 4 8 8 0 1 0 20 14.5z" fill="none" stroke="#000" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>';

  static const String notifications =
      '<svg viewBox="0 0 24 24"><path d="M6 9a6 6 0 0 1 12 0c0 6 2 7 2 7H4s2-1 2-7M10 20a2 2 0 0 0 4 0" fill="none" stroke="#000" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>';

  static const String storage =
      '<svg viewBox="0 0 24 24"><ellipse cx="12" cy="6" rx="8" ry="3" fill="none" stroke="#000" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/><path d="M4 6v6c0 1.7 3.6 3 8 3s8-1.3 8-3V6M4 12v6c0 1.7 3.6 3 8 3s8-1.3 8-3v-6" fill="none" stroke="#000" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>';

  static const String diagnostics =
      '<svg viewBox="0 0 24 24"><path d="M3 12h4l3-7 4 14 3-7h4" fill="none" stroke="#000" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>';

  static const String editProfile =
      '<svg viewBox="0 0 24 24"><path d="M4 20h4L19 9a2.8 2.8 0 0 0-4-4L4 16v4zM13.5 6.5l4 4" fill="none" stroke="#000" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>';

  static const String privacy =
      '<svg viewBox="0 0 24 24"><path d="M12 3l8 3v6c0 4.5-3.2 8-8 9-4.8-1-8-4.5-8-9V6l8-3z" fill="none" stroke="#000" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/><path d="M9 12l2.2 2.2L15.5 10" fill="none" stroke="#000" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>';

  static const String about =
      '<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="9" fill="none" stroke="#000" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/><path d="M12 11v5M12 8v.01" fill="none" stroke="#000" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>';

  static const String chevronRight =
      '<svg viewBox="0 0 24 24"><path d="M9 6l6 6-6 6" fill="none" stroke="#000" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>';

  static const String chevronLeft =
      '<svg viewBox="0 0 24 24"><path d="M15 6l-6 6 6 6" fill="none" stroke="#000" stroke-width="2.0" stroke-linecap="round" stroke-linejoin="round"/></svg>';

  static const String logout =
      '<svg viewBox="0 0 24 24"><path d="M9 4H6a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h3M16 8l4 4-4 4M20 12H9" fill="none" stroke="#000" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>';

  static Widget svg(String rawSvg, {double size = 20, required Color color}) {
    return SvgPicture.string(
      rawSvg,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}

/// Contenedor estándar de subsecciones con atmósfera difuminada y sin rebote.
class ProfileSubsectionScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final VoidCallback? onBack;
  final Widget? trailing;

  const ProfileSubsectionScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
    this.onBack,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final hPad = AppResponsive.horizontalPadding(context);

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: PivoteAmbientBackdrop(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  hPad,
                  topPad + 6,
                  hPad,
                  math.max(28, bottomPad + 24),
                ),
                children: [
                  PivoteSubHeader(
                    title: title,
                    subtitle: subtitle,
                    onBack: onBack,
                    trailing: trailing,
                  ),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Alias retrocompatible hacia `PivoteSubHeader`.
class ProfileSubHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;
  final bool showBackButton;

  const ProfileSubHeader({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return PivoteSubHeader(
      title: title,
      onBack: onBack,
      trailing: trailing,
      showBackButton: showBackButton,
    );
  }
}

/// Título de sección unificado (delega a `PivoteSectionHeader` estilo MatchesHero).
class ProfileSectionTitle extends StatelessWidget {
  final String text;
  final bool first;

  const ProfileSectionTitle(
    this.text, {
    super.key,
    this.first = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: first ? 4 : 22, bottom: 10),
      child: PivoteSectionHeader(title: text),
    );
  }
}

/// Tarjeta de grupo difuminada estilo MatchesHero con divisores 1px.
class ProfileGroupCard extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final bool highlighted;
  final Color? glowColor;

  const ProfileGroupCard({
    super.key,
    required this.children,
    this.padding,
    this.highlighted = false,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return PivoteDiffusedCard(
      borderRadius: AppRadius.lg,
      glowColor: glowColor,
      glowAlignment: const Alignment(-0.85, -0.8),
      glowOpacity: highlighted ? 1.15 : 0.58,
      highlighted: highlighted,
      padding: padding ?? EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1 && padding == null)
              Divider(
                height: 1,
                thickness: 1,
                color: AppTheme.border(context),
              ),
          ],
        ],
      ),
    );
  }
}

/// Fila interactiva moderna dentro de un grupo.
class ProfileGroupRow extends StatefulWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final String? valueText;
  final Widget? trailing;
  final bool showChevron;
  final bool isDanger;
  final VoidCallback? onTap;
  final double horizontalGap;

  const ProfileGroupRow({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.valueText,
    this.trailing,
    this.showChevron = false,
    this.isDanger = false,
    this.onTap,
    this.horizontalGap = 13,
  });

  @override
  State<ProfileGroupRow> createState() => _ProfileGroupRowState();
}

class _ProfileGroupRowState extends State<ProfileGroupRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final interactive = widget.onTap != null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: interactive ? (_) => setState(() => _pressed = true) : null,
      onTapUp: interactive ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: interactive ? () => setState(() => _pressed = false) : null,
      onTap: interactive
          ? () {
              HapticFeedback.selectionClick();
              widget.onTap!();
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 110),
        color: _pressed
            ? AppTheme.surface2(context).withValues(alpha: 0.72)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13.5),
        child: Row(
          children: [
            if (widget.leading != null) ...[
              widget.leading!,
              SizedBox(width: widget.horizontalGap),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title,
                    style: AppFont.primary(
                      fontSize: 14.8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: widget.isDanger
                          ? AppTheme.danger(context)
                          : AppTheme.textPrimary(context),
                    ),
                  ),
                  if (widget.subtitle != null &&
                      widget.subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2.5),
                    Text(
                      widget.subtitle!,
                      style: AppFont.primary(
                        fontSize: 12.2,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textTertiary(context),
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (widget.valueText != null && widget.valueText!.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                decoration: BoxDecoration(
                  color: AppTheme.surface2(context),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  border: Border.all(color: AppTheme.border(context)),
                ),
                child: Text(
                  widget.valueText!,
                  style: AppFont.primary(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary(context),
                  ),
                ),
              ),
            ],
            if (widget.trailing != null) ...[
              const SizedBox(width: 10),
              widget.trailing!,
            ],
            if (widget.showChevron) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 19,
                color: AppTheme.textTertiary(context),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Caja de icono 38x38 moderna con tinte suave y borde 1px.
class ProfileSettingIconBox extends StatelessWidget {
  final String? svgString;
  final IconData? icon;
  final bool highlight;

  const ProfileSettingIconBox({
    super.key,
    this.svgString,
    this.icon,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.accent(context);
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: highlight
            ? AppTheme.accentDim(context)
            : AppTheme.surface2(context),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: highlight
              ? accent.withValues(alpha: 0.30)
              : AppTheme.border(context),
        ),
      ),
      alignment: Alignment.center,
      child: icon != null
          ? Icon(
              icon,
              size: 19,
              color: highlight ? accent : AppTheme.textPrimary(context),
            )
          : ProfileSvgIcons.svg(
              svgString ?? ProfileSvgIcons.about,
              size: 19,
              color: highlight ? accent : AppTheme.textPrimary(context),
            ),
    );
  }
}

/// Interruptor tipo píldora 50x30 sincronizado con el acento del tema.
class ProfileSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;

  const ProfileSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final accent = AppTheme.accent(context);
    final onAccent = AppTheme.onAccent(context);

    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: GestureDetector(
        onTap: enabled && onChanged != null
            ? () {
                HapticFeedback.selectionClick();
                onChanged!(!value);
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: 50,
          height: 30,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            color: value ? accent : AppTheme.surface4(context),
            boxShadow: value
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: isDark ? 0.28 : 0.18),
                      blurRadius: 10,
                      spreadRadius: -2,
                    ),
                  ]
                : null,
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: value ? onAccent : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum ProfileButtonVariant { primary, soft, danger }

/// Botón de acción de ancho completo unificado (adapta Modo Claro y Oscuro).
class ProfileActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final ProfileButtonVariant variant;
  final Widget? leadingIcon;
  final bool loading;

  const ProfileActionButton({
    super.key,
    required this.label,
    required this.onTap,
    this.variant = ProfileButtonVariant.primary,
    this.leadingIcon,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.accent(context);
    final onAccent = AppTheme.onAccent(context);
    final danger = AppTheme.danger(context);

    Color bgColor;
    Color textColor;
    Border? border;
    List<BoxShadow>? boxShadow;

    switch (variant) {
      case ProfileButtonVariant.primary:
        bgColor = accent;
        textColor = onAccent;
        border = null;
        boxShadow = AppShadows.glow(accent, alpha: 0.26);
        break;
      case ProfileButtonVariant.soft:
        bgColor = AppTheme.surface1(context);
        textColor = AppTheme.textPrimary(context);
        border = Border.all(color: AppTheme.border(context), width: 1);
        boxShadow = AppShadows.card(context);
        break;
      case ProfileButtonVariant.danger:
        bgColor = AppTheme.dangerDim(context);
        textColor = danger;
        border = Border.all(color: danger.withValues(alpha: 0.34), width: 1);
        boxShadow = null;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: ApplePressable(
        scaleDownFactor: 0.975,
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: loading ? null : onTap,
        child: Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            color: bgColor,
            boxShadow: boxShadow,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: border,
          ),
          alignment: Alignment.center,
          child: loading
              ? PivoteLoader(
                  size: 20,
                  strokeWidth: 2.3,
                  color: textColor,
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (leadingIcon != null) ...[
                      leadingIcon!,
                      const SizedBox(width: 9),
                    ],
                    Text(
                      label,
                      style: AppFont.primary(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.15,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Avatar circular con anillo tonal de un solo acento (sin arcos multicolores).
class ProfileAvatarWithRing extends StatefulWidget {
  final double size;
  final String? imagePath;
  final String? photoUrl;
  final String fallbackInitial;
  final VoidCallback? onTap;

  const ProfileAvatarWithRing({
    super.key,
    this.size = 76,
    this.imagePath,
    this.photoUrl,
    required this.fallbackInitial,
    this.onTap,
  });

  @override
  State<ProfileAvatarWithRing> createState() => _ProfileAvatarWithRingState();
}

class _ProfileAvatarWithRingState extends State<ProfileAvatarWithRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final accent = AppTheme.accent(context);
    final reduceAnimations = context.select<ThemeProvider, bool>(
      (p) => p.reduceAnimations,
    );

    if (reduceAnimations && _controller.isAnimating) {
      _controller.stop();
    } else if (!reduceAnimations && !_controller.isAnimating) {
      _controller.repeat();
    }

    ImageProvider<Object>? imageProvider;
    if (!kIsWeb && widget.imagePath != null && widget.imagePath!.isNotEmpty) {
      final f = File(widget.imagePath!);
      if (f.existsSync()) imageProvider = FileImage(f);
    } else if (widget.photoUrl != null && widget.photoUrl!.isNotEmpty) {
      imageProvider = NetworkImage(widget.photoUrl!);
    }

    final ringPad = widget.size >= 96 ? 3.0 : 2.4;
    final gapPad = widget.size >= 96 ? 3.5 : 2.6;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final angle = _controller.value * 2 * math.pi;
          return Container(
            width: widget.size,
            height: widget.size,
            padding: EdgeInsets.all(ringPad),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  accent,
                  accent.withValues(alpha: isDark ? 0.28 : 0.22),
                  accent.withValues(alpha: isDark ? 0.72 : 0.65),
                  accent,
                ],
                transform: GradientRotation(angle),
              ),
            ),
            child: child,
          );
        },
        child: Container(
          padding: EdgeInsets.all(gapPad),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.surface1(context),
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.surface2(context),
              image: imageProvider != null
                  ? DecorationImage(
                      image: imageProvider,
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            alignment: Alignment.center,
            child: imageProvider == null
                ? Text(
                    widget.fallbackInitial,
                    style: AppFont.primary(
                      fontSize: widget.size * 0.36,
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

/// Píldora moderna de estado de cuenta (VIP en acento de marca / Estándar neutro).
class ProfilePlanBadge extends StatelessWidget {
  final bool isVip;
  final bool compact;

  const ProfilePlanBadge({
    super.key,
    required this.isVip,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.accent(context);

    if (isVip) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 11,
          vertical: compact ? 3.5 : 4.5,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          color: AppTheme.accentDim(context),
          border: Border.all(
            color: accent.withValues(alpha: 0.42),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!compact) ...[
              ProfileSvgIcons.svg(
                ProfileSvgIcons.crown,
                size: 13,
                color: accent,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              compact ? 'VIP' : 'Miembro VIP',
              style: AppFont.mono(
                fontSize: compact ? 11 : 11.5,
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 11,
        vertical: compact ? 3.5 : 4.5,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface2(context),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppTheme.border(context), width: 1),
      ),
      child: Text(
        compact ? 'Estándar' : 'Plan Estándar',
        style: AppFont.primary(
          fontSize: compact ? 11.5 : 12,
          fontWeight: FontWeight.w700,
          color: AppTheme.textSecondary(context),
        ),
      ),
    );
  }
}
