import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pivote/features/soccer/presentation/providers/soccer_provider.dart';
import 'package:pivote/features/video/presentation/providers/channel_provider.dart';
import 'package:pivote/features/soccer/data/models/soccer_models.dart';
import 'package:pivote/features/soccer/presentation/widgets/match_card.dart';
import 'package:pivote/features/video/presentation/screens/player_screen.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/core/theme/dialog_styles.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/shared/widgets/app_notifications.dart';

class MatchesHero extends StatefulWidget {
  final VoidCallback? onSeeAll;

  const MatchesHero({super.key, this.onSeeAll});

  @override
  State<MatchesHero> createState() => _MatchesHeroState();
}

class _MatchesHeroState extends State<MatchesHero> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SoccerProvider>(
      builder: (context, soccerProvider, child) {
        if (!soccerProvider.hasMatchesForToday) {
          return const SizedBox.shrink();
        }

        final matches = soccerProvider.heroMatches;
        final liveCount = soccerProvider.liveMatchesCount;
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final horizontalPad = AppResponsive.screenHorizontalPadding(context);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),

            // Header de sección
            Padding(
              padding: horizontalPad,
              child: Row(
                children: [
                  Container(
                    width: 3.5,
                    height: 18,
                    decoration: BoxDecoration(
                      color: liveCount > 0
                          ? AppColors.live
                          : theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        if (liveCount > 0)
                          BoxShadow(
                            color: AppColors.live.withValues(alpha: 0.45),
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
                            liveCount > 0
                                ? 'Partidos en vivo'
                                : 'Partidos de hoy',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppFont.primary(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: liveCount > 0
                                ? AppColors.live.withValues(alpha: 0.14)
                                : (isDark
                                    ? AppColors.ink3
                                    : Colors.black.withValues(alpha: 0.05)),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(
                              color: liveCount > 0
                                  ? AppColors.live.withValues(alpha: 0.30)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Text(
                            '${matches.length}',
                            style: AppFont.primary(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: liveCount > 0
                                  ? AppColors.live
                                  : (isDark
                                      ? AppColors.slate
                                      : theme.hintColor),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.onSeeAll != null)
                    InkWell(
                      onTap: widget.onSeeAll,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.ink2
                              : Colors.black.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: isDark
                                ? AppColors.ink3
                                : Colors.black.withValues(alpha: 0.06),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Agenda',
                              style: AppFont.primary(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppTheme.darkAccent
                                    : theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 15,
                              color: isDark
                                  ? AppTheme.darkAccent
                                  : theme.colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Lista horizontal de partidos
            SizedBox(
              height: 232,
              child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: horizontalPad,
                itemCount: matches.length,
                itemBuilder: (context, index) {
                  final match = matches[index];
                  return MatchCard(
                    match: match,
                    soccerData: soccerProvider.soccerData,
                    onWatchMatch: () => _watchMatch(context, match),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),
          ],
        );
      },
    );
  }

  void _watchMatch(BuildContext context, SoccerMatch match) {
    final channelProvider = Provider.of<ChannelProvider>(
      context,
      listen: false,
    );

    if (match.tvChannels.isEmpty) {
      AppNotifications.showSnackBar(
        context: context,
        message: 'No hay canal disponible para este partido',
        type: AppDialogType.warning,
      );
      return;
    }

    for (var soccerChannel in match.tvChannels) {
      if (soccerChannel.id != null) {
        final channel = channelProvider.getChannelById(soccerChannel.id!);

        if (channel != null) {
          Navigator.push(
            context,
            AppAnimations.createRoute(PlayerScreen(channel: channel)),
          );
          return;
        }
      }
    }

    AppNotifications.showSnackBar(
      context: context,
      message: 'Canal no encontrado en la lista',
      type: AppDialogType.error,
    );
  }
}
