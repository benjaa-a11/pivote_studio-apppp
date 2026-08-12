import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pivote/core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────
//  AppNotifications  –  Public API
// ─────────────────────────────────────────────────────────────
class AppNotifications {
  static void showSuccess(BuildContext context, String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _show(
      context,
      _ToastConfig(
        message: message,
        color: isDark ? AppTheme.darkSuccess : AppTheme.lightSuccess,
        icon: Icons.check_circle_rounded,
        label: 'Éxito',
      ),
    );
  }

  static void showError(BuildContext context, String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _show(
      context,
      _ToastConfig(
        message: message,
        color: isDark ? AppTheme.darkDanger : AppTheme.lightDanger,
        icon: Icons.error_rounded,
        label: 'Error',
      ),
    );
  }

  static void showWarning(BuildContext context, String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _show(
      context,
      _ToastConfig(
        message: message,
        color: isDark ? AppTheme.darkWarning : AppTheme.lightWarning,
        icon: Icons.priority_high_rounded,
        label: 'Atención',
      ),
    );
  }

  static void showInfo(BuildContext context, String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _show(
      context,
      _ToastConfig(
        message: message,
        color: isDark ? AppTheme.darkInfo : AppTheme.lightInfo,
        icon: Icons.info_rounded,
        label: 'Info',
      ),
    );
  }

  static void _show(BuildContext context, _ToastConfig config) {
    HapticFeedback.lightImpact();

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        padding: EdgeInsets.zero,
        dismissDirection: DismissDirection.horizontal,
        content: _PremiumToast(config: config),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  _ToastConfig
// ─────────────────────────────────────────────────────────────
class _ToastConfig {
  final String message;
  final Color color;
  final IconData icon;
  final String label;

  const _ToastConfig({
    required this.message,
    required this.color,
    required this.icon,
    required this.label,
  });
}

// ─────────────────────────────────────────────────────────────
//  _PremiumToast  –  Animated widget
// ─────────────────────────────────────────────────────────────
class _PremiumToast extends StatefulWidget {
  final _ToastConfig config;

  const _PremiumToast({required this.config});

  @override
  State<_PremiumToast> createState() => _PremiumToastState();
}

class _PremiumToastState extends State<_PremiumToast>
    with TickerProviderStateMixin {
  late final AnimationController _enter;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<double> _iconPop;

  @override
  void initState() {
    super.initState();

    // Entry animation
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _slide = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0, 0.7, curve: Curves.easeOutCubic),
    ).drive(Tween(begin: const Offset(0, 0.5), end: Offset.zero));

    _fade = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0, 0.5, curve: Curves.easeOut),
    ).drive(Tween(begin: 0.0, end: 1.0));

    _scale = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0, 0.8, curve: Curves.easeOutBack),
    ).drive(Tween(begin: 0.9, end: 1.0));

    // Icon pop – separate, delayed
    _iconPop = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
    ).drive(Tween(begin: 0.0, end: 1.0));

    _enter.forward();
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cfg = widget.config;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(
          scale: _scale,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF161920).withValues(alpha: 0.85)
                      : Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? cfg.color.withValues(alpha: 0.15)
                        : cfg.color.withValues(alpha: 0.12),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    // Icon Container
                    ScaleTransition(
                      scale: _iconPop,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: cfg.color.withValues(alpha: isDark ? 0.18 : 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          cfg.icon,
                          color: cfg.color,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Texts
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            cfg.label,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: cfg.color,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            cfg.message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 1.25,
                              color: isDark
                                  ? const Color(0xFFF0F4F8).withValues(alpha: 0.95)
                                  : const Color(0xFF1C222B).withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
