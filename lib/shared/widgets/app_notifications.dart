import 'dart:async';
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
        gradient: const [Color(0xFF00C896), Color(0xFF00A878)],
        icon: Icons.check_rounded,
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
        gradient: const [Color(0xFFFF5A5A), Color(0xFFE03A3A)],
        icon: Icons.close_rounded,
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
        gradient: const [Color(0xFFFFB547), Color(0xFFFF9500)],
        icon: Icons.priority_high_rounded,
        label: 'Atención',
      ),
    );
  }

  static void showInfo(BuildContext context, String message) {
    _show(
      context,
      _ToastConfig(
        message: message,
        color: Theme.of(context).colorScheme.primary,
        gradient: const [Color(0xFF5B8AF5), Color(0xFF3D6AE0)],
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
  final List<Color> gradient;
  final IconData icon;
  final String label;

  const _ToastConfig({
    required this.message,
    required this.color,
    required this.gradient,
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
  late final AnimationController _progress;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<double> _iconPop;
  Timer? _timer;

  static const Duration _duration = Duration(seconds: 4);

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

    // Progress bar (ticks down over toast duration)
    _progress = AnimationController(
      vsync: this,
      duration: _duration,
      value: 1.0,
    );

    _enter.forward();
    _progress.animateTo(0.0, curve: Curves.linear);
  }

  @override
  void dispose() {
    _enter.dispose();
    _progress.dispose();
    _timer?.cancel();
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
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : cfg.color.withValues(alpha: 0.15),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: cfg.color.withValues(alpha: 0.2),
                  blurRadius: 30,
                  spreadRadius: -4,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Content row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                    child: Row(
                      children: [
                        // Left accent + icon
                        ScaleTransition(
                          scale: _iconPop,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: cfg.gradient,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: cfg.color.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child:
                                Icon(cfg.icon, color: Colors.white, size: 22),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Text
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                cfg.label,
                                style: GoogleFonts.syne(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: cfg.color,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                cfg.message,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.dmSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.85)
                                      : Colors.black.withValues(alpha: 0.75),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Close hint
                        const SizedBox(width: 8),
                        Icon(
                          Icons.swipe_rounded,
                          size: 16,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.2),
                        ),
                      ],
                    ),
                  ),

                  // Animated progress bar
                  AnimatedBuilder(
                    animation: _progress,
                    builder: (_, __) {
                      return ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(20),
                        ),
                        child: LinearProgressIndicator(
                          value: _progress.value,
                          minHeight: 3,
                          backgroundColor:
                              cfg.color.withValues(alpha: isDark ? 0.12 : 0.08),
                          valueColor: AlwaysStoppedAnimation<Color>(cfg.color),
                        ),
                      );
                    },
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
