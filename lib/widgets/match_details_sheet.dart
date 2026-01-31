import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
              height: 300, child: Center(child: CircularProgressIndicator()));
        }

        SoccerMatch? match;
        try {
          match = soccerData.matches.firstWhere((m) => m.id == matchId);
        } catch (e) {
          return const SizedBox(
              height: 200,
              child: Center(
                  child: Text('Partido no encontrado',
                      style: TextStyle(color: Colors.white))));
        }
        final currentMatch = match;

        final league = soccerData.leagues.firstWhere(
            (l) => l.id == currentMatch.leagueId,
            orElse: () => SoccerLeague(
                id: currentMatch.leagueId,
                name: 'Liga',
                country: '',
                shortName: 'LIGA'));

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

        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: (isDark ? const Color(0xFF13191F) : Colors.white)
                    .withValues(alpha: 0.85),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(40)),
                border: Border(
                  top: BorderSide(
                      color: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.08)),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 48,
                    height: 6,
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // League Header
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      league.name.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.0,
                        fontSize: 10,
                      ),
                    ),
                  ),

                  // Scoreboard
                  _buildTemplateScoreboard(match, homeTeam, awayTeam, theme),

                  const SizedBox(height: 32),

                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Goals Section
                          _buildEventSection(
                            title: 'Goles',
                            icon: FontAwesomeIcons.futbol,
                            iconColor: theme.colorScheme.primary,
                            events: match.goals
                                .map((g) => _EventData(
                                      name: g.playerShortName,
                                      time: g.timeToDisplay,
                                      isHome:
                                          g.teamId == currentMatch.homeTeamId,
                                    ))
                                .toList(),
                            emptyText: 'Sin goles registrados',
                            theme: theme,
                          ),

                          const SizedBox(height: 24),

                          // Yellow Cards Section
                          _buildEventSection(
                            title: 'Tarjetas Amarillas',
                            icon: FontAwesomeIcons.solidSquare,
                            iconColor: Colors.amber,
                            events: match.yellowCards
                                .map((c) => _EventData(
                                      name: c.playerShortName,
                                      time: c.timeToDisplay,
                                      isHome: c.teamId == match!.homeTeamId,
                                    ))
                                .toList(),
                            emptyText: 'Sin tarjetas amarillas',
                            theme: theme,
                          ),

                          const SizedBox(height: 24),

                          // Red Cards Section
                          _buildEventSection(
                            title: 'Tarjetas Rojas',
                            icon: FontAwesomeIcons.solidSquare,
                            iconColor: Colors.red,
                            events: match.redCards
                                .map((c) => _EventData(
                                      name: c.playerShortName,
                                      time: c.timeToDisplay,
                                      isHome: c.teamId == match!.homeTeamId,
                                    ))
                                .toList(),
                            emptyText: 'Sin tarjetas rojas',
                            theme: theme,
                          ),

                          if (match.tvChannels.isNotEmpty) ...[
                            const SizedBox(height: 32),
                            _buildSectionHeader(
                                'Transmisión', Icons.live_tv_rounded, theme),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: match.tvChannels
                                    .map((channel) =>
                                        _buildChannelBadge(channel, theme))
                                    .toList(),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTemplateScoreboard(
      SoccerMatch match, SoccerTeam home, SoccerTeam away, ThemeData theme) {
    final homeScore = match.score.isNotEmpty ? match.score[0] : 0;
    final awayScore =
        match.score.isNotEmpty && match.score.length > 1 ? match.score[1] : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Row(
        children: [
          // Home Team
          Expanded(
            child: Column(
              children: [
                _buildTeamLogo(home.logoUrl, theme),
                const SizedBox(height: 12),
                Text(
                  home.shortName,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Center Score & Status
          Column(
            children: [
              // Status Badge
              _buildModernStatusBadge(match, theme),
              const SizedBox(height: 12),
              // Score
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Row(
                  key: ValueKey('$homeScore-$awayScore'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$homeScore',
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '-',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w200,
                        color: theme.hintColor.withValues(alpha: 0.2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$awayScore',
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Away Team
          Expanded(
            child: Column(
              children: [
                _buildTeamLogo(away.logoUrl, theme),
                const SizedBox(height: 12),
                Text(
                  away.shortName,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamLogo(String? url, ThemeData theme) {
    return Container(
      width: 64,
      height: 64,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: url != null
          ? CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.contain,
              placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2)),
              errorWidget: (context, url, error) =>
                  const Icon(Icons.shield, color: Colors.white24),
            )
          : const Icon(Icons.shield, color: Colors.white24, size: 32),
    );
  }

  Widget _buildModernStatusBadge(SoccerMatch match, ThemeData theme) {
    final isLive = match.isLive;
    final color = isLive ? const Color(0xFFFF4B4B) : theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLive) ...[
            _buildLiveIndicator(),
            const SizedBox(width: 6),
          ],
          Text(
            (isLive ? "LIVE ${match.time.replaceAll("'", "")}'" : match.status)
                .toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 9,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveIndicator() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1.0),
      duration: const Duration(seconds: 1),
      builder: (context, value, child) {
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: const Color(0xFFFF4B4B).withValues(alpha: value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildEventSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<_EventData> events,
    required String emptyText,
    required ThemeData theme,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 10),
              Text(
                title.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 10,
                ),
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
        ),
        Container(height: 1, color: Colors.white.withValues(alpha: 0.05)),
        const SizedBox(height: 12),
        if (events.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text(
                emptyText,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Colors.white.withValues(alpha: 0.2),
                  fontSize: 10,
                ),
              ),
            ),
          )
        else
          ...events.map((event) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    if (event.isHome) ...[
                      Text(
                        "${event.time} ${event.name}",
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 11,
                        ),
                      ),
                      const Spacer(),
                    ] else ...[
                      const Spacer(),
                      Text(
                        "${event.time} ${event.name}",
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              )),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.primary),
        const SizedBox(width: 10),
        Text(
          title.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 10,
          ),
        ),
        const Expanded(child: SizedBox()),
      ],
    );
  }

  Widget _buildChannelBadge(String name, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.play_circle_fill,
              size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            name,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _EventData {
  final String name;
  final String time;
  final bool isHome;

  _EventData({required this.name, required this.time, required this.isHome});
}
