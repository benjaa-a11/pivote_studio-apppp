import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/features/home/presentation/providers/notifications_provider.dart';
import 'package:pivote/features/home/presentation/screens/notifications_screen.dart';
import 'package:pivote/features/home/presentation/screens/search_screen.dart';
import 'package:pivote/features/home/presentation/widgets/category_chips_row.dart';
import 'package:pivote/features/soccer/data/models/soccer_models.dart';
import 'package:pivote/features/soccer/presentation/providers/soccer_provider.dart';
import 'package:pivote/features/soccer/presentation/widgets/matches_hero.dart';
import 'package:pivote/shared/widgets/common/loading_shimmer.dart';
import 'package:pivote/shared/widgets/common/pivote_surfaces.dart';
import 'package:pivote/shared/widgets/common/user_avatar.dart';

class UnifiedHomeHeader extends StatelessWidget {
  final void Function(int tabIndex)? onNavigateToTab;

  const UnifiedHomeHeader({super.key, this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTopBar(context),
        const Padding(
          padding: EdgeInsets.only(top: 4, bottom: 4),
          child: CategoryChipsRow(),
        ),
        _buildMatchesSection(),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final hPad = AppResponsive.screenHorizontalPadding(context);

    return Padding(
      padding: hPad.add(const EdgeInsets.symmetric(vertical: 10)),
      child: Row(
        children: [
          UserAvatar(
            size: 40,
            showBorder: true,
            onTap: () => onNavigateToTab?.call(3),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Pivote',
                  style: AppFont.primary(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.55,
                    height: 1.08,
                    color: AppTheme.textPrimary(context),
                  ),
                ),
                Text(
                  'TV & Deportes en vivo',
                  style: AppFont.primary(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textTertiary(context),
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PivoteIconButton(
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
              Consumer<NotificationsProvider>(
                builder: (context, notifications, _) {
                  final unread = notifications.unreadCount;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      PivoteIconButton(
                        icon: unread > 0
                            ? Icons.notifications_active_rounded
                            : Icons.notifications_none_rounded,
                        heroTag: 'notification_icon',
                        onTap: () {
                          Navigator.push(
                            context,
                            AppAnimations.createFadeRoute(
                              const NotificationsScreen(),
                            ),
                          );
                        },
                      ),
                      if (unread > 0)
                        Positioned(
                          right: -3,
                          top: -4,
                          child: Container(
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.danger(context),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                              border: Border.all(
                                color: AppTheme.bg(context),
                                width: 2,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              unread > 99 ? '99+' : '$unread',
                              style: AppFont.mono(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMatchesSection() {
    return Consumer<SoccerProvider>(
      builder: (context, soccerProvider, child) {
        final isLoading = soccerProvider.isLoading;
        final soccerData = soccerProvider.soccerData;

        if (isLoading && soccerData == null) {
          return const Padding(
            padding: EdgeInsets.only(top: 2),
            child: PivoteMatchesHeroSkeleton(),
          );
        }

        List<SoccerMatch> featuredMatches = [];
        if (soccerData != null) {
          featuredMatches = soccerData.matches.where((match) {
            if (match.shouldRemoveFromHero || match.isAutoFinished) {
              return false;
            }
            final isFeatured = match.isLive ||
                match.isScheduled ||
                (match.isFinished && !match.shouldRemoveFromHero);
            if (!isFeatured) return false;
            return match.tvChannels.any((c) => c.id != null);
          }).toList();
        }

        if (featuredMatches.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(top: 2),
          child: MatchesHero(
            onSeeAll: onNavigateToTab != null
                ? () => onNavigateToTab!(1)
                : null,
          ),
        );
      },
    );
  }
}
