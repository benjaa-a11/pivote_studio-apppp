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
import 'package:pivote/core/animations/app_animations.dart';

/// Unified premium header for the HomeScreen.
/// Merges user greetings, search triggers, and the matches hero carousel
/// into a single seamless card with rounded corners and gradients.
class UnifiedHomeHeader extends StatelessWidget {
  const UnifiedHomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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

        return AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      const Color(0xFF0F0E1B), // Midnight deep violet-black
                      const Color(0xFF07060F), // Absolute obsidian
                    ]
                  : [
                      const Color(0xFFF8FAFC), // Crisp clean gray-white
                      const Color(0xFFE8EEF5), // Light blue-gray tint
                    ],
            ),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(30),
            ),
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? AppTheme.darkBorder.withValues(alpha: 0.25)
                    : AppTheme.lightBorder.withValues(alpha: 0.5),
                width: 1.2,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Profile & Search Action Row
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Row(
                  children: [
                    // Greeting & User Name Info
                    Expanded(
                      child: Consumer<UserProvider>(
                        builder: (context, userProvider, child) {
                          final isUserLoading =
                              userProvider.isLoading || userProvider.user == null;
                          final name = userProvider.user?.name ?? 'Usuario Pro';

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    greeting,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.65),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    '👋',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Skeletonizer(
                                enabled: isUserLoading,
                                child: Text(
                                  name,
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: theme.colorScheme.onSurface,
                                    fontSize: 22,
                                    letterSpacing: -0.8,
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

                    // Modern Glassmorphic Search Trigger Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            AppAnimations.createFadeRoute(const SearchScreen()),
                          );
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? theme.colorScheme.primary.withValues(alpha: 0.08)
                                : theme.colorScheme.primary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: theme.colorScheme.primary.withValues(
                                  alpha: isDark ? 0.25 : 0.2),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(
                                    alpha: isDark ? 0.08 : 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Hero(
                            tag: 'search_icon',
                            child: Icon(
                              Icons.search_rounded,
                              size: 22,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Section: Matches Carousel OR Adapting Welcoming Banner
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
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

  Widget _buildWelcomingBanner(
      BuildContext context, ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  theme.colorScheme.primary.withValues(alpha: 0.12),
                  theme.colorScheme.secondary.withValues(alpha: 0.04),
                ]
              : [
                  theme.colorScheme.primary.withValues(alpha: 0.06),
                  theme.colorScheme.secondary.withValues(alpha: 0.02),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? theme.colorScheme.primary.withValues(alpha: 0.15)
              : theme.colorScheme.primary.withValues(alpha: 0.12),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          // Elegant Pulsing TV Icon
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

          // Message
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
