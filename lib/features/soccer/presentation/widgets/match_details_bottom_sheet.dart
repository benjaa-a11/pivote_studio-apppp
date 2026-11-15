import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/core/services/app_activity_service.dart';
import 'package:pivote/core/services/image_cache_helper.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/features/soccer/data/models/soccer_models.dart';
import 'package:pivote/features/video/data/models/channel.dart';
import 'package:pivote/features/video/presentation/providers/channel_provider.dart';
import 'package:pivote/features/video/presentation/screens/player_screen.dart';

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
    final channelProvider = context.watch<ChannelProvider>();

    final homeColor = homeTeam.primaryColor ?? AppColors.accent;
    final awayColor = awayTeam.primaryColor ?? AppColors.violet;

    // Resolver canales reproducibles en la app por `id`
    final playableChannels = <_ResolvedBroadcast>[];
    final otherBroadcasts = <SoccerTVChannel>[];
    final seenChannelIds = <String>{};

    for (final b in match.tvChannels) {
      final bid = b.id?.trim();
      if (bid != null && bid.isNotEmpty) {
        final appChannel = channelProvider.getChannelById(bid);
        if (appChannel != null && seenChannelIds.add(appChannel.id)) {
          playableChannels.add(_ResolvedBroadcast(broadcast: b, channel: appChannel));
          continue;
        }
      }
      if (b.name.trim().isNotEmpty) {
        otherBroadcasts.add(b);
      }
    }

    // Construir línea de tiempo cronológica (goles + tarjetas)
    final timeline = <_TimelineEvent>[
      for (final g in match.goals)
        _TimelineEvent(
          minute: g.time,
          minuteDisplay: g.timeToDisplay.isNotEmpty ? g.timeToDisplay : "${g.time}'",
          isHome: g.teamSide == 'home' || g.teamId == homeTeam.id,
          type: _TimelineType.goal,
          title: g.playerName.isNotEmpty ? g.playerName : g.playerShortName,
          badge: g.isPenalty
              ? 'Penal'
              : g.isOwnGoal
                  ? 'En contra'
                  : 'Gol',
        ),
      for (final c in match.cards)
        _TimelineEvent(
          minute: c.time,
          minuteDisplay: c.timeToDisplay.isNotEmpty ? c.timeToDisplay : "${c.time}'",
          isHome: c.teamSide == 'home' || c.teamId == homeTeam.id,
          type: c.isRed ? _TimelineType.redCard : _TimelineType.yellowCard,
          title: c.playerName.isNotEmpty ? c.playerName : c.playerShortName,
          badge: c.isRed ? 'Roja' : 'Amarilla',
        ),
    ]..sort((a, b) => a.minute.compareTo(b.minute));

    final bgColor = isDark
        ? const Color(0xF211151F)
        : AppTheme.lightBg1.withValues(alpha: 0.98);
    final cardColor = isDark ? AppColors.darkBg2 : AppTheme.lightBg2;
    final borderColor = isDark ? AppColors.glassBorder : AppTheme.lightBorder;
    final mutedColor = isDark ? AppColors.darkText3 : AppColors.lightText3;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: borderColor, width: 1)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Grab handle
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkBorder2
                          : AppColors.lightBorder2,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),

                Flexible(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ─── CABECERA SCOREBOARD (estilo .es-h) ───
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkBg1 : AppTheme.lightBg2,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: borderColor),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            children: [
                              if (isDark)
                                Positioned.fill(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.topRight,
                                        colors: [
                                          homeColor.withValues(alpha: 0.22),
                                          Colors.transparent,
                                          awayColor.withValues(alpha: 0.22),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                                child: Column(
                                  children: [
                                    // Liga + instancia
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        if (league.logoUrl != null &&
                                            league.logoUrl!.isNotEmpty) ...[
                                          CachedNetworkImage(
                                            imageUrl: league.logoUrl!,
                                            cacheManager:
                                                ImageCacheHelper.logoCacheManager,
                                            width: 18,
                                            height: 18,
                                            fit: BoxFit.contain,
                                            errorWidget: (_, __, ___) =>
                                                const SizedBox.shrink(),
                                          ),
                                          const SizedBox(width: 6),
                                        ],
                                        Flexible(
                                          child: Text(
                                            [
                                              league.name,
                                              if (match.stageRound.isNotEmpty &&
                                                  match.stageRound != league.name)
                                                match.stageRound,
                                            ].join(' · '),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppFont.primary(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: isDark
                                                  ? AppColors.darkText2
                                                  : AppColors.lightText2,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),

                                    // Equipos y marcador
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: _TeamColumn(
                                            team: homeTeam,
                                            accent: homeColor,
                                            isDark: isDark,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                          child: Column(
                                            children: [
                                              _StatusPill(match: match, isDark: isDark),
                                              const SizedBox(height: 10),
                                              if (match.isScheduled &&
                                                  !match.isLive &&
                                                  !match.isFinished)
                                                Text(
                                                  match.formattedTime.isNotEmpty
                                                      ? match.formattedTime
                                                      : 'VS',
                                                  style: AppFont.primary(
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.w900,
                                                    color: theme.colorScheme.onSurface,
                                                  ),
                                                )
                                              else
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      '${homeTeam.score}',
                                                      style: AppFont.primary(
                                                        fontSize: 34,
                                                        fontWeight: FontWeight.w900,
                                                        letterSpacing: -1,
                                                        color: theme.colorScheme.onSurface,
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                      ),
                                                      child: Text(
                                                        '-',
                                                        style: AppFont.primary(
                                                          fontSize: 22,
                                                          fontWeight: FontWeight.w700,
                                                          color: mutedColor,
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      '${awayTeam.score}',
                                                      style: AppFont.primary(
                                                        fontSize: 34,
                                                        fontWeight: FontWeight.w900,
                                                        letterSpacing: -1,
                                                        color: theme.colorScheme.onSurface,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: _TeamColumn(
                                            team: awayTeam,
                                            accent: awayColor,
                                            isDark: isDark,
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Chips de estadio / nota / estado
                                    if (match.venue != null &&
                                        match.venue!.formatted.isNotEmpty) ...[
                                      const SizedBox(height: 14),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? Colors.black.withValues(alpha: 0.28)
                                              : Colors.white.withValues(alpha: 0.7),
                                          borderRadius:
                                              BorderRadius.circular(AppRadius.pill),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.stadium_outlined,
                                              size: 14,
                                              color: mutedColor,
                                            ),
                                            const SizedBox(width: 6),
                                            Flexible(
                                              child: Text(
                                                match.venue!.formatted,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: AppFont.primary(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: isDark
                                                      ? AppColors.darkText2
                                                      : AppColors.lightText2,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ─── VER EN VIVO (canales mapeados en nuestra DB) ───
                        if (playableChannels.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _SectionCard(
                            title: 'Disponible en Pivote',
                            icon: Icons.live_tv_rounded,
                            iconColor: AppColors.live,
                            cardColor: cardColor,
                            borderColor: borderColor,
                            child: Column(
                              children: [
                                for (int i = 0; i < playableChannels.length; i++) ...[
                                  if (i > 0) const SizedBox(height: 8),
                                  _PlayableChannelTile(
                                    resolved: playableChannels[i],
                                    isDark: isDark,
                                    onTap: () {
                                      HapticFeedback.mediumImpact();
                                      final ch = playableChannels[i].channel;
                                      Navigator.pop(context);
                                      Navigator.push(
                                        context,
                                        AppAnimations.createRoute(
                                          PlayerScreen(channel: ch),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],

                        // ─── OTRAS TRANSMISIONES ───
                        if (otherBroadcasts.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _SectionCard(
                            title: 'Transmisión oficial',
                            icon: Icons.tv_rounded,
                            iconColor: AppTheme.accent(context),
                            cardColor: cardColor,
                            borderColor: borderColor,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: otherBroadcasts
                                  .map((b) => _BroadcastChip(
                                        broadcast: b,
                                        isDark: isDark,
                                      ))
                                  .toList(),
                            ),
                          ),
                        ],

                        // ─── LÍNEA DE TIEMPO (Goles y Tarjetas) ───
                        if (timeline.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _SectionCard(
                            title: 'Incidencias del partido',
                            icon: Icons.timeline_rounded,
                            iconColor: AppColors.positive,
                            cardColor: cardColor,
                            borderColor: borderColor,
                            child: Column(
                              children: [
                                for (int i = 0; i < timeline.length; i++) ...[
                                  if (i > 0)
                                    Divider(
                                      height: 14,
                                      color: borderColor.withValues(alpha: 0.5),
                                    ),
                                  _TimelineRow(
                                    event: timeline[i],
                                    homeColor: homeColor,
                                    awayColor: awayColor,
                                    isDark: isDark,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],

                        // ─── CUOTAS / PROBABILIDADES ───
                        if (match.odds != null && match.odds!.hasValues) ...[
                          const SizedBox(height: 12),
                          _SectionCard(
                            title: match.odds!.provider.isNotEmpty
                                ? 'Cuotas · ${match.odds!.provider}'
                                : 'Cuotas del partido',
                            icon: Icons.analytics_outlined,
                            iconColor: AppColors.warning,
                            cardColor: cardColor,
                            borderColor: borderColor,
                            child: _OddsBar(
                              odds: match.odds!,
                              homeLabel: homeTeam.shortName.isNotEmpty
                                  ? homeTeam.shortName
                                  : homeTeam.name,
                              awayLabel: awayTeam.shortName.isNotEmpty
                                  ? awayTeam.shortName
                                  : awayTeam.name,
                              homeColor: homeColor,
                              awayColor: awayColor,
                              isDark: isDark,
                            ),
                          ),
                        ],

                        // ─── RACHA RECIENTE (FORM) ───
                        if (homeTeam.form.isNotEmpty || awayTeam.form.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _SectionCard(
                            title: 'Forma reciente',
                            icon: Icons.trending_up_rounded,
                            iconColor: AppTheme.accent(context),
                            cardColor: cardColor,
                            borderColor: borderColor,
                            child: Column(
                              children: [
                                if (homeTeam.form.isNotEmpty)
                                  _FormRow(
                                    teamName: homeTeam.shortName.isNotEmpty
                                        ? homeTeam.shortName
                                        : homeTeam.name,
                                    form: homeTeam.form,
                                    isDark: isDark,
                                  ),
                                if (homeTeam.form.isNotEmpty &&
                                    awayTeam.form.isNotEmpty)
                                  const SizedBox(height: 10),
                                if (awayTeam.form.isNotEmpty)
                                  _FormRow(
                                    teamName: awayTeam.shortName.isNotEmpty
                                        ? awayTeam.shortName
                                        : awayTeam.name,
                                    form: awayTeam.form,
                                    isDark: isDark,
                                  ),
                              ],
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
      ),
    );
  }
}

class _ResolvedBroadcast {
  final SoccerTVChannel broadcast;
  final Channel channel;
  const _ResolvedBroadcast({required this.broadcast, required this.channel});
}

class _TeamColumn extends StatelessWidget {
  final SoccerTeam team;
  final Color accent;
  final bool isDark;

  const _TeamColumn({
    required this.team,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subColor = isDark ? AppColors.darkText3 : AppColors.lightText3;

    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.white,
            border: Border.all(
              color: accent.withValues(alpha: 0.55),
              width: 1.6,
            ),
          ),
          child: team.logoUrl != null && team.logoUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: team.logoUrl!,
                  cacheManager: ImageCacheHelper.logoCacheManager,
                  fit: BoxFit.contain,
                  errorWidget: (_, __, ___) => Icon(
                    Icons.shield_outlined,
                    size: 26,
                    color: subColor,
                  ),
                )
              : Icon(Icons.shield_outlined, size: 26, color: subColor),
        ),
        const SizedBox(height: 8),
        Text(
          team.name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppFont.primary(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            height: 1.2,
            color: textColor,
          ),
        ),
        if (team.redCards > 0 || team.yellowCards > 0) ...[
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (team.yellowCards > 0)
                _MiniCardBadge(count: team.yellowCards, isRed: false),
              if (team.yellowCards > 0 && team.redCards > 0)
                const SizedBox(width: 6),
              if (team.redCards > 0)
                _MiniCardBadge(count: team.redCards, isRed: true),
            ],
          ),
        ],
      ],
    );
  }
}

class _MiniCardBadge extends StatelessWidget {
  final int count;
  final bool isRed;
  const _MiniCardBadge({required this.count, required this.isRed});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 11,
          decoration: BoxDecoration(
            color: isRed ? AppColors.live : const Color(0xFFFACC15),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 3),
        Text(
          '$count',
          style: AppFont.primary(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isRed ? AppColors.liveTint : const Color(0xFFFACC15),
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final SoccerMatch match;
  final bool isDark;

  const _StatusPill({required this.match, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isLive = match.isLive;
    final label = isLive
        ? (match.time.isNotEmpty
            ? match.time
            : (match.matchStatus.label.isNotEmpty
                ? match.matchStatus.label
                : 'EN VIVO'))
        : match.isFinished
            ? 'FINALIZADO'
            : (match.formattedTime.isNotEmpty ? match.formattedTime : 'PRÓX.');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isLive
            ? AppColors.live
            : (isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06)),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLive) ...[
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: AppFont.primary(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: isLive
                  ? Colors.white
                  : (isDark ? AppColors.darkText2 : AppColors.lightText2),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Color cardColor;
  final Color borderColor;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.cardColor,
    required this.borderColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 15, color: iconColor),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: AppFont.primary(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _PlayableChannelTile extends StatelessWidget {
  final _ResolvedBroadcast resolved;
  final bool isDark;
  final VoidCallback onTap;

  const _PlayableChannelTile({
    required this.resolved,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.accent(context);
    final logo = resolved.channel.logoUrl.isNotEmpty
        ? resolved.channel.logoUrl.first
        : (resolved.broadcast.logo ?? '');

    return Material(
      color: accent.withValues(alpha: isDark ? 0.18 : 0.10),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withValues(alpha: 0.45)),
          ),
          child: Row(
            children: [
              if (logo.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: logo,
                    cacheManager: ImageCacheHelper.logoCacheManager,
                    width: 34,
                    height: 34,
                    fit: BoxFit.contain,
                    errorWidget: (_, __, ___) =>
                        Icon(Icons.tv_rounded, color: accent, size: 22),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resolved.channel.name,
                      style: AppFont.primary(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkText : AppColors.lightText,
                      ),
                    ),
                    Text(
                      'Tocar para ver transmisión en vivo',
                      style: AppFont.primary(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.accentTint : accent,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_arrow_rounded,
                        size: 16, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      'Ver',
                      style: AppFont.primary(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BroadcastChip extends StatelessWidget {
  final SoccerTVChannel broadcast;
  final bool isDark;

  const _BroadcastChip({required this.broadcast, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBg3 : AppTheme.lightBg1,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.darkBorder2 : AppTheme.lightBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (broadcast.logo != null && broadcast.logo!.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: CachedNetworkImage(
                imageUrl: broadcast.logo!,
                cacheManager: ImageCacheHelper.logoCacheManager,
                width: 18,
                height: 18,
                fit: BoxFit.contain,
                errorWidget: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            broadcast.name,
            style: AppFont.primary(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkText2 : AppColors.lightText,
            ),
          ),
        ],
      ),
    );
  }
}

enum _TimelineType { goal, yellowCard, redCard }

class _TimelineEvent {
  final int minute;
  final String minuteDisplay;
  final bool isHome;
  final _TimelineType type;
  final String title;
  final String badge;

  const _TimelineEvent({
    required this.minute,
    required this.minuteDisplay,
    required this.isHome,
    required this.type,
    required this.title,
    required this.badge,
  });
}

class _TimelineRow extends StatelessWidget {
  final _TimelineEvent event;
  final Color homeColor;
  final Color awayColor;
  final bool isDark;

  const _TimelineRow({
    required this.event,
    required this.homeColor,
    required this.awayColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final sideColor = event.isHome ? homeColor : awayColor;
    final IconData icon;
    final Color iconColor;
    switch (event.type) {
      case _TimelineType.goal:
        icon = Icons.sports_soccer_rounded;
        iconColor = AppColors.positive;
      case _TimelineType.yellowCard:
        icon = Icons.style_rounded;
        iconColor = const Color(0xFFFACC15);
      case _TimelineType.redCard:
        icon = Icons.style_rounded;
        iconColor = AppColors.live;
    }

    return Row(
      children: [
        SizedBox(
          width: 38,
          child: Text(
            event.minuteDisplay,
            style: AppFont.primary(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkText3 : AppColors.lightText3,
            ),
          ),
        ),
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 14, color: iconColor),
        ),
        const SizedBox(width: 10),
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: sideColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            event.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFont.primary(
              fontSize: 13,
              fontWeight:
                  event.type == _TimelineType.goal ? FontWeight.w800 : FontWeight.w600,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            event.badge,
            style: AppFont.primary(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: iconColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _OddsBar extends StatelessWidget {
  final SoccerOdds odds;
  final String homeLabel;
  final String awayLabel;
  final Color homeColor;
  final Color awayColor;
  final bool isDark;

  const _OddsBar({
    required this.odds,
    required this.homeLabel,
    required this.awayLabel,
    required this.homeColor,
    required this.awayColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final h = odds.home ?? 1.0;
    final d = odds.draw ?? 1.0;
    final a = odds.away ?? 1.0;

    final invH = h > 0 ? 1 / h : 0.0;
    final invD = d > 0 ? 1 / d : 0.0;
    final invA = a > 0 ? 1 / a : 0.0;
    final sum = invH + invD + invA;
    final pH = sum > 0 ? (invH / sum) : 0.33;
    final pD = sum > 0 ? (invD / sum) : 0.34;
    final pA = sum > 0 ? (invA / sum) : 0.33;

    return Column(
      children: [
        Row(
          children: [
            _OddPill(
              label: homeLabel,
              odd: h.toStringAsFixed(2),
              pct: '${(pH * 100).round()}%',
              color: homeColor,
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            _OddPill(
              label: 'Empate',
              odd: d.toStringAsFixed(2),
              pct: '${(pD * 100).round()}%',
              color: isDark ? AppColors.darkText3 : AppColors.lightText3,
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            _OddPill(
              label: awayLabel,
              odd: a.toStringAsFixed(2),
              pct: '${(pA * 100).round()}%',
              color: awayColor,
              isDark: isDark,
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: SizedBox(
            height: 7,
            child: Row(
              children: [
                Flexible(
                  flex: (pH * 100).round().clamp(1, 98),
                  child: Container(color: homeColor),
                ),
                const SizedBox(width: 2),
                Flexible(
                  flex: (pD * 100).round().clamp(1, 98),
                  child: Container(
                    color: isDark ? AppColors.darkBg4 : AppTheme.lightBorder2,
                  ),
                ),
                const SizedBox(width: 2),
                Flexible(
                  flex: (pA * 100).round().clamp(1, 98),
                  child: Container(color: awayColor),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OddPill extends StatelessWidget {
  final String label;
  final String odd;
  final String pct;
  final Color color;
  final bool isDark;

  const _OddPill({
    required this.label,
    required this.odd,
    required this.pct,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBg3 : AppTheme.lightBg1,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppTheme.lightBorder,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFont.primary(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkText3 : AppColors.lightText3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              odd,
              style: AppFont.primary(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
            Text(
              pct,
              style: AppFont.primary(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormRow extends StatelessWidget {
  final String teamName;
  final String form;
  final bool isDark;

  const _FormRow({
    required this.teamName,
    required this.form,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final chars = form.trim().toUpperCase().split('');

    return Row(
      children: [
        Expanded(
          child: Text(
            teamName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFont.primary(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: chars.map((ch) {
            final Color bg;
            if (ch == 'G' || ch == 'W') {
              bg = const Color(0xFF16A34A);
            } else if (ch == 'E' || ch == 'D') {
              bg = const Color(0xFF64748B);
            } else {
              bg = const Color(0xFFDC2626);
            }
            return Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(left: 5),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(7),
              ),
              alignment: Alignment.center,
              child: Text(
                ch,
                style: AppFont.primary(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
