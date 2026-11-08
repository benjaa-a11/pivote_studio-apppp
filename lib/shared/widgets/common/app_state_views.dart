import 'package:flutter/material.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/shared/widgets/common/apple_pressable.dart';

/// Vista unificada del Design System para estados vacíos, errores de conexión
/// o mensajes sin resultados en listas y pantallas.
class AppStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final bool isError;
  final bool compact;

  const AppStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.isError = false,
    this.compact = false,
  });

  const AppStateView.empty({
    super.key,
    this.icon = Icons.inbox_rounded,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.compact = false,
  }) : isError = false;

  const AppStateView.error({
    super.key,
    this.icon = Icons.wifi_off_rounded,
    required this.title,
    required this.subtitle,
    this.actionLabel = 'Reintentar',
    this.actionIcon = Icons.refresh_rounded,
    this.onAction,
    this.compact = false,
  }) : isError = true;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final accentColor =
        isError ? AppTheme.danger(context) : AppTheme.accent(context);
    final surfaceColor = AppTheme.cardSurface(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: compact ? AppSpacing.xl : AppSpacing.xxxl,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Container(
            padding: EdgeInsets.all(compact ? 22 : 28),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(AppRadius.hero),
              border: AppBorders.card(context),
              boxShadow: AppShadows.appleDepth(context, elevation: 0.9),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: compact ? 56 : 68,
                  height: compact ? 56 : 68,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: isDark ? 0.12 : 0.09),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accentColor.withValues(alpha: isDark ? 0.28 : 0.2),
                      width: 1.2,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: compact ? 26 : 30,
                    color: accentColor,
                  ),
                ),
                SizedBox(height: compact ? 14 : 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppFont.primary(
                    fontSize: compact ? 16.5 : 18.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: AppTheme.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: AppFont.primary(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                    color: AppTheme.textSecondary(context),
                  ),
                ),
                if (onAction != null && actionLabel != null) ...[
                  const SizedBox(height: 20),
                  ApplePressable(
                    scaleDownFactor: 0.96,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    onTap: onAction,
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      decoration: BoxDecoration(
                        color: isError
                            ? AppTheme.danger(context)
                            : AppTheme.accent(context),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        boxShadow: AppShadows.glow(
                          isError
                              ? AppTheme.danger(context)
                              : AppTheme.accent(context),
                          alpha: 0.24,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (actionIcon != null) ...[
                            Icon(
                              actionIcon,
                              size: 18,
                              color: isError
                                  ? Colors.white
                                  : AppTheme.onAccent(context),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            actionLabel!,
                            style: AppFont.primary(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: isError
                                  ? Colors.white
                                  : AppTheme.onAccent(context),
                              letterSpacing: -0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Encabezado de sección unificado (inspirado en MatchesHero).
class AppSectionTitle extends StatelessWidget {
  final String title;
  final String? badgeText;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const AppSectionTitle({
    super.key,
    required this.title,
    this.badgeText,
    this.trailing,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final accent = AppTheme.accent(context);

    return Padding(
      padding: padding,
      child: Row(
        children: [
          Container(
            width: 3.5,
            height: 18,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                if (isDark)
                  BoxShadow(
                    color: accent.withValues(alpha: 0.35),
                    blurRadius: 8,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFont.primary(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                ),
                if (badgeText != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2.5,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: isDark ? 0.14 : 0.10),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: accent.withValues(alpha: isDark ? 0.28 : 0.22),
                      ),
                    ),
                    child: Text(
                      badgeText!,
                      style: AppFont.primary(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Chip / Píldora de filtro interactiva con estética unificada.
class AppFilterPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;
  final int? count;

  const AppFilterPill({
    super.key,
    required this.label,
    this.icon,
    required this.selected,
    required this.onTap,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final accent = AppTheme.accent(context);
    final onAccent = AppTheme.onAccent(context);

    return ApplePressable(
      scaleDownFactor: 0.95,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8.5),
        decoration: BoxDecoration(
          color: selected
              ? accent
              : (isDark ? AppTheme.darkBg2 : AppTheme.lightBg1),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: selected
                ? accent
                : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppTheme.lightBorder),
            width: 1,
          ),
          boxShadow: selected
              ? AppShadows.glow(accent, alpha: isDark ? 0.25 : 0.16)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 15,
                color: selected ? onAccent : AppTheme.textSecondary(context),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppFont.primary(
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                letterSpacing: -0.1,
                color: selected ? onAccent : AppTheme.textSecondary(context),
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: selected
                      ? onAccent.withValues(alpha: 0.16)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.07)
                          : Colors.black.withValues(alpha: 0.05)),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '$count',
                  style: AppFont.primary(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: selected ? onAccent : AppTheme.textTertiary(context),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

