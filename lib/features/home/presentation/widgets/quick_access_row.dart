import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/features/soccer/presentation/providers/soccer_provider.dart';
import 'package:pivote/shared/widgets/common/apple_pressable.dart';

class QuickAccessRow extends StatelessWidget {
  final void Function(int tabIndex) onNavigateToTab;

  const QuickAccessRow({super.key, required this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.isDark;
    final hPad = AppResponsive.screenHorizontalPadding(context);

    return Padding(
      padding: hPad.add(
        const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.sm),
      ),
      child: Row(
        children: [
          Expanded(
            child: Consumer<SoccerProvider>(
              builder: (context, soccer, child) {
                final liveCount =
                    soccer.soccerData?.matches.where((m) => m.isLive).length ??
                        0;
                return _QuickAccessCard(
                  isDark: isDark,
                  icon: Icons.sports_soccer_rounded,
                  accent: AppColors.live,
                  label: 'Fútbol',
                  caption:
                      liveCount > 0 ? '$liveCount en vivo' : 'Ver partidos',
                  isLive: liveCount > 0,
                  onTap: () => onNavigateToTab(0),
                );
              },
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _QuickAccessCard(
              isDark: isDark,
              icon: Icons.favorite_rounded,
              accent: AppColors.violet,
              label: 'Favoritos',
              caption: 'Tus guardados',
              onTap: () => onNavigateToTab(1),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _QuickAccessCard(
              isDark: isDark,
              icon: Icons.radio_rounded,
              accent: theme.colorScheme.secondary,
              label: 'Radio',
              caption: 'En vivo 24h',
              onTap: () => onNavigateToTab(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color accent;
  final String label;
  final String caption;
  final bool isLive;
  final VoidCallback onTap;

  const _QuickAccessCard({
    required this.isDark,
    required this.icon,
    required this.accent,
    required this.label,
    required this.caption,
    required this.onTap,
    this.isLive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ApplePressable(
      scaleDownFactor: 0.95,
      borderRadius: AppRadius.cardAll,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkBg2 : AppTheme.lightBg1,
          borderRadius: AppRadius.cardAll,
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : AppTheme.lightBorder,
            width: 1.0,
          ),
          boxShadow: AppShadows.appleDepth(context, elevation: 0.7),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: isDark ? 0.18 : 0.12),
                    borderRadius: AppRadius.sAll,
                  ),
                  child: Icon(icon, size: 18, color: accent),
                ),
                if (isLive)
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: AppColors.live,
                      shape: BoxShape.circle,
                      boxShadow: AppShadows.glow(AppColors.live, alpha: 0.6),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: AppFont.primary(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFont.primary(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: isLive
                    ? AppColors.live
                    : AppTheme.textTertiary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
