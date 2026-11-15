import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/core/services/image_cache_helper.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/features/soccer/data/models/soccer_models.dart';
import 'package:pivote/features/soccer/presentation/providers/soccer_provider.dart';
import 'package:pivote/features/soccer/presentation/widgets/match_details_bottom_sheet.dart';
import 'package:pivote/features/video/data/models/channel.dart';
import 'package:pivote/features/video/presentation/providers/channel_provider.dart';
import 'package:pivote/features/video/presentation/screens/player_screen.dart';
import 'package:pivote/shared/widgets/common/pivote_loader.dart';

enum _MatchFilter { all, live, scheduled, finished, playable }

class FutbolScreen extends StatefulWidget {
  const FutbolScreen({super.key});

  @override
  State<FutbolScreen> createState() => _FutbolScreenState();
}

class _FutbolScreenState extends State<FutbolScreen> {
  final TextEditingController _searchController = TextEditingController();
  _MatchFilter _selectedFilter = _MatchFilter.all;
  String? _selectedLeagueId;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_LeagueSectionData> _buildSections(
    SoccerData data,
    ChannelProvider channelProvider,
    SoccerProvider soccerProvider,
  ) {
    final query = _searchQuery.trim().toLowerCase();

    bool matchesFilter(SoccerMatch m) {
      if (_selectedLeagueId != null && m.leagueData.id != _selectedLeagueId) {
        return false;
      }

      switch (_selectedFilter) {
        case _MatchFilter.all:
          break;
        case _MatchFilter.live:
          if (!m.isLive) return false;
        case _MatchFilter.scheduled:
          if (!m.isScheduled) return false;
        case _MatchFilter.finished:
          if (!m.isFinished) return false;
        case _MatchFilter.playable:
          if (soccerProvider.resolveChannelsForMatch(m, channelProvider).isEmpty) {
            return false;
          }
      }

      if (query.isNotEmpty) {
        final hay = [
          m.homeTeam,
          m.homeTeamData.shortName,
          m.awayTeam,
          m.awayTeamData.shortName,
          m.leagueData.name,
          m.leagueData.country,
          m.stageRound,
        ].join(' ').toLowerCase();
        if (!hay.contains(query)) return false;
      }

      return true;
    }

    if (data.leagueGroups.isNotEmpty) {
      final sections = <_LeagueSectionData>[];
      for (final g in data.leagueGroups) {
        final filtered = g.matches.where(matchesFilter).toList();
        if (filtered.isNotEmpty) {
          sections.add(_LeagueSectionData(league: g.league, matches: filtered));
        }
      }
      return sections;
    }

    // Fallback: agrupar desde data.matches
    final grouped = <String, List<SoccerMatch>>{};
    final leagueById = <String, SoccerLeague>{};
    for (final m in data.matches) {
      if (!matchesFilter(m)) continue;
      final lid = m.leagueData.id.isNotEmpty ? m.leagueData.id : 'other';
      leagueById[lid] = m.leagueData;
      grouped.putIfAbsent(lid, () => []).add(m);
    }

    return grouped.entries
        .map((e) => _LeagueSectionData(
              league: leagueById[e.key]!,
              matches: e.value,
            ))
        .toList();
  }

  void _openMatchDetails(BuildContext context, SoccerMatch match) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: dark ? const Color(0xBD02040A) : const Color(0x8C02040A),
      showDragHandle: false,
      useSafeArea: true,
      builder: (_) => MatchDetailsBottomSheet(
        match: match,
        homeTeam: match.homeTeamData,
        awayTeam: match.awayTeamData,
        league: match.leagueData,
      ),
    );
  }

  void _watchChannel(BuildContext context, Channel channel) {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      AppAnimations.createRoute(PlayerScreen(channel: channel)),
    );
  }

  Future<void> _pickDate(
    BuildContext context,
    SoccerProvider soccerProvider,
  ) async {
    final now = DateTime.now();
    final initial = soccerProvider.isViewingToday
        ? now
        : (DateTime.tryParse(soccerProvider.selectedDateKey) ?? now);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 90)),
      lastDate: now.add(const Duration(days: 90)),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: AppColors.darkAccent,
                    onPrimary: Colors.white,
                    surface: AppColors.darkBg1,
                    onSurface: AppColors.darkText,
                  )
                : const ColorScheme.light(
                    primary: AppColors.lightAccent,
                    onPrimary: Colors.white,
                    surface: AppColors.lightBg1,
                    onSurface: AppColors.lightText,
                  ),
            dialogTheme: DialogThemeData(
              backgroundColor: isDark ? AppColors.darkBg1 : AppColors.lightBg1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedLeagueId = null);
      await soccerProvider.selectDate(SoccerProvider.formatDateKey(picked));
    }
  }

  String _formatDateBadgeLabel(String dateKey) {
    if (dateKey == 'today') return 'Hoy';
    final parsed = DateTime.tryParse(dateKey);
    if (parsed == null) return dateKey;
    final dd = parsed.day.toString().padLeft(2, '0');
    final mm = parsed.month.toString().padLeft(2, '0');
    return '$dd/$mm';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hPad = AppResponsive.screenHorizontalPadding(context);
    final topPad = MediaQuery.paddingOf(context).top;

    final soccerProvider = context.watch<SoccerProvider>();
    final channelProvider = context.watch<ChannelProvider>();
    final data = soccerProvider.selectedDateData;
    final isLoading = soccerProvider.isLoadingSelectedDate;
    final dateError = soccerProvider.selectedDateError;

    final now = DateTime.now();
    final yesterdayKey =
        SoccerProvider.formatDateKey(now.subtract(const Duration(days: 1)));
    final tomorrowKey =
        SoccerProvider.formatDateKey(now.add(const Duration(days: 1)));
    final selectedKey = soccerProvider.selectedDateKey;
    final isCustomDate = !soccerProvider.isViewingToday &&
        selectedKey != yesterdayKey &&
        selectedKey != tomorrowKey;

    final allMatches = data?.matches ?? const <SoccerMatch>[];
    final liveCount = allMatches.where((m) => m.isLive).length;
    final scheduledCount = allMatches.where((m) => m.isScheduled).length;
    final finishedCount = allMatches.where((m) => m.isFinished).length;
    final playableCount = allMatches
        .where(
            (m) => soccerProvider.resolveChannelsForMatch(m, channelProvider).isNotEmpty)
        .length;

    final sections = data != null
        ? _buildSections(data, channelProvider, soccerProvider)
        : const <_LeagueSectionData>[];

    final leaguesList = data?.leagues ?? const <SoccerLeague>[];

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: RefreshIndicator(
        onRefresh: () => soccerProvider.refresh(),
        color: AppTheme.accent(context),
        backgroundColor: AppTheme.surface1(context),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics(),
          ),
          slivers: [
            // ─── HEADER + BUSCADOR + CHIPS ───
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  hPad.left,
                  topPad + 14,
                  hPad.right,
                  8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Fútbol',
                                style: AppFont.primary(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.6,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                data != null
                                    ? '${allMatches.length} partidos · ${leaguesList.length} torneos'
                                    : 'Agenda y resultados en vivo',
                                style: AppFont.primary(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textTertiary(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (liveCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.live.withValues(alpha: 0.14),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                              border: Border.all(
                                color: AppColors.live.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: AppColors.live,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$liveCount EN VIVO',
                                  style: AppFont.primary(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.4,
                                    color: isDark
                                        ? AppColors.liveTint
                                        : AppColors.live,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Selector de fecha (Ayer · Hoy · Mañana · Elegir fecha)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const ClampingScrollPhysics(),
                      child: Row(
                        children: [
                          _DatePill(
                            label: 'Ayer',
                            selected: selectedKey == yesterdayKey,
                            onTap: () {
                              setState(() => _selectedLeagueId = null);
                              soccerProvider.selectDate(yesterdayKey);
                            },
                          ),
                          const SizedBox(width: 8),
                          _DatePill(
                            label: 'Hoy',
                            selected: soccerProvider.isViewingToday,
                            onTap: () {
                              setState(() => _selectedLeagueId = null);
                              soccerProvider.selectDate('today');
                            },
                          ),
                          const SizedBox(width: 8),
                          _DatePill(
                            label: 'Mañana',
                            selected: selectedKey == tomorrowKey,
                            onTap: () {
                              setState(() => _selectedLeagueId = null);
                              soccerProvider.selectDate(tomorrowKey);
                            },
                          ),
                          const SizedBox(width: 8),
                          _DatePill(
                            label: isCustomDate
                                ? _formatDateBadgeLabel(selectedKey)
                                : 'Fecha',
                            icon: Icons.calendar_month_rounded,
                            selected: isCustomDate,
                            onTap: () => _pickDate(context, soccerProvider),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Barra de búsqueda (.sbar)
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.surface1(context),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark
                              ? AppColors.glassBorderSubtle
                              : AppTheme.lightBorder,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: AppTheme.textTertiary(context),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (v) => setState(() => _searchQuery = v),
                              style: AppFont.primary(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                              decoration: InputDecoration(
                                isCollapsed: true,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                fillColor: Colors.transparent,
                                filled: false,
                                hintText: 'Buscar equipo, torneo o instancia...',
                                hintStyle: AppFont.primary(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textTertiary(context),
                                ),
                              ),
                            ),
                          ),
                          if (_searchQuery.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                              child: Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: AppTheme.textTertiary(context),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ─── FILTROS DE ESTADO ───
            SliverToBoxAdapter(
              child: SizedBox(
                height: 46,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: hPad.left,
                    vertical: 4,
                  ),
                  children: [
                    _FilterPill(
                      label: 'Todos (${allMatches.length})',
                      selected: _selectedFilter == _MatchFilter.all,
                      onTap: () =>
                          setState(() => _selectedFilter = _MatchFilter.all),
                    ),
                    const SizedBox(width: 8),
                    _FilterPill(
                      label: 'En vivo ($liveCount)',
                      selected: _selectedFilter == _MatchFilter.live,
                      isLive: liveCount > 0,
                      onTap: () =>
                          setState(() => _selectedFilter = _MatchFilter.live),
                    ),
                    const SizedBox(width: 8),
                    _FilterPill(
                      label: 'Con TV ($playableCount)',
                      selected: _selectedFilter == _MatchFilter.playable,
                      onTap: () => setState(
                          () => _selectedFilter = _MatchFilter.playable),
                    ),
                    const SizedBox(width: 8),
                    _FilterPill(
                      label: 'Próximos ($scheduledCount)',
                      selected: _selectedFilter == _MatchFilter.scheduled,
                      onTap: () => setState(
                          () => _selectedFilter = _MatchFilter.scheduled),
                    ),
                    const SizedBox(width: 8),
                    _FilterPill(
                      label: 'Finalizados ($finishedCount)',
                      selected: _selectedFilter == _MatchFilter.finished,
                      onTap: () => setState(
                          () => _selectedFilter = _MatchFilter.finished),
                    ),
                  ],
                ),
              ),
            ),

            // ─── FILTROS POR LIGA ───
            if (leaguesList.length > 1)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 42,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: hPad.left,
                      vertical: 4,
                    ),
                    itemCount: leaguesList.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _LeagueChip(
                          name: 'Todas las ligas',
                          logoUrl: null,
                          selected: _selectedLeagueId == null,
                          onTap: () => setState(() => _selectedLeagueId = null),
                        );
                      }
                      final league = leaguesList[index - 1];
                      return _LeagueChip(
                        name: league.name,
                        logoUrl: league.logoUrl,
                        selected: _selectedLeagueId == league.id,
                        onTap: () => setState(() {
                          _selectedLeagueId =
                              _selectedLeagueId == league.id ? null : league.id;
                        }),
                      );
                    },
                  ),
                ),
              ),

            // ─── ESTADO DE CARGA / ERROR / VACÍO ───
            if (isLoading && data == null)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: PivoteLoader(size: 40)),
              )
            else if (dateError != null && data == null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.wifi_off_rounded,
                          size: 44,
                          color: AppTheme.textTertiary(context),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No pudimos cargar los partidos',
                          style: AppFont.primary(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Desliza hacia abajo o reintenta para actualizar la agenda.',
                          textAlign: TextAlign.center,
                          style: AppFont.primary(
                            fontSize: 13.5,
                            color: AppTheme.textTertiary(context),
                          ),
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton(
                          onPressed: () => soccerProvider.retry(),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (sections.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.sports_soccer_rounded,
                          size: 44,
                          color: AppTheme.textTertiary(context),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Sin partidos para este filtro',
                          style: AppFont.primary(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Prueba cambiando el filtro o limpiando la búsqueda.',
                          textAlign: TextAlign.center,
                          style: AppFont.primary(
                            fontSize: 13.5,
                            color: AppTheme.textTertiary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  hPad.left,
                  10,
                  hPad.right,
                  110,
                ),
                sliver: SliverList.separated(
                  itemCount: sections.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final section = sections[index];
                    return _LeagueSectionCard(
                      section: section,
                      soccerProvider: soccerProvider,
                      channelProvider: channelProvider,
                      onMatchTap: (m) => _openMatchDetails(context, m),
                      onWatchChannel: (ch) => _watchChannel(context, ch),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LeagueSectionData {
  final SoccerLeague league;
  final List<SoccerMatch> matches;

  const _LeagueSectionData({
    required this.league,
    required this.matches,
  });
}

class _DatePill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _DatePill({
    required this.label,
    this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppTheme.accent(context);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected
              ? accent
              : (isDark ? AppColors.darkBg1 : AppTheme.lightBg1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? accent
                : (isDark ? AppColors.darkBorder2 : AppTheme.lightBorder),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 15,
                color: selected ? Colors.white : AppTheme.textSecondary(context),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppFont.primary(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppTheme.textSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isLive;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.selected,
    this.isLive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppTheme.accent(context);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected
              ? (isLive
                  ? AppColors.live.withValues(alpha: 0.22)
                  : (isDark
                      ? AppColors.accentBg
                      : accent.withValues(alpha: 0.14)))
              : (isDark ? AppColors.glass : AppTheme.lightBg1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? (isLive ? AppColors.live : accent)
                : (isDark ? AppColors.glassBorder : AppTheme.lightBorder),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppFont.primary(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected
                ? (isDark ? Colors.white : (isLive ? AppColors.live : accent))
                : AppTheme.textSecondary(context),
          ),
        ),
      ),
    );
  }
}

class _LeagueChip extends StatelessWidget {
  final String name;
  final String? logoUrl;
  final bool selected;
  final VoidCallback onTap;

  const _LeagueChip({
    required this.name,
    required this.logoUrl,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppTheme.accent(context);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? Colors.white : accent)
              : (isDark ? AppColors.darkBg1 : AppTheme.lightBg1),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? (isDark ? Colors.white : accent)
                : (isDark ? AppColors.darkBorder2 : AppTheme.lightBorder),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (logoUrl != null && logoUrl!.isNotEmpty) ...[
              CachedNetworkImage(
                imageUrl: logoUrl!,
                cacheManager: ImageCacheHelper.logoCacheManager,
                width: 16,
                height: 16,
                fit: BoxFit.contain,
                errorWidget: (_, __, ___) => const SizedBox.shrink(),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              name,
              style: AppFont.primary(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: selected
                    ? (isDark ? AppColors.darkBg : Colors.white)
                    : AppTheme.textSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeagueSectionCard extends StatelessWidget {
  final _LeagueSectionData section;
  final SoccerProvider soccerProvider;
  final ChannelProvider channelProvider;
  final ValueChanged<SoccerMatch> onMatchTap;
  final ValueChanged<Channel> onWatchChannel;

  const _LeagueSectionCard({
    required this.section,
    required this.soccerProvider,
    required this.channelProvider,
    required this.onMatchTap,
    required this.onWatchChannel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final league = section.league;
    final liveInLeague = section.matches.where((m) => m.isLive).length;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface1(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.glassBorderSubtle : AppTheme.lightBorder,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabecera de la liga
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            color: isDark
                ? AppColors.darkBg2.withValues(alpha: 0.65)
                : AppTheme.lightBg2.withValues(alpha: 0.7),
            child: Row(
              children: [
                if (league.logoUrl != null && league.logoUrl!.isNotEmpty) ...[
                  CachedNetworkImage(
                    imageUrl: league.logoUrl!,
                    cacheManager: ImageCacheHelper.logoCacheManager,
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                    errorWidget: (_, __, ___) => Icon(
                      Icons.emoji_events_outlined,
                      size: 20,
                      color: AppTheme.textTertiary(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        league.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFont.primary(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      if (league.country.isNotEmpty)
                        Text(
                          league.country,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFont.primary(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textTertiary(context),
                          ),
                        ),
                    ],
                  ),
                ),
                if (liveInLeague > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.live.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      '$liveInLeague VIVO',
                      style: AppFont.primary(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.liveTint : AppColors.live,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Lista de partidos
          for (int i = 0; i < section.matches.length; i++) ...[
            Divider(
              height: 1,
              thickness: 1,
              color: isDark ? const Color(0xFF1C2231) : AppTheme.lightBorder,
            ),
            _MatchListRow(
              match: section.matches[i],
              playableChannels: soccerProvider.resolveChannelsForMatch(
                section.matches[i],
                channelProvider,
              ),
              onTap: () => onMatchTap(section.matches[i]),
              onWatchChannel: onWatchChannel,
            ),
          ],
        ],
      ),
    );
  }
}

class _MatchListRow extends StatelessWidget {
  final SoccerMatch match;
  final List<Channel> playableChannels;
  final VoidCallback onTap;
  final ValueChanged<Channel> onWatchChannel;

  const _MatchListRow({
    required this.match,
    required this.playableChannels,
    required this.onTap,
    required this.onWatchChannel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final home = match.homeTeamData;
    final away = match.awayTeamData;
    final isLive = match.isLive;
    final hasScore = isLive || match.isFinished;

    final homeScorers = match.getScorersSummary(match.homeTeamId);
    final awayScorers = match.getScorersSummary(match.awayTeamId);
    final hasScorers = homeScorers.isNotEmpty || awayScorers.isNotEmpty;

    final statusText = isLive
        ? (match.time.isNotEmpty ? match.time : 'VIVO')
        : match.isFinished
            ? 'FIN'
            : (match.formattedTime.isNotEmpty ? match.formattedTime : 'PROX');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Fila superior: estado/minuto + instancia + canal
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isLive
                          ? AppColors.live
                          : (isDark ? AppColors.darkBg2 : AppTheme.lightBg2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isLive) ...[
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                        ],
                        Text(
                          statusText,
                          style: AppFont.primary(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: isLive
                                ? Colors.white
                                : AppTheme.textSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (match.stageRound.isNotEmpty &&
                      match.stageRound != match.leagueData.name) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        match.stageRound,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFont.primary(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textTertiary(context),
                        ),
                      ),
                    ),
                  ] else
                    const Spacer(),
                  if (playableChannels.isNotEmpty)
                    GestureDetector(
                      onTap: () => onWatchChannel(playableChannels.first),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accent(context),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.play_arrow_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              playableChannels.first.name,
                              style: AppFont.primary(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (match.tvChannelsDisplay.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBg2 : AppTheme.lightBg2,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        match.tvChannelsDisplay,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFont.primary(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textTertiary(context),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 11),

              // Fila central: Local vs Visitante
              Row(
                children: [
                  Expanded(
                    child: _TeamScoreRow(
                      team: home,
                      score: hasScore ? '${home.score}' : null,
                      isWinner: match.isFinished && home.winner,
                      isDark: isDark,
                      textColor: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  Expanded(
                    child: _TeamScoreRow(
                      team: away,
                      score: hasScore ? '${away.score}' : null,
                      isWinner: match.isFinished && away.winner,
                      isDark: isDark,
                      textColor: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),

              if (hasScorers) ...[
                const SizedBox(height: 8),
                Text(
                  [
                    if (homeScorers.isNotEmpty) homeScorers,
                    if (awayScorers.isNotEmpty) awayScorers,
                  ].join('  ·  '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFont.primary(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textTertiary(context),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamScoreRow extends StatelessWidget {
  final SoccerTeam team;
  final String? score;
  final bool isWinner;
  final bool isDark;
  final Color textColor;

  const _TeamScoreRow({
    required this.team,
    required this.score,
    required this.isWinner,
    required this.isDark,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: team.logoUrl != null && team.logoUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: team.logoUrl!,
                  cacheManager: ImageCacheHelper.logoCacheManager,
                  fit: BoxFit.contain,
                  errorWidget: (_, __, ___) => Icon(
                    Icons.shield_outlined,
                    size: 18,
                    color: AppTheme.textTertiary(context),
                  ),
                )
              : Icon(
                  Icons.shield_outlined,
                  size: 18,
                  color: AppTheme.textTertiary(context),
                ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            team.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFont.primary(
              fontSize: 14.5,
              fontWeight: isWinner ? FontWeight.w800 : FontWeight.w700,
              color: textColor,
            ),
          ),
        ),
        if (team.redCards > 0)
          Container(
            width: 8,
            height: 11,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppColors.live,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        if (score != null)
          SizedBox(
            width: 26,
            child: Text(
              score!,
              textAlign: TextAlign.right,
              style: AppFont.primary(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
            ),
          ),
      ],
    );
  }
}
