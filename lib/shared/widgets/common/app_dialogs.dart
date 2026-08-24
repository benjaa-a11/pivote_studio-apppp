import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pivote/core/theme/dialog_styles.dart';
import 'package:pivote/shared/widgets/common/pivote_loader.dart';

export 'package:pivote/core/theme/dialog_styles.dart' show AppDialogType;

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
      barrierColor: Colors.black.withAlpha(153),
      builder: (_) => _ModernDialog(
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
      barrierColor: Colors.black.withAlpha(153),
      builder: (_) => _ModernDialog(
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
      builder: (ctx) => _ModernBottomSheet(
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
      barrierColor: Colors.black.withAlpha(140),
      builder: (_) => _ModernLoadingDialog(message: message),
    );
  }
}

class _ModernDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? confirmLabel;
  final String? cancelLabel;
  final bool isDestructive;
  final AppDialogType type;
  final bool isConfirm;

  const _ModernDialog({
    required this.title,
    required this.message,
    this.confirmLabel,
    this.cancelLabel,
    this.isDestructive = false,
    this.type = AppDialogType.info,
    required this.isConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final iconColor = DialogStyles.getIconColor(type, isDark);
    final iconBgColor = DialogStyles.getIconBgColor(type, isDark);
    final iconData = DialogStyles.getIcon(type);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Dialog(
        backgroundColor: isDark
            ? theme.colorScheme.surface.withValues(alpha: 0.8)
            : Colors.white.withValues(alpha: 0.9),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DialogStyles.borderRadius),
          side: BorderSide(color: theme.dividerColor.withAlpha(20)),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Padding(
          padding: DialogStyles.contentPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [iconBgColor, iconBgColor.withValues(alpha: 0.5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withValues(alpha: 0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(child: Icon(iconData, color: iconColor, size: 34)),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 15,
                  height: 1.5,
                  color: theme.colorScheme.onSurface.withAlpha(170),
                ),
              ),
              const SizedBox(height: 32),
              if (isConfirm)
                Row(
                  children: [
                    Expanded(
                      child: _DialogButton(
                        label: cancelLabel ?? 'Cancelar',
                        isPrimary: false,
                        onTap: () => Navigator.pop(context, false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DialogButton(
                        label: confirmLabel ?? 'Confirmar',
                        isPrimary: true,
                        isDestructive: isDestructive,
                        accentColor: iconColor,
                        onTap: () => Navigator.pop(context, true),
                      ),
                    ),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: _DialogButton(
                    label: 'Entendido',
                    isPrimary: true,
                    accentColor: iconColor,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final bool isDestructive;
  final Color? accentColor;
  final VoidCallback onTap;

  const _DialogButton({
    required this.label,
    required this.isPrimary,
    this.isDestructive = false,
    this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = !isPrimary
        ? theme.colorScheme.onSurface.withAlpha(15)
        : isDestructive
            ? theme.colorScheme.error
            : accentColor ?? theme.colorScheme.primary;
    final fg = !isPrimary
        ? theme.colorScheme.onSurface
        : isDestructive
            ? Colors.white
            : theme.brightness == Brightness.dark
                ? const Color(0xFF090B0F)
                : Colors.white;

    return InkWell(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isPrimary
              ? [BoxShadow(color: bg.withValues(alpha: .3), blurRadius: 12, offset: const Offset(0, 4))]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.bold, color: fg, letterSpacing: .3),
        ),
      ),
    );
  }
}

class _ModernBottomSheet extends StatelessWidget {
  final Widget child;
  final bool scrollable;
  const _ModernBottomSheet({required this.child, required this.scrollable});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mq = MediaQuery.of(context);
    final dark = theme.brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          constraints: BoxConstraints(maxHeight: mq.size.height * .92),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: dark ? .85 : .9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: theme.dividerColor.withValues(alpha: .1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(width: 48, height: 4, decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(4))),
              ),
              scrollable ? Flexible(child: SingleChildScrollView(child: child)) : Flexible(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModernLoadingDialog extends StatefulWidget {
  final String message;
  const _ModernLoadingDialog({required this.message});

  @override
  State<_ModernLoadingDialog> createState() => _ModernLoadingDialogState();
}

class _ModernLoadingDialogState extends State<_ModernLoadingDialog> {
  Timer? _failsafe;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _failsafe = Timer(const Duration(seconds: 7), () {
      if (mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
    });
    _animateProgress();
  }

  Future<void> _animateProgress() async {
    const steps = 28;
    for (var i = 1; i <= steps; i++) {
      await Future.delayed(const Duration(milliseconds: 120));
      if (!mounted) return;
      setState(() => _progress = i / steps);
    }
  }

  @override
  void dispose() {
    _failsafe?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;

    return PopScope(
      canPop: false,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Center(
          child: Container(
            width: 292,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: theme.dividerColor.withValues(alpha: .08)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: dark ? .25 : .10), blurRadius: 34, offset: const Offset(0, 16))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(color: accent.withValues(alpha: .10), borderRadius: BorderRadius.circular(18)),
                  child: PivoteLoader(color: accent, strokeWidth: 3, size: 30),
                ),
                const SizedBox(height: 18),
                Text(widget.message, textAlign: TextAlign.center, style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, fontSize: 14.5)),
                const SizedBox(height: 13),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 5,
                    backgroundColor: accent.withValues(alpha: .08),
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                  ),
                ),
                const SizedBox(height: 9),
                Text('Podés esperar unos segundos mientras terminamos la comprobación.', textAlign: TextAlign.center, style: GoogleFonts.spaceGrotesk(fontSize: 10.5, fontWeight: FontWeight.w500, color: theme.hintColor, height: 1.35)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
