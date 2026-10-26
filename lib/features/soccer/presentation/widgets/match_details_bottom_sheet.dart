import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import 'package:pivote/features/soccer/data/models/soccer_models.dart';
import 'package:pivote/features/soccer/presentation/widgets/soccer_pitch_painter.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/services/image_cache_helper.dart';
import 'package:pivote/core/services/app_activity_service.dart';
import 'package:pivote/features/video/presentation/providers/channel_provider.dart';
import 'package:pivote/features/video/presentation/screens/player_screen.dart';
import 'package:pivote/core/animations/app_animations.dart';

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
    final activityService =
        Provider.of<AppActivityService>(context, listen: false);
    Future.delayed(Duration.zero, () {
      try {
        activityService.trackMatchView();
      } catch (e) {
        debugPrint('Error tracking match view: $e');
      }
    });

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final goals = List<SoccerGoal>.from(match.goals)
      ..sort((a, b) => a.time.compareTo(b.time));

    final homeColor = homeTeam.primaryColor ?? AppTheme.darkAccent;
    final awayColor = awayTeam.primaryColor ?? const Color(0xFF3B82F6);

    final watchableChannels =
        match.tvChannels.where((c) => c.name.isNotEmpty).toList();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1017) : theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: isDark ? const Color(0xFF1E2533) : AppTheme.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 38,
              height: 4.5,
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ─── Banner con cancha de fondo y aura de escudos ───
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: isDark ? const Color(0xFF131722) : theme.cardColor,
              border: Border.all(
                color: isDark ? const Color(0xFF1E2533) : AppTheme.lightBorder,
              ),
            ),
            child: Stack(
              children: [
                // Glow local
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: RadialGradient(
                        center: const Alignment(-1.1, 0.0),
                        radius: 1.2,
                        colors: [
                          homeColor.withValues(alpha: isDark ? 0.35 : 0.20),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Glow visitante
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: RadialGradient(
                        center: const Alignment(1.1, 0.0),
                        radius: 1.2,
                        colors: [
                          awayColor.withValues(alpha: isDark ? 0.35 : 0.20),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Pitch outline
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: CustomPaint(
                      painter: SoccerPitchPainter(
                        lineColor: (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: isDark ? 0.09 : 0.06),
                      ),
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    children: [
                      // Torneo y fase
                      Text(
                        '${league.name}${match.stage.isNotEmpty ? ' · ${match.stage}' : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? const Color(0xFFAAB3C5)
                              : theme.hintColor,
                        ),
                      ),
                      const Spacer(),
                      // Equipos y Marcador
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Local
                          Expanded(
                            child: _buildTeamBadge(
                              homeTeam,
                              homeColor,
                              theme,
                              isDark,
                            ),
                          ),
                          // Marcador / Hora central
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: _buildScoreCenter(theme, isDark),
                          ),
                          // Visitante
                          Expanded(
                            child: _buildTeamBadge(
                              awayTeam,
                              awayColor,
                              theme,
                              isDark,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ─── Contenido Scrolleable (Canales de TV + Goles + Tarjetas) ───
          Flexible(
            child: ListView(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                // Canales disponibles para ver
                if (watchableChannels.isNotEmpty) ...[
                  Text(
                    'SEÑALES DISPONIBLES',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: isDark ? const Color(0xFF7C879B) : theme.hintColor,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: watchableChannels.map((c) {
                      return _buildChannelChip(context, c, theme, isDark);
                    }).toList(),
                  ),
                  const SizedBox(height: 18),
                ],

                // Goles del partido
                Text(
                  'GOLES Y EVENTOS',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: isDark ? const Color(0xFF7C879B) : theme.hintColor,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),

                if (goals.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'Aún no hay goles registrados en este partido',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFF7C879B)
                              : theme.hintColor,
                        ),
                      ),
                    ),
                  )
                else
                  ...goals.map((g) {
                    final isHome = g.teamId == match.homeTeamId;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color:
                            isDark ? const Color(0xFF131722) : theme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF1E2533)
                              : AppTheme.lightBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: isHome
                                ? Text(
                                    g.playerShortName,
                                    textAlign: TextAlign.right,
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color:
                                    AppTheme.darkAccent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                g.timeToDisplay.isNotEmpty
                                    ? g.timeToDisplay
                                    : "${g.time}'",
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.darkAccent,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: !isHome
                                ? Text(
                                    g.playerShortName,
                                    textAlign: TextAlign.left,
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    );
                  }),

                const SizedBox(height: 24),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  Widget _buildTeamBadge(
    SoccerTeam team,
    Color teamColor,
    ThemeData theme,
    bool isDark,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? const Color(0xFF0F131C) : Colors.white,
            border: Border.all(
              color: teamColor.withValues(alpha: 0.3),
              width: 1.2,
            ),
          ),
          padding: const EdgeInsets.all(5),
          child: (team.logoUrl != null && team.logoUrl!.isNotEmpty)
              ? CachedNetworkImage(
                  cacheManager: ImageCacheHelper.logoCacheManager,
                  imageUrl: team.logoUrl!,
                  fit: BoxFit.contain,
                  errorWidget: (_, __, ___) => FaIcon(
                    FontAwesomeIcons.shield,
                    size: 18,
                    color: teamColor,
                  ),
                )
              : FaIcon(
                  FontAwesomeIcons.shield,
                  size: 18,
                  color: teamColor,
                ),
        ),
        const SizedBox(height: 6),
        Text(
          team.shortName.isNotEmpty ? team.shortName : team.name,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreCenter(ThemeData theme, bool isDark) {
    final isLive = match.isLive;
    final isFinished = match.isFinished;

    if ((isLive || isFinished) && match.score.isNotEmpty) {
      final h = match.score.isNotEmpty ? match.score[0] : 0;
      final a = match.score.length > 1 ? match.score[1] : 0;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$h',
                style: GoogleFonts.bigShouldersDisplay(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: isLive
                      ? AppTheme.darkAccent
                      : theme.colorScheme.onSurface,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  ':',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: isDark ? const Color(0xFF7C879B) : theme.hintColor,
                  ),
                ),
              ),
              Text(
                '$a',
                style: GoogleFonts.bigShouldersDisplay(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: isLive
                      ? AppTheme.darkAccent
                      : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isLive
                  ? const Color(0xFFFF5468).withValues(alpha: 0.15)
                  : (isDark
                      ? const Color(0xFF161B27)
                      : Colors.black.withValues(alpha: 0.05)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isLive
                  ? (match.timeStatus.isNotEmpty ? match.timeStatus : 'EN VIVO')
                  : 'FINAL',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: isLive
                    ? const Color(0xFFFF5468)
                    : (isDark ? const Color(0xFF7C879B) : theme.hintColor),
              ),
            ),
          ),
        ],
      );
    }

    // Programado
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          match.formattedTime,
          style: GoogleFonts.bigShouldersDisplay(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: isDark ? AppTheme.darkAccent : theme.colorScheme.primary,
          ),
        ),
        Text(
          match.dayLabel.toUpperCase(),
          style: GoogleFonts.spaceGrotesk(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFF7C879B) : theme.hintColor,
          ),
        ),
      ],
    );
  }

  Widget _buildChannelChip(
    BuildContext context,
    SoccerTVChannel soccerChannel,
    ThemeData theme,
    bool isDark,
  ) {
    final channelProvider =
        Provider.of<ChannelProvider>(context, listen: false);
    final mappedChannel = soccerChannel.id != null
        ? channelProvider.getChannelById(soccerChannel.id!)
        : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: mappedChannel != null
            ? () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  AppAnimations.createFadeRoute(
                    PlayerScreen(channel: mappedChannel),
                  ),
                );
              }
            : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131722) : theme.cardColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: mappedChannel != null
                  ? (isDark
                      ? AppTheme.darkAccent.withValues(alpha: 0.3)
                      : theme.colorScheme.primary.withValues(alpha: 0.3))
                  : (isDark ? const Color(0xFF1E2533) : AppTheme.lightBorder),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                mappedChannel != null
                    ? Icons.play_circle_fill_rounded
                    : Icons.tv_rounded,
                size: 14,
                color: mappedChannel != null
                    ? (isDark ? AppTheme.darkAccent : theme.colorScheme.primary)
                    : (isDark ? const Color(0xFF7C879B) : theme.hintColor),
              ),
              const SizedBox(width: 6),
              Text(
                soccerChannel.name,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: mappedChannel != null
                      ? theme.colorScheme.onSurface
                      : (isDark ? const Color(0xFF7C879B) : theme.hintColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
