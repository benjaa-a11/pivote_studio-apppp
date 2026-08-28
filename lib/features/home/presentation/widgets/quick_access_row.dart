import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/features/soccer/presentation/providers/soccer_provider.dart';
import 'package:pivote/shared/widgets/common/apple_pressable.dart';

/// Discovery row for the Home screen. Surfaces the three other content
/// pillars of the app (Fútbol, Películas, Radio) with real, live counts
/// instead of static icons — so Inicio feels like a hub, not just a
/// channel grid.
///
/// [onNavigateToTab] lets Home jump straight to the corresponding bottom
/// nav tab (indices match MainScreen._screens: 1=Fútbol, 2=Películas,
/// 4=Radio).
class QuickAccessRow extends StatelessWidget {
  final void Function(int tabIndex) onNavigateToTab;

  const QuickAccessRow({super.key, required this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.isDark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Consumer<SoccerProvider>(
              builder: (context, soccer, child) {
                final liveCount = soccer.soccerData?.matches
                        .where((m) => m.isLive)
                        .length ??
                    0;
                return _QuickAccessCard(
                  isDark: isDark,
                  icon: Icons.sports_soccer_rounded,
                  accent: const Color(0xFFE83600),
                  label: 'Fútbol',
                  caption: liveCount > 0
                      ? '$liveCount en vivo'
                      : 'Ver partidos',
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
              accent: Colors.pinkAccent,
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
      borderRadius: AppRadius.mAll,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          color: isDark
              ? AppTheme.darkBg2.withValues(alpha: 0.92)
              : Colors.white,
          borderRadius: AppRadius.mAll,
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
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
                      color: theme.colorScheme.error,
                      shape: BoxShape.circle,
                      boxShadow:
                          AppShadows.glow(theme.colorScheme.error, alpha: 0.6),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
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
              style: GoogleFonts.spaceGrotesk(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: isLive
                    ? theme.colorScheme.error
                    : (isDark ? AppTheme.darkText3 : AppTheme.lightText3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
