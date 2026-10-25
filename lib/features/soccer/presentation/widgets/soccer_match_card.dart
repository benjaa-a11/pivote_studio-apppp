import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pivote/features/soccer/data/models/soccer_models.dart';
import 'package:pivote/core/services/image_cache_helper.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/features/soccer/presentation/widgets/match_details_bottom_sheet.dart';
import 'package:pivote/shared/widgets/common/apple_pressable.dart';

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

  bool get isLive => match.isLive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final homeTeam = data.teams.firstWhere(
      (t) => t.id == match.homeTeamId,
      orElse: () => SoccerTeam(
        id: match.homeTeamId,
        name: match.homeTeam,
        shortName: match.homeTeam,
      ),
    );
    final awayTeam = data.teams.firstWhere(
      (t) => t.id == match.awayTeamId,
      orElse: () => SoccerTeam(
        id: match.awayTeamId,
        name: match.awayTeam,
        shortName: match.awayTeam,
      ),
    );
    final league = data.leagues.firstWhere(
      (l) => l.id == match.leagueId,
      orElse: () => SoccerLeague(
        id: match.leagueId,
        name: 'Torneo',
        country: '',
        shortName: '',
      ),
    );

    final homeScorers = match.getScorersSummary(match.homeTeamId);
    final awayScorers = match.getScorersSummary(match.awayTeamId);

    // Determinar ganador en finalizados
    int winner = 0; // 0 = empate / no finalizado, 1 = local, 2 = visitante
    if (match.isFinished && match.score.length >= 2) {
      final h = int.tryParse(match.score[0].toString()) ?? 0;
      final a = int.tryParse(match.score[1].toString()) ?? 0;
      if (h > a) winner = 1;
      if (a > h) winner = 2;
    }

    final hasChannels = match.tvChannels.any((c) => c.name.isNotEmpty);

    return ApplePressable(
      scaleDownFactor: 0.985,
      borderRadius: isLast
          ? const BorderRadius.vertical(bottom: Radius.circular(20))
          : BorderRadius.zero,
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) {
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
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
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F131C) : theme.cardColor,
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                    color: isDark
                        ? const Color(0xFF1E2533)
                        : AppTheme.lightBorder.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
        ),
        child: Stack(
          children: [
            // Barra vertical izquierda si está en vivo (estilo Pivote Live HTML)
            if (isLive)
              Positioned(
                left: 0,
                top: 8,
                bottom: 8,
                width: 3.5,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5468),
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF5468).withValues(alpha: 0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Columna 1: Estado / Tiempo
                  SizedBox(
                    width: 60,
                    child: _buildStatusColumn(theme, isDark),
                  ),

                  const SizedBox(width: 10),

                  // Columna 2: Equipos, Goles y Marcadores
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTeamLine(
                          team: homeTeam,
                          score: match.score.isNotEmpty ? match.score[0] : null,
                          scorers: homeScorers,
                          isWinner: winner == 1,
                          isLoser: winner == 2,
                          theme: theme,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 7),
                        _buildTeamLine(
                          team: awayTeam,
                          score: match.score.length > 1 ? match.score[1] : null,
                          scorers: awayScorers,
                          isWinner: winner == 2,
                          isLoser: winner == 1,
                          theme: theme,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Columna 3: Icono de señal o chevron
                  _buildTrailingAction(hasChannels, theme, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusColumn(ThemeData theme, bool isDark) {
    if (isLive) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF5468),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  match.timeStatus.isNotEmpty ? match.timeStatus : 'VIVO',
                  maxLines: 1,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFFF5468),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'En vivo',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFFF5468).withValues(alpha: 0.8),
            ),
          ),
        ],
      );
    }

    if (match.isFinished) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Final',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: isDark ? const Color(0xFFEEF1F6) : theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            match.dayLabel,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF7C879B) : theme.hintColor,
            ),
          ),
        ],
      );
    }

    // Programado
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          match.formattedTime,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: isDark ? AppTheme.darkAccent : theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          match.dayLabel,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFF7C879B) : theme.hintColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTeamLine({
    required SoccerTeam team,
    required dynamic score,
    required String scorers,
    required bool isWinner,
    required bool isLoser,
    required ThemeData theme,
    required bool isDark,
  }) {
    final teamColor = team.primaryColor ?? (isDark ? const Color(0xFF262C36) : AppTheme.lightBorder);
    final scoreStr = score != null ? score.toString() : '';

    final nameColor = isLoser
        ? (isDark ? const Color(0xFF7C879B) : theme.hintColor)
        : (isDark ? const Color(0xFFEEF1F6) : theme.colorScheme.onSurface);

    final scoreColor = isLive
        ? AppTheme.darkAccent
        : isWinner
            ? (isDark ? const Color(0xFFEEF1F6) : theme.colorScheme.onSurface)
            : (isDark ? const Color(0xFF7C879B) : theme.hintColor);

    return Row(
      children: [
        // Escudo del equipo con sutil borde de su color
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? const Color(0xFF161B27) : Colors.white,
            border: Border.all(
              color: teamColor.withValues(alpha: isDark ? 0.35 : 0.2),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(2),
          child: (team.logoUrl != null && team.logoUrl!.isNotEmpty)
              ? CachedNetworkImage(
                  cacheManager: ImageCacheHelper.logoCacheManager,
                  imageUrl: team.logoUrl!,
                  fit: BoxFit.contain,
                  memCacheWidth: 80,
                  memCacheHeight: 80,
                  errorWidget: (_, __, ___) => FaIcon(
                    FontAwesomeIcons.shield,
                    size: 11,
                    color: teamColor,
                  ),
                )
              : FaIcon(
                  FontAwesomeIcons.shield,
                  size: 11,
                  color: teamColor,
                ),
        ),
        const SizedBox(width: 8),

        // Nombre del equipo + goleadores
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                team.shortName.isNotEmpty ? team.shortName : team.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: isWinner || isLive ? FontWeight.w800 : FontWeight.w600,
                  color: nameColor,
                ),
              ),
              if (scorers.isNotEmpty)
                Text(
                  scorers,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF7C879B) : theme.hintColor,
                  ),
                ),
            ],
          ),
        ),

        // Marcador del equipo
        if (scoreStr.isNotEmpty) ...[
          const SizedBox(width: 8),
          Text(
            scoreStr,
            style: GoogleFonts.bigShouldersDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1.0,
              color: scoreColor,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTrailingAction(bool hasChannels, ThemeData theme, bool isDark) {
    if (isLive && hasChannels) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: const Color(0xFFFF5468).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.play_arrow_rounded,
          size: 16,
          color: Color(0xFFFF5468),
        ),
      );
    }

    if (hasChannels) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: (isDark ? AppTheme.darkAccent : theme.colorScheme.primary)
              .withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.tv_rounded,
          size: 14,
          color: isDark ? AppTheme.darkAccent : theme.colorScheme.primary,
        ),
      );
    }

    return Icon(
      Icons.chevron_right_rounded,
      size: 18,
      color: isDark ? const Color(0xFF7C879B) : theme.hintColor.withValues(alpha: 0.5),
    );
  }
}
