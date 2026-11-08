import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:pivote/features/soccer/presentation/providers/soccer_provider.dart';
import 'package:pivote/features/soccer/presentation/widgets/soccer_match_card.dart';
import 'package:pivote/features/soccer/presentation/widgets/match_details_bottom_sheet.dart';
import 'package:pivote/features/soccer/presentation/widgets/soccer_pitch_painter.dart';
import 'package:pivote/features/soccer/data/models/soccer_models.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/core/services/image_cache_helper.dart';
import 'package:pivote/shared/widgets/common/pivote_app_bar.dart';
import 'package:pivote/shared/widgets/common/apple_pressable.dart';
import 'package:pivote/shared/widgets/common/app_state_views.dart';

class FutbolScreen extends StatefulWidget {
  const FutbolScreen({super.key});

  @override
  State<FutbolScreen> createState() => _FutbolScreenState();
}

enum _MatchFilter { all, live, today, finished }

class _FutbolScreenState extends State<FutbolScreen> {
  final Set<String> _collapsedLeagues = {};
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _searchDebounce;
  String _searchQuery = '';
  bool _isSearching = false;
  _MatchFilter _selectedFilter = _MatchFilter.all;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toggleLeague(String leagueId) {
    setState(() {
      if (_collapsedLeagues.contains(leagueId)) {
        _collapsedLeagues.remove(leagueId);
      } else {
        _collapsedLeagues.add(leagueId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final horizontalPad = AppResponsive.horizontalPadding(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          const SliverToBoxAdapter(
            child: PivoteAppBar(
              title: 'Agenda Deportiva',
              showBackButton: false,
            ),
          ),
        ],
        body: Consumer<SoccerProvider>(
          builder: (context, soccerProvider, child) {
            if (soccerProvider.isLoading && soccerProvider.data == null) {
              return _buildSkeletonState(theme, isDark, horizontalPad);
            }

            if (soccerProvider.data == null) {
              return _buildErrorState(soccerProvider, theme, isDark);
            }

            final data = soccerProvider.data!;
            if (data.matches.isEmpty) {
              return _buildEmptyState(theme, isDark);
            }

            final allMatches = List<SoccerMatch>.from(data.matches);
            final liveCount = allMatches.where((m) => m.isLive).length;
            final todayCount = allMatches.where((m) => m.isToday).length;
            final finishedCount = allMatches.where((m) => m.isFinished).length;

            // Partido destacado (Hero Match): Priorizar en vivo, sino próximo hoy con canales
            final heroCandidates = allMatches.where((m) => !m.isFinished).toList()
              ..sort((a, b) {
                if (a.isLive && !b.isLive) return -1;
                if (!a.isLive && b.isLive) return 1;
                final aHasCh = a.tvChannels.any((c) => c.name.isNotEmpty);
                final bHasCh = b.tvChannels.any((c) => c.name.isNotEmpty);
                if (aHasCh && !bHasCh) return -1;
                if (!aHasCh && bHasCh) return 1;
                final aTime =
                    a.kickoff ?? DateTime.fromMillisecondsSinceEpoch(0);
                final bTime =
                    b.kickoff ?? DateTime.fromMillisecondsSinceEpoch(0);
                return aTime.compareTo(bTime);
              });
            final SoccerMatch? heroMatch =
                heroCandidates.isNotEmpty ? heroCandidates.first : null;

            // Filtrar partidos según pestaña y búsqueda
            final q = _searchQuery.trim().toLowerCase();
            final filteredMatches = allMatches.where((m) {
              if (_selectedFilter == _MatchFilter.live && !m.isLive) {
                return false;
              }
              if (_selectedFilter == _MatchFilter.today && !m.isToday) {
                return false;
              }
              if (_selectedFilter == _MatchFilter.finished && !m.isFinished) {
                return false;
              }
              if (q.isNotEmpty) {
                final league = data.leagues.firstWhere(
                  (l) => l.id == m.leagueId,
                  orElse: () => SoccerLeague(
                      id: '', name: '', country: '', shortName: ''),
                );
                return m.homeTeam.toLowerCase().contains(q) ||
                    m.awayTeam.toLowerCase().contains(q) ||
                    league.name.toLowerCase().contains(q) ||
                    league.country.toLowerCase().contains(q);
              }
              return true;
            }).toList();

            // Agrupar por liga
            final Map<String, List<SoccerMatch>> matchesByLeague = {};
            for (final match in filteredMatches) {
              matchesByLeague.putIfAbsent(match.leagueId, () => []).add(match);
            }

            final sortedLeagueIds = matchesByLeague.keys.toList();
            sortedLeagueIds.sort((a, b) {
              final matchesA = matchesByLeague[a]!;
              final matchesB = matchesByLeague[b]!;
              final hasLiveA = matchesA.any((m) => m.isLive);
              final hasLiveB = matchesB.any((m) => m.isLive);
              if (hasLiveA && !hasLiveB) return -1;
              if (!hasLiveA && hasLiveB) return 1;
              return 0;
            });

            return RefreshIndicator(
              onRefresh: () => soccerProvider.refresh(),
              color: AppTheme.accent(context),
              backgroundColor: AppTheme.cardSurface(context),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  // ─── HEADER SECCIÓN + BUSCADOR ───
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                          horizontalPad, 12, horizontalPad, 12),
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
                                      'AGENDA DEPORTIVA',
                                      style: AppFont.primary(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.4,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      liveCount > 0
                                          ? '$liveCount ${liveCount == 1 ? 'partido' : 'partidos'} en juego ahora mismo'
                                          : '${allMatches.length} partidos programados en la fecha',
                                      style: AppFont.primary(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textSecondary(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Botón búsqueda rápida de partido / equipo
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isSearching = !_isSearching;
                                    if (!_isSearching) {
                                      _searchCtrl.clear();
                                      _searchQuery = '';
                                    }
                                  });
                                },
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: _isSearching
                                        ? AppTheme.accent(context)
                                            .withValues(alpha: 0.16)
                                        : AppTheme.surface1(context),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _isSearching
                                          ? AppTheme.accent(context)
                                          : AppTheme.border(context),
                                    ),
                                  ),
                                  child: Icon(
                                    _isSearching
                                        ? Icons.close_rounded
                                        : Icons.search_rounded,
                                    size: 18,
                                    color: _isSearching
                                        ? AppTheme.accent(context)
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Barra de búsqueda colapsable
                          AnimatedCrossFade(
                            duration: const Duration(milliseconds: 220),
                            crossFadeState: _isSearching
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            firstChild: const SizedBox.shrink(),
                            secondChild: Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Container(
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppTheme.surface1(context),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md),
                                  border: Border.all(
                                    color: AppTheme.border(context),
                                  ),
                                ),
                                child: TextField(
                                  controller: _searchCtrl,
                                  onChanged: (val) {
                                    _searchDebounce?.cancel();
                                    _searchDebounce = Timer(
                                      const Duration(milliseconds: 140),
                                      () {
                                        if (mounted) {
                                          setState(() => _searchQuery = val);
                                        }
                                      },
                                    );
                                  },
                                  style: AppFont.primary(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Buscar equipo, torneo o país...',
                                    hintStyle: AppFont.primary(
                                      fontSize: 13,
                                      color: AppTheme.textSecondary(context),
                                    ),
                                    prefixIcon: Icon(
                                      Icons.search_rounded,
                                      size: 18,
                                      color: AppTheme.textSecondary(context),
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // ─── PILLS DE FILTRO RÁPIDO ───
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: [
                                _buildFilterChip(
                                  label: 'Todos (${allMatches.length})',
                                  filter: _MatchFilter.all,
                                  theme: theme,
                                  isDark: isDark,
                                ),
                                const SizedBox(width: 8),
                                _buildFilterChip(
                                  label: 'En vivo ($liveCount)',
                                  filter: _MatchFilter.live,
                                  isLiveBadge: liveCount > 0,
                                  theme: theme,
                                  isDark: isDark,
                                ),
                                const SizedBox(width: 8),
                                _buildFilterChip(
                                  label: 'Hoy ($todayCount)',
                                  filter: _MatchFilter.today,
                                  theme: theme,
                                  isDark: isDark,
                                ),
                                const SizedBox(width: 8),
                                _buildFilterChip(
                                  label: 'Finalizados ($finishedCount)',
                                  filter: _MatchFilter.finished,
                                  theme: theme,
                                  isDark: isDark,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ─── HERO MATCH DESTACADO (Si estamos en Todos y sin búsqueda) ───
                  if (heroMatch != null &&
                      _selectedFilter == _MatchFilter.all &&
                      _searchQuery.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                            horizontalPad, 4, horizontalPad, 20),
                        child: _buildFeaturedHeroCard(
                            context, heroMatch, data, theme, isDark),
                      ),
                    ),

                  // ─── ESTADO SIN RESULTADOS DE FILTRO ───
                  if (sortedLeagueIds.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: AppStateView.empty(
                        icon: Icons.sports_soccer_rounded,
                        title: 'No encontramos partidos',
                        subtitle:
                            'Probá cambiando el filtro o buscando otro equipo.',
                      ),
                    )
                  else
                    // ─── LISTA DE LIGAS Y PARTIDOS ───
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                          horizontalPad, 0, horizontalPad, 110),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final leagueId = sortedLeagueIds[index];
                            final league = data.leagues.firstWhere(
                              (l) => l.id == leagueId,
                              orElse: () => SoccerLeague(
                                id: leagueId,
                                name: 'Torneo Internacional',
                                country: '',
                                shortName: '',
                              ),
                            );
                            final matches = matchesByLeague[leagueId]!;
                            final isCollapsed =
                                _collapsedLeagues.contains(leagueId);
                            final liveInLeague =
                                matches.where((m) => m.isLive).length;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.cardSurface(context),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.xl),
                                  border: Border.all(
                                    color: AppTheme.border(context),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                          alpha: isDark ? 0.28 : 0.04),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    // Cabecera del Torneo
                                    InkWell(
                                      onTap: () => _toggleLeague(leagueId),
                                      borderRadius: BorderRadius.vertical(
                                        top: const Radius.circular(
                                            AppRadius.xl),
                                        bottom: isCollapsed
                                            ? const Radius.circular(
                                                AppRadius.xl)
                                            : Radius.zero,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 11,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? AppColors.ink2
                                                  .withValues(alpha: 0.72)
                                              : AppColors.lightSurface2
                                                  .withValues(alpha: 0.65),
                                          borderRadius: BorderRadius.vertical(
                                            top: const Radius.circular(
                                                AppRadius.xl),
                                            bottom: isCollapsed
                                                ? const Radius.circular(
                                                    AppRadius.xl)
                                                : Radius.zero,
                                          ),
                                          border: isCollapsed
                                              ? null
                                              : Border(
                                                  bottom: BorderSide(
                                                    color: AppTheme.border(
                                                        context),
                                                    width: 1,
                                                  ),
                                                ),
                                        ),
                                        child: Row(
                                          children: [
                                            _buildLeagueBadge(league, isDark),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  if (league.country.isNotEmpty)
                                                    Text(
                                                      league.country
                                                          .toUpperCase(),
                                                      style: AppFont.primary(
                                                        fontSize: 9.5,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        letterSpacing: 0.8,
                                                        color: AppTheme
                                                            .textSecondary(
                                                                context),
                                                      ),
                                                    ),
                                                  Text(
                                                    league.name,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: AppFont.primary(
                                                      fontSize: 13.5,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: theme.colorScheme
                                                          .onSurface,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (liveInLeague > 0) ...[
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 7,
                                                  vertical: 3,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.live
                                                      .withValues(alpha: 0.15),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Container(
                                                      width: 5,
                                                      height: 5,
                                                      decoration:
                                                          const BoxDecoration(
                                                        color: AppColors.live,
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '$liveInLeague VIVO',
                                                      style: AppFont.primary(
                                                        fontSize: 9.5,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        color: AppColors.live,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                            ],
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 7,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: (isDark
                                                        ? Colors.white
                                                        : Colors.black)
                                                    .withValues(alpha: 0.06),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                '${matches.length}',
                                                style: AppFont.primary(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w800,
                                                  color: AppTheme.textSecondary(
                                                      context),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            AnimatedRotation(
                                              turns: isCollapsed ? -0.25 : 0,
                                              duration: const Duration(
                                                  milliseconds: 220),
                                              child: Icon(
                                                Icons
                                                    .keyboard_arrow_down_rounded,
                                                size: 20,
                                                color: AppTheme.textSecondary(
                                                    context),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // Partidos de la Liga
                                    if (!isCollapsed)
                                      Column(
                                        children: List.generate(
                                          matches.length,
                                          (mIndex) => SoccerMatchCard(
                                            match: matches[mIndex],
                                            data: data,
                                            isLast:
                                                mIndex == matches.length - 1,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                          childCount: sortedLeagueIds.length,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required _MatchFilter filter,
    required ThemeData theme,
    required bool isDark,
    bool isLiveBadge = false,
  }) {
    final isSelected = _selectedFilter == filter;
    final activeColor = isLiveBadge
        ? AppColors.live
        : AppTheme.accent(context);

    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor
              : AppTheme.surface1(context),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected
                ? activeColor
                : AppTheme.border(context),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLiveBadge) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : AppColors.live,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppFont.primary(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isSelected
                    ? (isLiveBadge
                        ? Colors.white
                        : AppTheme.onAccent(context))
                    : AppTheme.textSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedHeroCard(
    BuildContext context,
    SoccerMatch match,
    SoccerData data,
    ThemeData theme,
    bool isDark,
  ) {
    final homeTeam = data.teams.firstWhere(
      (t) => t.id == match.homeTeamId,
      orElse: () => SoccerTeam(
          id: match.homeTeamId,
          name: match.homeTeam,
          shortName: match.homeTeam),
    );
    final awayTeam = data.teams.firstWhere(
      (t) => t.id == match.awayTeamId,
      orElse: () => SoccerTeam(
          id: match.awayTeamId,
          name: match.awayTeam,
          shortName: match.awayTeam),
    );
    final league = data.leagues.firstWhere(
      (l) => l.id == match.leagueId,
      orElse: () => SoccerLeague(
          id: match.leagueId, name: 'Destacado', country: '', shortName: ''),
    );

    final homeColor = homeTeam.primaryColor ?? AppColors.accent;
    final awayColor = awayTeam.primaryColor ?? AppColors.secondary;

    return ApplePressable(
      scaleDownFactor: 0.97,
      borderRadius: BorderRadius.circular(AppRadius.xxl),
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          showDragHandle: false,
          useSafeArea: true,
          builder: (context) => ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            child: MatchDetailsBottomSheet(
              match: match,
              homeTeam: homeTeam,
              awayTeam: awayTeam,
              league: league,
            ),
          ),
        );
      },
      child: Container(
        height: 146,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          color: isDark ? AppColors.ink2 : theme.cardColor,
          border: Border.all(
            color: match.isLive
                ? AppColors.live.withValues(alpha: 0.45)
                : AppTheme.border(context),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Aura local
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.xxl),
                  gradient: RadialGradient(
                    center: const Alignment(-1.05, -0.2),
                    radius: 1.2,
                    colors: [
                      homeColor.withValues(alpha: isDark ? 0.35 : 0.16),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Aura visitante
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.xxl),
                  gradient: RadialGradient(
                    center: const Alignment(1.05, 0.2),
                    radius: 1.2,
                    colors: [
                      awayColor.withValues(alpha: isDark ? 0.35 : 0.16),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Cancha dibujada sutil
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.xxl),
                child: CustomPaint(
                  painter: SoccerPitchPainter(
                    lineColor: (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: isDark ? 0.08 : 0.05),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  // Header del Hero
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: match.isLive
                              ? AppColors.live
                              : AppTheme.accent(context).withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          match.isLive
                              ? 'DESTACADO EN VIVO'
                              : 'PARTIDO DESTACADO',
                          style: AppFont.primary(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                            color: match.isLive
                                ? Colors.white
                                : AppTheme.accent(context),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          league.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFont.primary(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textSecondary(context),
                          ),
                        ),
                      ),
                      if (match.tvChannels.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.tv_rounded,
                              size: 13,
                              color: AppTheme.accent(context),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              match.tvChannels.first.name,
                              style: AppFont.primary(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.accent(context),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const Spacer(),
                  // Equipos + Marcador
                  Row(
                    children: [
                      // Local
                      Expanded(
                        child: Row(
                          children: [
                            _buildTeamCircle(homeTeam, homeColor, isDark),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                homeTeam.shortName.isNotEmpty
                                    ? homeTeam.shortName
                                    : homeTeam.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppFont.primary(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  height: 1.15,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Centro (Marcador u Hora)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: match.isLive && match.score.length >= 2
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${match.score[0]} - ${match.score[1]}',
                                    style: AppFont.score(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w900,
                                      height: 1.0,
                                      color: AppTheme.accent(context),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    match.timeStatus.isNotEmpty
                                        ? match.timeStatus
                                        : 'EN JUEGO',
                                    style: AppFont.primary(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.live,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    match.formattedTime,
                                    style: AppFont.score(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      height: 1.0,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    match.dayLabel.toUpperCase(),
                                    style: AppFont.primary(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.textSecondary(context),
                                    ),
                                  ),
                                ],
                              ),
                      ),

                      // Visitante
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Text(
                                awayTeam.shortName.isNotEmpty
                                    ? awayTeam.shortName
                                    : awayTeam.name,
                                textAlign: TextAlign.right,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppFont.primary(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  height: 1.15,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            _buildTeamCircle(awayTeam, awayColor, isDark),
                          ],
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
    );
  }

  Widget _buildTeamCircle(SoccerTeam team, Color color, bool isDark) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? AppColors.ink1 : Colors.white,
        border: Border.all(
          color: color.withValues(alpha: 0.4),
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
                size: 16,
                color: color,
              ),
            )
          : FaIcon(
              FontAwesomeIcons.shield,
              size: 16,
              color: color,
            ),
    );
  }

  Widget _buildLeagueBadge(SoccerLeague league, bool isDark) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: isDark ? AppColors.ink1 : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: (league.logoUrl != null && league.logoUrl!.isNotEmpty)
          ? CachedNetworkImage(
              cacheManager: ImageCacheHelper.logoCacheManager,
              imageUrl: league.logoUrl!,
              fit: BoxFit.contain,
              errorWidget: (_, __, ___) => Icon(
                Icons.emoji_events_rounded,
                size: 15,
                color: isDark ? AppColors.accent : AppColors.lightAccent,
              ),
            )
          : Icon(
              Icons.emoji_events_rounded,
              size: 15,
              color: isDark ? AppColors.accent : AppColors.lightAccent,
            ),
    );
  }

  Widget _buildSkeletonState(
    ThemeData theme,
    bool isDark,
    double horizontalPad,
  ) {
    final baseColor = isDark ? AppColors.ink2 : AppColors.lightSurface2;
    final highlightColor = isDark ? AppColors.ink3 : Colors.white;
    final cardColor = isDark ? AppColors.ink1 : theme.cardColor;

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: horizontalPad, vertical: 12),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header shimmer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 130,
                      height: 18,
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 180,
                      height: 12,
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: cardColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Filter pills shimmer
            Row(
              children: List.generate(4, (i) {
                return Expanded(
                  child: Container(
                    height: 34,
                    margin: EdgeInsets.only(right: i < 3 ? 8 : 0),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),

            // Hero Match Card shimmer
            Container(
              height: 146,
              width: double.infinity,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(
                  color: AppTheme.border(context),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 70,
                        height: 14,
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: baseColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 60,
                            height: 14,
                            decoration: BoxDecoration(
                              color: baseColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 32,
                        height: 24,
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 60,
                            height: 14,
                            decoration: BoxDecoration(
                              color: baseColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: baseColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // League Title shimmer
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: cardColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 140,
                  height: 16,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Match rows shimmer
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(
                  color: AppTheme.border(context),
                  width: 1,
                ),
              ),
              child: Column(
                children: List.generate(3, (i) {
                  return Container(
                    height: 64,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: i < 2
                          ? Border(
                              bottom: BorderSide(
                                color: AppTheme.border(context),
                                width: 0.8,
                              ),
                            )
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: baseColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              width: 90,
                              height: 12,
                              decoration: BoxDecoration(
                                color: baseColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 40,
                          height: 16,
                          decoration: BoxDecoration(
                            color: baseColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 90,
                              height: 12,
                              decoration: BoxDecoration(
                                color: baseColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: baseColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(
    SoccerProvider provider,
    ThemeData theme,
    bool isDark,
  ) {
    return AppStateView.error(
      title: 'No pudimos cargar los partidos',
      subtitle: 'La fuente tarda en responder. Seguimos intentando.',
      onAction: () => provider.retry(),
      actionLabel: 'Reintentar ahora',
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return const AppStateView.empty(
      icon: Icons.sports_soccer_outlined,
      title: 'Sin partidos cargados',
      subtitle: 'Todavía no hay partidos cargados para la fecha.',
    );
  }
}
