import 'package:flutter/material.dart';
import 'package:pivote/core/theme/app_theme.dart';

enum AppDialogType { success, error, warning, info }

class DialogStyles {
  // Configuración general
  static const double borderRadius = 24.0;
  static const EdgeInsets contentPadding = EdgeInsets.fromLTRB(28, 32, 28, 28);

  static Color getIconColor(AppDialogType type, bool isDark) {
    switch (type) {
      case AppDialogType.success:
        return isDark ? AppTheme.darkSuccess : AppTheme.lightSuccess;
      case AppDialogType.error:
        return isDark ? AppTheme.darkDanger : AppTheme.lightDanger;
      case AppDialogType.warning:
        return isDark ? AppTheme.darkWarning : AppTheme.lightWarning;
      case AppDialogType.info:
        return isDark ? AppTheme.darkInfo : AppTheme.lightInfo;
    }
  }

  static Color getIconBgColor(AppDialogType type, bool isDark) {
    switch (type) {
      case AppDialogType.success:
        return isDark ? AppTheme.darkSuccessDim : AppTheme.lightSuccessDim;
      case AppDialogType.error:
        return isDark ? AppTheme.darkDangerDim : AppTheme.lightDangerDim;
      case AppDialogType.warning:
        return isDark ? AppTheme.darkWarningDim : AppTheme.lightWarningDim;
      case AppDialogType.info:
        return isDark ? AppTheme.darkInfoDim : AppTheme.lightInfoDim;
    }
  }

  static IconData getIcon(AppDialogType type) {
    switch (type) {
      case AppDialogType.success:
        return Icons.check_circle_outline_rounded;
      case AppDialogType.error:
        return Icons.error_outline_rounded;
      case AppDialogType.warning:
        return Icons.warning_amber_rounded;
      case AppDialogType.info:
        return Icons.info_outline_rounded;
    }
  }
}
