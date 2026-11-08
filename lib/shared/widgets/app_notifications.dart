import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/core/theme/dialog_styles.dart';

class AppNotifications {
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

  static void showSnackBar({
    required BuildContext context,
    required String message,
    AppDialogType type = AppDialogType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final iconColor = DialogStyles.getIconColor(type, isDark);
    final iconData = DialogStyles.getIcon(type);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: duration,
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        padding: EdgeInsets.zero,
        content: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.darkBg2.withValues(alpha: 0.92)
                    : AppTheme.lightBg1.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(
                  color: iconColor.withValues(alpha: isDark ? 0.35 : 0.28),
                  width: 1.1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(iconData, color: iconColor, size: 19),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: AppFont.primary(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                        height: 1.35,
                      ),
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
