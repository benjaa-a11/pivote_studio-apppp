import 'dart:async';
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
        gradient: const [
          Color(0xFF34D399),
          Color(0xFF059669)
        ], // More modern greens
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
        gradient: const [
          Color(0xFFF87171),
          Color(0xFFDC2626)
        ], // More modern reds
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
        gradient: const [
          Color(0xFF60A5FA),
          Color(0xFF2563EB)
        ], // FIFA/Modern Blues
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1C1C1E).withValues(alpha: 0.7)
                      : Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : cfg.color.withValues(alpha: 0.1),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.4 : 0.06),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Content row
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: Row(
                        children: [
                          // Left accent + icon
                          ScaleTransition(
                            scale: _iconPop,
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: cfg.gradient,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: cfg.color.withValues(alpha: 0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child:
                                  Icon(cfg.icon, color: Colors.white, size: 24),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Text
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  cfg.label.toUpperCase(),
                                  style: GoogleFonts.syne(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: cfg.color,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  cfg.message,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    height: 1.3,
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.9)
                                        : Colors.black.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Animated progress bar
                    AnimatedBuilder(
                      animation: _progress,
                      builder: (_, __) {
                        return LinearProgressIndicator(
                          value: _progress.value,
                          minHeight: 2.5,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            cfg.color.withValues(alpha: 0.5),
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
      ),
    );
  }
}
