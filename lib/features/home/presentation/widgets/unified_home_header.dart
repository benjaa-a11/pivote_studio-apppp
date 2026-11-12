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
import 'package:pivote/features/home/presentation/providers/notifications_provider.dart';
import 'package:pivote/shared/widgets/common/apple_pressable.dart';

class UnifiedHomeHeader extends StatelessWidget {
  final void Function(int tabIndex)? onNavigateToTab;
  const UnifiedHomeHeader({super.key, this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTopBar(context, theme, isDark),
        const Padding(
          padding: EdgeInsets.only(top: 4, bottom: 4),
          child: CategoryChipsRow(),
        ),
        _buildMatchesSection(),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context, ThemeData theme, bool isDark) {
    final hPad = AppResponsive.screenHorizontalPadding(context);
    return Padding(
      padding: hPad.add(const EdgeInsets.symmetric(vertical: 10)),
      child: Row(
        children: [
          UserAvatar(
            size: 40,
            showBorder: true,
            onTap: () {
              onNavigateToTab?.call(3);
            },
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
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    height: 1.1,
                    color: theme.colorScheme.onSurface,
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
              Consumer<NotificationsProvider>(
                builder: (context, notifications, _) {
                  final unread = notifications.unreadCount;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _buildHeaderIconButton(
                        context: context,
                        theme: theme,
                        isDark: isDark,
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
                              minWidth: 17,
                              minHeight: 17,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: AppColors.live,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                              border: Border.all(
                                color: isDark
                                    ? AppTheme.darkBg
                                    : theme.scaffoldBackgroundColor,
                                width: 2,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              unread > 99 ? '99+' : '$unread',
                              style: AppFont.primary(
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

  Widget _buildHeaderIconButton({
    required BuildContext context,
    required ThemeData theme,
    required bool isDark,
    required IconData icon,
    required String heroTag,
    required VoidCallback onTap,
  }) {
    return ApplePressable(
      scaleDownFactor: 0.92,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBg2 : AppTheme.lightBg1,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: isDark
                ? AppColors.darkBorder2
                : AppTheme.lightBorder,
            width: 1.0,
          ),
          boxShadow: AppShadows.card(context),
        ),
        alignment: Alignment.center,
        child: Hero(
          tag: heroTag,
          child: Icon(
            icon,
            size: 20,
            color: isDark ? AppColors.darkText : theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildMatchesSection() {
    return Consumer<SoccerProvider>(
      builder: (context, soccerProvider, child) {
        final isLoading = soccerProvider.isLoading;
        final soccerData = soccerProvider.soccerData;
        List<SoccerMatch> featuredMatches = [];
        if (!isLoading && soccerData != null) {
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
        final hasMatches = isLoading || featuredMatches.isNotEmpty;
        if (!hasMatches) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 2),
          child: MatchesHero(
            onSeeAll: onNavigateToTab != null
                ? () => onNavigateToTab!(0)
                : null,
          ),
        );
      },
    );
  }
}
