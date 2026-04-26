import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pivote/features/soccer/data/models/soccer_models.dart';
import 'package:pivote/core/services/image_cache_helper.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/features/soccer/presentation/widgets/match_details_bottom_sheet.dart';

class SoccerMatchCard extends StatelessWidget {
  final SoccerMatch match;
  final SoccerData data;
  final bool isLast;

  const SoccerMatchCard({
    super.key,
    required this.match,
    required this.data,
    this.isLast = false,
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
        orElse: () => SoccerLeague(id: match.leagueId, name: 'Desconocida', country: '', shortName: ''));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) {
              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: MatchDetailsBottomSheet(
                  match: match,
                  homeTeam: homeTeam,
                  awayTeam: awayTeam,
                  league: league,
                ),
              );
            },
          );
        },
        splashColor: theme.colorScheme.primary.withValues(alpha: 0.04),
        highlightColor: theme.colorScheme.primary.withValues(alpha: 0.02),
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(20))
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : Border(
                    bottom: BorderSide(
                      color: isDark
                          ? AppTheme.darkBorder.withValues(alpha: 0.2)
                          : AppTheme.lightBorder.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
          ),
          child: Row(
            children: [
              // Status and Time Column
              SizedBox(
                width: 72,
                child: _buildTimeColumn(theme, isDark),
              ),

              // Vertical Divider with gradient
              Container(
                height: 48,
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      isDark
                          ? AppTheme.darkBorder.withValues(alpha: 0.65)
                          : AppTheme.lightBorder.withValues(alpha: 0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
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
                      child: Row(
                        children: [
                          const SizedBox(width: 40),
                          Expanded(
                            child: Divider(
                              height: 1,
                              color: isDark
                                  ? AppTheme.darkBorder.withValues(alpha: 0.55)
                                  : AppTheme.lightBorder.withValues(alpha: 0.3),
                            ),
                          ),
                        ],
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
        ),
      ),
    );
  }

  Widget _buildTimeColumn(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (match.isLive) ...[
          _AnimatedLiveBadge(theme: theme),
          const SizedBox(height: 5),
          Text(
            match.timeStatus,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
        ] else if (match.isFinished)
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  match.timeStatus.isNotEmpty
                      ? match.timeStatus.toUpperCase()
                      : 'FINAL',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: theme.hintColor.withValues(alpha: 0.5),
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          )
        else
          Column(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 14,
                color: theme.colorScheme.primary.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 4),
              Text(
                _formatStartTime(match.startTime),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildTeamRow(SoccerTeam team, int? currentScore, ThemeData theme,
      bool isDark, bool isHome) {
    final hasGoals = isHome
        ? match.goals.where((g) => g.teamId == team.id).toList()
        : match.goals.where((g) => g.teamId == team.id).toList();

    return Row(
      children: [
        // Team Logo Container
        Container(
          width: 32,
          height: 32,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04),
            ),
          ),
          child: CachedNetworkImage(
            cacheManager: ImageCacheHelper.customCacheManager,
            imageUrl: team.logoUrl ?? '',
            fit: BoxFit.contain,
            errorWidget: (context, url, error) => Icon(Icons.shield_outlined,
                size: 16, color: theme.hintColor.withValues(alpha: 0.4)),
          ),
        ),
        const SizedBox(width: 10),
        // Team Name + Goal scorers
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                team.name,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              // Show goal scorers if available
              if (hasGoals.isNotEmpty && (match.isLive || match.isFinished))
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    hasGoals
                        .map((g) => '${g.playerShortName} ${g.timeToDisplay}')
                        .join(', '),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: theme.hintColor.withValues(alpha: 0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
        // Score
        if (currentScore != null) ...[
          Container(
            height: 20,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            color: isDark
                ? AppTheme.darkBorder.withValues(alpha: 0.15)
                : AppTheme.lightBorder.withValues(alpha: 0.3),
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 32),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: match.isLive
                  ? theme.colorScheme.error.withValues(alpha: 0.1)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.04)),
              borderRadius: BorderRadius.circular(8),
              border: match.isLive
                  ? Border.all(
                      color: theme.colorScheme.error.withValues(alpha: 0.15))
                  : null,
            ),
            child: Text(
              currentScore.toString(),
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: match.isLive
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
        ] else
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Text(
              '–',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: theme.hintColor.withValues(alpha: 0.2),
              ),
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

/// Animated live badge with pulsing dot
class _AnimatedLiveBadge extends StatefulWidget {
  final ThemeData theme;

  const _AnimatedLiveBadge({required this.theme});

  @override
  State<_AnimatedLiveBadge> createState() => _AnimatedLiveBadgeState();
}

class _AnimatedLiveBadgeState extends State<_AnimatedLiveBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 0.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: widget.theme.colorScheme.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: widget.theme.colorScheme.error
                    .withValues(alpha: _glowAnimation.value * 0.3),
                blurRadius: 6,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: widget.theme.colorScheme.error
                      .withValues(alpha: _pulseAnimation.value),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.theme.colorScheme.error
                          .withValues(alpha: _pulseAnimation.value * 0.5),
                      blurRadius: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'VIVO',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  color: widget.theme.colorScheme.error,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
