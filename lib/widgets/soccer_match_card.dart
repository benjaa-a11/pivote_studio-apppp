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
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E2229).withValues(alpha: 0.8)
            : theme.cardColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header: Stage and Status
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  match.stage.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    fontWeight: FontWeight.w700,
                    fontSize: 9,
                    letterSpacing: 0.8,
                  ),
                ),
                _buildStatusBadge(theme),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Main content: Teams and Score/Time
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildTeamCol(homeTeam, theme),
                Expanded(
                  child: _buildCenterSection(theme, isLive),
                ),
                _buildTeamCol(awayTeam, theme),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Footer: TV Channels
          if (match.tvChannels.isNotEmpty) _buildChannelsFooter(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildCenterSection(ThemeData theme, bool isLive) {
    if (isLive || match.isFinished) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildScoreText(
                match.score.isNotEmpty ? match.score[0].toString() : '0',
                isLive,
                theme,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(':',
                    style: GoogleFonts.inter(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.2),
                        fontSize: 28,
                        fontWeight: FontWeight.w200)),
              ),
              _buildScoreText(
                match.score.isNotEmpty && match.score.length > 1
                    ? match.score[1].toString()
                    : '0',
                isLive,
                theme,
              ),
            ],
          ),
          if (isLive) ...[
            const SizedBox(height: 4),
            _buildLiveTimeBadge(theme),
          ],
        ],
      );
    } else {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'HOY',
              style: GoogleFonts.inter(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatStartTime(match.startTime),
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w900,
              fontSize: 22,
              letterSpacing: -0.5,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildChannelsFooter(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color:
            theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.03 : 0.02),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.live_tv_rounded,
              size: 14,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              match.tvChannels.join(' • '),
              style: GoogleFonts.inter(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
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

  Widget _buildLiveTimeBadge(ThemeData theme) {
    String displayTime = match.time;
    final ts = match.timeStatus.toLowerCase();
    if (ts.contains('et') || ts.contains('entretiempo')) {
      displayTime = 'Entretiempo';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        displayTime.toUpperCase(),
        style: GoogleFonts.inter(
          color: theme.colorScheme.primary,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildTeamCol(SoccerTeam team, ThemeData theme) {
    return Expanded(
      child: Column(
        children: [
          team.logoUrl != null
              ? Hero(
                  tag: 'team_${team.id}_${match.id}',
                  child: CachedNetworkImage(
                    imageUrl: team.logoUrl!,
                    height: 52,
                    width: 52,
                    fit: BoxFit.contain,
                    placeholder: (context, url) =>
                        const SizedBox(width: 52, height: 52),
                    errorWidget: (context, url, error) => Icon(
                        Icons.sports_soccer_outlined,
                        size: 36,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                  ),
                )
              : Icon(Icons.sports_soccer_outlined,
                  size: 36,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
          const SizedBox(height: 10),
          Text(
            team.shortName,
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w900,
              fontSize: 13,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildScoreText(String score, bool isLive, ThemeData theme) {
    return Text(
      score,
      style: GoogleFonts.inter(
        fontWeight: FontWeight.w900,
        color: isLive ? theme.colorScheme.primary : theme.colorScheme.onSurface,
        fontSize: 34,
        letterSpacing: -1,
      ),
    );
  }

  Widget _buildStatusBadge(ThemeData theme) {
    final isLive = match.isLive;
    final isFinished = match.isFinished;
    final isScheduled = match.isScheduled;

    Color badgeColor = theme.colorScheme.onSurface.withValues(alpha: 0.05);
    Color textColor = theme.colorScheme.onSurface.withValues(alpha: 0.4);
    String statusText = match.status;

    if (isLive) {
      badgeColor = Colors.red.withValues(alpha: 0.1);
      textColor = Colors.red;
      statusText = 'EN VIVO';
    } else if (isScheduled) {
      badgeColor = theme.colorScheme.primary.withValues(alpha: 0.1);
      textColor = theme.colorScheme.primary;
      statusText = 'PRÓXIMO';
    } else if (isFinished) {
      statusText = 'FINALIZADO';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLive) ...[
            _buildPulseDot(),
            const SizedBox(width: 6),
          ],
          Text(
            statusText.toUpperCase(),
            style: GoogleFonts.inter(
              color: textColor,
              fontWeight: FontWeight.w900,
              fontSize: 8,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPulseDot() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      builder: (context, value, child) {
        return Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: value),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: value * 0.5),
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
}
