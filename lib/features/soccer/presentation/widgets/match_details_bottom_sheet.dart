import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pivote/features/soccer/data/models/soccer_models.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/services/image_cache_helper.dart';

class MatchDetailsBottomSheet extends StatelessWidget {
  final SoccerMatch match;
  final SoccerTeam homeTeam;
  final SoccerTeam awayTeam;
  final SoccerLeague league;

  const MatchDetailsBottomSheet({
    super.key,
    required this.match,
    required this.homeTeam,
    required this.awayTeam,
    required this.league,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Obtener los goles y ordenarlos por tiempo
    final goals = List<SoccerGoal>.from(match.goals);
    goals.sort((a, b) => a.time.compareTo(b.time));

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle drag
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.hintColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // League info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              '${league.name} ${match.stage.isNotEmpty ? '- ${match.stage}' : ''}',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: theme.hintColor,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),

          // Teams and Score
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Home Team
                Expanded(
                  child: _buildTeamLogo(homeTeam, theme),
                ),

                // Score
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildScoreDisplay(theme, isDark),
                ),

                // Away Team
                Expanded(
                  child: _buildTeamLogo(awayTeam, theme),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Team Names
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    homeTeam.name,
                    style: GoogleFonts.syne(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ),
                const SizedBox(width: 80), // Space for score
                Expanded(
                  child: Text(
                    awayTeam.name,
                    style: GoogleFonts.syne(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Divider(
            height: 1,
            color: isDark
                ? AppTheme.darkBorder.withValues(alpha: 0.3)
                : AppTheme.lightBorder.withValues(alpha: 0.5),
          ),

          // Events Timeline (Goals)
          Flexible(
            child: goals.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.sports_soccer_outlined,
                          size: 40,
                          color: theme.hintColor.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Aún no hay goles en este partido.',
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            color: theme.hintColor.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 24),
                    itemCount: goals.length,
                    itemBuilder: (context, index) {
                      final goal = goals[index];
                      final isHome = goal.teamId == match.homeTeamId;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Home goal
                            Expanded(
                              child: isHome
                                  ? _buildGoalEvent(goal, theme, isHome: true)
                                  : const SizedBox.shrink(),
                            ),

                            // Center icon
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                '⚽',
                                style: GoogleFonts.dmSans(fontSize: 16),
                              ),
                            ),

                            // Away goal
                            Expanded(
                              child: !isHome
                                  ? _buildGoalEvent(goal, theme, isHome: false)
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          // Extra bottom padding for safety
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildGoalEvent(SoccerGoal goal, ThemeData theme,
      {required bool isHome}) {
    return Column(
      crossAxisAlignment:
          isHome ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          goal.playerShortName,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
          textAlign: isHome ? TextAlign.right : TextAlign.left,
        ),
        Text(
          goal.timeToDisplay,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: theme.hintColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTeamLogo(SoccerTeam team, ThemeData theme) {
    return SizedBox(
      width: 70,
      height: 70,
      child: (team.logoUrl != null && team.logoUrl!.isNotEmpty)
          ? CachedNetworkImage(
              cacheManager: ImageCacheHelper.customCacheManager,
              imageUrl: team.logoUrl!,
              fit: BoxFit.contain,
              errorWidget: (context, error, stackTrace) =>
                  Icon(Icons.shield, size: 40, color: theme.hintColor),
            )
          : Icon(Icons.shield, size: 40, color: theme.hintColor),
    );
  }

  Widget _buildScoreDisplay(ThemeData theme, bool isDark) {
    final homeScore = match.score.isNotEmpty ? match.score[0].toString() : '0';
    final awayScore = match.score.length > 1 ? match.score[1].toString() : '0';

    final isLive = match.isLive;
    final isFinished = match.isFinished;
    final scoreColor =
        isLive ? theme.colorScheme.error : theme.colorScheme.onSurface;

    if (!isLive && !isFinished) {
      String timeText = match.startTime;
      final parts = match.startTime.split(' ');
      if (parts.length > 1) {
        timeText = parts[1];
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            timeText,
            style: GoogleFonts.syne(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'HOY',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: theme.hintColor,
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              homeScore,
              style: GoogleFonts.syne(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: scoreColor,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                ':',
                style: GoogleFonts.syne(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: scoreColor.withValues(alpha: 0.4),
                ),
              ),
            ),
            Text(
              awayScore,
              style: GoogleFonts.syne(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: scoreColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isLive
                ? theme.colorScheme.error.withValues(alpha: 0.1)
                : theme.colorScheme.onSurface.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            isLive ? (match.timeStatus.isNotEmpty ? match.timeStatus : 'EN VIVO') : 'FINAL',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: isLive
                  ? theme.colorScheme.error
                  : theme.hintColor.withValues(alpha: 0.8),
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}
