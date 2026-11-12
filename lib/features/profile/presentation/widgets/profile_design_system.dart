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

/// Paleta unificada conectada directamente al Design System (`AppTheme` / `AppColors`).
/// Comparte exactamente la misma identidad visual en modo oscuro y modo claro.
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (isDark) {
      return ProfilePalette(
        isDark: true,
        bg: AppTheme.darkBg,
        card: AppTheme.darkBg2,
        cardPressed: AppTheme.darkBg3,
        border: AppTheme.darkBorder,
        iconBox: AppTheme.darkBg3,
        text: AppTheme.darkText,
        muted: AppTheme.darkText2,
        chevron: AppTheme.darkText3,
        switchOff: AppTheme.darkBg4,
        switchOn: AppTheme.darkAccent,
        switchThumbOn: AppColors.onDarkAccent,
        accent: AppTheme.darkAccent,
        primaryBtnBg: AppTheme.darkAccent,
        primaryBtnText: AppColors.onDarkAccent,
        danger: AppTheme.darkDanger,
        dangerBg: AppTheme.darkDangerDim,
        dangerBorder: AppTheme.darkDanger.withValues(alpha: 0.28),
        avatarPlaceholderBg: AppTheme.darkBg4,
        cardShadow: AppShadows.card(context),
      );
    } else {
      return ProfilePalette(
        isDark: false,
        bg: AppTheme.lightBg,
        card: AppTheme.lightBg1,
        cardPressed: AppTheme.lightBg2,
        border: AppTheme.lightBorder,
        iconBox: AppTheme.lightBg2,
        text: AppTheme.lightText,
        muted: AppTheme.lightText2,
        chevron: AppTheme.lightText3,
        switchOff: AppTheme.lightBg4,
        switchOn: AppTheme.lightAccent,
        switchThumbOn: AppColors.onLightAccent,
        accent: AppTheme.lightAccent,
        primaryBtnBg: AppTheme.lightAccent,
        primaryBtnText: AppColors.onLightAccent,
        danger: AppTheme.lightDanger,
        dangerBg: AppTheme.lightDangerDim,
        dangerBorder: AppTheme.lightDanger.withValues(alpha: 0.25),
        avatarPlaceholderBg: AppTheme.lightText3,
        cardShadow: AppShadows.appleDepth(context, elevation: 0.7),
      );
    }
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

/// Contenedor estándar de subsecciones con ancho adaptable.
class ProfileSubsectionScaffold extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final VoidCallback? onBack;
  final Widget? trailing;

  const ProfileSubsectionScaffold({
    super.key,
    required this.title,
    required this.children,
    this.onBack,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ProfilePalette.of(context);
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final hPad = AppResponsive.screenHorizontalPadding(context).horizontal / 2;

    return Scaffold(
      backgroundColor: palette.bg,
      body: GestureDetector(
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
                topPad + 10,
                hPad,
                math.max(24, bottomPad + 22),
              ),
              children: [
                ProfileSubHeader(
                  title: title,
                  onBack: onBack,
                  trailing: trailing,
                ),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Encabezado de subsección unificado.
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
    final palette = ProfilePalette.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 8, 2, 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (showBackButton)
            _PressableScale(
              onTap: () {
                HapticFeedback.lightImpact();
                if (onBack != null) {
                  onBack!();
                } else {
                  Navigator.of(context).maybePop();
                }
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: palette.card,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: palette.border,
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: ProfileSvgIcons.svg(
                  ProfileSvgIcons.chevronLeft,
                  size: 18,
                  color: palette.text,
                ),
              ),
            )
          else
            const SizedBox(width: 40, height: 40),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFont.primary(
                fontSize: 19.5,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: palette.text,
              ),
            ),
          ),
          trailing ?? const SizedBox(width: 40, height: 40),
        ],
      ),
    );
  }
}

/// Título de sección con jerarquía tipográfica unificada.
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
    final palette = ProfilePalette.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(8, first ? 0 : 18, 8, 8),
      child: Text(
        text,
        style: AppFont.primary(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.1,
          color: palette.muted,
        ),
      ),
    );
  }
}

/// Tarjeta de grupo con bordes y radios unificados (`AppRadius.lg`).
class ProfileGroupCard extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  const ProfileGroupCard({
    super.key,
    required this.children,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ProfilePalette.of(context);

    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: palette.border, width: 1),
        boxShadow: palette.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg - 1),
        child: Padding(
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
                    color: palette.border,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Fila interactiva dentro de un grupo.
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
    this.horizontalGap = 12,
  });

  @override
  State<ProfileGroupRow> createState() => _ProfileGroupRowState();
}

class _ProfileGroupRowState extends State<ProfileGroupRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final palette = ProfilePalette.of(context);
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
        duration: const Duration(milliseconds: 120),
        color: _pressed ? palette.cardPressed : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                      color: widget.isDanger ? palette.danger : palette.text,
                    ),
                  ),
                  if (widget.subtitle != null &&
                      widget.subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle!,
                      style: AppFont.primary(
                        fontSize: 12.8,
                        fontWeight: FontWeight.w500,
                        color: palette.muted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (widget.valueText != null && widget.valueText!.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                widget.valueText!,
                style: AppFont.primary(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: palette.muted,
                ),
              ),
            ],
            if (widget.trailing != null) ...[
              const SizedBox(width: 12),
              widget.trailing!,
            ],
            if (widget.showChevron) ...[
              SizedBox(width: widget.valueText != null ? 8 : 10),
              ProfileSvgIcons.svg(
                ProfileSvgIcons.chevronRight,
                size: 18,
                color: palette.chevron,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Caja de icono de 38x38 con radio `AppRadius.sm`.
class ProfileSettingIconBox extends StatelessWidget {
  final String svgString;

  const ProfileSettingIconBox({
    super.key,
    required this.svgString,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ProfilePalette.of(context);
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: palette.iconBox,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      alignment: Alignment.center,
      child: ProfileSvgIcons.svg(
        svgString,
        size: 20,
        color: palette.text,
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
    final palette = ProfilePalette.of(context);

    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
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
            color: value ? palette.switchOn : palette.switchOff,
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
                color: value ? palette.switchThumbOn : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 3,
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

/// Botón de acción de ancho completo unificado con el sistema de diseño.
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
    final palette = ProfilePalette.of(context);

    Color bgColor;
    Color textColor;
    Border? border;

    switch (variant) {
      case ProfileButtonVariant.primary:
        bgColor = palette.primaryBtnBg;
        textColor = palette.primaryBtnText;
        border = null;
        break;
      case ProfileButtonVariant.soft:
        bgColor = palette.card;
        textColor = palette.text;
        border = Border.all(color: palette.border, width: 1);
        break;
      case ProfileButtonVariant.danger:
        bgColor = palette.dangerBg;
        textColor = palette.danger;
        border = Border.all(color: palette.dangerBorder, width: 1);
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: _PressableScale(
        onTap: loading ? null : onTap,
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: border,
          ),
          alignment: Alignment.center,
          child: loading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation<Color>(textColor),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (leadingIcon != null) ...[
                      leadingIcon!,
                      const SizedBox(width: 10),
                    ],
                    Text(
                      label,
                      style: AppFont.primary(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
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

/// Banner de portada de perfil unificado con la estética de Pivote.
class ProfileCoverBanner extends StatelessWidget {
  const ProfileCoverBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = ProfilePalette.of(context);

    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: palette.border,
          width: 1,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette.isDark
              ? const [
                  AppColors.ink1,
                  AppColors.ink2,
                ]
              : const [
                  AppColors.lightBg2,
                  AppColors.lightBg3,
                ],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl - 1),
        child: CustomPaint(
          painter: _CloudCoverPainter(
            isDark: palette.isDark,
            accentColor: palette.accent,
          ),
        ),
      ),
    );
  }
}

class _CloudCoverPainter extends CustomPainter {
  final bool isDark;
  final Color accentColor;

  _CloudCoverPainter({
    required this.isDark,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (isDark) {
      final accentGlow = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.25),
          radius: 0.85,
          colors: [
            accentColor.withValues(alpha: 0.22),
            accentColor.withValues(alpha: 0.05),
            Colors.transparent,
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Offset.zero & size);
      canvas.drawRect(Offset.zero & size, accentGlow);

      _drawCloudBlob(
        canvas,
        size,
        center: Offset(size.width * 0.72, size.height * 0.45),
        rx: size.width * 0.42,
        ry: size.height * 0.40,
        innerColor: AppColors.info.withValues(alpha: 0.16),
        midColor: AppColors.info.withValues(alpha: 0.04),
      );
    } else {
      _drawCloudBlob(
        canvas,
        size,
        center: Offset(size.width * 0.30, size.height * 0.38),
        rx: size.width * 0.52,
        ry: size.height * 0.45,
        innerColor: accentColor.withValues(alpha: 0.12),
        midColor: accentColor.withValues(alpha: 0.03),
      );
      _drawCloudBlob(
        canvas,
        size,
        center: Offset(size.width * 0.72, size.height * 0.58),
        rx: size.width * 0.38,
        ry: size.height * 0.32,
        innerColor: AppColors.info.withValues(alpha: 0.10),
        midColor: Colors.white.withValues(alpha: 0.45),
      );
    }
  }

  void _drawCloudBlob(
    Canvas canvas,
    Size size, {
    required Offset center,
    required double rx,
    required double ry,
    required Color innerColor,
    required Color midColor,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(rx, ry);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [innerColor, midColor, Colors.transparent],
        stops: const [0.0, 0.45, 0.85],
      ).createShader(const Rect.fromLTRB(-1.0, -1.0, 1.0, 1.0));
    canvas.drawCircle(Offset.zero, 1.0, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CloudCoverPainter oldDelegate) {
    return oldDelegate.isDark != isDark ||
        oldDelegate.accentColor != accentColor;
  }
}

/// Avatar circular con anillo degradado animado.
class ProfileAvatarWithRing extends StatefulWidget {
  final double size;
  final String? imagePath;
  final String? photoUrl;
  final String fallbackInitial;
  final VoidCallback? onTap;

  const ProfileAvatarWithRing({
    super.key,
    this.size = 156,
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
      duration: const Duration(seconds: 9),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = ProfilePalette.of(context);
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
      imageProvider = FileImage(File(widget.imagePath!));
    } else if (widget.photoUrl != null && widget.photoUrl!.isNotEmpty) {
      imageProvider = NetworkImage(widget.photoUrl!);
    }

    final ringPad = widget.size >= 120 ? 5.0 : 4.0;
    final gapPad = widget.size >= 120 ? 6.0 : 4.5;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final angle = 3.4906585 + (_controller.value * 2 * math.pi);
          return Container(
            width: widget.size,
            height: widget.size,
            padding: EdgeInsets.all(ringPad),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: const [
                  AppColors.darkAccent,
                  AppColors.info,
                  AppColors.positive,
                  AppColors.violet,
                  AppColors.darkAccent,
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
            color: palette.bg,
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.avatarPlaceholderBg,
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
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

/// Píldora de estado de cuenta (VIP o Normal).
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
    final palette = ProfilePalette.of(context);

    if (isVip) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 14,
          vertical: compact ? 4 : 6,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF7E08A),
              AppColors.gold,
            ],
          ),
          boxShadow: compact
              ? null
              : [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.38),
                    blurRadius: 12,
                    spreadRadius: -4,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!compact) ...[
              ProfileSvgIcons.svg(
                ProfileSvgIcons.crown,
                size: 15,
                color: const Color(0xFF422F00),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              compact ? 'VIP' : 'Usuario VIP',
              style: AppFont.primary(
                fontSize: compact ? 12.5 : 13.5,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF422F00),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: palette.border, width: 1),
      ),
      child: Text(
        compact ? 'Normal' : 'Usuario normal',
        style: AppFont.primary(
          fontSize: compact ? 12.5 : 13.5,
          fontWeight: FontWeight.w700,
          color: palette.muted,
        ),
      ),
    );
  }
}

class _PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _PressableScale({
    required this.child,
    this.onTap,
  });

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
