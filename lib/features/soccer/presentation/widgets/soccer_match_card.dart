import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pivote/features/soccer/data/models/soccer_models.dart';
import 'package:pivote/core/services/image_cache_helper.dart';

class SoccerMatchCard extends StatelessWidget {
  final SoccerMatch match;
  final SoccerData data;

  const SoccerMatchCard({
    super.key,
    required this.match,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final homeTeam = data.teams.firstWhere((t) => t.id == match.homeTeamId,
        orElse: () => SoccerTeam(
            id: '', name: match.homeTeam, shortName: match.homeTeam));
    final awayTeam = data.teams.firstWhere((t) => t.id == match.awayTeamId,
        orElse: () => SoccerTeam(
            id: '', name: match.awayTeam, shortName: match.awayTeam));

    final league = data.leagues.firstWhere((l) => l.id == match.leagueId,
        orElse: () => SoccerLeague(
            id: match.leagueId,
            name: match.leagueId.toUpperCase(),
            shortName: match.leagueId.toUpperCase(),
            country: ''));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // League Header within Card
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Text(
                  league.name.toUpperCase(),
                  style: GoogleFonts.dmSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    color: theme.colorScheme.primary.withValues(alpha: 0.7),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 8,
                  color: theme.hintColor.withValues(alpha: 0.2),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: theme.dividerColor.withValues(alpha: 0.05),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Status and Time Column
              SizedBox(
                width: 70,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (match.isLive) ...[
                      _buildLiveBadge(theme),
                      const SizedBox(height: 6),
                      Text(
                        match.timeStatus,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ] else if (match.isFinished)
                      Text(
                        match.timeStatus.toUpperCase(),
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: theme.hintColor.withValues(alpha: 0.5),
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      )
                    else
                      Text(
                        _formatStartTime(match.startTime),
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),

              // Vertical Divider
              Container(
                height: 40,
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: theme.dividerColor.withValues(alpha: 0.08),
              ),

              // Match Details: Teams and Score
              Expanded(
                child: Column(
                  children: [
                    _buildTeamRow(
                        homeTeam,
                        match.score.isNotEmpty ? match.score[0] : null,
                        theme,
                        isDark,
                        true),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Divider(
                        height: 1,
                        color: theme.dividerColor.withValues(alpha: 0.04),
                      ),
                    ),
                    _buildTeamRow(
                        awayTeam,
                        match.score.isNotEmpty ? match.score[1] : null,
                        theme,
                        isDark,
                        false),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveBadge(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLivePulse(theme),
          const SizedBox(width: 4),
          Text(
            'VIVO',
            style: GoogleFonts.dmSans(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.error,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLivePulse(ThemeData theme) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      builder: (context, value, child) {
        return Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: theme.colorScheme.error.withValues(alpha: value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildTeamRow(SoccerTeam team, int? currentScore, ThemeData theme,
      bool isDark, bool isHome) {
    return Row(
      children: [
        // Team Logo Container
        Container(
          width: 28,
          height: 28,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.03)
                : Colors.black.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(8),
          ),
          child: CachedNetworkImage(
            cacheManager: ImageCacheHelper.customCacheManager,
            imageUrl: team.logoUrl ?? '',
            fit: BoxFit.contain,
            errorWidget: (context, url, error) =>
                const Icon(Icons.shield_outlined, size: 14),
          ),
        ),
        const SizedBox(width: 12),
        // Team Name
        Expanded(
          child: Text(
            team.name,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Score Divider
        if (currentScore != null)
          Container(
            height: 16,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: theme.dividerColor.withValues(alpha: 0.08),
          ),
        // Score (if available)
        if (currentScore != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: match.isLive
                  ? theme.colorScheme.error.withValues(alpha: 0.08)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.03)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              currentScore.toString(),
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: match.isLive
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurface,
              ),
            ),
          )
        else
          Text(
            '-',
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: theme.hintColor.withValues(alpha: 0.2),
            ),
          ),
      ],
    );
  }

  String _formatStartTime(String startTime) {
    try {
      final parts = startTime.split(' ');
      if (parts.length > 1) {
        return parts[1];
      }
    } catch (e) {
      return startTime;
    }
    return startTime;
  }
}