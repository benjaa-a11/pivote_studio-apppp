import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/core/theme/dialog_styles.dart';
import 'package:pivote/shared/widgets/common/apple_pressable.dart';
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
      barrierColor: AppTheme.barrierColor(context),
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
      barrierColor: AppTheme.barrierColor(context),
      builder: (_) => _ModernDialog(
        title: title,
        message: message,
        type: type,
        isConfirm: false,
      ),
    );
  }

  /// Diálogo moderno con campo de texto integrado (recuperar clave, confirmar
  /// contraseña actual, etc.) con estética de cristal difuminado.
  static Future<String?> showInputDialog({
    required BuildContext context,
    required String title,
    required String message,
    required String hintText,
    String initialValue = '',
    String confirmLabel = 'Confirmar',
    String cancelLabel = 'Cancelar',
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    IconData icon = Icons.lock_outline_rounded,
  }) async {
    return showDialog<String>(
      context: context,
      barrierColor: AppTheme.barrierColor(context),
      builder: (_) => _ModernInputDialog(
        title: title,
        message: message,
        hintText: hintText,
        initialValue: initialValue,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        obscureText: obscureText,
        keyboardType: keyboardType,
        icon: icon,
      ),
    );
  }

  /// Bottom Sheet unificado de Pivote: cristal esmerilado, difuminación radial
  /// superior estilo MatchesHero, indicador de arrastre y soporte de teclado.
  static Future<T?> showModal<T>({
    required BuildContext context,
    required Widget child,
    bool scrollable = true,
    Color? glowColor,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: AppTheme.barrierColor(context),
      isScrollControlled: true,
      showDragHandle: false,
      useSafeArea: true,
      builder: (ctx) => _ModernBottomSheet(
        scrollable: scrollable,
        glowColor: glowColor,
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
      barrierColor: AppTheme.barrierColor(context),
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
    final isDark = AppTheme.isDark(context);
    final iconColor = isDestructive
        ? AppTheme.danger(context)
        : DialogStyles.getIconColor(type, isDark);
    final iconBgColor = isDestructive
        ? AppTheme.dangerDim(context)
        : DialogStyles.getIconBgColor(type, isDark);
    final iconData = DialogStyles.getIcon(type);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkBg1.withValues(alpha: 0.96)
                : AppColors.lightBg1.withValues(alpha: 0.98),
            borderRadius: BorderRadius.circular(DialogStyles.borderRadius),
            border: Border.all(color: AppTheme.borderStrong(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.58 : 0.16),
                blurRadius: 36,
                spreadRadius: -8,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0.0, -1.05),
                        radius: 1.15,
                        colors: [
                          iconColor.withValues(alpha: isDark ? 0.22 : 0.12),
                          iconColor.withValues(alpha: 0.0),
                        ],
                        stops: const [0.0, 0.72],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: DialogStyles.contentPadding,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: iconBgColor,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(
                          color: iconColor.withValues(alpha: 0.30),
                          width: 1.1,
                        ),
                      ),
                      child: Center(
                        child: Icon(iconData, color: iconColor, size: 28),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: AppFont.primary(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.35,
                        color: AppTheme.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: AppFont.primary(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        height: 1.48,
                        color: AppTheme.textSecondary(context),
                      ),
                    ),
                    const SizedBox(height: 24),
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
                          const SizedBox(width: 10),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _ModernInputDialog extends StatefulWidget {
  final String title;
  final String message;
  final String hintText;
  final String initialValue;
  final String confirmLabel;
  final String cancelLabel;
  final bool obscureText;
  final TextInputType keyboardType;
  final IconData icon;

  const _ModernInputDialog({
    required this.title,
    required this.message,
    required this.hintText,
    required this.initialValue,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.obscureText,
    required this.keyboardType,
    required this.icon,
  });

  @override
  State<_ModernInputDialog> createState() => _ModernInputDialogState();
}

class _ModernInputDialogState extends State<_ModernInputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final accent = AppTheme.accent(context);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 22),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkBg1.withValues(alpha: 0.96)
                : AppColors.lightBg1.withValues(alpha: 0.98),
            borderRadius: BorderRadius.circular(DialogStyles.borderRadius),
            border: Border.all(color: AppTheme.borderStrong(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.58 : 0.16),
                blurRadius: 36,
                spreadRadius: -8,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0.0, -1.1),
                        radius: 1.1,
                        colors: [
                          accent.withValues(alpha: isDark ? 0.18 : 0.10),
                          accent.withValues(alpha: 0.0),
                        ],
                        stops: const [0.0, 0.72],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppTheme.accentDim(context),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.30),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Icon(widget.icon, size: 20, color: accent),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.title,
                            style: AppFont.primary(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: AppTheme.textPrimary(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.message,
                      style: AppFont.primary(
                        fontSize: 13.5,
                        height: 1.45,
                        color: AppTheme.textSecondary(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _controller,
                      autofocus: true,
                      obscureText: widget.obscureText,
                      keyboardType: widget.keyboardType,
                      style: AppFont.primary(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary(context),
                      ),
                      decoration: InputDecoration(
                        hintText: widget.hintText,
                        filled: true,
                        fillColor: AppTheme.surface2(context),
                      ),
                      onSubmitted: (val) => Navigator.pop(context, val),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _DialogButton(
                            label: widget.cancelLabel,
                            isPrimary: false,
                            onTap: () => Navigator.pop(context),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _DialogButton(
                            label: widget.confirmLabel,
                            isPrimary: true,
                            accentColor: accent,
                            onTap: () =>
                                Navigator.pop(context, _controller.text),
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
    final bg = !isPrimary
        ? AppTheme.surface2(context)
        : isDestructive
            ? AppTheme.danger(context)
            : accentColor ?? AppTheme.accent(context);
    final fg = !isPrimary
        ? AppTheme.textPrimary(context)
        : isDestructive
            ? Colors.white
            : (bg.computeLuminance() > 0.45
                ? AppColors.onDarkAccent
                : Colors.white);

    return ApplePressable(
      scaleDownFactor: 0.96,
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: !isPrimary
              ? Border.all(color: AppTheme.border(context))
              : null,
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: bg.withValues(alpha: 0.24),
                    blurRadius: 14,
                    spreadRadius: -2,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppFont.primary(
            fontSize: 14,
            fontWeight: FontWeight.w800,
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
  final Color? glowColor;

  const _ModernBottomSheet({
    required this.child,
    required this.scrollable,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isDark = AppTheme.isDark(context);
    final glow = glowColor ?? AppTheme.accent(context);

    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            constraints: BoxConstraints(maxHeight: mq.size.height * 0.90),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkBg1.withValues(alpha: 0.92)
                  : AppColors.lightBg1.withValues(alpha: 0.96),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.xl),
              ),
              border: Border(
                top: BorderSide(
                  color: AppTheme.borderStrong(context),
                  width: 1.0,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.65 : 0.16),
                  blurRadius: 40,
                  offset: const Offset(0, -12),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Difuminación ambiental superior estilo MatchesHero
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0.0, -1.15),
                          radius: 1.15,
                          colors: [
                            glow.withValues(alpha: isDark ? 0.16 : 0.085),
                            glow.withValues(alpha: 0.0),
                          ],
                          stops: const [0.0, 0.68],
                        ),
                      ),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 8),
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.borderStrong(context),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                    ),
                    scrollable
                        ? Flexible(
                            child: SingleChildScrollView(
                              physics: const ClampingScrollPhysics(),
                              child: child,
                            ),
                          )
                        : Flexible(child: child),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModernLoadingDialog extends StatelessWidget {
  final String message;

  const _ModernLoadingDialog({required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final accent = AppTheme.accent(context);

    return PopScope(
      canPop: false,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Center(
          child: Container(
            width: 288,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBg1 : AppColors.lightBg1,
              borderRadius: BorderRadius.circular(AppRadius.hero),
              border: Border.all(color: AppTheme.borderStrong(context)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
                  blurRadius: 32,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.accentDim(context),
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                  child: PivoteLoader(color: accent, strokeWidth: 3, size: 28),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppFont.primary(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppTheme.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    value: null,
                    minHeight: 4,
                    backgroundColor: AppTheme.surface2(context),
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
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
