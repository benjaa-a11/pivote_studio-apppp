import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/theme_provider.dart';

/// Unified color palette for Profile & Settings Subsections,
/// adapting the HTML design system to Pivote's Dark and Light themes.
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accent = themeProvider.accentFor(isDark);

    if (isDark) {
      final isBrightAccent =
          ThemeData.estimateBrightnessForColor(accent) == Brightness.light;
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
        switchOn: accent,
        switchThumbOn: isBrightAccent ? AppTheme.darkBg : Colors.white,
        accent: accent,
        primaryBtnBg: accent,
        primaryBtnText: isBrightAccent ? AppTheme.darkBg : Colors.white,
        danger: AppTheme.darkDanger,
        dangerBg: AppTheme.darkDangerDim,
        dangerBorder: const Color(0x38FF4D4F),
        avatarPlaceholderBg: AppTheme.darkBg4,
        cardShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.32),
            blurRadius: 16,
            spreadRadius: -10,
            offset: const Offset(0, 6),
          ),
        ],
      );
    } else {
      final useDarkPrimary = themeProvider.accentIndex == 0;
      final activeFill = useDarkPrimary ? AppTheme.lightText : accent;
      return ProfilePalette(
        isDark: false,
        bg: AppTheme.lightBg1,
        card: const Color(0xFFE9EFF8),
        cardPressed: const Color(0xFFDDE6F3),
        border: const Color(0xFFD6E0EE),
        iconBox: Colors.white,
        text: const Color(0xFF111111),
        muted: const Color(0xFF6B6B6B),
        chevron: const Color(0xFFAAB4C4),
        switchOff: const Color(0xFFC9D3E2),
        switchOn: activeFill,
        switchThumbOn: Colors.white,
        accent: accent,
        primaryBtnBg: activeFill,
        primaryBtnText: Colors.white,
        danger: const Color(0xFFD93025),
        dangerBg: const Color(0xFFFDECEB),
        dangerBorder: const Color(0x2ED93025),
        avatarPlaceholderBg: const Color(0xFFCFD6DB),
        cardShadow: [
          BoxShadow(
            color: const Color(0xFF142850).withValues(alpha: 0.14),
            blurRadius: 16,
            spreadRadius: -10,
            offset: const Offset(0, 6),
          ),
        ],
      );
    }
  }
}

/// Exact SVG icons from the HTML specifications.
class ProfileSvgIcons {
  static const String crown =
      '<svg viewBox="0 0 24 24"><path d="M3 8l4.5 4L12 5l4.5 7L21 8l-2 11H5L3 8z"/></svg>';

  static const String appearance =
      '<svg viewBox="0 0 24 24"><path d="M20 14.5A8 8 0 0 1 9.5 4 8 8 0 1 0 20 14.5z" fill="none" stroke="#000" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>';

  static const String notifications =
      '<svg viewBox="0 0 24 24"><path d="M6 9a6 6 0 0 1 12 0c0 6 2 7 2 7H4s2-1 2-7M10 20a2 2 0 0 0 4 0" fill="none" stroke="#000" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>';

  static const String storage =
      '<svg viewBox="0 0 24 24"><ellipse cx="12" cy="6" rx="8" ry="3" fill="none" stroke="#000" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/><path d="M4 6v6c0 1.7 3.6 3 8 3s8-1.3 8-3V6M4 12v6c0 1.7 3.6 3 8 3s8-1.3 8-3v-6" fill="none" stroke="#000" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>';

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

/// Standard screen wrapper for subsections (.screen in HTML: padding 10, max-width 430).
class ProfileSubsectionScaffold extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final VoidCallback? onBack;

  const ProfileSubsectionScaffold({
    super.key,
    required this.title,
    required this.children,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ProfilePalette.of(context);
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: palette.bg,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: ListView(
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                10,
                topPad + 10,
                10,
                math.max(24, bottomPad + 22),
              ),
              children: [
                ProfileSubHeader(title: title, onBack: onBack),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Subsection Header (.hdr: back 40x40 circle #E9EFF8, centered 20px w600 title, 40px spacer).
class ProfileSubHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;

  const ProfileSubHeader({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ProfilePalette.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
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
                shape: BoxShape.circle,
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
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
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

/// Section title (.title: padding 18px 12px 8px, font-size 14px, weight 600, muted).
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
      padding: EdgeInsets.fromLTRB(12, first ? 0 : 18, 12, 8),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: palette.muted,
        ),
      ),
    );
  }
}

/// Group card (.group: background card, border 1px line, border-radius 26px, 1px dividers).
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
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: palette.border, width: 1),
        boxShadow: palette.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
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

/// Row inside a group (.row: padding 15x16, gap 12/14, title 16.5 w500, subtitle 13.5 muted).
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
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
                    style: GoogleFonts.inter(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w500,
                      color: widget.isDanger ? palette.danger : palette.text,
                    ),
                  ),
                  if (widget.subtitle != null &&
                      widget.subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle!,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w400,
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
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w400,
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

/// 38x38 rounded icon container (.icon: 38x38, radius 12, white in light / elevated dark in dark).
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
        borderRadius: BorderRadius.circular(12),
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

/// Custom 50x30 pill switch (.sw: 50x30, radius 999, thumb 24x24, 3px inset).
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
            borderRadius: BorderRadius.circular(999),
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

/// Full-width 54dp button (.btn, .btn.soft, .btn.bad: height 54, radius 26, font 16.5 w600).
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
          height: 54,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(26),
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
                      style: GoogleFonts.inter(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w600,
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

/// Cover banner (.cover: height 210, radius 30, cloud/sky atmospheric artwork).
class ProfileCoverBanner extends StatelessWidget {
  const ProfileCoverBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = ProfilePalette.of(context);

    return Container(
      height: 210,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: palette.isDark
              ? [
                  const Color(0xFF172234),
                  const Color(0xFF1E2D44),
                ]
              : [
                  const Color(0xFFB9CBE2),
                  const Color(0xFFC4D3E6),
                ],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
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
      // Subtle studio glow + soft night clouds for dark mode
      final accentGlow = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.25, -0.2),
          radius: 0.75,
          colors: [
            accentColor.withValues(alpha: 0.22),
            accentColor.withValues(alpha: 0.06),
            Colors.transparent,
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Offset.zero & size);
      canvas.drawRect(Offset.zero & size, accentGlow);

      _drawCloudBlob(
        canvas,
        size,
        center: Offset(size.width * 0.38, size.height * 0.42),
        rx: size.width * 0.48,
        ry: size.height * 0.42,
        innerColor: Colors.white.withValues(alpha: 0.14),
        midColor: Colors.white.withValues(alpha: 0.06),
      );
      _drawCloudBlob(
        canvas,
        size,
        center: Offset(size.width * 0.64, size.height * 0.62),
        rx: size.width * 0.35,
        ry: size.height * 0.32,
        innerColor: const Color(0xFF4F9BF0).withValues(alpha: 0.18),
        midColor: const Color(0xFF4F9BF0).withValues(alpha: 0.05),
      );
      _drawCloudBlob(
        canvas,
        size,
        center: Offset(size.width * 0.22, size.height * 0.60),
        rx: size.width * 0.30,
        ry: size.height * 0.26,
        innerColor: Colors.white.withValues(alpha: 0.11),
        midColor: Colors.white.withValues(alpha: 0.03),
      );
    } else {
      // Exact radial cloud gradients from profile.html
      _drawCloudBlob(
        canvas,
        size,
        center: Offset(size.width * 0.38, size.height * 0.42),
        rx: size.width * 0.55,
        ry: size.height * 0.45,
        innerColor: Colors.white,
        midColor: Colors.white.withValues(alpha: 0.85),
      );
      _drawCloudBlob(
        canvas,
        size,
        center: Offset(size.width * 0.62, size.height * 0.62),
        rx: size.width * 0.35,
        ry: size.height * 0.30,
        innerColor: Colors.white.withValues(alpha: 0.90),
        midColor: Colors.white.withValues(alpha: 0.45),
      );
      _drawCloudBlob(
        canvas,
        size,
        center: Offset(size.width * 0.22, size.height * 0.60),
        rx: size.width * 0.30,
        ry: size.height * 0.25,
        innerColor: Colors.white.withValues(alpha: 0.80),
        midColor: Colors.white.withValues(alpha: 0.35),
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

/// Avatar with conic/sweep gradient ring (.avatar-wrap: 156 diameter, 5dp ring, 4dp bg gap, photo/initial).
class ProfileAvatarWithRing extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final palette = ProfilePalette.of(context);

    ImageProvider<Object>? imageProvider;
    if (imagePath != null && imagePath!.isNotEmpty) {
      imageProvider = FileImage(File(imagePath!));
    } else if (photoUrl != null && photoUrl!.isNotEmpty) {
      imageProvider = NetworkImage(photoUrl!);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(5),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(
            colors: [
              Color(0xFF9B6BE6),
              Color(0xFF4F9BF0),
              Color(0xFF3FD1A0),
              Color(0xFFF0C93A),
              Color(0xFF9B6BE6),
            ],
            transform: GradientRotation(3.4906585),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(6),
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
                    fallbackInitial,
                    style: GoogleFonts.inter(
                      fontSize: size * 0.36,
                      fontWeight: FontWeight.w600,
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

/// Plan Pill (.plan: VIP gold gradient with crown SVG or normal pill).
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
          borderRadius: BorderRadius.circular(999),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF7E08A),
              Color(0xFFE3B341),
            ],
          ),
          boxShadow: compact
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFFE3B341).withValues(alpha: 0.45),
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
                color: const Color(0xFF5B4100),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              compact ? 'VIP' : 'Usuario VIP',
              style: GoogleFonts.inter(
                fontSize: compact ? 13 : 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF5B4100),
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
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.border, width: 1),
      ),
      child: Text(
        compact ? 'Normal' : 'Usuario normal',
        style: GoogleFonts.inter(
          fontSize: compact ? 13 : 14,
          fontWeight: FontWeight.w600,
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
