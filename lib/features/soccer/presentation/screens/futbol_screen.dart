import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pivote/features/soccer/data/models/soccer_models.dart';
import 'package:pivote/features/soccer/presentation/providers/soccer_provider.dart';
import 'package:pivote/features/soccer/presentation/widgets/soccer_match_card.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/shared/widgets/common/pivote_loader.dart';

enum SoccerStatusFilter { all, live, scheduled, finished }

class FutbolScreen extends StatefulWidget {
  const FutbolScreen({super.key});

  @override
  State<FutbolScreen> createState() => _FutbolScreenState();
}

class _FutbolScreenState extends State<FutbolScreen> {
  String _selectedLeagueId = 'all';
  SoccerStatusFilter _selectedStatus = SoccerStatusFilter.all;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchOpen = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final soccerProvider = context.watch<SoccerProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: _buildContent(soccerProvider, theme, isDark),
      ),
    );
  }

  Widget _buildContent(
    SoccerProvider provider,
    ThemeData theme,
    bool isDark,
  ) {
    if (provider.isLoading && provider.soccerData == null) {
      return _buildLoadingState(theme);
    }

    if (provider.error != null && provider.soccerData == null) {
      return _buildErrorState(provider, theme, isDark);
    }

    final soccerData = provider.soccerData;
    if (soccerData == null || soccerData.matches.isEmpty) {
      return _buildEmptyState(theme, isDark);
    }

    final allMatches = soccerData.matches;
    final liveMatches = allMatches.where((m) => m.isLive).toList();
    final scheduledMatches = allMatches.where((m) => m.isScheduled).toList();
    final finishedMatches = allMatches.where((m) => m.isFinished).toList();

    return RefreshIndicator(
      color: isDark ? AppTheme.darkAccent : theme.colorScheme.primary,
      backgroundColor: isDark ? AppTheme.darkBg2 : theme.colorScheme.surface,
      strokeWidth: 2.5,
      onRefresh: () => provider.fetchData(),
      child: CustomScrollView(
        key: const ValueKey('soccer_scroll_view'),
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        slivers: [
          // ─── Header con buscador y badge En Vivo ───
          _buildSliverHeader(theme, isDark, liveMatches.length, allMatches.length),

          // ─── Pestañas de Estado (Todos, En Vivo, Próximos, Finalizados) ───
          SliverToBoxAdapter(
            child: _buildStatusFilterChips(
              theme,
              isDark,
              allMatches.length,
              liveMatches.length,
              scheduledMatches.length,
              finishedMatches.length,
            ),
          ),

          // ─── Carrusel de Ligas ───
          SliverToBoxAdapter(
            child: _buildLeagueCarousel(soccerData, theme, isDark),
          ),

          // ─── Lista de Partidos agrupada por Liga ───
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: _buildMatchesList(soccerData, theme, isDark),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  // ─── Sliver Header ───
  Widget _buildSliverHeader(
    ThemeData theme,
    bool isDark,
    int liveCount,
    int totalCount,
  ) {
    final textColor = theme.colorScheme.onSurface;

    return SliverAppBar(
      floating: true,
      snap: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      toolbarHeight: _isSearchOpen ? 120 : 64,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor
                  .withValues(alpha: isDark ? 0.85 : 0.90),
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.05),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    // Icono de Fútbol y Título
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.sports_soccer_rounded,
                        size: 20,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Fútbol en Vivo',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                color: textColor,
                              ),
                            ),
                            if (liveCount > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'LIVE $liveCount',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          '$totalCount partidos hoy',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: textColor.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),

                    // Botón de búsqueda local de partidos
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _isSearchOpen = !_isSearchOpen;
                            if (!_isSearchOpen) {
                              _searchController.clear();
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: _isSearchOpen
                                ? (isDark
                                    ? AppTheme.darkAccent
                                    : theme.colorScheme.primary)
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : Colors.black.withValues(alpha: 0.04)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _isSearchOpen
                                ? Icons.close_rounded
                                : Icons.search_rounded,
                            size: 19,
                            color: _isSearchOpen
                                ? (isDark ? Colors.black : Colors.white)
                                : textColor.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Barra de búsqueda expandible
                if (_isSearchOpen) ...[
                  const SizedBox(height: 10),
                  Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkBg2 : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.08),
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() {}),
                      cursorColor:
                          isDark ? AppTheme.darkAccent : theme.colorScheme.primary,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Buscar equipo, liga o canal...',
                        hintStyle: GoogleFonts.spaceGrotesk(
                          fontSize: 12.5,
                          color: textColor.withValues(alpha: 0.4),
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          size: 18,
                          color: isDark
                              ? AppTheme.darkAccent
                              : theme.colorScheme.primary,
                        ),
                        prefixIconConstraints:
                            const BoxConstraints(minWidth: 36, minHeight: 36),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 11),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Status Filter Chips ───
  Widget _buildStatusFilterChips(
    ThemeData theme,
    bool isDark,
    int totalCount,
    int liveCount,
    int scheduledCount,
    int finishedCount,
  ) {
    final tabs = [
      (
        filter: SoccerStatusFilter.all,
        label: 'Todos',
        icon: Icons.all_inclusive_rounded,
        count: totalCount,
        color: isDark ? AppTheme.darkAccent : theme.colorScheme.primary,
      ),
      (
        filter: SoccerStatusFilter.live,
        label: 'En Vivo',
        icon: Icons.flash_on_rounded,
        count: liveCount,
        color: const Color(0xFFEF4444),
      ),
      (
        filter: SoccerStatusFilter.scheduled,
        label: 'Próximos',
        icon: Icons.schedule_rounded,
        count: scheduledCount,
        color: const Color(0xFF3B82F6),
      ),
      (
        filter: SoccerStatusFilter.finished,
        label: 'Finalizados',
        icon: Icons.check_circle_outline_rounded,
        count: finishedCount,
        color: Colors.grey,
      ),
    ];

    return Container(
      height: 42,
      margin: const EdgeInsets.only(top: 8, bottom: 2),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        itemCount: tabs.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = tabs[index];
          final isSelected = _selectedStatus == item.filter;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedStatus = item.filter);
              },
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected
                      ? item.color
                      : (isDark
                          ? AppTheme.darkBg2
                          : theme.colorScheme.surface),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: isSelected
                        ? item.color
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06)),
                  ),
                  boxShadow: isSelected
                      ? AppShadows.glow(item.color, alpha: 0.25)
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      size: 14,
                      color: isSelected
                          ? (item.color == AppTheme.darkAccent
                              ? Colors.black
                              : Colors.white)
                          : item.color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item.label,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected
                            ? (item.color == AppTheme.darkAccent
                                ? Colors.black
                                : Colors.white)
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    if (item.count > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.black.withValues(alpha: 0.2)
                              : item.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${item.count}',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? (item.color == AppTheme.darkAccent
                                    ? Colors.black
                                    : Colors.white)
                                : item.color,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── League Carousel ───
  Widget _buildLeagueCarousel(
    SoccerData data,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(top: 8, bottom: 10),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        itemCount: data.leagues.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildLeagueItem('all', 'Todas las Ligas', null, theme, isDark,
                isAll: true, matchCount: data.matches.length);
          }
          final league = data.leagues[index - 1];
          final matchCount =
              data.matches.where((m) => m.leagueId == league.id).length;
          return _buildLeagueItem(
            league.id,
            league.shortName.isNotEmpty ? league.shortName : league.name,
            league.logoUrl,
            theme,
            isDark,
            matchCount: matchCount,
          );
        },
      ),
    );
  }

  Widget _buildLeagueItem(
    String id,
    String label,
    String? logoUrl,
    ThemeData theme,
    bool isDark, {
    bool isAll = false,
    int matchCount = 0,
  }) {
    final isSelected = _selectedLeagueId == id;
    final activeColor = isDark ? AppTheme.darkAccent : theme.colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          if (_selectedLeagueId != id) {
            setState(() => _selectedLeagueId = id);
          }
        },
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: isSelected
                ? activeColor
                : (isDark ? AppTheme.darkBg2 : theme.colorScheme.surface),
            border: Border.all(
              color: isSelected
                  ? activeColor
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06)),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isAll)
                Icon(
                  Icons.grid_view_rounded,
                  size: 15,
                  color: isSelected
                      ? (isDark ? Colors.black : Colors.white)
                      : activeColor,
                )
              else if (logoUrl != null && logoUrl.isNotEmpty)
                ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: logoUrl,
                    width: 18,
                    height: 18,
                    fit: BoxFit.contain,
                    errorWidget: (_, __, ___) => Icon(
                      Icons.sports_soccer_outlined,
                      color: isSelected
                          ? (isDark ? Colors.black : Colors.white)
                          : theme.hintColor,
                      size: 15,
                    ),
                  ),
                )
              else
                Icon(
                  Icons.sports_soccer_outlined,
                  color: isSelected
                      ? (isDark ? Colors.black : Colors.white)
                      : theme.hintColor,
                  size: 15,
                ),
              const SizedBox(width: 7),
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? (isDark ? Colors.black : Colors.white)
                      : theme.colorScheme.onSurface,
                ),
              ),
              if (matchCount > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.black.withValues(alpha: 0.2)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.05)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    matchCount.toString(),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? (isDark ? Colors.black : Colors.white)
                          : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─── Matches List ───
  Widget _buildMatchesList(
    SoccerData data,
    ThemeData theme,
    bool isDark,
  ) {
    var filteredMatches = data.matches;

    // Filter by League
    if (_selectedLeagueId != 'all') {
      filteredMatches =
          filteredMatches.where((m) => m.leagueId == _selectedLeagueId).toList();
    }

    // Filter by Status
    if (_selectedStatus == SoccerStatusFilter.live) {
      filteredMatches = filteredMatches.where((m) => m.isLive).toList();
    } else if (_selectedStatus == SoccerStatusFilter.scheduled) {
      filteredMatches = filteredMatches.where((m) => m.isScheduled).toList();
    } else if (_selectedStatus == SoccerStatusFilter.finished) {
      filteredMatches = filteredMatches.where((m) => m.isFinished).toList();
    }

    // Filter by Local Search Query
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      filteredMatches = filteredMatches.where((m) {
        final homeName = m.homeTeam.toLowerCase();
        final awayName = m.awayTeam.toLowerCase();
        final channelNames =
            m.tvChannels.map((c) => c.name.toLowerCase()).join(' ');
        return homeName.contains(query) ||
            awayName.contains(query) ||
            channelNames.contains(query);
      }).toList();
    }

    if (filteredMatches.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.sports_soccer_outlined,
                  size: 44,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 14),
                Text(
                  'Sin partidos encontrados',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'No hay partidos para los filtros seleccionados.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12.5,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Group by League
    Map<String, List<SoccerMatch>> grouped = {};
    for (var match in filteredMatches) {
      if (!grouped.containsKey(match.leagueId)) {
        grouped[match.leagueId] = [];
      }
      grouped[match.leagueId]!.add(match);
    }

    final leagueIds = grouped.keys.toList();

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final leagueId = leagueIds[index];
          final league = data.leagues.firstWhere(
            (l) => l.id == leagueId,
            orElse: () => SoccerLeague(
              id: leagueId,
              name: leagueId.toUpperCase(),
              shortName: leagueId.toUpperCase(),
              country: '',
            ),
          );
          final matches = grouped[leagueId]!;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildLeagueSection(league, matches, data, theme, isDark),
          );
        },
        childCount: leagueIds.length,
      ),
    );
  }

  Widget _buildLeagueSection(
    SoccerLeague league,
    List<SoccerMatch> matches,
    SoccerData data,
    ThemeData theme,
    bool isDark,
  ) {
    final liveMatchesInLeague = matches.where((m) => m.isLive).length;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBg2 : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la Liga
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                if (league.logoUrl != null && league.logoUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CachedNetworkImage(
                      imageUrl: league.logoUrl!,
                      width: 22,
                      height: 22,
                      fit: BoxFit.contain,
                      errorWidget: (_, __, ___) => const Icon(
                        Icons.emoji_events_outlined,
                        size: 20,
                      ),
                    ),
                  )
                else
                  const Icon(Icons.emoji_events_outlined, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    league.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                if (liveMatchesInLeague > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$liveMatchesInLeague EN VIVO',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.05),
          ),

          // Matches
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: matches.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.03),
            ),
            itemBuilder: (context, index) {
              return SoccerMatchCard(
                match: matches[index],
                data: data,
                isLast: index == matches.length - 1,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: PivoteLoader(
        color: theme.colorScheme.primary,
        strokeWidth: 3,
        size: 40,
      ),
    );
  }

  Widget _buildErrorState(
    SoccerProvider provider,
    ThemeData theme,
    bool isDark,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar partidos',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.error ?? 'No se pudo sincronizar la información.',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => provider.retry(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isDark ? AppTheme.darkAccent : theme.colorScheme.primary,
                foregroundColor: isDark ? Colors.black : Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_soccer_outlined,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay partidos programados',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vuelve más tarde para consultar la cartelera de partidos en vivo.',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
