import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/soccer_models.dart';
import '../providers/soccer_provider.dart';

class MatchDetailsSheet extends StatelessWidget {
  final String matchId;

  const MatchDetailsSheet({
    super.key,
    required this.matchId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<SoccerProvider>(
      builder: (context, provider, child) {
        final soccerData = provider.soccerData;
        if (soccerData == null) {
          return const SizedBox(
              height: 400, child: Center(child: CircularProgressIndicator()));
        }

        SoccerMatch? match;
        try {
          match = soccerData.matches.firstWhere((m) => m.id == matchId);
        } catch (e) {
          return SizedBox(
              height: 200,
              child: Center(
                  child: Text('Partido no encontrado',
                      style: theme.textTheme.bodyLarge)));
        }
        final currentMatch = match;

        final league = soccerData.leagues.firstWhere(
            (l) => l.id == currentMatch.leagueId,
            orElse: () => SoccerLeague(
                id: currentMatch.leagueId,
                name: 'Competición',
                country: '',
                shortName: 'LEAGUE'));

        final homeTeam = soccerData.teams.firstWhere(
            (t) => t.id == currentMatch.homeTeamId,
            orElse: () => SoccerTeam(
                id: currentMatch.homeTeamId,
                name: currentMatch.homeTeam,
                shortName: currentMatch.homeTeam));
        final awayTeam = soccerData.teams.firstWhere(
            (t) => t.id == currentMatch.awayTeamId,
            orElse: () => SoccerTeam(
                id: currentMatch.awayTeamId,
                name: currentMatch.awayTeam,
                shortName: currentMatch.awayTeam));

        final screenWidth = MediaQuery.of(context).size.width;
        final isLargeScreen = screenWidth > 600;

        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.05),
                    blurRadius: 40,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Scoreboard Card
                    _buildModernScoreboard(context, currentMatch, league,
                        homeTeam, awayTeam, isLargeScreen),

                    // Events Timeline Container
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.cardColor.withValues(alpha: 0.3),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(32)),
                      ),
                      child:
                          _buildTimeline(context, currentMatch, isLargeScreen),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModernScoreboard(
      BuildContext context,
      SoccerMatch match,
      SoccerLeague league,
      SoccerTeam home,
      SoccerTeam away,
      bool isLargeScreen) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final homeScore = match.score.isNotEmpty ? match.score[0] : 0;
    final awayScore =
        match.score.isNotEmpty && match.score.length > 1 ? match.score[1] : 0;

    return Container(
      margin: EdgeInsets.symmetric(
          horizontal: isLargeScreen ? 32 : 16, vertical: 16),
      padding: EdgeInsets.all(isLargeScreen ? 32 : 24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
        boxShadow: [
          boxShadow(isDark, theme),
        ],
      ),
      child: Column(
        children: [
          // Tournament Info with Logo
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (league.logoUrl != null) ...[
                CachedNetworkImage(
                  imageUrl: league.logoUrl!,
                  height: 20,
                  width: 20,
                  fit: BoxFit.contain,
                  errorWidget: (c, e, s) => Icon(Icons.sports_soccer_rounded,
                      size: 18,
                      color: theme.colorScheme.primary.withValues(alpha: 0.6)),
                ),
                const SizedBox(width: 8),
              ] else ...[
                Icon(Icons.sports_soccer_rounded,
                    size: 18,
                    color: theme.colorScheme.primary.withValues(alpha: 0.6)),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  league.name.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (match.isLive) ...[
                const SizedBox(width: 10),
                _buildLivePulse(),
              ],
            ],
          ),
          const SizedBox(height: 24),

          // Match Stats (Score and Teams)
          Row(
            children: [
              // Home Team
              Expanded(
                child: Column(
                  children: [
                    _buildTeamBadge(home.logoUrl, theme, isLargeScreen),
                    const SizedBox(height: 12),
                    Text(
                      home.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Score Area
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$homeScore',
                            style: theme.textTheme.displayMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: theme.colorScheme.onSurface,
                            )),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(':',
                              style: theme.textTheme.displayMedium?.copyWith(
                                fontWeight: FontWeight.w200,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.2),
                              )),
                        ),
                        Text('$awayScore',
                            style: theme.textTheme.displayMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: theme.colorScheme.onSurface,
                            )),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildStatusIndicator(match, theme),
                  ],
                ),
              ),

              // Away Team
              Expanded(
                child: Column(
                  children: [
                    _buildTeamBadge(away.logoUrl, theme, isLargeScreen),
                    const SizedBox(height: 12),
                    Text(
                      away.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  BoxShadow boxShadow(bool isDark, ThemeData theme) {
    return isDark
        ? BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 10))
        : BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8));
  }

  Widget _buildTeamBadge(String? url, ThemeData theme, bool isLargeScreen) {
    final size = isLargeScreen ? 85.0 : 70.0;
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
        shape: BoxShape.circle,
        border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.05)),
      ),
      child: url != null
          ? CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.contain,
              errorWidget: (c, e, s) => Icon(Icons.shield_rounded,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  size: size * 0.45),
            )
          : Icon(Icons.shield_rounded,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
              size: size * 0.45),
    );
  }

  Widget _buildStatusIndicator(SoccerMatch match, ThemeData theme) {
    final isLive = match.isLive;

    String statusStr = match.status;
    if (isLive) {
      statusStr = match.time.replaceAll("'", "");
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isLive
            ? theme.colorScheme.secondary.withValues(alpha: 0.1)
            : theme.colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isLive ? '$statusStr\'' : statusStr.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w900,
          color: isLive
              ? theme.colorScheme.secondary
              : theme.colorScheme.onSurface.withValues(alpha: 0.6),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildLivePulse() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1.0),
      duration: const Duration(seconds: 1),
      builder: (context, value, child) {
        final theme = Theme.of(context);
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary.withValues(alpha: value),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color:
                    theme.colorScheme.secondary.withValues(alpha: value * 0.5),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimeline(
      BuildContext context, SoccerMatch match, bool isLargeScreen) {
    final theme = Theme.of(context);
    final events = _getSortedEvents(match);

    if (events.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 40),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.event_note_rounded,
                  size: 56,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
            ),
            const SizedBox(height: 24),
            Text(
              match.isScheduled
                  ? 'El partido aún no ha comenzado'
                  : 'Sin eventos registrados',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 32),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: events.length + 2, // Start, End, and events
      itemBuilder: (context, index) {
        if (index == 0) {
          String endLabel = match.isFinished ? 'Final del partido' : 'En juego';
          return _buildTimelinePoint(
              context,
              endLabel,
              match.time.isEmpty ? '?' : match.time,
              Icons.sports_score_rounded);
        }
        if (index == events.length + 1) {
          return _buildTimelinePoint(
              context, 'Inicio del partido', '0\'', Icons.sports_score_rounded);
        }

        final event = events[index - 1];
        return _buildTimelineEventRow(context, event, match.homeTeamId);
      },
    );
  }

  Widget _buildTimelinePoint(
      BuildContext context, String title, String time, IconData icon) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        border: Border.symmetric(
            horizontal:
                BorderSide(color: theme.dividerColor.withValues(alpha: 0.03))),
      ),
      child: Row(
        children: [
          Expanded(
              child: Text(title.toUpperCase(),
                  textAlign: TextAlign.right,
                  style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.4)))),
          const SizedBox(width: 24),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 6),
              Text(time.contains("'") ? time : "$time'",
                  style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.3))),
            ],
          ),
          const SizedBox(width: 24),
          const Expanded(child: SizedBox()),
        ],
      ),
    );
  }

  Widget _buildTimelineEventRow(
      BuildContext context, _MatchEvent event, String homeTeamId) {
    final theme = Theme.of(context);
    final isHome = event.teamId == homeTeamId;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        border: Border(
            bottom:
                BorderSide(color: theme.dividerColor.withValues(alpha: 0.03))),
      ),
      child: Row(
        children: [
          // Left Side (Home)
          Expanded(
            child: isHome
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(event.playerName,
                          style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface)),
                    ],
                  )
                : const SizedBox(),
          ),

          // Center Icon & Time
          SizedBox(
            width: 80,
            child: Column(
              children: [
                _buildEventIcon(event, theme),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${event.time}\'',
                      style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.4))),
                ),
              ],
            ),
          ),

          // Right Side (Away)
          Expanded(
            child: !isHome
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(event.playerName,
                          style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface)),
                    ],
                  )
                : const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _buildEventIcon(_MatchEvent event, ThemeData theme) {
    switch (event.type) {
      case _EventType.goal:
        return Icon(Icons.sports_soccer_rounded,
            size: 22, color: theme.colorScheme.secondary);
      case _EventType.yellowCard:
        return Container(
          width: 14,
          height: 20,
          decoration: BoxDecoration(
              color: Colors.amber, borderRadius: BorderRadius.circular(4)),
        );
      case _EventType.redCard:
        return Container(
          width: 14,
          height: 20,
          decoration: BoxDecoration(
              color: theme.colorScheme.error,
              borderRadius: BorderRadius.circular(4)),
        );
      case _EventType.substitution:
        return Icon(Icons.swap_vert_rounded,
            size: 22, color: theme.colorScheme.tertiary);
    }
  }

  List<_MatchEvent> _getSortedEvents(SoccerMatch match) {
    final List<_MatchEvent> events = [];

    for (var g in match.goals) {
      events.add(_MatchEvent(
        type: _EventType.goal,
        time: g.time,
        playerName: g.playerShortName,
        teamId: g.teamId,
      ));
    }

    for (var c in match.yellowCards) {
      events.add(_MatchEvent(
        type: _EventType.yellowCard,
        time: c.time,
        playerName: c.playerShortName,
        teamId: c.teamId,
      ));
    }

    for (var c in match.redCards) {
      events.add(_MatchEvent(
        type: _EventType.redCard,
        time: c.time,
        playerName: c.playerShortName,
        teamId: c.teamId,
      ));
    }

    events.sort((a, b) => b.time.compareTo(a.time));
    return events;
  }
}

enum _EventType { goal, yellowCard, redCard, substitution }

class _MatchEvent {
  final _EventType type;
  final int time;
  final String playerName;
  final String teamId;

  _MatchEvent({
    required this.type,
    required this.time,
    required this.playerName,
    required this.teamId,
  });
}
