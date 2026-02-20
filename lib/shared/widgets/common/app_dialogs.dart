import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pivote/core/theme/app_theme.dart';

enum AppDialogType { success, error, warning, info }

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
      builder: (context) => _ModernDialog(
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
      builder: (context) => _ModernDialog(
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
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: scrollable ? SingleChildScrollView(child: child) : child,
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
      builder: (context) => PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
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

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIcon(),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              isConfirm
                  ? _buildConfirmActions(context)
                  : _buildAlertActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        Color color;
        IconData icon;
        switch (type) {
          case AppDialogType.success:
            color = isDark ? AppTheme.darkSuccess : AppTheme.lightSuccess;
            icon = Icons.check_circle_outline_rounded;
            break;
          case AppDialogType.error:
            color = isDark ? AppTheme.darkDanger : AppTheme.lightDanger;
            icon = Icons.error_outline_rounded;
            break;
          case AppDialogType.warning:
            color = isDark ? AppTheme.darkWarning : AppTheme.lightWarning;
            icon = Icons.warning_amber_rounded;
            break;
          case AppDialogType.info:
            color = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
            icon = Icons.info_outline_rounded;
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 40),
        );
      },
    );
  }

  Widget _buildConfirmActions(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              cancelLabel ?? 'Cancelar',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDestructive
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              confirmLabel ?? 'Confirmar',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAlertActions(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          'Aceptar',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
