import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
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
                      style: GoogleFonts.inter(
                          color: theme.colorScheme.onSurface))));
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

        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF121418) : theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
            border: Border.all(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 30,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),

              // Scoreboard Card
              _buildModernScoreboard(
                  context, currentMatch, league, homeTeam, awayTeam),

              // Events Timeline
              Flexible(
                child: Container(
                  width: double.infinity,
                  color: isDark
                      ? const Color(0xFF0A0C10).withValues(alpha: 0.5)
                      : theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.1),
                  child: _buildTimeline(context, currentMatch),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModernScoreboard(BuildContext context, SoccerMatch match,
      SoccerLeague league, SoccerTeam home, SoccerTeam away) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final homeScore = match.score.isNotEmpty ? match.score[0] : 0;
    final awayScore =
        match.score.isNotEmpty && match.score.length > 1 ? match.score[1] : 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2229) : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
            color:
                (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)),
        boxShadow: [
          isDark
              ? BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 25,
                  offset: const Offset(0, 8))
              : BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          // Tournament Info
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sports_soccer_rounded,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
              const SizedBox(width: 8),
              Text(
                league.name.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
              if (match.isLive) ...[
                const SizedBox(width: 8),
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
                    _buildTeamBadge(home.logoUrl, theme),
                    const SizedBox(height: 12),
                    Text(
                      home.name,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Score
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$homeScore',
                            style: GoogleFonts.inter(
                                fontSize: 42,
                                fontWeight: FontWeight.w900,
                                color: theme.colorScheme.onSurface)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('-',
                              style: GoogleFonts.inter(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w200,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.3))),
                        ),
                        Text('$awayScore',
                            style: GoogleFonts.inter(
                                fontSize: 42,
                                fontWeight: FontWeight.w900,
                                color: theme.colorScheme.onSurface)),
                      ],
                    ),
                    _buildStatusIndicator(match, theme),
                  ],
                ),
              ),

              // Away Team
              Expanded(
                child: Column(
                  children: [
                    _buildTeamBadge(away.logoUrl, theme),
                    const SizedBox(height: 12),
                    Text(
                      away.name,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
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

  Widget _buildTeamBadge(String? url, ThemeData theme) {
    return Container(
      width: 65,
      height: 65,
      padding: const EdgeInsets.all(12),
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
                  size: 30),
            )
          : Icon(Icons.shield_rounded,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
              size: 30),
    );
  }

  Widget _buildStatusIndicator(SoccerMatch match, ThemeData theme) {
    final isLive = match.isLive;

    String statusStr = match.status;
    if (isLive) {
      statusStr = match.time.replaceAll("'", "");
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isLive
            ? Colors.green.withValues(alpha: 0.1)
            : theme.colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        isLive ? '$statusStr\'' : statusStr.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: isLive
              ? Colors.green
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
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: value),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.green.withValues(alpha: value * 0.5),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimeline(BuildContext context, SoccerMatch match) {
    final theme = Theme.of(context);
    final events = _getSortedEvents(match);

    if (events.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(60),
        child: Column(
          children: [
            Icon(Icons.event_note_rounded,
                size: 48,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
            const SizedBox(height: 16),
            Text(
              match.isScheduled
                  ? 'El partido aún no ha comenzado'
                  : 'Sin eventos registrados',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 24),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: events.length + 2, // Start, End, and events
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildTimelinePoint(
              context, 'Inicio del partido', '0\'', Icons.sports_score_rounded);
        }
        if (index == events.length + 1) {
          String endLabel = match.isFinished ? 'Final del partido' : 'En juego';
          return _buildTimelinePoint(
              context,
              endLabel,
              match.time.isEmpty ? '?' : match.time,
              Icons.sports_score_rounded);
        }

        final event = events[index - 1];
        return _buildTimelineEventRow(context, event, match.homeTeamId);
      },
    );
  }

  Widget _buildTimelinePoint(
      BuildContext context, String title, String time, IconData icon) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF121418).withValues(alpha: 0.5)
            : theme.colorScheme.onSurface.withValues(alpha: 0.05),
      ),
      child: Row(
        children: [
          Expanded(
              child: Text(title,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.5)))),
          const SizedBox(width: 16),
          Column(
            children: [
              Icon(icon, size: 16, color: Colors.blue.shade400),
              const SizedBox(height: 4),
              Text(time,
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.4))),
            ],
          ),
          const SizedBox(width: 16),
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
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.03))),
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
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface)),
                    ],
                  )
                : const SizedBox(),
          ),

          // Center Icon & Time
          const SizedBox(width: 16),
          Column(
            children: [
              _buildEventIcon(event),
              const SizedBox(height: 4),
              Text('${event.time}\'',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.5))),
            ],
          ),
          const SizedBox(width: 16),

          // Right Side (Away)
          Expanded(
            child: !isHome
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(event.playerName,
                          style: GoogleFonts.inter(
                              fontSize: 14,
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

  Widget _buildEventIcon(_MatchEvent event) {
    switch (event.type) {
      case _EventType.goal:
        return const Icon(Icons.sports_soccer_rounded,
            size: 18, color: Colors.green);
      case _EventType.yellowCard:
        return Container(
          width: 12,
          height: 16,
          decoration: BoxDecoration(
              color: Colors.amber, borderRadius: BorderRadius.circular(2)),
        );
      case _EventType.redCard:
        return Container(
          width: 12,
          height: 16,
          decoration: BoxDecoration(
              color: Colors.red, borderRadius: BorderRadius.circular(2)),
        );
      case _EventType.substitution:
        return const Icon(Icons.swap_vert_rounded,
            size: 18, color: Colors.blue);
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

    // Note: Substitutions are not currently in the model,
    // but the structure allows adding them later easily.

    events.sort((a, b) => a.time.compareTo(b.time));
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
