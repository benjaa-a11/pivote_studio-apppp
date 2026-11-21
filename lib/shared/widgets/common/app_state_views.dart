import 'package:flutter/material.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/shared/widgets/common/apple_pressable.dart';
import 'package:pivote/shared/widgets/common/pivote_surfaces.dart';

/// Vista unificada del Design System para estados vacíos y errores con
/// difuminación radial inspirada en `MatchesHero`.
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
    final accentColor =
        isError ? AppTheme.danger(context) : AppTheme.accent(context);
    final badgeBg =
        isError ? AppTheme.dangerDim(context) : AppTheme.accentDim(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: compact ? AppSpacing.lg : AppSpacing.xxl,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: PivoteDiffusedCard(
            borderRadius: AppRadius.hero,
            glowColor: accentColor,
            glowAlignment: const Alignment(0.0, -0.9),
            glowOpacity: 1.25,
            padding: EdgeInsets.all(compact ? 22 : 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: compact ? 54 : 64,
                  height: compact ? 54 : 64,
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.30),
                      width: 1.1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: compact ? 25 : 29,
                    color: accentColor,
                  ),
                ),
                SizedBox(height: compact ? 14 : 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppFont.primary(
                    fontSize: compact ? 16.5 : 18,
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
                        color: accentColor,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        boxShadow: AppShadows.glow(accentColor, alpha: 0.22),
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

/// Alias compatible que delega a `PivoteSectionHeader`.
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
    return PivoteSectionHeader(
      title: title,
      badgeText: badgeText,
      trailing: trailing,
      padding: padding,
    );
  }
}

/// Alias compatible que delega a `PivoteFilterPill`.
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
    return PivoteFilterPill(
      label: label,
      icon: icon,
      selected: selected,
      onTap: onTap,
      count: count,
    );
  }
}
