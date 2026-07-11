import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:pivote/features/auth/presentation/providers/user_provider.dart';
import 'package:pivote/features/home/presentation/screens/search_screen.dart';
import 'package:pivote/features/soccer/presentation/providers/soccer_provider.dart';
import 'package:pivote/features/soccer/data/models/soccer_models.dart';
import 'package:pivote/features/soccer/presentation/widgets/matches_hero.dart';
import 'package:pivote/core/services/greeting_service.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/core/animations/app_animations.dart';

/// Header premium unificado para HomeScreen.
/// Une avatar, saludo, acceso a búsqueda y el carrusel de partidos en una
/// sola superficie continua, con jerarquía tipográfica clara y curvas
/// consistentes con el resto del sistema de diseño (squircle / iOS-like).
class UnifiedHomeHeader extends StatelessWidget {
  const UnifiedHomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.isDark;
    final greeting = GreetingService.getGreeting();

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

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: AppGradients.backdrop(isDark),
            borderRadius: AppRadius.bottomXxl,
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? AppTheme.darkBorder.withValues(alpha: 0.25)
                    : AppTheme.lightBorder.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Fila superior: avatar + saludo + acceso a búsqueda
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.lg),
                child: Row(
                  children: [
                    _buildAvatar(context, theme, isDark),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Consumer<UserProvider>(
                        builder: (context, userProvider, child) {
                          final isUserLoading = userProvider.isLoading ||
                              userProvider.user == null;
                          final name = userProvider.user?.name ?? 'Usuario Pro';

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                greeting.toUpperCase(),
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Skeletonizer(
                                enabled: isUserLoading,
                                child: Text(
                                  name,
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: theme.colorScheme.onSurface,
                                    fontSize: 21,
                                    letterSpacing: -0.7,
                                    height: 1.1,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildSearchButton(context, theme, isDark),
                  ],
                ),
              ),

              // Carrusel de partidos o banner de bienvenida
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                child: hasMatches
                    ? const MatchesHero()
                    : _buildWelcomingBanner(context, theme, isDark),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatar(BuildContext context, ThemeData theme, bool isDark) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: isDark ? 0.28 : 0.16),
            theme.colorScheme.secondary.withValues(alpha: isDark ? 0.12 : 0.06),
          ],
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.3 : 0.18),
          width: 1.2,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.person_rounded,
        size: 22,
        color: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildSearchButton(BuildContext context, ThemeData theme, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            AppAnimations.createFadeRoute(const SearchScreen()),
          );
        },
        borderRadius: AppRadius.mAll,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: isDark
                ? theme.colorScheme.primary.withValues(alpha: 0.09)
                : theme.colorScheme.primary.withValues(alpha: 0.06),
            borderRadius: AppRadius.mAll,
            border: Border.all(
              color:
                  theme.colorScheme.primary.withValues(alpha: isDark ? 0.25 : 0.18),
              width: 1.2,
            ),
          ),
          alignment: Alignment.center,
          child: Hero(
            tag: 'search_icon',
            child: Icon(
              Icons.search_rounded,
              size: 21,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomingBanner(
      BuildContext context, ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: AppGradients.accentGlass(context, isDark: isDark),
        borderRadius: AppRadius.lAll,
        border: Border.all(
          color: isDark
              ? theme.colorScheme.primary.withValues(alpha: 0.15)
              : theme.colorScheme.primary.withValues(alpha: 0.12),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.live_tv_rounded,
              color: theme.colorScheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Pivote Studio',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.primary,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'El mejor contenido en vivo, deportes, películas y radios en un solo lugar.',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
