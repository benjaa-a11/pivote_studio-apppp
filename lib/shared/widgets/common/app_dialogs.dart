import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/core/theme/dialog_styles.dart';
import 'package:pivote/shared/widgets/common/pivote_loader.dart';
import 'package:pivote/shared/widgets/common/apple_pressable.dart';

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
      showDragHandle: false,
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
      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
      child: Dialog(
        backgroundColor: isDark
            ? AppTheme.darkBg2.withValues(alpha: 0.94)
            : AppTheme.lightBg1.withValues(alpha: 0.96),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DialogStyles.borderRadius),
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.09)
                : AppTheme.lightBorder,
          ),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Padding(
          padding: DialogStyles.contentPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [iconBgColor, iconBgColor.withValues(alpha: 0.5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: iconColor.withValues(alpha: 0.24),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withValues(alpha: 0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child:
                    Center(child: Icon(iconData, color: iconColor, size: 32)),
              ),
              const SizedBox(height: 22),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppFont.primary(
                  fontSize: 19.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.35,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppFont.primary(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.48,
                  color: AppTheme.textSecondary(context),
                ),
              ),
              const SizedBox(height: 28),
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
    final isDark = theme.brightness == Brightness.dark;
    final bg = !isPrimary
        ? (isDark ? AppTheme.darkBg3 : AppTheme.lightBg2)
        : isDestructive
            ? theme.colorScheme.error
            : accentColor ?? theme.colorScheme.primary;
    final fg = !isPrimary
        ? theme.colorScheme.onSurface
        : isDestructive
            ? Colors.white
            : (bg.computeLuminance() > 0.45
                ? AppColors.onDarkAccent
                : Colors.white);

    return ApplePressable(
      scaleDownFactor: 0.96,
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: !isPrimary
              ? Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : AppTheme.lightBorder,
                )
              : null,
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: bg.withValues(alpha: 0.26),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppFont.primary(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: fg,
            letterSpacing: -0.15,
          ),
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
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadius.xl),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          constraints: BoxConstraints(maxHeight: mq.size.height * 0.92),
          decoration: BoxDecoration(
            color: (dark ? AppTheme.darkBg1 : AppTheme.lightBg1)
                .withValues(alpha: dark ? 0.94 : 0.96),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl),
            ),
            border: Border(
              top: BorderSide(
                color: dark
                    ? Colors.white.withValues(alpha: 0.10)
                    : AppTheme.lightBorder,
                width: 1.0,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 8),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              scrollable
                  ? Flexible(child: SingleChildScrollView(child: child))
                  : Flexible(child: child),
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
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;

    return PopScope(
      canPop: false,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Center(
          child: Container(
            width: 292,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
            decoration: BoxDecoration(
              color: dark ? AppTheme.darkBg2 : AppTheme.lightBg1,
              borderRadius: BorderRadius.circular(AppRadius.hero),
              border: Border.all(
                color: dark
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppTheme.lightBorder,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: dark ? 0.35 : 0.10),
                  blurRadius: 32,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                  child: PivoteLoader(color: accent, strokeWidth: 3, size: 30),
                ),
                const SizedBox(height: 18),
                Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: AppFont.primary(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    value: null,
                    minHeight: 5,
                    backgroundColor: accent.withValues(alpha: 0.10),
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Este proceso puede tardar un momento. La ventana se cerrará cuando termine.',
                  textAlign: TextAlign.center,
                  style: AppFont.primary(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textTertiary(context),
                    height: 1.38,
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
