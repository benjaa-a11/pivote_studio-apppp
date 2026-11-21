import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/core/services/image_cache_helper.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/features/soccer/data/models/soccer_models.dart';
import 'package:pivote/features/soccer/data/services/soccer_service.dart';
import 'package:pivote/features/soccer/presentation/providers/soccer_provider.dart';
import 'package:pivote/features/video/data/models/channel.dart';
import 'package:pivote/features/video/presentation/providers/channel_provider.dart';
import 'package:pivote/features/video/presentation/screens/player_screen.dart';
import 'package:pivote/shared/widgets/common/app_state_views.dart';
import 'package:pivote/shared/widgets/common/apple_pressable.dart';
import 'package:pivote/shared/widgets/common/loading_shimmer.dart';
import 'package:pivote/shared/widgets/common/pivote_surfaces.dart';

class MatchDetailScreen extends StatefulWidget {
  final SoccerMatch match;

  const MatchDetailScreen({
    super.key,
    required this.match,
  });

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  final SoccerService _service = SoccerService();
  SoccerMatchDetail? _detail;
  bool _loading = true;
  String? _error;
  int _selectedTab = 0; // 0: Resumen, 1: Estadísticas, 2: Alineaciones, 3: Historial
  Timer? _refreshTimer;

  SoccerMatch get _match => _detail?.match ?? widget.match;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDetail({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final detail = await _service.fetchMatchDetail(widget.match.id);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
        _error = null;
      });
      _syncRefreshTimer(detail.match);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (_detail == null) {
          _error = 'No se pudo cargar el detalle completo del partido.';
        }
      });
      _syncRefreshTimer(_match);
    }
  }

  void _syncRefreshTimer(SoccerMatch match) {
    if (match.isLive) {
      _refreshTimer ??= Timer.periodic(const Duration(seconds: 15), (_) {
        if (mounted) _loadDetail(silent: true);
      });
    } else {
      _refreshTimer?.cancel();
      _refreshTimer = null;
    }
  }

  Color _effectiveTeamColor(BuildContext context, Color? color, bool isHome) {
    if (color == null ||
        color.computeLuminance() < 0.05 ||
        color.computeLuminance() > 0.92) {
      return isHome ? AppTheme.accent(context) : AppTheme.textSecondary(context);
    }
    return color;
  }

  @override
  Widget build(BuildContext context) {
    final match = _match;
    final channelProvider = context.watch<ChannelProvider>();
    final soccerProvider = context.watch<SoccerProvider>();
    final hPad = AppResponsive.screenHorizontalPadding(context);

    final resolvedChannels = match.isWatchable
        ? soccerProvider.resolveChannelsForMatch(match, channelProvider)
        : const <Channel>[];

    final homeColor =
        _effectiveTeamColor(context, match.homeTeamData.primaryColor, true);
    final awayColor =
        _effectiveTeamColor(context, match.awayTeamData.primaryColor, false);

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: PivoteAmbientBackdrop(
        accentColor:
            match.isLive ? AppTheme.danger(context) : AppTheme.accent(context),
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: [
              // Top bar unificada
              SliverToBoxAdapter(
                child: Padding(
                  padding: hPad.add(const EdgeInsets.only(top: 8, bottom: 8)),
                  child: Row(
                    children: [
                      PivoteIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        iconSize: 17,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              match.leagueData.name.isNotEmpty
                                  ? match.leagueData.name
                                  : 'Fútbol',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppFont.primary(
                                color: AppTheme.textPrimary(context),
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.25,
                              ),
                            ),
                            if (match.stageRound.isNotEmpty ||
                                match.leagueData.country.isNotEmpty)
                              Text(
                                [
                                  if (match.leagueData.country.isNotEmpty)
                                    match.leagueData.country,
                                  if (match.stageRound.isNotEmpty)
                                    match.stageRound,
                                ].join(' · '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppFont.primary(
                                  color: AppTheme.textTertiary(context),
                                  fontSize: 11.8,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (match.isLive) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.dangerDim(context),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(
                              color: AppTheme.danger(context)
                                  .withValues(alpha: 0.36),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: AppTheme.danger(context),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'EN VIVO',
                                style: AppFont.mono(
                                  color: AppTheme.danger(context),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      PivoteIconButton(
                        icon: Icons.refresh_rounded,
                        size: 38,
                        iconSize: 18,
                        tooltip: 'Actualizar partido',
                        onTap: () {
                          HapticFeedback.lightImpact();
                          unawaited(_loadDetail(silent: true));
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Scoreboard Hero con difuminación radial dual estilo MatchesHero
              SliverToBoxAdapter(
                child: Padding(
                  padding: hPad.add(const EdgeInsets.only(top: 6, bottom: 14)),
                  child: _ScoreboardCard(
                    match: match,
                    homeColor: homeColor,
                    awayColor: awayColor,
                    stageScores: _detail?.stageScores ?? const [],
                  ),
                ),
              ),

              // Canales para ver en Pivote
              if (resolvedChannels.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: hPad.add(const EdgeInsets.only(bottom: 14)),
                    child: _WatchChannelsSection(channels: resolvedChannels),
                  ),
                ),

              // Metadatos del encuentro
              if (match.tvChannels.isNotEmpty ||
                  (_detail?.gameInfo.isNotEmpty ?? false) ||
                  match.venue != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: hPad.add(const EdgeInsets.only(bottom: 14)),
                    child: _MatchMetadataCard(
                      match: match,
                      gameInfo: _detail?.gameInfo ?? const [],
                      attendance: _detail?.attendance ?? '',
                      referee: _detail?.referee ?? '',
                    ),
                  ),
                ),

              // Pestañas modernas con PivoteFilterPill
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2, bottom: 14),
                  child: _DetailTabs(
                    selectedIndex: _selectedTab,
                    onSelect: (i) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedTab = i);
                    },
                  ),
                ),
              ),

              // Cuerpo de la pestaña con Skeleton + Shimmer
              if (_loading && _detail == null)
                SliverPadding(
                  padding: hPad.add(const EdgeInsets.only(bottom: 40)),
                  sliver: const SliverToBoxAdapter(
                    child: PivoteMatchDetailSkeleton(),
                  ),
                )
              else if (_error != null && _detail == null)
                SliverPadding(
                  padding: hPad.add(const EdgeInsets.only(bottom: 40)),
                  sliver: SliverToBoxAdapter(
                    child: AppStateView.error(
                      icon: Icons.wifi_off_rounded,
                      title: 'Detalle no disponible',
                      subtitle: _error!,
                      actionLabel: 'Reintentar',
                      onAction: _loadDetail,
                      compact: true,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: hPad.add(const EdgeInsets.only(bottom: 44)),
                  sliver: SliverToBoxAdapter(
                    child: _buildTabContent(match),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(SoccerMatch match) {
    final detail = _detail;
    switch (_selectedTab) {
      case 0:
        return _SummaryTab(
          match: match,
          events: detail?.events ?? const [],
          recentForm: detail?.recentForm,
        );
      case 1:
        return _StatsTab(
          match: match,
          statistics: detail?.statistics ?? const [],
        );
      case 2:
        return _LineupsTab(
          match: match,
          homeLineup: detail?.homeLineup,
          awayLineup: detail?.awayLineup,
        );
      case 3:
        return _HistoryTab(
          match: match,
          headToHead: detail?.headToHead,
          news: detail?.news ?? const [],
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _ScoreboardCard extends StatelessWidget {
  final SoccerMatch match;
  final Color homeColor;
  final Color awayColor;
  final List<SoccerStageScore> stageScores;

  const _ScoreboardCard({
    required this.match,
    required this.homeColor,
    required this.awayColor,
    required this.stageScores,
  });

  @override
  Widget build(BuildContext context) {
    final hasScore = !match.isScheduled;
    final statusText = match.isFinished
        ? (match.matchStatus.shortLabel.isNotEmpty
            ? match.matchStatus.shortLabel.toUpperCase()
            : 'FINAL')
        : match.isLive
            ? (match.time.isNotEmpty
                ? match.time
                : (match.matchStatus.shortLabel.isNotEmpty
                    ? match.matchStatus.shortLabel
                    : 'VIVO'))
            : (match.timeLocalAr.isNotEmpty
                ? match.timeLocalAr
                : match.formattedTime);

    final statusColor = match.isLive
        ? AppTheme.danger(context)
        : match.isFinished
            ? AppTheme.textTertiary(context)
            : AppTheme.accent(context);

    return PivoteDiffusedCard(
      borderRadius: AppRadius.hero,
      glowColor: homeColor,
      secondaryGlowColor: awayColor,
      glowAlignment: const Alignment(-0.88, -0.05),
      secondaryGlowAlignment: const Alignment(0.88, -0.05),
      glowOpacity: 1.5,
      highlighted: match.isLive,
      borderColor: match.isLive
          ? AppTheme.danger(context).withValues(alpha: 0.45)
          : null,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Column(
        children: [
          // Pill de estado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.34),
              ),
            ),
            child: Text(
              statusText,
              style: AppFont.mono(
                color: statusColor,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Equipos y marcador
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _TeamColumn(
                  name: match.homeTeamData.name.isNotEmpty
                      ? match.homeTeamData.name
                      : match.homeTeam,
                  logoUrl: match.homeTeamData.logoUrl ?? '',
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: hasScore
                    ? Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${match.homeTeamData.score}',
                                style: AppFont.score(
                                  color: match.isLive
                                      ? AppTheme.accent(context)
                                      : AppTheme.textPrimary(context),
                                  fontSize: 44,
                                  fontWeight: FontWeight.w900,
                                  height: 1.0,
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: Container(
                                  width: 10,
                                  height: 3.5,
                                  decoration: BoxDecoration(
                                    color: AppTheme.textTertiary(context)
                                        .withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              Text(
                                '${match.awayTeamData.score}',
                                style: AppFont.score(
                                  color: match.isLive
                                      ? AppTheme.accent(context)
                                      : AppTheme.textPrimary(context),
                                  fontSize: 44,
                                  fontWeight: FontWeight.w900,
                                  height: 1.0,
                                ),
                              ),
                            ],
                          ),
                          if (match.matchStatus.state.toUpperCase() == 'PEN')
                            Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: Text(
                                'POR PENALES',
                                style: AppFont.mono(
                                  color: AppTheme.accent(context),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                        ],
                      )
                    : Text(
                        'VS',
                        style: AppFont.score(
                          color: AppTheme.textTertiary(context),
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.4,
                        ),
                      ),
              ),
              Expanded(
                child: _TeamColumn(
                  name: match.awayTeamData.name.isNotEmpty
                      ? match.awayTeamData.name
                      : match.awayTeam,
                  logoUrl: match.awayTeamData.logoUrl ?? '',
                ),
              ),
            ],
          ),

          if (stageScores.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surface2(context),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppTheme.border(context)),
              ),
              child: Wrap(
                spacing: 14,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: stageScores
                    .map(
                      (s) => Text(
                        '${s.stage}: ${s.homeScore}-${s.awayScore}',
                        style: AppFont.mono(
                          color: AppTheme.textSecondary(context),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TeamColumn extends StatelessWidget {
  final String name;
  final String logoUrl;

  const _TeamColumn({required this.name, required this.logoUrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 58,
          height: 58,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.surface2(context).withValues(alpha: 0.72),
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.border(context)),
          ),
          child: logoUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: logoUrl,
                  cacheManager: ImageCacheHelper.logoCacheManager,
                  fit: BoxFit.contain,
                  errorWidget: (_, __, ___) => Icon(
                    Icons.shield_outlined,
                    color: AppTheme.textTertiary(context),
                    size: 26,
                  ),
                )
              : Icon(
                  Icons.shield_outlined,
                  color: AppTheme.textTertiary(context),
                  size: 26,
                ),
        ),
        const SizedBox(height: 10),
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppFont.primary(
            color: AppTheme.textPrimary(context),
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

class _WatchChannelsSection extends StatelessWidget {
  final List<Channel> channels;

  const _WatchChannelsSection({required this.channels});

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.accent(context);
    final onAccent = AppTheme.onAccent(context);

    return PivoteDiffusedCard(
      borderRadius: AppRadius.card,
      glowColor: accent,
      glowAlignment: const Alignment(-0.85, -0.7),
      glowOpacity: 1.25,
      highlighted: true,
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.play_circle_fill_rounded, color: accent, size: 19),
              const SizedBox(width: 8),
              Text(
                'Ver en Pivote',
                style: AppFont.primary(
                  color: AppTheme.textPrimary(context),
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: channels.map((ch) {
              return ApplePressable(
                scaleDownFactor: 0.95,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).push(
                    AppAnimations.createRoute(PlayerScreen(channel: ch)),
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_arrow_rounded, color: onAccent, size: 18),
                      const SizedBox(width: 5),
                      Text(
                        ch.name,
                        style: AppFont.primary(
                          color: onAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _MatchMetadataCard extends StatelessWidget {
  final SoccerMatch match;
  final List<SoccerGameInfoItem> gameInfo;
  final String attendance;
  final String referee;

  const _MatchMetadataCard({
    required this.match,
    required this.gameInfo,
    required this.attendance,
    required this.referee,
  });

  @override
  Widget build(BuildContext context) {
    final infoItems = <SoccerGameInfoItem>[...gameInfo];
    if (infoItems.isEmpty &&
        match.venue != null &&
        match.venue!.name.isNotEmpty) {
      infoItems.add(
        SoccerGameInfoItem(label: 'Estadio', value: match.venue!.name),
      );
    }
    if (referee.isNotEmpty &&
        !infoItems.any((e) => e.label.toLowerCase().contains('árbitro'))) {
      infoItems.add(SoccerGameInfoItem(label: 'Árbitro', value: referee));
    }
    if (attendance.isNotEmpty) {
      infoItems.add(SoccerGameInfoItem(label: 'Asistencia', value: attendance));
    }

    return PivoteDiffusedCard(
      borderRadius: AppRadius.card,
      glowOpacity: 0.5,
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (infoItems.isNotEmpty)
            Wrap(
              spacing: 18,
              runSpacing: 10,
              children: infoItems.map((item) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.label.toUpperCase(),
                      style: AppFont.mono(
                        color: AppTheme.textTertiary(context),
                        fontSize: 9.8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.value,
                      style: AppFont.primary(
                        color: AppTheme.textPrimary(context),
                        fontSize: 13.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          if (match.tvChannels.isNotEmpty) ...[
            if (infoItems.isNotEmpty) ...[
              const SizedBox(height: 12),
              Divider(height: 1, thickness: 1, color: AppTheme.border(context)),
              const SizedBox(height: 12),
            ],
            Text(
              'TRANSMISIÓN OFICIAL',
              style: AppFont.mono(
                color: AppTheme.textTertiary(context),
                fontSize: 9.8,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: match.tvChannels
                  .map(
                    (tv) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surface2(context),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(color: AppTheme.border(context)),
                      ),
                      child: Text(
                        tv.name,
                        style: AppFont.primary(
                          color: AppTheme.textSecondary(context),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _DetailTabs({required this.selectedIndex, required this.onSelect});

  static const _tabs = ['Resumen', 'Estadísticas', 'Alineaciones', 'Historial'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        padding: AppResponsive.screenHorizontalPadding(context),
        itemCount: _tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) => PivoteFilterPill(
          label: _tabs[i],
          selected: i == selectedIndex,
          onTap: () => onSelect(i),
        ),
      ),
    );
  }
}

class _SummaryTab extends StatelessWidget {
  final SoccerMatch match;
  final List<SoccerMatchEvent> events;
  final SoccerRecentForm? recentForm;

  const _SummaryTab({
    required this.match,
    required this.events,
    required this.recentForm,
  });

  @override
  Widget build(BuildContext context) {
    final hasEvents = events.isNotEmpty;
    final hasFallbackGoals = !hasEvents && match.goals.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasEvents)
          _SectionCard(
            title: 'Incidencias del partido',
            child: Column(
              children: events.map((ev) => _EventRow(event: ev)).toList(),
            ),
          )
        else if (hasFallbackGoals)
          _SectionCard(
            title: 'Goles',
            child: Column(
              children: match.goals
                  .map(
                    (g) => _EventRow(
                      event: SoccerMatchEvent(
                        type: 'goal',
                        teamSide: g.teamSide,
                        minute: g.time,
                        minuteDisplay: g.timeToDisplay,
                        playerName: g.playerName.isNotEmpty
                            ? g.playerName
                            : g.playerShortName,
                      ),
                    ),
                  )
                  .toList(),
            ),
          )
        else
          const AppStateView.empty(
            icon: Icons.sports_soccer_rounded,
            title: 'Sin incidencias registradas',
            subtitle:
                'Los goles, tarjetas y sustituciones aparecerán aquí en cuanto comiencen.',
            compact: true,
          ),
        if (recentForm != null &&
            (recentForm!.home.isNotEmpty || recentForm!.away.isNotEmpty)) ...[
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Forma reciente',
            child: Column(
              children: [
                if (recentForm!.home.isNotEmpty)
                  _FormRow(
                    teamName: match.homeTeam,
                    results: recentForm!.home,
                  ),
                if (recentForm!.home.isNotEmpty && recentForm!.away.isNotEmpty)
                  const SizedBox(height: 12),
                if (recentForm!.away.isNotEmpty)
                  _FormRow(
                    teamName: match.awayTeam,
                    results: recentForm!.away,
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _EventRow extends StatelessWidget {
  final SoccerMatchEvent event;

  const _EventRow({required this.event});

  @override
  Widget build(BuildContext context) {
    IconData icon = Icons.circle_outlined;
    Color iconColor = AppTheme.textTertiary(context);

    if (event.isGoal) {
      icon = Icons.sports_soccer_rounded;
      iconColor = AppTheme.accent(context);
    } else if (event.isYellowCard) {
      icon = Icons.style_rounded;
      iconColor = AppTheme.warning(context);
    } else if (event.isRedCard) {
      icon = Icons.style_rounded;
      iconColor = AppTheme.danger(context);
    } else if (event.isSubstitution) {
      icon = Icons.swap_horiz_rounded;
      iconColor = AppTheme.textSecondary(context);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(
              event.minuteDisplay.isNotEmpty ? event.minuteDisplay : '-',
              style: AppFont.mono(
                color: AppTheme.accent(context),
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Icon(icon, color: iconColor, size: 17),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.playerName,
                  style: AppFont.primary(
                    color: AppTheme.textPrimary(context),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (event.secondaryPlayerName != null &&
                    event.secondaryPlayerName!.isNotEmpty)
                  Text(
                    event.isSubstitution
                        ? 'Sale: ${event.secondaryPlayerName}'
                        : 'Asist: ${event.secondaryPlayerName}',
                    style: AppFont.primary(
                      color: AppTheme.textTertiary(context),
                      fontSize: 11.5,
                    ),
                  ),
              ],
            ),
          ),
          if (event.teamName.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.surface2(context),
                borderRadius: BorderRadius.circular(AppRadius.xs),
                border: Border.all(color: AppTheme.border(context)),
              ),
              child: Text(
                event.isHome ? 'LOC' : 'VIS',
                style: AppFont.mono(
                  color: AppTheme.textTertiary(context),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FormRow extends StatelessWidget {
  final String teamName;
  final List<String> results;

  const _FormRow({required this.teamName, required this.results});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            teamName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFont.primary(
              color: AppTheme.textPrimary(context),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: results.take(5).map((r) {
            final upper = r.toUpperCase();
            final color = upper == 'W' || upper == 'G'
                ? AppTheme.accent(context)
                : upper == 'L' || upper == 'P'
                    ? AppTheme.danger(context)
                    : AppTheme.textTertiary(context);
            return Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(left: 5),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: color.withValues(alpha: 0.34)),
              ),
              child: Text(
                upper,
                style: AppFont.mono(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _StatsTab extends StatelessWidget {
  final SoccerMatch match;
  final List<SoccerStat> statistics;

  const _StatsTab({required this.match, required this.statistics});

  @override
  Widget build(BuildContext context) {
    if (statistics.isEmpty) {
      return const AppStateView.empty(
        icon: Icons.bar_chart_rounded,
        title: 'Estadísticas no disponibles',
        subtitle:
            'Las métricas de posesión, remates y faltas aparecerán cuando haya datos del partido.',
        compact: true,
      );
    }

    final accent = AppTheme.accent(context);
    final awayBar = AppTheme.textTertiary(context);

    return _SectionCard(
      title: 'Estadísticas comparativas',
      child: Column(
        children: statistics.map((st) {
          final homeFrac = (st.homePct / 100).clamp(0.0, 1.0);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      st.homeValue,
                      style: AppFont.mono(
                        color: st.homeNumeric >= st.awayNumeric
                            ? accent
                            : AppTheme.textPrimary(context),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        st.label,
                        textAlign: TextAlign.center,
                        style: AppFont.primary(
                          color: AppTheme.textSecondary(context),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      st.awayValue,
                      style: AppFont.mono(
                        color: st.awayNumeric >= st.homeNumeric
                            ? AppTheme.textPrimary(context)
                            : AppTheme.textTertiary(context),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: SizedBox(
                    height: 6,
                    child: Row(
                      children: [
                        Expanded(
                          flex: (homeFrac * 100).round().clamp(1, 99),
                          child: Container(color: accent),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          flex: ((1 - homeFrac) * 100).round().clamp(1, 99),
                          child: Container(
                            color: awayBar.withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _LineupsTab extends StatefulWidget {
  final SoccerMatch match;
  final SoccerLineup? homeLineup;
  final SoccerLineup? awayLineup;

  const _LineupsTab({
    required this.match,
    required this.homeLineup,
    required this.awayLineup,
  });

  @override
  State<_LineupsTab> createState() => _LineupsTabState();
}

class _LineupsTabState extends State<_LineupsTab> {
  int _teamIndex = 0;

  @override
  Widget build(BuildContext context) {
    final home = widget.homeLineup;
    final away = widget.awayLineup;
    if (home == null && away == null) {
      return const AppStateView.empty(
        icon: Icons.groups_rounded,
        title: 'Alineaciones no confirmadas',
        subtitle:
            'Los titulares, suplentes y formación táctica estarán disponibles cerca del inicio.',
        compact: true,
      );
    }

    final current = _teamIndex == 0 ? (home ?? away!) : (away ?? home!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (home != null && away != null) ...[
          Row(
            children: [
              Expanded(
                child: _TeamSwitchPill(
                  label: home.teamName.isNotEmpty
                      ? home.teamName
                      : widget.match.homeTeam,
                  formation: home.formation,
                  selected: _teamIndex == 0,
                  onTap: () => setState(() => _teamIndex = 0),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TeamSwitchPill(
                  label: away.teamName.isNotEmpty
                      ? away.teamName
                      : widget.match.awayTeam,
                  formation: away.formation,
                  selected: _teamIndex == 1,
                  onTap: () => setState(() => _teamIndex = 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
        ],
        _SectionCard(
          title:
              'Titulares${current.formation.isNotEmpty ? ' · ${current.formation}' : ''}',
          trailing: current.coach != null && current.coach!.name.isNotEmpty
              ? Text(
                  'DT: ${current.coach!.name}',
                  style: AppFont.primary(
                    color: AppTheme.textTertiary(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : null,
          child: Column(
            children: current.starters
                .map((p) => _PlayerRow(player: p))
                .toList(),
          ),
        ),
        if (current.bench.isNotEmpty) ...[
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Suplentes',
            child: Column(
              children: current.bench
                  .map((p) => _PlayerRow(player: p))
                  .toList(),
            ),
          ),
        ],
      ],
    );
  }
}

class _TeamSwitchPill extends StatelessWidget {
  final String label;
  final String formation;
  final bool selected;
  final VoidCallback onTap;

  const _TeamSwitchPill({
    required this.label,
    required this.formation,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.accent(context);
    return ApplePressable(
      scaleDownFactor: 0.96,
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.accentDim(context)
              : AppTheme.surface1(context),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected
                ? accent.withValues(alpha: 0.5)
                : AppTheme.border(context),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFont.primary(
                color: selected ? accent : AppTheme.textPrimary(context),
                fontSize: 13.2,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (formation.isNotEmpty)
              Text(
                formation,
                style: AppFont.mono(
                  color: AppTheme.textTertiary(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  final SoccerLineupPlayer player;

  const _PlayerRow({required this.player});

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.accent(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.surface2(context),
              borderRadius: BorderRadius.circular(AppRadius.xs),
              border: Border.all(color: AppTheme.border(context)),
            ),
            child: Text(
              player.jerseyNumber != null ? '${player.jerseyNumber}' : '-',
              style: AppFont.mono(
                color: accent,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${player.name}${player.isCaptain ? ' (C)' : ''}',
                  style: AppFont.primary(
                    color: AppTheme.textPrimary(context),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (player.formationPosition.isNotEmpty ||
                    player.position.isNotEmpty)
                  Text(
                    player.formationPosition.isNotEmpty
                        ? player.formationPosition
                        : player.position,
                    style: AppFont.primary(
                      color: AppTheme.textTertiary(context),
                      fontSize: 11.5,
                    ),
                  ),
              ],
            ),
          ),
          if (player.goals > 0)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Icon(Icons.sports_soccer_rounded, color: accent, size: 15),
            ),
          if (player.yellowCards > 0)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Icon(
                Icons.style_rounded,
                color: AppTheme.warning(context),
                size: 15,
              ),
            ),
          if (player.redCards > 0)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Icon(
                Icons.style_rounded,
                color: AppTheme.danger(context),
                size: 15,
              ),
            ),
        ],
      ),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  final SoccerMatch match;
  final SoccerH2H? headToHead;
  final List<SoccerNewsItem> news;

  const _HistoryTab({
    required this.match,
    required this.headToHead,
    required this.news,
  });

  @override
  Widget build(BuildContext context) {
    if (headToHead == null && news.isEmpty) {
      return const AppStateView.empty(
        icon: Icons.history_rounded,
        title: 'Sin historial disponible',
        subtitle:
            'No hay enfrentamientos previos ni noticias registradas para este cruce.',
        compact: true,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (headToHead != null) ...[
          _SectionCard(
            title: 'Historial directo',
            child: Column(
              children: [
                Row(
                  children: [
                    _H2HStatBox(
                      label: match.homeTeamData.shortName.isNotEmpty
                          ? match.homeTeamData.shortName
                          : 'Local',
                      value: '${headToHead!.homeWins}',
                      color: AppTheme.accent(context),
                    ),
                    const SizedBox(width: 8),
                    _H2HStatBox(
                      label: 'Empates',
                      value: '${headToHead!.draws}',
                      color: AppTheme.textSecondary(context),
                    ),
                    const SizedBox(width: 8),
                    _H2HStatBox(
                      label: match.awayTeamData.shortName.isNotEmpty
                          ? match.awayTeamData.shortName
                          : 'Visita',
                      value: '${headToHead!.awayWins}',
                      color: AppTheme.textPrimary(context),
                    ),
                  ],
                ),
                if (headToHead!.recentMatches.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...headToHead!.recentMatches.take(6).map((m) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${m.homeName} vs ${m.awayName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppFont.primary(
                                color: AppTheme.textPrimary(context),
                                fontSize: 12.8,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.surface2(context),
                              borderRadius: BorderRadius.circular(AppRadius.xs),
                              border:
                                  Border.all(color: AppTheme.border(context)),
                            ),
                            child: Text(
                              '${m.homeScore} - ${m.awayScore}',
                              style: AppFont.mono(
                                color: AppTheme.textPrimary(context),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (news.isNotEmpty)
          _SectionCard(
            title: 'Noticias relacionadas',
            child: Column(
              children: news.take(4).map((n) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        n.headline,
                        style: AppFont.primary(
                          color: AppTheme.textPrimary(context),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (n.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          n.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppFont.primary(
                            color: AppTheme.textSecondary(context),
                            fontSize: 12.2,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _H2HStatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _H2HStatBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
        decoration: BoxDecoration(
          color: AppTheme.surface2(context),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppTheme.border(context)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppFont.mono(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFont.primary(
                color: AppTheme.textTertiary(context),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final Widget child;

  const _SectionCard({
    required this.title,
    this.trailing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return PivoteDiffusedCard(
      borderRadius: AppRadius.lg,
      glowOpacity: 0.6,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppFont.primary(
                    color: AppTheme.textPrimary(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
