import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/shared/widgets/common/apple_pressable.dart';

class PivoteAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final double height;

  const PivoteAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
    this.showBackButton = true,
    this.onBackPressed,
    this.height = 68,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.isDark;
    final topPadding = MediaQuery.of(context).padding.top;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppMaterials.blurRegular,
          sigmaY: AppMaterials.blurRegular,
        ),
        child: Container(
          height: height + topPadding,
          padding: EdgeInsets.fromLTRB(16, topPadding, 16, 0),
          decoration: BoxDecoration(
            color: isDark
                ? AppTheme.darkBg.withValues(alpha: 0.82)
                : AppTheme.lightBg1.withValues(alpha: 0.88),
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppTheme.lightBorder,
                width: 1.0,
              ),
            ),
          ),
          child: Row(
            children: [
              if (leading != null)
                leading!
              else if (showBackButton)
                _buildDefaultBackButton(context, isDark, theme)
              else
                const SizedBox(width: 4),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppFont.primary(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: theme.colorScheme.onSurface,
                        height: 1.12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppFont.primary(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textTertiary(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (actions != null) ...[
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: actions!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultBackButton(
    BuildContext context,
    bool isDark,
    ThemeData theme,
  ) {
    return ApplePressable(
      scaleDownFactor: 0.92,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: onBackPressed ?? () => Navigator.pop(context),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkBg2 : AppTheme.lightBg2,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.09)
                : AppTheme.lightBorder,
            width: 1.0,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 15,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
