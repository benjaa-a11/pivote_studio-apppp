import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/soccer_models.dart';

class SoccerMatchCard extends StatelessWidget {
  final SoccerMatch match;
  final SoccerData data;
  final VoidCallback onTap;

  const SoccerMatchCard({
    super.key,
    required this.match,
    required this.data,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLive = match.isLive;

    final homeTeam = data.teams.firstWhere((t) => t.id == match.homeTeamId,
        orElse: () => SoccerTeam(
            id: '', name: match.homeTeam, shortName: match.homeTeam));
    final awayTeam = data.teams.firstWhere((t) => t.id == match.awayTeamId,
        orElse: () => SoccerTeam(
            id: '', name: match.awayTeam, shortName: match.awayTeam));

    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color:
                (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
            width: 0.5,
          ),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Time / Live Status Column
              _buildTimeColumn(theme, isDark),

              // Team and Score section
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          _buildTeamInfo(homeTeam, theme, isDark, true),
                          _buildMatchScore(theme, isDark, isLive),
                          _buildTeamInfo(awayTeam, theme, isDark, false),
                        ],
                      ),
                      // Goal events placeholder
                      if (match.isLive || match.isFinished)
                        _buildGoalEvents(theme, isDark),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeColumn(ThemeData theme, bool isDark) {
    final isLive = match.isLive;
    final bgColor = isDark
        ? theme.cardColor.withValues(alpha: 0.3)
        : theme.colorScheme.surface;
    final borderColor = theme.dividerColor.withValues(alpha: 0.1);

    return Container(
      width: 70,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          right: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLive) ...[
            Text(
              match.time,
              style: GoogleFonts.poppins(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            _buildLivePulse(theme),
          ] else ...[
            Text(
              _formatStartTime(match.startTime),
              style: GoogleFonts.poppins(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w800,
                fontSize: 14,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'HOY',
              style: GoogleFonts.poppins(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                fontWeight: FontWeight.w700,
                fontSize: 9,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLivePulse(ThemeData theme) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: const Duration(seconds: 1),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: theme.colorScheme.error.withValues(alpha: value),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.error.withValues(alpha: value * 0.5),
                blurRadius: 4,
                spreadRadius: 2,
              ),
            ],
          ),
        );
      },
      onEnd: () {},
    );
  }

  Widget _buildTeamInfo(
      SoccerTeam team, ThemeData theme, bool isDark, bool isHome) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildTeamLogo(team, isDark),
          const SizedBox(height: 8),
          Text(
            team.shortName.toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
              height: 1.0,
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTeamLogo(SoccerTeam team, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: CachedNetworkImage(
          imageUrl: team.logoUrl ?? '',
          width: 24,
          height: 24,
          fit: BoxFit.contain,
          errorWidget: (context, url, error) =>
              const Icon(Icons.sports_soccer, size: 16),
        ),
      ),
    );
  }

  Widget _buildMatchScore(ThemeData theme, bool isDark, bool isLive) {
    final scoreText =
        match.score.isNotEmpty ? '${match.score[0]} - ${match.score[1]}' : 'vs';
    final boxColor =
        isDark ? theme.scaffoldBackgroundColor : theme.colorScheme.surface;

    return Container(
      width: 54,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: boxColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        scoreText,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: isLive ? theme.colorScheme.error : theme.colorScheme.onSurface,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildGoalEvents(ThemeData theme, bool isDark) {
    // This is hardcoded for the demo based on the template, in reality we'd pull this from match.events
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 4, right: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              '', // Right aligned home goals
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: isDark ? Colors.white38 : Colors.black38),
            ),
          ),
          const SizedBox(width: 50), // alignment with score
          Expanded(
            child: Text(
              '', // Left aligned away goals
              textAlign: TextAlign.left,
              style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: isDark ? Colors.white38 : Colors.black38),
            ),
          ),
        ],
      ),
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
