import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/core/theme/dialog_styles.dart';

/// Sistema de notificaciones Toast flotantes de Pivote.
///
/// Anclado en la zona superior segura (estilo Dynamic Pill / cristal esmerilado
/// con difuminación radial), por lo que nunca colisiona con la barra flotante
/// inferior ni con el teclado ni con los Bottom Sheets.
/// Soporta deslizamiento hacia arriba para descartar y reemplazo limpio.
class AppNotifications {
  static OverlayEntry? _activeEntry;
  static Timer? _dismissTimer;

  static void showSuccess(BuildContext context, String message) {
    showSnackBar(
      context: context,
      message: message,
      type: AppDialogType.success,
    );
  }

  static void showError(BuildContext context, String message) {
    showSnackBar(
      context: context,
      message: message,
      type: AppDialogType.error,
    );
  }

  static void showWarning(BuildContext context, String message) {
    showSnackBar(
      context: context,
      message: message,
      type: AppDialogType.warning,
    );
  }

  static void showInfo(BuildContext context, String message) {
    showSnackBar(
      context: context,
      message: message,
      type: AppDialogType.info,
    );
  }

  static void dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    try {
      _activeEntry?.remove();
    } catch (_) {}
    _activeEntry = null;
  }

  static void showSnackBar({
    required BuildContext context,
    required String message,
    AppDialogType type = AppDialogType.info,
    Duration duration = const Duration(milliseconds: 2800),
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      // Fallback seguro si no existe Overlay (ej. tests aislados).
      ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(message), duration: duration),
      );
      return;
    }

    dismiss();
    HapticFeedback.selectionClick();

    final isDark = AppTheme.isDark(context);
    final accentColor = DialogStyles.getIconColor(type, isDark);
    final iconData = DialogStyles.getIcon(type);

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) => _FloatingGlassToast(
        message: message,
        accentColor: accentColor,
        icon: iconData,
        duration: duration,
        onDismissed: () {
          if (_activeEntry == entry) {
            dismiss();
          } else {
            try {
              entry.remove();
            } catch (_) {}
          }
        },
      ),
    );

    _activeEntry = entry;
    overlay.insert(entry);
  }
}

class _FloatingGlassToast extends StatefulWidget {
  final String message;
  final Color accentColor;
  final IconData icon;
  final Duration duration;
  final VoidCallback onDismissed;

  const _FloatingGlassToast({
    required this.message,
    required this.accentColor,
    required this.icon,
    required this.duration,
    required this.onDismissed,
  });

  @override
  State<_FloatingGlassToast> createState() => _FloatingGlassToastState();
}

class _FloatingGlassToastState extends State<_FloatingGlassToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  Timer? _autoTimer;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.45),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));
    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _scale = Tween<double>(begin: 0.96, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();
    _autoTimer = Timer(widget.duration, _dismiss);
  }

  Future<void> _dismiss() async {
    if (_dismissing || !mounted) return;
    _dismissing = true;
    _autoTimer?.cancel();
    await _controller.reverse();
    if (mounted) widget.onDismissed();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final topPad = MediaQuery.paddingOf(context).top;

    return Positioned(
      top: topPad + 12,
      left: 16,
      right: 16,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SlideTransition(
            position: _slide,
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: GestureDetector(
                  onVerticalDragUpdate: (details) {
                    if (details.delta.dy < -4) _dismiss();
                  },
                  onTap: _dismiss,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: isDark ? 0.52 : 0.14),
                            blurRadius: 28,
                            spreadRadius: -6,
                            offset: const Offset(0, 12),
                          ),
                          BoxShadow(
                            color: widget.accentColor
                                .withValues(alpha: isDark ? 0.16 : 0.10),
                            blurRadius: 20,
                            spreadRadius: -4,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkBg1.withValues(alpha: 0.90)
                                  : AppColors.lightBg1.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              border: Border.all(
                                color: widget.accentColor
                                    .withValues(alpha: isDark ? 0.36 : 0.28),
                                width: 1.1,
                              ),
                            ),
                            child: Stack(
                              children: [
                                // Difuminación radial izquierda estilo MatchesHero
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: RadialGradient(
                                          center: const Alignment(-0.92, 0.0),
                                          radius: 1.2,
                                          colors: [
                                            widget.accentColor.withValues(
                                              alpha: isDark ? 0.22 : 0.12,
                                            ),
                                            widget.accentColor
                                                .withValues(alpha: 0.0),
                                          ],
                                          stops: const [0.0, 0.72],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 34,
                                        height: 34,
                                        decoration: BoxDecoration(
                                          color: widget.accentColor
                                              .withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(
                                            AppRadius.sm,
                                          ),
                                          border: Border.all(
                                            color: widget.accentColor
                                                .withValues(alpha: 0.30),
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Icon(
                                          widget.icon,
                                          color: widget.accentColor,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          widget.message,
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppFont.primary(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.textPrimary(context),
                                            height: 1.32,
                                            letterSpacing: -0.15,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.close_rounded,
                                        size: 16,
                                        color: AppTheme.textTertiary(context),
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
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
