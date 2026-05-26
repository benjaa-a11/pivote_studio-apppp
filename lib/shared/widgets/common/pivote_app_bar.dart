import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pivote/core/theme/app_theme.dart';

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
    final isDark = theme.brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: height + topPadding,
          padding: EdgeInsets.fromLTRB(16, topPadding, 16, 0),
          decoration: BoxDecoration(
            color: isDark
                ? AppTheme.darkBg.withValues(alpha: 0.75)
                : AppTheme.lightBg.withValues(alpha: 0.8),
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? AppTheme.darkBorder.withValues(alpha: 0.4)
                    : AppTheme.lightBorder.withValues(alpha: 0.5),
                width: 1.2,
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
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.6,
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onBackPressed ?? () => Navigator.pop(context),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDark
                ? AppTheme.darkBg2.withValues(alpha: 0.5)
                : AppTheme.lightBg2.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? AppTheme.darkBorder.withValues(alpha: 0.3)
                  : AppTheme.lightBorder,
              width: 1,
            ),
          ),
          child: Center(
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 14,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
