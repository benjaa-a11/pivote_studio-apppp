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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Status and Time Column
          SizedBox(
            width: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (match.isLive) ...[
                  _buildLiveBadge(theme),
                  const SizedBox(height: 4),
                  Text(
                    match.timeStatus,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ] else if (match.isFinished)
                  Text(
                    match.timeStatus.toUpperCase(),
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: theme.hintColor.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  )
                else if (match.timeStatus.toLowerCase().contains('prog') ||
                    match.timeStatus.toLowerCase().contains('aplaz') ||
                    match.timeStatus.toLowerCase().contains('susp'))
                  Text(
                    '${match.timeStatus}\n${_formatStartTime(match.startTime)}',
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  )
                else
                  Text(
                    _formatStartTime(match.startTime),
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),

          const SizedBox(width: 8),

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
                const SizedBox(height: 12),
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
    return LivePulseIndicator(color: theme.colorScheme.error, size: 5.0);
  }

  Widget _buildTeamRow(SoccerTeam team, int? currentScore, ThemeData theme,
      bool isDark, bool isHome) {
    final redCardsCount =
        match.redCards.where((c) => c.teamId == team.id).length;
    final goals = match.goals.where((g) => g.teamId == team.id).map((g) {
      return '${g.playerShortName} ${g.timeToDisplay}';
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      team.name,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (redCardsCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 10,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.red[700],
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Center(
                        child: Text(
                          redCardsCount.toString(),
                          style: GoogleFonts.dmSans(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Score (if available)
            if (currentScore != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: match.isLive
                      ? theme.colorScheme.error.withValues(alpha: 0.05)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.03)
                          : Colors.black.withValues(alpha: 0.02)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  currentScore.toString(),
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
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
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: theme.hintColor.withValues(alpha: 0.3),
                ),
              ),
          ],
        ),
        if (goals.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 40, top: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.sports_soccer_rounded,
                  size: 10,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    goals.join(', '),
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
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

class LivePulseIndicator extends StatefulWidget {
  final Color color;
  final double size;

  const LivePulseIndicator({super.key, required this.color, this.size = 5.0});

  @override
  State<LivePulseIndicator> createState() => _LivePulseIndicatorState();
}

class _LivePulseIndicatorState extends State<LivePulseIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.2, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: _animation.value),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
