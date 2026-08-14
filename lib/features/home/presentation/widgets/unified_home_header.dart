import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pivote/features/home/presentation/screens/search_screen.dart';
import 'package:pivote/features/home/presentation/screens/notifications_screen.dart';
import 'package:pivote/features/home/presentation/providers/notifications_provider.dart';
import 'package:pivote/features/soccer/presentation/providers/soccer_provider.dart';
import 'package:pivote/features/soccer/data/models/soccer_models.dart';
import 'package:pivote/features/soccer/presentation/widgets/matches_hero.dart';
import 'package:pivote/shared/widgets/common/user_avatar.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/features/home/presentation/widgets/category_chips_row.dart';

class UnifiedHomeHeader extends StatelessWidget {
  final void Function(int tabIndex)? onNavigateToTab;
  const UnifiedHomeHeader({super.key, this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.isDark;
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildTopBar(context, theme, isDark),
      const Padding(padding: EdgeInsets.only(top: 6, bottom: 2), child: CategoryChipsRow()),
      _buildMatchesSection(),
    ]);
  }

  Widget _buildTopBar(BuildContext context, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(children: [
        UserAvatar(size: 40, showBorder: true, onTap: () { if (onNavigateToTab != null) onNavigateToTab!(3); }),
        const Expanded(child: SizedBox.shrink()),
        Row(mainAxisSize: MainAxisSize.min, children: [
          _buildHeaderIconButton(context: context, theme: theme, isDark: isDark, icon: Icons.search_rounded, heroTag: 'search_icon', onTap: () { Navigator.push(context, AppAnimations.createFadeRoute(const SearchScreen())); }),
          const SizedBox(width: 8),
          Consumer<NotificationsProvider>(
            builder: (context, notifications, _) => _buildNotificationButton(
              context: context,
              theme: theme,
              isDark: isDark,
              unread: notifications.unreadCount,
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _buildNotificationButton({required BuildContext context, required ThemeData theme, required bool isDark, required int unread}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.push(context, AppAnimations.createFadeRoute(const NotificationsScreen())),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkBg2 : theme.colorScheme.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : theme.colorScheme.primary.withValues(alpha: 0.12)),
          ),
          child: Stack(alignment: Alignment.center, children: [
            Hero(tag: 'notification_icon', child: Icon(Icons.notifications_none_rounded, size: 20, color: isDark ? AppTheme.darkAccent : theme.colorScheme.primary)),
            if (unread > 0)
              Positioned(
                right: 5,
                top: 4,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(color: theme.colorScheme.error, borderRadius: BorderRadius.circular(10), border: Border.all(color: isDark ? AppTheme.darkBg2 : theme.scaffoldBackgroundColor, width: 2)),
                  alignment: Alignment.center,
                  child: Text(unread > 99 ? '99+' : '$unread', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white)),
                ),
              ),
          ]),
        ),
      ),
    );
  }

  Widget _buildHeaderIconButton({required BuildContext context, required ThemeData theme, required bool isDark, required IconData icon, required String heroTag, required VoidCallback onTap}) {
    return Material(color: Colors.transparent, child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(14), child: Container(width: 40, height: 40, decoration: BoxDecoration(color: isDark ? AppTheme.darkBg2 : theme.colorScheme.primary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(14), border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : theme.colorScheme.primary.withValues(alpha: 0.12))), alignment: Alignment.center, child: Hero(tag: heroTag, child: Icon(icon, size: 20, color: isDark ? AppTheme.darkAccent : theme.colorScheme.primary))));
  }

  Widget _buildMatchesSection() {
    return Consumer<SoccerProvider>(builder: (context, soccerProvider, child) {
      final isLoading = soccerProvider.isLoading;
      final soccerData = soccerProvider.soccerData;
      List<SoccerMatch> featuredMatches = [];
      if (!isLoading && soccerData != null) {
        featuredMatches = soccerData.matches.where((match) {
          if (match.shouldRemoveFromHero || match.isAutoFinished) return false;
          final isFeatured = match.isLive || match.isScheduled || (match.isFinished && !match.shouldRemoveFromHero);
          if (!isFeatured) return false;
          return match.tvChannels.any((c) => c.id != null);
        }).toList();
      }
      final hasMatches = isLoading || featuredMatches.isNotEmpty;
      if (!hasMatches) return const SizedBox.shrink();
      return const Padding(padding: EdgeInsets.only(top: 4), child: MatchesHero());
    });
  }
}
