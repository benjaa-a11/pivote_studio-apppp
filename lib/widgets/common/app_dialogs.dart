import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppDialogType { success, warning, error, info }

class AppDialogs {
  /// Shows a clean, professional confirmation dialog.
  static Future<bool?> showConfirm({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Confirmar',
    String cancelLabel = 'Cancelar',
    AppDialogType type = AppDialogType.warning,
    bool isDestructive = false,
  }) {
    return _showAnimatedRawDialog<bool>(
      context: context,
      child: _BaseDialog(
        title: title,
        message: message,
        type: type,
        actions: [
          _DialogButton(
            label: cancelLabel,
            onPressed: () => Navigator.pop(context, false),
            isPrimary: false,
          ),
          _DialogButton(
            label: confirmLabel,
            onPressed: () => Navigator.pop(context, true),
            isPrimary: true,
            isDestructive: isDestructive || type == AppDialogType.error,
            color: _getTypeColor(type),
          ),
        ],
      ),
    );
  }

  /// Shows an informational alert dialog with a single button.
  static Future<void> showAlert({
    required BuildContext context,
    required String title,
    required String message,
    String buttonLabel = 'Entendido',
    AppDialogType type = AppDialogType.info,
  }) {
    return _showAnimatedRawDialog<void>(
      context: context,
      child: _BaseDialog(
        title: title,
        message: message,
        type: type,
        actions: [
          _DialogButton(
            label: buttonLabel,
            onPressed: () => Navigator.pop(context),
            isPrimary: true,
            color: _getTypeColor(type),
          ),
        ],
      ),
    );
  }

  /// Shows a professional loading overlay.
  static void showLoading({
    required BuildContext context,
    required String message,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, a1, a2) => PopScope(
        canPop: false,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Directionality(
                  textDirection: TextDirection.ltr,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                const SizedBox(height: 24),
                Text(
                  message,
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Shows a modern bottom sheet with a blurred background.
  static Future<T?> showModal<T>({
    required BuildContext context,
    required Widget child,
    double maxHeightMultiplier = 0.8,
  }) {
    final theme = Theme.of(context);

    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      elevation: 0,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * maxHeightMultiplier,
          ),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor.withValues(alpha: 0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Flexible(child: child),
            ],
          ),
        ),
      ),
    );
  }

  static Color _getTypeColor(AppDialogType type) {
    switch (type) {
      case AppDialogType.success:
        return const Color(0xFF2ECC71);
      case AppDialogType.warning:
        return const Color(0xFFF1C40F);
      case AppDialogType.error:
        return const Color(0xFFE74C3C);
      case AppDialogType.info:
        return const Color(0xFF3498DB);
    }
  }

  static Future<T?> _showAnimatedRawDialog<T>({
    required BuildContext context,
    required Widget child,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.7),
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, a1, a2, widget) {
        final curve = Curves.easeOutBack.transform(a1.value);
        return Transform.scale(
          scale: 0.9 + (0.1 * curve),
          child: FadeTransition(
            opacity: a1,
            child: widget,
          ),
        );
      },
      pageBuilder: (context, a1, a2) => child,
    );
  }
}

class _BaseDialog extends StatelessWidget {
  final String title;
  final String message;
  final AppDialogType type;
  final List<Widget> actions;

  const _BaseDialog({
    required this.title,
    required this.message,
    required this.type,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(32),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 15,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions.map((a) => Expanded(child: a)).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool isDestructive;
  final Color? color;

  const _DialogButton({
    required this.label,
    required this.onPressed,
    this.isPrimary = true,
    this.isDestructive = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!isPrimary) {
      return TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDestructive
              ? Colors.redAccent
              : (color ?? theme.colorScheme.primary),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
