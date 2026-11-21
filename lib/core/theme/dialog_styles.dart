import 'package:flutter/material.dart';
import 'package:pivote/core/theme/app_theme.dart';

enum AppDialogType { success, error, warning, info }

class DialogStyles {
  static const double borderRadius = 26.0;
  static const EdgeInsets contentPadding = EdgeInsets.fromLTRB(24, 28, 24, 24);

  /// Estrictamente acotado a la paleta de 3 colores:
  /// - success / info -> Acento de marca
  /// - error / warning -> Señal carmesí (o tono de acento suave)
  static Color getIconColor(AppDialogType type, bool isDark) {
    switch (type) {
      case AppDialogType.success:
      case AppDialogType.info:
        return isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
      case AppDialogType.error:
        return isDark ? AppTheme.darkDanger : AppTheme.lightDanger;
      case AppDialogType.warning:
        return isDark ? AppTheme.darkDanger : AppTheme.lightDanger;
    }
  }

  static Color getIconBgColor(AppDialogType type, bool isDark) {
    switch (type) {
      case AppDialogType.success:
      case AppDialogType.info:
        return isDark ? AppTheme.darkAccentDim : AppTheme.lightAccentDim;
      case AppDialogType.error:
      case AppDialogType.warning:
        return isDark ? AppTheme.darkDangerDim : AppTheme.lightDangerDim;
    }
  }

  static IconData getIcon(AppDialogType type) {
    switch (type) {
      case AppDialogType.success:
        return Icons.check_circle_rounded;
      case AppDialogType.error:
        return Icons.error_rounded;
      case AppDialogType.warning:
        return Icons.warning_amber_rounded;
      case AppDialogType.info:
        return Icons.info_rounded;
    }
  }
}
