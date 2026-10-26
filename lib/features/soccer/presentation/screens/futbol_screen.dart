import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import 'package:pivote/features/soccer/data/models/soccer_models.dart';
import 'package:pivote/features/soccer/presentation/providers/soccer_provider.dart';
import 'package:pivote/features/soccer/presentation/widgets/soccer_match_card.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/services/image_cache_helper.dart';

enum SoccerStatusFilter { all, live, scheduled, finished }

class FutbolScreen extends StatefulWidget {
  const FutbolScreen({super.key});

  @override
  State<FutbolScreen> createState() => _FutbolScreenState();
}

class _FutbolScreenState extends State<FutbolScreen> {
  String _selectedLeagueId = 'all';
  SoccerStatusFilter _selectedStatus = SoccerStatusFilter.all;

  String _getFormattedSpanishDate() {
    final now = DateTime.now();
    const weekdays = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo'
    ];
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];
    final weekday = weekdays[(now.weekday - 1) % 7];
    final month = months[(now.month - 1) % 12];
    return '$weekday, ${now.day} de $month';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final soccerProvider = context.watch<SoccerProvider>();

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF080B11) : theme.scaffoldBackgroundColor,
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
      return _buildLoadingState(theme, isDark);
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
      backgroundColor:
          isDark ? const Color(0xFF131722) : theme.colorScheme.surface,
      strokeWidth: 2.5,
      onRefresh: () => provider.fetchData(),
      child: CustomScrollView(
        key: const ValueKey('soccer_scroll_view'),
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        slivers: [
          // ─── Header estilo Pivote Live con fecha ───
          _buildSliverHeader(
              theme, isDark, liveMatches.length, allMatches.length),

          // ─── Pestañas de Estado (Todos, En Vivo, Próximos, Finalizados) ───
          SliverToBoxAdapter(
            child: _buildStatusFilterTabs(
              theme,
              isDark,
              allMatches.length,
              liveMatches.length,
              scheduledMatches.length,
              finishedMatches.length,
            ),
          ),

          // ─── Rail de Ligas (Horizontal scroll) ───
          SliverToBoxAdapter(
            child: _buildLeagueRail(soccerData, theme, isDark),
          ),

          // ─── Separador sutil antes de la lista ───
          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // ─── Lista de Partidos agrupada por Liga ───
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: _buildMatchesList(soccerData, theme, isDark),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 90)),
        ],
      ),
    );
  }

  // ─── Sliver Header: Logo PIVOTE LIVE + Fecha ───
  Widget _buildSliverHeader(
    ThemeData theme,
    bool isDark,
    int liveCount,
    int totalCount,
  ) {
    return SliverAppBar(
      floating: true,
      snap: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      toolbarHeight: 58,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: (isDark
                      ? const Color(0xFF080B11)
                      : theme.scaffoldBackgroundColor)
                  .withValues(alpha: isDark ? 0.90 : 0.94),
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? const Color(0xFF1E2533)
                      : Colors.black.withValues(alpha: 0.06),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo PIVOTE LIVE (con 'LIVE' en verde lima brillante)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'PIVOTE',
                      style: GoogleFonts.bigShouldersDisplay(
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: isDark
                            ? const Color(0xFFEEF1F6)
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: AppTheme.darkAccent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'LIVE',
                        style: GoogleFonts.bigShouldersDisplay(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF080B11),
                        ),
                      ),
                    ),
                  ],
                ),

                // Fecha en español estilizada en píldora moderna
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF131722)
                        : Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF1E2533)
                          : AppTheme.lightBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 13,
                        color: isDark
                            ? AppTheme.darkAccent
                            : theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getFormattedSpanishDate(),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? const Color(0xFFC7CFDD)
                              : const Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Status Filter Tabs: Todos, En Vivo, Próximos, Finalizados ───
  Widget _buildStatusFilterTabs(
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
        count: totalCount,
        hasDot: false,
      ),
      (
        filter: SoccerStatusFilter.live,
        label: 'En vivo',
        count: liveCount,
        hasDot: liveCount > 0,
      ),
      (
        filter: SoccerStatusFilter.scheduled,
        label: 'Próximos',
        count: scheduledCount,
        hasDot: false,
      ),
      (
        filter: SoccerStatusFilter.finished,
        label: 'Finalizados',
        count: finishedCount,
        hasDot: false,
      ),
    ];

    return Container(
      height: 44,
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
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
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark
                          ? const Color(0xFF161B27)
                          : theme.colorScheme.surface)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? (isDark
                            ? const Color(0xFF1E2533)
                            : AppTheme.lightBorder)
                        : Colors.transparent,
                  ),
                  boxShadow: isSelected && isDark
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item.hasDot) ...[
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF5468),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      item.label,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected
                            ? (isDark
                                ? const Color(0xFFEEF1F6)
                                : theme.colorScheme.onSurface)
                            : (isDark
                                ? const Color(0xFF7C879B)
                                : theme.hintColor),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${item.count}',
                      style: GoogleFonts.bigShouldersDisplay(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color:
                            isSelected && item.filter == SoccerStatusFilter.live
                                ? const Color(0xFFFF5468)
                                : isSelected
                                    ? (isDark
                                        ? AppTheme.darkAccent
                                        : theme.colorScheme.primary)
                                    : (isDark
                                        ? const Color(0xFF7C879B)
                                        : theme.hintColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Rail de Ligas (Horizontal Pills con Escudos y Contadores) ───
  Widget _buildLeagueRail(
    SoccerData data,
    ThemeData theme,
    bool isDark,
  ) {
    // Calcular conteo por liga
    final Map<String, int> leagueCounts = {};
    for (final m in data.matches) {
      leagueCounts[m.leagueId] = (leagueCounts[m.leagueId] ?? 0) + 1;
    }

    // Filtrar solo ligas con al menos 1 partido
    final activeLeagues =
        data.leagues.where((l) => (leagueCounts[l.id] ?? 0) > 0).toList();

    return Container(
      height: 42,
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        itemCount: activeLeagues.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            final isSelected = _selectedLeagueId == 'all';
            return _buildLeagueChip(
              id: 'all',
              label: 'Todas las ligas',
              logoUrl: null,
              count: data.matches.length,
              isSelected: isSelected,
              theme: theme,
              isDark: isDark,
            );
          }

          final league = activeLeagues[index - 1];
          final isSelected = _selectedLeagueId == league.id;
          final count = leagueCounts[league.id] ?? 0;

          return _buildLeagueChip(
            id: league.id,
            label: league.shortName.isNotEmpty ? league.shortName : league.name,
            logoUrl: league.logoUrl,
            count: count,
            isSelected: isSelected,
            theme: theme,
            isDark: isDark,
          );
        },
      ),
    );
  }

  Widget _buildLeagueChip({
    required String id,
    required String label,
    required String? logoUrl,
    required int count,
    required bool isSelected,
    required ThemeData theme,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedLeagueId = id);
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF161B27) : theme.colorScheme.surface)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? (isDark
                      ? AppTheme.darkAccent.withValues(alpha: 0.6)
                      : theme.colorScheme.primary)
                  : (isDark ? const Color(0xFF1E2533) : AppTheme.lightBorder),
              width: isSelected ? 1.4 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (logoUrl != null && logoUrl.isNotEmpty) ...[
                ClipOval(
                  child: CachedNetworkImage(
                    cacheManager: ImageCacheHelper.logoCacheManager,
                    imageUrl: logoUrl,
                    width: 17,
                    height: 17,
                    fit: BoxFit.contain,
                    errorWidget: (_, __, ___) => const Icon(
                      Icons.sports_soccer,
                      size: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 7),
              ],
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? (isDark
                          ? const Color(0xFFEEF1F6)
                          : theme.colorScheme.onSurface)
                      : (isDark ? const Color(0xFF7C879B) : theme.hintColor),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$count',
                style: GoogleFonts.bigShouldersDisplay(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isSelected
                      ? AppTheme.darkAccent
                      : (isDark ? const Color(0xFF7C879B) : theme.hintColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Lista de Partidos Agrupada por Liga ───
  Widget _buildMatchesList(
    SoccerData data,
    ThemeData theme,
    bool isDark,
  ) {
    var filteredMatches = data.matches;

    // Filtro por liga
    if (_selectedLeagueId != 'all') {
      filteredMatches = filteredMatches
          .where((m) => m.leagueId == _selectedLeagueId)
          .toList();
    }

    // Filtro por estado
    if (_selectedStatus == SoccerStatusFilter.live) {
      filteredMatches = filteredMatches.where((m) => m.isLive).toList();
    } else if (_selectedStatus == SoccerStatusFilter.scheduled) {
      filteredMatches = filteredMatches.where((m) => m.isScheduled).toList();
    } else if (_selectedStatus == SoccerStatusFilter.finished) {
      filteredMatches = filteredMatches.where((m) => m.isFinished).toList();
    }

    if (filteredMatches.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: _buildEmptyFilterState(theme, isDark),
          ),
        ),
      );
    }

    // Agrupar por Liga
    final Map<String, List<SoccerMatch>> grouped = {};
    for (final match in filteredMatches) {
      grouped.putIfAbsent(match.leagueId, () => []).add(match);
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
              name: 'Torneo',
              shortName: 'Torneo',
              country: '',
            ),
          );
          final matches = grouped[leagueId]!;

          return Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: _buildLeagueCardSection(
              league,
              matches,
              data,
              theme,
              isDark,
            ),
          );
        },
        childCount: leagueIds.length,
      ),
    );
  }

  Widget _buildLeagueCardSection(
    SoccerLeague league,
    List<SoccerMatch> matches,
    SoccerData data,
    ThemeData theme,
    bool isDark,
  ) {
    final liveInLeague = matches.where((m) => m.isLive).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado de la liga (Estilo HTML .sh)
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
          child: Row(
            children: [
              if (league.logoUrl != null && league.logoUrl!.isNotEmpty)
                ClipOval(
                  child: CachedNetworkImage(
                    cacheManager: ImageCacheHelper.logoCacheManager,
                    imageUrl: league.logoUrl!,
                    width: 26,
                    height: 26,
                    fit: BoxFit.contain,
                    errorWidget: (_, __, ___) => const Icon(
                      Icons.emoji_events_outlined,
                      size: 22,
                    ),
                  ),
                )
              else
                const Icon(Icons.emoji_events_outlined, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      league.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.bigShouldersDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                        color: isDark
                            ? const Color(0xFFEEF1F6)
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    if (league.country.isNotEmpty)
                      Text(
                        league.country,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFF7C879B)
                              : theme.hintColor,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Contador de partidos
              Text(
                liveInLeague > 0
                    ? '$liveInLeague en vivo · ${matches.length} partidos'
                    : '${matches.length} partidos',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: liveInLeague > 0
                      ? const Color(0xFFFF5468)
                      : (isDark ? const Color(0xFF7C879B) : theme.hintColor),
                ),
              ),
            ],
          ),
        ),

        // Contenedor de filas de partidos (Estilo HTML .rows)
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F131C) : theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF1E2533) : AppTheme.lightBorder,
              width: 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: List.generate(matches.length, (i) {
              return SoccerMatchCard(
                match: matches[i],
                data: data,
                isLast: i == matches.length - 1,
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyFilterState(ThemeData theme, bool isDark) {
    String title;
    String subtitle;

    switch (_selectedStatus) {
      case SoccerStatusFilter.live:
        title = 'No hay partidos en juego';
        subtitle = 'Cuando arranque uno, aparece acá.';
        break;
      case SoccerStatusFilter.scheduled:
        title = 'No quedan partidos por jugar';
        subtitle = 'Mirá los finalizados para ver los resultados.';
        break;
      case SoccerStatusFilter.finished:
        title = 'Todavía no terminó ninguno';
        subtitle = 'Los resultados aparecen apenas finalizan.';
        break;
      case SoccerStatusFilter.all:
        title = 'Sin partidos encontrados';
        subtitle = 'No hay partidos para los filtros seleccionados.';
        break;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.sports_soccer_outlined,
          size: 46,
          color: isDark
              ? const Color(0xFF7C879B)
              : theme.hintColor.withValues(alpha: 0.5),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 13,
            color: isDark ? const Color(0xFF7C879B) : theme.hintColor,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState(ThemeData theme, bool isDark) {
    final baseColor = isDark ? const Color(0xFF131824) : Colors.grey.shade300;
    final highlightColor =
        isDark ? const Color(0xFF222B3D) : Colors.grey.shade100;
    final cardColor = isDark ? const Color(0xFF0F131C) : theme.cardColor;

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      isDark ? const Color(0xFF1E2533) : AppTheme.lightBorder,
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
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      isDark ? const Color(0xFF1E2533) : AppTheme.lightBorder,
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
                                color: isDark
                                    ? const Color(0xFF1E2533)
                                    : AppTheme.lightBorder,
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: Color(0xFFFF5468),
            ),
            const SizedBox(height: 16),
            Text(
              'No pudimos cargar los partidos',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'La fuente tarda en responder. Seguimos intentando.',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                color: isDark ? const Color(0xFF7C879B) : theme.hintColor,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => provider.retry(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reintentar ahora'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.darkAccent,
                foregroundColor: const Color(0xFF080B11),
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
              color: isDark ? const Color(0xFF7C879B) : theme.hintColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Sin partidos cargados',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Todavía no hay partidos cargados para la fecha.',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                color: isDark ? const Color(0xFF7C879B) : theme.hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
