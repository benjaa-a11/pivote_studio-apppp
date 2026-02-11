import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum DialogType { success, warning, error, info }

class CustomDialogs {
  static Future<T?> showConfirmDialog<T>(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirmar',
    String cancelLabel = 'Cancelar',
    DialogType type = DialogType.warning,
    bool isDestructive = false,
  }) {
    return _showAnimatedDialog<T>(
      context,
      ModernAppDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        type: type,
        isDestructive: isDestructive || type == DialogType.error,
        showCancel: true,
        onConfirm: () => Navigator.pop(context, true as T),
        onCancel: () => Navigator.pop(context, false as T),
      ),
    );
  }

  static Future<void> showAlertDialog(
    BuildContext context, {
    required String title,
    required String message,
    String buttonLabel = 'Entendido',
    DialogType type = DialogType.info,
    VoidCallback? onPressed,
  }) {
    return _showAnimatedDialog<void>(
      context,
      ModernAppDialog(
        title: title,
        message: message,
        confirmLabel: buttonLabel,
        cancelLabel: '',
        type: type,
        isDestructive: false,
        showCancel: false,
        onConfirm: () {
          Navigator.pop(context);
          onPressed?.call();
        },
        onCancel: () {},
      ),
    );
  }

  static Future<T?> showLoadingDialog<T>(
    BuildContext context, {
    required String message,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.7),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, a1, a2) => const SizedBox.shrink(),
      transitionBuilder: (context, a1, a2, child) {
        final curvedValue = Curves.easeOutBack.transform(a1.value);
        return Transform.scale(
          scale: 0.92 + (0.08 * curvedValue),
          child: FadeTransition(
            opacity: a1,
            child: ModernLoadingDialog(message: message),
          ),
        );
      },
    );
  }

  static Future<T?> _showAnimatedDialog<T>(
      BuildContext context, Widget dialog) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.7),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, a1, a2) => const SizedBox.shrink(),
      transitionBuilder: (context, a1, a2, child) {
        final curvedValue = Curves.easeOutBack.transform(a1.value);
        return Transform.scale(
          scale: 0.92 + (0.08 * curvedValue),
          child: FadeTransition(
            opacity: a1,
            child: dialog,
          ),
        );
      },
    );
  }

  static Future<T?> showModernModalBottomSheet<T>(
    BuildContext context, {
    required Widget child,
    String? title,
    IconData? titleIcon,
    Color? iconColor,
    bool isScrollControlled = true,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
            border: Border(
              top: BorderSide(
                color: (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: 0.05),
                width: 1,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              if (title != null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Row(
                    children: [
                      if (titleIcon != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (iconColor ?? theme.colorScheme.primary)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            titleIcon,
                            color: iconColor ?? theme.colorScheme.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor:
                              (isDark ? Colors.white : Colors.black)
                                  .withValues(alpha: 0.05),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Flexible(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class ModernAppDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final DialogType type;
  final bool isDestructive;
  final bool showCancel;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const ModernAppDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    this.type = DialogType.warning,
    this.isDestructive = false,
    this.showCancel = true,
    required this.onConfirm,
    required this.onCancel,
  });

  Color _getTypeColor(BuildContext context) {
    switch (type) {
      case DialogType.success:
        return const Color(0xFF00C853);
      case DialogType.warning:
        return const Color(0xFFFFAB00);
      case DialogType.error:
        return const Color(0xFFFF3D00);
      case DialogType.info:
        return Theme.of(context).colorScheme.primary;
    }
  }

  IconData _getTypeIcon() {
    switch (type) {
      case DialogType.success:
        return Icons.check_circle_rounded;
      case DialogType.warning:
        return Icons.warning_amber_rounded;
      case DialogType.error:
        return Icons.error_outline_rounded;
      case DialogType.info:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = _getTypeColor(context);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          constraints: const BoxConstraints(maxWidth: 360),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.15),
                blurRadius: 50,
                spreadRadius: -10,
              ),
            ],
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      _getTypeIcon(),
                      size: 36,
                      color: primaryColor,
                    ),
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Column(
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: -0.5,
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
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Buttons
                    Row(
                      children: [
                        if (showCancel) ...[
                          Expanded(
                            child: TextButton(
                              onPressed: onCancel,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                foregroundColor: theme.colorScheme.onSurface,
                              ),
                              child: Text(
                                cancelLabel,
                                style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: ElevatedButton(
                            onPressed: onConfirm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              shadowColor: primaryColor.withValues(alpha: 0.5),
                            ),
                            child: Text(
                              confirmLabel,
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ModernLoadingDialog extends StatelessWidget {
  final String message;

  const ModernLoadingDialog({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          constraints: const BoxConstraints(maxWidth: 320),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
