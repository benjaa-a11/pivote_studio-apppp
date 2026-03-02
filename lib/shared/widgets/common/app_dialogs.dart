import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pivote/core/theme/dialog_styles.dart';

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
      barrierColor: Colors.black.withAlpha(153), // 0.6
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
      barrierColor: Colors.black.withAlpha(140), // 0.55
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
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Dialog(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DialogStyles.borderRadius),
          side: BorderSide(
            color: theme.dividerColor.withAlpha(20),
            width: 1,
          ),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Padding(
          padding: DialogStyles.contentPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Badge
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    iconData,
                    color: iconColor,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.syne(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              // Message
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  height: 1.5,
                  color: theme.colorScheme.onSurface.withAlpha(170), // ~0.65
                ),
              ),
              const SizedBox(height: 32),
              // Actions
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

    Color getBgColor() {
      if (!isPrimary) return theme.colorScheme.onSurface.withAlpha(15);
      if (isDestructive) return theme.colorScheme.error;
      return accentColor ?? theme.colorScheme.primary;
    }

    Color getTextColor() {
      if (!isPrimary) return theme.colorScheme.onSurface;
      if (isDestructive) return Colors.white;
      // In primary button with accent tint
      return theme.brightness == Brightness.dark &&
              (accentColor == theme.colorScheme.primary ||
                  accentColor == const Color(0xFFC8FF47))
          ? const Color(0xFF090B0F)
          : Colors.white;
    }

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: getBgColor(),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: getTextColor(),
          ),
        ),
      ),
    );
  }
}

class _ModernBottomSheet extends StatelessWidget {
  final Widget child;
  final bool scrollable;

  const _ModernBottomSheet({
    required this.child,
    required this.scrollable,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mq = MediaQuery.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: mq.size.height * 0.92,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(4),
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

class _ModernLoadingDialog extends StatelessWidget {
  final String message;

  const _ModernLoadingDialog({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: theme.dividerColor.withAlpha(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                  strokeWidth: 3,
                ),
                const SizedBox(height: 24),
                Text(
                  message,
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
