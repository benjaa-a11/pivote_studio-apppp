import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pivote/features/home/presentation/screens/search_screen.dart';
import 'package:pivote/features/home/presentation/screens/notifications_screen.dart';
import 'package:pivote/features/soccer/presentation/providers/soccer_provider.dart';
import 'package:pivote/features/soccer/data/models/soccer_models.dart';
import 'package:pivote/features/soccer/presentation/widgets/matches_hero.dart';
import 'package:pivote/shared/widgets/common/user_avatar.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/features/home/presentation/widgets/category_chips_row.dart';

/// Header premium 2026 para HomeScreen.
/// Estructura:
/// 1. Barra superior plana (no flotante): Avatar → centro limpio → Lupa + Campana.
/// 2. Sección de chips de categoría.
/// 3. Hero de partidos (solo si hay partidos; si no hay, no se muestra nada).
class UnifiedHomeHeader extends StatelessWidget {
  /// Callback para navegar a un tab específico del bottom nav.
  final void Function(int tabIndex)? onNavigateToTab;

  const UnifiedHomeHeader({super.key, this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.isDark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Barra superior plana ───
        _buildTopBar(context, theme, isDark),

        // ─── Chips de categoría ───
        const Padding(
          padding: EdgeInsets.only(top: 6, bottom: 2),
          child: CategoryChipsRow(),
        ),

        // ─── Hero de partidos (solo si hay) ───
        _buildMatchesSection(),
      ],
    );
  }

  /// Barra superior: avatar | centro limpio | iconos
  Widget _buildTopBar(BuildContext context, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          // Avatar con navegación a perfil
          UserAvatar(
            size: 40,
            showBorder: true,
            onTap: () {
              if (onNavigateToTab != null) {
                onNavigateToTab!(2); // Índice del tab Perfil
              }
            },
          ),

          // Centro limpio — sin texto ni dot
          const Expanded(child: SizedBox.shrink()),

          // Iconos de acción
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeaderIconButton(
                context: context,
                theme: theme,
                isDark: isDark,
                icon: Icons.search_rounded,
                heroTag: 'search_icon',
                onTap: () {
                  Navigator.push(
                    context,
                    AppAnimations.createFadeRoute(const SearchScreen()),
                  );
                },
              ),
              const SizedBox(width: 8),
              _buildHeaderIconButton(
                context: context,
                theme: theme,
                isDark: isDark,
                icon: Icons.notifications_none_rounded,
                heroTag: 'notification_icon',
                onTap: () {
                  Navigator.push(
                    context,
                    AppAnimations.createFadeRoute(
                        const NotificationsScreen()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Sección de partidos: solo aparece si hay partidos (o cargando).
  /// Si no hay partidos, no muestra nada.
  Widget _buildMatchesSection() {
    return Consumer<SoccerProvider>(
      builder: (context, soccerProvider, child) {
        final isLoading = soccerProvider.isLoading;
        final soccerData = soccerProvider.soccerData;

        List<SoccerMatch> featuredMatches = [];
        if (!isLoading && soccerData != null) {
          featuredMatches = soccerData.matches.where((match) {
            if (match.shouldRemoveFromHero || match.isAutoFinished) return false;
            final isFeatured = match.isLive ||
                match.isScheduled ||
                (match.isFinished && !match.shouldRemoveFromHero);
            if (!isFeatured) return false;
            return match.tvChannels.any((c) => c.id != null);
          }).toList();
        }

        final hasMatches = isLoading || featuredMatches.isNotEmpty;

        if (!hasMatches) {
          return const SizedBox.shrink();
        }

        return const Padding(
          padding: EdgeInsets.only(top: 4),
          child: MatchesHero(),
        );
      },
    );
  }

  Widget _buildHeaderIconButton({
    required BuildContext context,
    required ThemeData theme,
    required bool isDark,
    required IconData icon,
    required String heroTag,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDark
                ? AppTheme.darkBg2
                : theme.colorScheme.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : theme.colorScheme.primary.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Hero(
            tag: heroTag,
            child: Icon(
              icon,
              size: 20,
              color: isDark ? AppTheme.darkAccent : theme.colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}
