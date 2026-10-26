import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pivote/features/soccer/data/models/soccer_models.dart';
import 'package:pivote/features/video/presentation/providers/channel_provider.dart';
import 'package:pivote/features/video/presentation/screens/player_screen.dart';
import 'package:pivote/core/services/image_cache_helper.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/shared/widgets/common/pivote_loader.dart';
import 'package:pivote/core/animations/app_animations.dart';

class MatchCard extends StatelessWidget {
  final SoccerMatch match;
  final SoccerData? soccerData;
  final VoidCallback onWatchMatch;

  const MatchCard({
    super.key,
    required this.match,
    this.soccerData,
    required this.onWatchMatch,
  });

  bool get isLive => match.isLive;

  Color _effectiveTeamColor(SoccerTeam team, bool isHome) {
    final c = team.primaryColor;
    if (c == null) {
      return isHome ? AppTheme.darkAccent : const Color(0xFF3B82F6);
    }
    // Si es demasiado oscuro en modo oscuro, levantamos luminosidad
    if (c.computeLuminance() < 0.05) {
      return isHome ? const Color(0xFF22C55E) : const Color(0xFF3B82F6);
    }
    // Si es blanco puro en modo oscuro, dar un sutil tinte
    if (c.computeLuminance() > 0.95) {
      return isHome ? const Color(0xFFE2E8F0) : const Color(0xFFCBD5E1);
    }
    return c;
  }

  @override
  Widget build(BuildContext context) {
    if (soccerData == null) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth * 0.88).clamp(310.0, 420.0);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final teamA = soccerData!.teams.firstWhere(
      (t) => t.id == match.homeTeamId,
      orElse: () => SoccerTeam(
        id: match.homeTeamId,
        name: match.homeTeam,
        shortName: match.homeTeam,
      ),
    );
    final teamB = soccerData!.teams.firstWhere(
      (t) => t.id == match.awayTeamId,
      orElse: () => SoccerTeam(
        id: match.awayTeamId,
        name: match.awayTeam,
        shortName: match.awayTeam,
      ),
    );
    final league = soccerData!.leagues.firstWhere(
      (t) => t.id == match.leagueId,
      orElse: () => SoccerLeague(
        id: match.leagueId,
        name: 'Liga',
        country: '',
        shortName: 'L',
      ),
    );

    final homeColor = _effectiveTeamColor(teamA, true);
    final awayColor = _effectiveTeamColor(teamB, false);
    final tournamentLogoUrl = league.logoUrl ?? '';

    final hasMultipleChannels =
        match.tvChannels.where((c) => c.id != null).length > 1;

    return Container(
      width: cardWidth,
      height: 265,
      margin: const EdgeInsets.only(right: 14),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () {
            if (hasMultipleChannels) {
              _showChannelOptions(context);
            } else {
              onWatchMatch();
            }
          },
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // ─── 1. Fondo base ───
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F131C) : theme.cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isLive
                          ? const Color(0xFFFF5468)
                              .withValues(alpha: isDark ? 0.45 : 0.3)
                          : (isDark
                              ? const Color(0xFF1E2533)
                              : AppTheme.lightBorder),
                      width: isLive ? 1.4 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isLive
                            ? const Color(0xFFFF5468)
                                .withValues(alpha: isDark ? 0.22 : 0.12)
                            : Colors.black
                                .withValues(alpha: isDark ? 0.35 : 0.08),
                        blurRadius: isLive ? 22 : 14,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                ),
              ),

              // ─── 2. Glow radial escudo local (izquierda) ───
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: RadialGradient(
                      center: const Alignment(-0.85, -0.05),
                      radius: 1.0,
                      colors: [
                        homeColor.withValues(alpha: isDark ? 0.32 : 0.20),
                        homeColor.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.75],
                    ),
                  ),
                ),
              ),

              // ─── 3. Glow radial escudo visitante (derecha) ───
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: RadialGradient(
                      center: const Alignment(0.85, -0.05),
                      radius: 1.0,
                      colors: [
                        awayColor.withValues(alpha: isDark ? 0.32 : 0.20),
                        awayColor.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.75],
                    ),
                  ),
                ),
              ),

              // ─── 4. Contenido interactivo del Hero ───
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  child: Column(
                    children: [
                      // Header con liga y pill de estado
                      _buildHeader(league, tournamentLogoUrl, theme, isDark),

                      const SizedBox(height: 10),

                      // Línea divisoria horizontal superior
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06),
                      ),

                      const Spacer(),

                      // Match Center: Equipos y Marcador / Hora
                      _buildTeamsMatchCenter(
                        context,
                        teamA,
                        teamB,
                        homeColor,
                        awayColor,
                        theme,
                        isDark,
                      ),

                      const Spacer(),

                      // Línea divisoria horizontal inferior
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06),
                      ),

                      const SizedBox(height: 10),

                      // Footer con botón de acción (Próximo, Ver partido, En vivo)
                      _buildFooter(
                        context,
                        hasMultipleChannels,
                        theme,
                        isDark,
                      ),
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

  // ─── Top Header: Liga, Etapa y Pill de Estado ───
  Widget _buildHeader(
    SoccerLeague league,
    String tournamentLogoUrl,
    ThemeData theme,
    bool isDark,
  ) {
    final showStatusPill = isLive || match.isFinished;

    return Row(
      children: [
        // Logo de la liga
        if (tournamentLogoUrl.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: CachedNetworkImage(
              cacheManager: ImageCacheHelper.logoCacheManager,
              imageUrl: tournamentLogoUrl,
              width: 20,
              height: 20,
              fit: BoxFit.contain,
              errorWidget: (_, __, ___) => const Icon(
                Icons.emoji_events_outlined,
                size: 18,
                color: Colors.amber,
              ),
            ),
          )
        else
          const Icon(
            Icons.emoji_events_outlined,
            size: 18,
            color: Colors.amber,
          ),
        const SizedBox(width: 8),

        // Nombre de la liga y fecha
        Expanded(
          child: Text(
            '${league.name}${match.stage.isNotEmpty ? ' · ${match.stage}' : ''}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.1,
              color: isDark ? const Color(0xFFC7CFDD) : const Color(0xFF334155),
            ),
          ),
        ),
        if (showStatusPill) ...[
          const SizedBox(width: 8),
          _buildStatusPill(theme, isDark),
        ],
      ],
    );
  }

  Widget _buildStatusPill(ThemeData theme, bool isDark) {
    if (isLive) {
      return _PulsingLivePill(
        timeStatus: match.timeStatus.isNotEmpty ? match.timeStatus : 'EN VIVO',
      );
    }

    if (match.isFinished) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF161B27)
              : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isDark
                ? const Color(0xFF1E2533)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: Text(
          'Final',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFF7C879B) : theme.hintColor,
          ),
        ),
      );
    }

    // Para partidos programados, el horario ya se muestra de forma destacada en el centro
    return const SizedBox.shrink();
  }

  // ─── Match Center: Equipo Local, Marcador y Equipo Visitante ───
  Widget _buildTeamsMatchCenter(
    BuildContext context,
    SoccerTeam teamA,
    SoccerTeam teamB,
    Color homeColor,
    Color awayColor,
    ThemeData theme,
    bool isDark,
  ) {
    final homeScorers = match.getScorersSummary(match.homeTeamId);
    final awayScorers = match.getScorersSummary(match.awayTeamId);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Columna Equipo Local
        Expanded(
          child: _buildTeamColumn(
            teamA,
            homeColor,
            homeScorers,
            theme,
            isDark,
          ),
        ),

        // Centro: Marcador / Hora y barra de progreso
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: _buildCenterDisplay(theme, isDark),
        ),

        // Columna Equipo Visitante
        Expanded(
          child: _buildTeamColumn(
            teamB,
            awayColor,
            awayScorers,
            theme,
            isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildTeamColumn(
    SoccerTeam team,
    Color teamColor,
    String scorers,
    ThemeData theme,
    bool isDark,
  ) {
    final logoUrl = team.logoUrl ?? '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Escudo del equipo libre (sin círculo sólido ni borde), solo con el degradado de su color
        Container(
          width: 58,
          height: 58,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                teamColor.withValues(alpha: isDark ? 0.35 : 0.22),
                teamColor.withValues(alpha: 0.0),
              ],
              radius: 0.75,
            ),
          ),
          child: logoUrl.isNotEmpty
              ? CachedNetworkImage(
                  cacheManager: ImageCacheHelper.logoCacheManager,
                  imageUrl: logoUrl,
                  fit: BoxFit.contain,
                  memCacheWidth: 160,
                  memCacheHeight: 160,
                  placeholder: (_, __) => const Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: PivoteLoader(strokeWidth: 2, size: 16),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Center(
                    child: FaIcon(
                      FontAwesomeIcons.shieldHalved,
                      size: 28,
                      color: teamColor,
                    ),
                  ),
                )
              : Center(
                  child: FaIcon(
                    FontAwesomeIcons.shieldHalved,
                    size: 28,
                    color: teamColor,
                  ),
                ),
        ),
        const SizedBox(height: 8),

        // Nombre del equipo
        Text(
          team.shortName.isNotEmpty ? team.shortName : team.name,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
            letterSpacing: -0.2,
          ),
        ),

        // Resumen de goleadores (ej: "Cavani 34'")
        if (scorers.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            scorers,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFB7BFD0) : theme.hintColor,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCenterDisplay(ThemeData theme, bool isDark) {
    final isFinished = match.isFinished;

    // Partido en Vivo o Finalizado con marcador disponible
    if ((isLive || isFinished) && match.score.isNotEmpty) {
      final homeScore =
          match.score.isNotEmpty ? match.score[0].toString() : '0';
      final awayScore =
          match.score.length > 1 ? match.score[1].toString() : '0';

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Marcador gigante
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                homeScore,
                style: GoogleFonts.bigShouldersDisplay(
                  fontSize: 46,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                  color: isLive
                      ? AppTheme.darkAccent
                      : theme.colorScheme.onSurface,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Container(
                  width: 14,
                  height: 4,
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                awayScore,
                style: GoogleFonts.bigShouldersDisplay(
                  fontSize: 46,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                  color: isLive
                      ? AppTheme.darkAccent
                      : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),

          // Barra de progreso del tiempo de juego si está en vivo
          if (isLive) ...[
            const SizedBox(height: 6),
            Container(
              width: 74,
              height: 4,
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: match.elapsedPercent,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.darkAccent,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.darkAccent.withValues(alpha: 0.5),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      );
    }

    // Partido Programado
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          match.formattedTime,
          style: GoogleFonts.bigShouldersDisplay(
            fontSize: 40,
            fontWeight: FontWeight.w900,
            height: 1.0,
            color: isDark ? AppTheme.darkAccent : theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          match.dayLabel.toUpperCase(),
          style: GoogleFonts.spaceGrotesk(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFF7C879B) : theme.hintColor,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  // ─── Footer: Botón de Acción Centrado y Elegante ───
  Widget _buildFooter(
    BuildContext context,
    bool hasMultipleChannels,
    ThemeData theme,
    bool isDark,
  ) {
    return Center(
      child: isLive
          ? _buildLiveButton(context, hasMultipleChannels, theme, isDark)
          : (match.isWatchable
              ? _buildWatchButton(context, hasMultipleChannels, theme, isDark)
              : _buildInfoButton(context, hasMultipleChannels, theme, isDark)),
    );
  }

  Widget _buildLiveButton(
    BuildContext context,
    bool hasMultipleChannels,
    ThemeData theme,
    bool isDark,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton.icon(
          onPressed: onWatchMatch,
          icon: const Icon(Icons.play_arrow_rounded, size: 18),
          label: Text(
            'En vivo',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF5468),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
            shadowColor: const Color(0xFFFF5468).withValues(alpha: 0.4),
          ),
        ),
        if (hasMultipleChannels) ...[
          const SizedBox(width: 8),
          _buildOptionsButton(context, theme, isDark),
        ],
      ],
    );
  }

  Widget _buildWatchButton(
    BuildContext context,
    bool hasMultipleChannels,
    ThemeData theme,
    bool isDark,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton.icon(
          onPressed: onWatchMatch,
          icon: const Icon(Icons.play_arrow_rounded, size: 18),
          label: Text(
            'Ver partido',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isDark ? AppTheme.darkAccent : theme.colorScheme.primary,
            foregroundColor: isDark ? Colors.black : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
        ),
        if (hasMultipleChannels) ...[
          const SizedBox(width: 8),
          _buildOptionsButton(context, theme, isDark),
        ],
      ],
    );
  }

  Widget _buildInfoButton(
    BuildContext context,
    bool hasMultipleChannels,
    ThemeData theme,
    bool isDark,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (hasMultipleChannels) {
                _showChannelOptions(context);
              } else {
                onWatchMatch();
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF161B27)
                    : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF1E2533)
                      : Colors.black.withValues(alpha: 0.06),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 15,
                    color: isDark ? const Color(0xFF7C879B) : theme.hintColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Próximo',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFF9EABB9) : theme.hintColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (hasMultipleChannels) ...[
          const SizedBox(width: 8),
          _buildOptionsButton(context, theme, isDark),
        ],
      ],
    );
  }

  Widget _buildOptionsButton(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B27) : AppTheme.lightBg2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF1E2533) : AppTheme.lightBorder,
        ),
      ),
      child: IconButton(
        onPressed: () => _showChannelOptions(context),
        icon: Icon(
          Icons.more_horiz_rounded,
          color: isDark ? const Color(0xFFAAB3C5) : theme.hintColor,
          size: 18,
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }

  void _showChannelOptions(BuildContext context) {
    final channelProvider = Provider.of<ChannelProvider>(
      context,
      listen: false,
    );
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.hintColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Selecciona una señal',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                '${match.homeTeam} vs ${match.awayTeam}',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.hintColor,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Divider(
              height: 1,
              color: isDark
                  ? AppTheme.darkBorder.withValues(alpha: 0.3)
                  : AppTheme.lightBorder.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 8),
            ...match.tvChannels.map((soccerChannel) {
              if (soccerChannel.id == null) return const SizedBox.shrink();
              final channel = channelProvider.getChannelById(soccerChannel.id!);

              if (channel == null) return const SizedBox.shrink();

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 4,
                ),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkBg3 : AppTheme.lightBg2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? AppTheme.darkBorder.withValues(alpha: 0.3)
                          : AppTheme.lightBorder,
                    ),
                  ),
                  padding: const EdgeInsets.all(6),
                  child: channel.logoUrl.isNotEmpty
                      ? CachedNetworkImage(
                          cacheManager: ImageCacheHelper.logoCacheManager,
                          imageUrl: channel.logoUrl.first,
                          fit: BoxFit.contain,
                          memCacheWidth: 150,
                          memCacheHeight: 150,
                          errorWidget: (_, __, ___) => Icon(
                            Icons.live_tv_rounded,
                            color: isDark
                                ? AppTheme.darkAccent
                                : theme.colorScheme.primary,
                            size: 22,
                          ),
                        )
                      : Icon(
                          Icons.live_tv_rounded,
                          color: isDark
                              ? AppTheme.darkAccent
                              : theme.colorScheme.primary,
                          size: 22,
                        ),
                ),
                title: Text(
                  channel.name,
                  style: GoogleFonts.spaceGrotesk(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                trailing: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: (isDark
                            ? AppTheme.darkAccent
                            : theme.colorScheme.primary)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: isDark
                        ? AppTheme.darkAccent
                        : theme.colorScheme.primary,
                    size: 18,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    AppAnimations.createFadeRoute(
                      PlayerScreen(channel: channel),
                    ),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// Pulsing live indicator pill with animated glowing dot
class _PulsingLivePill extends StatefulWidget {
  final String timeStatus;

  const _PulsingLivePill({required this.timeStatus});

  @override
  State<_PulsingLivePill> createState() => _PulsingLivePillState();
}

class _PulsingLivePillState extends State<_PulsingLivePill>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.35, end: 1.0).animate(
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
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFF5468).withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: const Color(0xFFFF5468).withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5468)
                      .withValues(alpha: _pulseAnimation.value),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF5468)
                          .withValues(alpha: _pulseAnimation.value * 0.6),
                      blurRadius: 5,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                widget.timeStatus,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFFF5468),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
