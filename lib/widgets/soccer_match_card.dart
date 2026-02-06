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
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildTeamInfo(homeTeam, theme, isDark, true),
                          _buildMatchScore(theme, isDark, isLive),
                          _buildTeamInfo(awayTeam, theme, isDark, false),
                        ],
                      ),
                      // Goal events placeholder
                      if (match.isLive || match.isFinished)
                        _buildGoalEvents(theme, isDark),
                      // TV Channels
                      if (match.tvChannels.isNotEmpty)
                        _buildChannelsRow(theme, isDark),
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

  Widget _buildChannelsRow(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.live_tv_rounded,
            size: 10,
            color:
                (isDark ? Colors.white : Colors.black).withValues(alpha: 0.3),
          ),
          const SizedBox(width: 4),
          Text(
            match.tvChannels.join(' • ').toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color:
                  (isDark ? Colors.white : Colors.black).withValues(alpha: 0.3),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeColumn(ThemeData theme, bool isDark) {
    final isLive = match.isLive;
    final bgColor = isDark ? const Color(0xFF0E4536) : const Color(0xFFF9FAFB);
    final borderColor = isDark ? const Color(0xFF0A3A2F) : Colors.grey[200];

    return Container(
      width: 60,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          right: BorderSide(color: borderColor!, width: 0.5),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLive) ...[
            Text(
              match.time,
              style: GoogleFonts.poppins(
                color: Colors.redAccent,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            _buildLivePulse(),
          ] else ...[
            Text(
              _formatStartTime(match.startTime),
              style: GoogleFonts.poppins(
                color: isDark ? Colors.white70 : Colors.black54,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLivePulse() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: const Duration(seconds: 1),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.redAccent,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
      onEnd: () {},
    );
  }

  Widget _buildTeamInfo(
      SoccerTeam team, ThemeData theme, bool isDark, bool isHome) {
    return Expanded(
      child: Row(
        mainAxisAlignment:
            isHome ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isHome) ...[
            _buildTeamLogo(team, isDark),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              team.name,
              textAlign: isHome ? TextAlign.right : TextAlign.left,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
                height: 1.1,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isHome) ...[
            const SizedBox(width: 8),
            _buildTeamLogo(team, isDark),
          ],
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
        match.score.isNotEmpty ? '${match.score[0]} - ${match.score[1]}' : '-';
    final cardColor =
        isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0xFFF3F4F6);

    return Container(
      width: 50,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        scoreText,
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: isLive
              ? Colors.redAccent
              : (isDark ? Colors.white : Colors.black87),
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
