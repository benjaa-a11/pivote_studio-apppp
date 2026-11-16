import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/core/services/image_cache_helper.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/features/soccer/data/models/soccer_models.dart';
import 'package:pivote/features/soccer/data/services/soccer_service.dart';
import 'package:pivote/features/soccer/presentation/providers/soccer_provider.dart';
import 'package:pivote/features/video/data/models/channel.dart';
import 'package:pivote/features/video/presentation/providers/channel_provider.dart';
import 'package:pivote/features/video/presentation/screens/player_screen.dart';
import 'package:pivote/shared/widgets/common/pivote_loader.dart';

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

  @override
  Widget build(BuildContext context) {
    final match = _match;
    final channelProvider = context.watch<ChannelProvider>();
    final soccerProvider = context.watch<SoccerProvider>();
    final resolvedChannels = match.isWatchable
        ? soccerProvider.resolveChannelsForMatch(match, channelProvider)
        : const <Channel>[];

    final homeColor =
        match.homeTeamData.primaryColor ?? AppColors.darkAccent;
    final awayColor =
        match.awayTeamData.primaryColor ?? AppColors.darkInfo;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Stack(
        children: [
          // Top-right subtle lime radial glow (from CSS body)
          Positioned(
            top: -120,
            right: -80,
            child: IgnorePointer(
              child: Container(
                width: 340,
                height: 340,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.darkAccent.withValues(alpha: 0.09),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: RefreshIndicator(
              color: AppColors.darkAccent,
              backgroundColor: AppColors.darkBg1,
              onRefresh: () => _loadDetail(silent: true),
              child: CustomScrollView(
                physics: const ClampingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  // Top Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                      child: Row(
                        children: [
                          _GlassIconButton(
                            icon: Icons.arrow_back_rounded,
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
                                    color: AppColors.darkText,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
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
                                      color: AppColors.darkText3,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (match.isLive)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.live.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(99),
                                border: Border.all(
                                  color: AppColors.live.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: AppColors.live,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'EN VIVO',
                                    style: AppFont.mono(
                                      color: AppColors.live,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Scoreboard Hero
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                      child: _ScoreboardCard(
                        match: match,
                        homeColor: homeColor,
                        awayColor: awayColor,
                        stageScores: _detail?.stageScores ?? const [],
                      ),
                    ),
                  ),

                  // Watchable Channels (ONLY if match.isWatchable and channels exist)
                  if (resolvedChannels.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                        child: _WatchChannelsSection(channels: resolvedChannels),
                      ),
                    ),

                  // Broadcasts + Game Info
                  if (match.tvChannels.isNotEmpty ||
                      (_detail?.gameInfo.isNotEmpty ?? false) ||
                      match.venue != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                        child: _MatchMetadataCard(
                          match: match,
                          gameInfo: _detail?.gameInfo ?? const [],
                          attendance: _detail?.attendance ?? '',
                          referee: _detail?.referee ?? '',
                        ),
                      ),
                    ),

                  // Segmented Tabs
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 2, 16, 14),
                      child: _DetailTabs(
                        selectedIndex: _selectedTab,
                        onSelect: (i) {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedTab = i);
                        },
                      ),
                    ),
                  ),

                  // Tab Body
                  if (_loading && _detail == null)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Center(child: PivoteLoader(size: 32)),
                      ),
                    )
                  else if (_error != null && _detail == null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                        child: _EmptyDetailCard(
                          icon: Icons.wifi_off_rounded,
                          title: 'Detalle no disponible',
                          subtitle: _error!,
                          actionLabel: 'Reintentar',
                          onAction: _loadDetail,
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 36),
                      sliver: SliverToBoxAdapter(
                        child: _buildTabContent(match),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
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

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.glass,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: Icon(icon, color: AppColors.darkText, size: 20),
        ),
      ),
    );
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
        ? AppColors.live
        : match.isFinished
            ? AppColors.darkText3
            : AppColors.darkAccent;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.darkBg1,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.darkBorder),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              homeColor.withValues(alpha: 0.14),
              AppColors.darkBg1,
              awayColor.withValues(alpha: 0.14),
            ],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        child: Column(
          children: [
            // Status Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                statusText,
                style: AppFont.mono(
                  color: statusColor,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Teams + Score Row
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
                                  style: AppFont.mono(
                                    color: AppColors.darkText,
                                    fontSize: 34,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8),
                                  child: Text(
                                    ':',
                                    style: AppFont.mono(
                                      color: AppColors.darkText3,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${match.awayTeamData.score}',
                                  style: AppFont.mono(
                                    color: AppColors.darkText,
                                    fontSize: 34,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            if (match.matchStatus.state.toUpperCase() == 'PEN')
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'POR PENALES',
                                  style: AppFont.mono(
                                    color: AppColors.darkWarning,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        )
                      : Text(
                          'VS',
                          style: AppFont.mono(
                            color: AppColors.darkText3,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.glass,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.darkBorder),
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
                            color: AppColors.darkText2,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ],
        ),
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
            color: AppColors.glass,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: logoUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: logoUrl,
                  cacheManager: ImageCacheHelper.logoCacheManager,
                  fit: BoxFit.contain,
                  errorWidget: (_, __, ___) => const Icon(
                    Icons.shield_outlined,
                    color: AppColors.darkText3,
                    size: 26,
                  ),
                )
              : const Icon(
                  Icons.shield_outlined,
                  color: AppColors.darkText3,
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
            color: AppColors.darkText,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.darkAccent.withValues(alpha: 0.30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.play_circle_fill_rounded,
                color: AppColors.darkAccent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Ver en Pivote',
                style: AppFont.primary(
                  color: AppColors.darkText,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: channels.map((ch) {
              return Material(
                color: AppColors.darkAccent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).push(
                      AppAnimations.createRoute(
                        PlayerScreen(
                          channel: ch,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.play_arrow_rounded,
                          color: AppColors.onDarkAccent,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          ch.name,
                          style: AppFont.primary(
                            color: AppColors.onDarkAccent,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
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
    if (infoItems.isEmpty && match.venue != null && match.venue!.name.isNotEmpty) {
      infoItems.add(SoccerGameInfoItem(label: 'Estadio', value: match.venue!.name));
    }
    if (referee.isNotEmpty &&
        !infoItems.any((e) => e.label.toLowerCase().contains('árbitro'))) {
      infoItems.add(SoccerGameInfoItem(label: 'Árbitro', value: referee));
    }
    if (attendance.isNotEmpty) {
      infoItems.add(SoccerGameInfoItem(label: 'Asistencia', value: attendance));
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (infoItems.isNotEmpty)
            Wrap(
              spacing: 16,
              runSpacing: 10,
              children: infoItems.map((item) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.label.toUpperCase(),
                      style: AppFont.mono(
                        color: AppColors.darkText3,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.value,
                      style: AppFont.primary(
                        color: AppColors.darkText,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          if (match.tvChannels.isNotEmpty) ...[
            if (infoItems.isNotEmpty) const SizedBox(height: 12),
            Text(
              'TRANSMISIÓN OFICIAL',
              style: AppFont.mono(
                color: AppColors.darkText3,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: match.tvChannels
                  .map(
                    (tv) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.darkBg2,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: AppColors.darkBorder),
                      ),
                      child: Text(
                        tv.name,
                        style: AppFont.primary(
                          color: AppColors.darkText2,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const ClampingScrollPhysics(),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final active = i == selectedIndex;
          return Padding(
            padding: EdgeInsets.only(right: i == _tabs.length - 1 ? 0 : 8),
            child: GestureDetector(
              onTap: () => onSelect(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: active ? AppColors.darkAccent : AppColors.glass,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color:
                        active ? AppColors.darkAccent : AppColors.darkBorder,
                  ),
                ),
                child: Text(
                  _tabs[i],
                  style: AppFont.primary(
                    color: active
                        ? AppColors.onDarkAccent
                        : AppColors.darkText2,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        }),
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
          const _EmptyDetailCard(
            icon: Icons.sports_soccer_rounded,
            title: 'Sin incidencias registradas',
            subtitle:
                'Los goles, tarjetas y sustituciones aparecerán aquí en cuanto comiencen.',
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
    Color iconColor = AppColors.darkText3;

    if (event.isGoal) {
      icon = Icons.sports_soccer_rounded;
      iconColor = AppColors.darkSuccess;
    } else if (event.isYellowCard) {
      icon = Icons.style_rounded;
      iconColor = AppColors.darkWarning;
    } else if (event.isRedCard) {
      icon = Icons.style_rounded;
      iconColor = AppColors.live;
    } else if (event.isSubstitution) {
      icon = Icons.swap_horiz_rounded;
      iconColor = AppColors.darkInfo;
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
                color: AppColors.darkAccent,
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
                    color: AppColors.darkText,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (event.secondaryPlayerName != null &&
                    event.secondaryPlayerName!.isNotEmpty)
                  Text(
                    event.isSubstitution
                        ? 'Sale: ${event.secondaryPlayerName}'
                        : 'Asist: ${event.secondaryPlayerName}',
                    style: AppFont.primary(
                      color: AppColors.darkText3,
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
                color: AppColors.darkBg2,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: Text(
                event.isHome ? 'LOC' : 'VIS',
                style: AppFont.mono(
                  color: AppColors.darkText3,
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
              color: AppColors.darkText,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: results.take(5).map((r) {
            final upper = r.toUpperCase();
            final color = upper == 'W' || upper == 'G'
                ? AppColors.darkSuccess
                : upper == 'L' || upper == 'P'
                    ? AppColors.live
                    : AppColors.darkWarning;
            return Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(left: 5),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: color.withValues(alpha: 0.35)),
              ),
              child: Text(
                upper,
                style: AppFont.mono(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
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
      return const _EmptyDetailCard(
        icon: Icons.bar_chart_rounded,
        title: 'Estadísticas no disponibles',
        subtitle:
            'Las métricas de posesión, remates y faltas aparecerán cuando haya datos del partido.',
      );
    }

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
                            ? AppColors.darkAccent
                            : AppColors.darkText,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        st.label,
                        textAlign: TextAlign.center,
                        style: AppFont.primary(
                          color: AppColors.darkText2,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      st.awayValue,
                      style: AppFont.mono(
                        color: st.awayNumeric >= st.homeNumeric
                            ? AppColors.darkInfo
                            : AppColors.darkText,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: SizedBox(
                    height: 6,
                    child: Row(
                      children: [
                        Expanded(
                          flex: (homeFrac * 100).round().clamp(1, 99),
                          child: Container(color: AppColors.darkAccent),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          flex: ((1 - homeFrac) * 100).round().clamp(1, 99),
                          child: Container(color: AppColors.darkInfo),
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
      return const _EmptyDetailCard(
        icon: Icons.groups_rounded,
        title: 'Alineaciones no confirmadas',
        subtitle:
            'Los titulares, suplentes y formación táctica estarán disponibles cerca del inicio.',
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
          title: 'Titulares${current.formation.isNotEmpty ? ' · ${current.formation}' : ''}',
          trailing: current.coach != null && current.coach!.name.isNotEmpty
              ? Text(
                  'DT: ${current.coach!.name}',
                  style: AppFont.primary(
                    color: AppColors.darkText3,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.darkAccent.withValues(alpha: 0.14)
              : AppColors.glass,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.darkAccent.withValues(alpha: 0.5)
                : AppColors.darkBorder,
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
                color: selected ? AppColors.darkAccent : AppColors.darkText,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (formation.isNotEmpty)
              Text(
                formation,
                style: AppFont.mono(
                  color: AppColors.darkText3,
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.darkBg2,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Text(
              player.jerseyNumber != null ? '${player.jerseyNumber}' : '-',
              style: AppFont.mono(
                color: AppColors.darkAccent,
                fontSize: 12,
                fontWeight: FontWeight.w700,
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
                    color: AppColors.darkText,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (player.formationPosition.isNotEmpty ||
                    player.position.isNotEmpty)
                  Text(
                    player.formationPosition.isNotEmpty
                        ? player.formationPosition
                        : player.position,
                    style: AppFont.primary(
                      color: AppColors.darkText3,
                      fontSize: 11.5,
                    ),
                  ),
              ],
            ),
          ),
          if (player.goals > 0)
            const Padding(
              padding: EdgeInsets.only(left: 6),
              child: Icon(Icons.sports_soccer_rounded,
                  color: AppColors.darkSuccess, size: 15),
            ),
          if (player.yellowCards > 0)
            const Padding(
              padding: EdgeInsets.only(left: 6),
              child: Icon(Icons.style_rounded,
                  color: AppColors.darkWarning, size: 15),
            ),
          if (player.redCards > 0)
            const Padding(
              padding: EdgeInsets.only(left: 6),
              child: Icon(Icons.style_rounded,
                  color: AppColors.live, size: 15),
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
      return const _EmptyDetailCard(
        icon: Icons.history_rounded,
        title: 'Sin historial disponible',
        subtitle:
            'No hay enfrentamientos previos ni noticias registradas para este cruce.',
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
                      color: AppColors.darkAccent,
                    ),
                    const SizedBox(width: 8),
                    _H2HStatBox(
                      label: 'Empates',
                      value: '${headToHead!.draws}',
                      color: AppColors.darkText2,
                    ),
                    const SizedBox(width: 8),
                    _H2HStatBox(
                      label: match.awayTeamData.shortName.isNotEmpty
                          ? match.awayTeamData.shortName
                          : 'Visita',
                      value: '${headToHead!.awayWins}',
                      color: AppColors.darkInfo,
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
                                color: AppColors.darkText,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.darkBg2,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${m.homeScore} - ${m.awayScore}',
                              style: AppFont.mono(
                                color: AppColors.darkText,
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
                          color: AppColors.darkText,
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
                            color: AppColors.darkText3,
                            fontSize: 12,
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
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.darkBg2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.darkBorder),
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
                color: AppColors.darkText3,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppFont.primary(
                    color: AppColors.darkText,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
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

class _EmptyDetailCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyDetailCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.darkText3, size: 32),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppFont.primary(
              color: AppColors.darkText,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppFont.primary(
              color: AppColors.darkText3,
              fontSize: 12.5,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: AppFont.primary(
                  color: AppColors.darkAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
