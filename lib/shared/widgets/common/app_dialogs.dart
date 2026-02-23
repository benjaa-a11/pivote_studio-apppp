import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pivote/core/theme/app_theme.dart';

enum AppDialogType { success, error, warning, info }

// ─────────────────────────────────────────────────────────────
//  AppDialogs  –  Public API (unchanged so callers don't break)
// ─────────────────────────────────────────────────────────────
class AppDialogs {
  static Future<bool?> showConfirm({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Confirmar',
    String cancelLabel = 'Cancelar',
    bool isDestructive = false,
    AppDialogType type = AppDialogType.info,
  }) async {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => _PremiumDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
        type: type,
        isConfirm: true,
      ),
    );
  }

  static Future<void> showAlert({
    required BuildContext context,
    required String title,
    required String message,
    AppDialogType type = AppDialogType.info,
  }) async {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => _PremiumDialog(
        title: title,
        message: message,
        type: type,
        isConfirm: false,
      ),
    );
  }

  static Future<T?> showModal<T>({
    required BuildContext context,
    required Widget child,
    bool scrollable = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _PremiumBottomSheet(
        scrollable: scrollable,
        child: child,
      ),
    );
  }

  static void showLoading({
    required BuildContext context,
    String message = 'Cargando...',
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => const _PremiumLoadingDialog(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  _DialogConfig  –  Per-type colors / icons / gradients
// ─────────────────────────────────────────────────────────────
class _DialogConfig {
  final Color color;
  final Color colorLight;
  final IconData icon;
  final List<Color> gradient;

  const _DialogConfig({
    required this.color,
    required this.colorLight,
    required this.icon,
    required this.gradient,
  });

  static _DialogConfig of(AppDialogType type, bool isDark) {
    switch (type) {
      case AppDialogType.success:
        final c = isDark ? AppTheme.darkSuccess : AppTheme.lightSuccess;
        return _DialogConfig(
          color: c,
          colorLight: c.withValues(alpha: 0.12),
          icon: Icons.check_rounded,
          gradient: [
            const Color(0xFF00C896),
            const Color(0xFF00A878),
          ],
        );
      case AppDialogType.error:
        final c = isDark ? AppTheme.darkDanger : AppTheme.lightDanger;
        return _DialogConfig(
          color: c,
          colorLight: c.withValues(alpha: 0.12),
          icon: Icons.close_rounded,
          gradient: [
            const Color(0xFFFF5A5A),
            const Color(0xFFE03A3A),
          ],
        );
      case AppDialogType.warning:
        final c = isDark ? AppTheme.darkWarning : AppTheme.lightWarning;
        return _DialogConfig(
          color: c,
          colorLight: c.withValues(alpha: 0.12),
          icon: Icons.priority_high_rounded,
          gradient: [
            const Color(0xFFFFB547),
            const Color(0xFFFF9500),
          ],
        );
      case AppDialogType.info:
        return _DialogConfig(
          color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
          colorLight: (isDark ? AppTheme.darkAccent : AppTheme.lightAccent)
              .withValues(alpha: 0.12),
          icon: Icons.info_rounded,
          gradient: [
            const Color(0xFF5B8AF5),
            const Color(0xFF3D6AE0),
          ],
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────
//  _PremiumDialog
// ─────────────────────────────────────────────────────────────
class _PremiumDialog extends StatefulWidget {
  final String title;
  final String message;
  final String? confirmLabel;
  final String? cancelLabel;
  final bool isDestructive;
  final AppDialogType type;
  final bool isConfirm;

  const _PremiumDialog({
    required this.title,
    required this.message,
    this.confirmLabel,
    this.cancelLabel,
    this.isDestructive = false,
    this.type = AppDialogType.info,
    required this.isConfirm,
  });

  @override
  State<_PremiumDialog> createState() => _PremiumDialogState();
}

class _PremiumDialogState extends State<_PremiumDialog>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final AnimationController _iconController;
  late final Animation<double> _iconScale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _scale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.8, curve: Curves.easeOutBack),
    ).drive(Tween(begin: 0.82, end: 1.0));

    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.5, curve: Curves.easeOut),
    ).drive(Tween(begin: 0.0, end: 1.0));

    _slide = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.6, curve: Curves.easeOutCubic),
    ).drive(Tween(begin: const Offset(0, 0.04), end: Offset.zero));

    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    _iconScale = CurvedAnimation(
      parent: _iconController,
      curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
    ).drive(Tween(begin: 0.0, end: 1.0));

    _controller.forward();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _iconController.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cfg = _DialogConfig.of(widget.type, isDark);
    final mq = MediaQuery.of(context);
    final maxW = (mq.size.width * 0.88).clamp(0.0, 380.0);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: FadeTransition(
        opacity: _fade,
        child: ScaleTransition(
          scale: _scale,
          child: SlideTransition(
            position: _slide,
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxW),
                child: _buildCard(context, theme, isDark, cfg),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    _DialogConfig cfg,
  ) {
    final surfaceColor = isDark
        ? const Color(0xFF1C1C1E)
        : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.black.withValues(alpha: 0.04),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: cfg.color.withValues(alpha: 0.15),
            blurRadius: 60,
            spreadRadius: -5,
            offset: const Offset(0, 20),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top accent bar
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: cfg.gradient),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildIconBadge(cfg, isDark),
                  const SizedBox(height: 24),
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.syne(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      fontSize: 14.5,
                      height: 1.6,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.55),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 28),
                  widget.isConfirm
                      ? _buildConfirmActions(context, theme, cfg)
                      : _buildAlertAction(context, theme, cfg),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconBadge(_DialogConfig cfg, bool isDark) {
    return ScaleTransition(
      scale: _iconScale,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: cfg.colorLight,
          shape: BoxShape.circle,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Subtle ring
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: cfg.color.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
            ),
            // Inner gradient circle
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: cfg.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: cfg.color.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(cfg.icon, color: Colors.white, size: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmActions(
    BuildContext context,
    ThemeData theme,
    _DialogConfig cfg,
  ) {
    return Row(
      children: [
        Expanded(
          child: _GhostButton(
            label: widget.cancelLabel ?? 'Cancelar',
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context, false);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _GradientButton(
            label: widget.confirmLabel ?? 'Confirmar',
            gradient: widget.isDestructive
                ? const [Color(0xFFFF5A5A), Color(0xFFE03A3A)]
                : cfg.gradient,
            onTap: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(context, true);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAlertAction(
    BuildContext context,
    ThemeData theme,
    _DialogConfig cfg,
  ) {
    return SizedBox(
      width: double.infinity,
      child: _GradientButton(
        label: 'Entendido',
        gradient: cfg.gradient,
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  _PremiumBottomSheet
// ─────────────────────────────────────────────────────────────
class _PremiumBottomSheet extends StatelessWidget {
  final Widget child;
  final bool scrollable;

  const _PremiumBottomSheet({
    required this.child,
    required this.scrollable,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mq = MediaQuery.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: mq.size.height * 0.92,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 50,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 6),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          scrollable
              ? Flexible(child: SingleChildScrollView(child: child))
              : Flexible(child: child),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  _PremiumLoadingDialog
// ─────────────────────────────────────────────────────────────
class _PremiumLoadingDialog extends StatefulWidget {
  const _PremiumLoadingDialog();

  @override
  State<_PremiumLoadingDialog> createState() => _PremiumLoadingDialogState();
}

class _PremiumLoadingDialogState extends State<_PremiumLoadingDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnim = CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)
        .drive(Tween(begin: 0.85, end: 1.0));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Center(
          child: ScaleTransition(
            scale: _pulseAnim,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.07)
                      : Colors.black.withValues(alpha: 0.04),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 50,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      strokeCap: StrokeCap.round,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Cargando...',
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
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

// ─────────────────────────────────────────────────────────────
//  Reusable Button Primitives
// ─────────────────────────────────────────────────────────────

class _GradientButton extends StatefulWidget {
  final String label;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _GradientButton({
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scale = CurvedAnimation(parent: _press, curve: Curves.easeOut)
        .drive(Tween(begin: 1.0, end: 0.95));
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _press.forward(),
      onTapUp: (_) {
        _press.reverse();
        widget.onTap();
      },
      onTapCancel: () => _press.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.gradient.first.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: GoogleFonts.dmSans(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _GhostButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _GhostButton({required this.label, required this.onTap});

  @override
  State<_GhostButton> createState() => _GhostButtonState();
}

class _GhostButtonState extends State<_GhostButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scale = CurvedAnimation(parent: _press, curve: Curves.easeOut)
        .drive(Tween(begin: 1.0, end: 0.95));
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => _press.forward(),
      onTapUp: (_) {
        _press.reverse();
        widget.onTap();
      },
      onTapCancel: () => _press.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: GoogleFonts.dmSans(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}