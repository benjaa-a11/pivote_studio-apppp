import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
                ? AppTheme.darkBg.withValues(alpha: 0.78)
                : AppTheme.lightBg.withValues(alpha: 0.82),
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
                width: 1.0,
              ),
            ),
          ),
          child: Row(
            children: [
              // Leading section (Default back button or custom leading)
              if (leading != null)
                leading!
              else if (showBackButton)
                _buildDefaultBackButton(context, isDark, theme)
              else
                const SizedBox(width: 8),

              const SizedBox(width: 14),

              // Title and Subtitle section
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: theme.colorScheme.onSurface,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppTheme.darkText3 : AppTheme.lightText3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Actions section
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
      BuildContext context, bool isDark, ThemeData theme) {
    return ApplePressable(
      scaleDownFactor: 0.92,
      borderRadius: BorderRadius.circular(14),
      onTap: onBackPressed ?? () => Navigator.pop(context),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark
              ? AppTheme.darkBg2.withValues(alpha: 0.70)
              : AppTheme.lightBg2.withValues(alpha: 0.70),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.black.withValues(alpha: 0.06),
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
