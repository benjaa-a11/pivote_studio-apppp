import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pivote/features/soccer/data/models/soccer_models.dart';
import 'package:pivote/features/soccer/presentation/providers/soccer_provider.dart';
import 'package:pivote/features/soccer/presentation/widgets/soccer_match_card.dart';
import 'package:pivote/features/soccer/presentation/widgets/world_cup_countdown.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/shared/widgets/common/pivote_loader.dart';

class FutbolScreen extends StatefulWidget {
  const FutbolScreen({super.key});

  @override
  State<FutbolScreen> createState() => _FutbolScreenState();
}

class _FutbolScreenState extends State<FutbolScreen> {
  String _selectedLeagueId = 'all';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final soccerProvider = context.watch<SoccerProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              // Sleek Modern Header with title and live status
              SliverToBoxAdapter(
                child: _buildScreenHeader(theme, soccerProvider),
              ),
            ];
          },
          body: _buildContent(soccerProvider, theme),
        ),
      ),
    );
  }

  Widget _buildScreenHeader(ThemeData theme, SoccerProvider provider) {
    final liveCount =
        provider.soccerData?.matches.where((m) => m.isLive).length ?? 0;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey).withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Glowing Sports Soccer Icon Box
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.sports_soccer_rounded,
              size: 24,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'Fútbol',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: -0.6,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color:
                            theme.colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.25),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        'LIGAS & RESULTADOS',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Agenda Deportiva & Marcadores en Vivo',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.darkText3 : AppTheme.lightText3,
                  ),
                ),
              ],
            ),
          ),
          // Live count badge or Refresh button
          if (liveCount > 0) ...[
            const SizedBox(width: 8),
            _buildLiveCountBadge(theme, liveCount),
          ] else ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                provider.fetchData();
              },
              icon: const Icon(Icons.refresh_rounded, size: 20),
              color: theme.colorScheme.primary,
              style: IconButton.styleFrom(
                backgroundColor:
                    theme.colorScheme.primary.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLiveCountBadge(ThemeData theme, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AnimatedLiveDot(color: theme.colorScheme.error),
          const SizedBox(width: 6),
          Text(
            '$count EN VIVO',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.error,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(SoccerProvider provider, ThemeData theme) {
    if (provider.isLoading && provider.soccerData == null) {
      return _buildLoadingState(theme);
    }

    if (provider.error != null && provider.soccerData == null) {
      return _buildErrorState(provider, theme);
    }

    final soccerData = provider.soccerData;
    if (soccerData == null || soccerData.matches.isEmpty) {
      return _buildEmptyState(theme);
    }

    return RefreshIndicator(
      color: theme.colorScheme.primary,
      backgroundColor: theme.cardColor,
      strokeWidth: 2.5,
      onRefresh: () => provider.fetchData(),
      child: CustomScrollView(
        key: const ValueKey('soccer_scroll_view'),
        physics: const ClampingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _buildLeagueCarousel(soccerData, theme),
          ),
          if (_selectedLeagueId == 'all')
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverToBoxAdapter(
                child: WorldCupCountdown(),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: _buildMatchesList(soccerData, theme),
          ),
          SliverToBoxAdapter(child: _buildVersionFooter(theme)),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
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

  Widget _buildLeagueCarousel(SoccerData data, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 56,
      margin: const EdgeInsets.only(top: 8, bottom: 12),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: data.leagues.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildLeagueItem('all', 'Todo', null, theme, isDark,
                isAll: true, matchCount: data.matches.length);
          }
          final league = data.leagues[index - 1];
          final matchCount =
              data.matches.where((m) => m.leagueId == league.id).length;
          return _buildLeagueItem(
              league.id, league.shortName, league.logoUrl, theme, isDark,
              matchCount: matchCount);
        },
      ),
    );
  }

  Widget _buildLeagueItem(
      String id, String label, String? logoUrl, ThemeData theme, bool isDark,
      {bool isAll = false, int matchCount = 0}) {
    final isSelected = _selectedLeagueId == id;

    return GestureDetector(
      onTap: () {
        if (_selectedLeagueId != id) {
          setState(() => _selectedLeagueId = id);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: isDark
                      ? [AppTheme.darkCard, AppTheme.darkBg]
                      : [Colors.white, theme.colorScheme.surface],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.4)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.05)),
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isAll)
              Icon(
                Icons.apps_rounded,
                size: 16,
                color: isSelected ? Colors.white : theme.colorScheme.primary,
              )
            else if (logoUrl != null)
              ClipOval(
                child: CachedNetworkImage(
                  imageUrl: logoUrl,
                  width: 20,
                  height: 20,
                  fit: BoxFit.contain,
                  errorWidget: (_, __, ___) => Icon(
                    Icons.sports_soccer_outlined,
                    color: isSelected ? Colors.white70 : theme.hintColor,
                    size: 16,
                  ),
                ),
              )
            else
              Icon(
                Icons.sports_soccer_outlined,
                color: isSelected ? Colors.white70 : theme.hintColor,
                size: 16,
              ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : theme.colorScheme.onSurface,
              ),
            ),
            if (matchCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  matchCount.toString(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color:
                        isSelected ? Colors.white : theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMatchesList(SoccerData data, ThemeData theme) {
    final filteredMatches = _selectedLeagueId == 'all'
        ? data.matches
        : data.matches.where((m) => m.leagueId == _selectedLeagueId).toList();

    Map<String, List<SoccerMatch>> grouped = {};
    for (var match in filteredMatches) {
      if (!grouped.containsKey(match.leagueId)) {
        grouped[match.leagueId] = [];
      }
      grouped[match.leagueId]!.add(match);
    }

    final leagueIds = grouped.keys.toList();

    if (leagueIds.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child:
            _buildEmptyState(theme, message: 'No hay partidos para esta liga'),
      );
    }

    final liveMatches =
        filteredMatches.where((m) => m.isLive).toList(growable: false);
    final upcomingMatches = filteredMatches
        .where((m) => !m.isLive && !m.isFinished)
        .toList(growable: false);

    final width = MediaQuery.sizeOf(context).width;
    final isWide = width > 700;

    if (isWide) {
      // Split league sections into left and right columns for responsiveness
      final leftColumnLeagues = <String>[];
      final rightColumnLeagues = <String>[];
      for (int i = 0; i < leagueIds.length; i++) {
        if (i % 2 == 0) {
          leftColumnLeagues.add(leagueIds[i]);
        } else {
          rightColumnLeagues.add(leagueIds[i]);
        }
      }

      return SliverList(
        delegate: SliverChildListDelegate([
          KeyedSubtree(
            key: ValueKey('summary_$_selectedLeagueId'),
            child: AppAnimations.staggeredSlideIn(
              index: 0,
              child: _buildMatchesSummary(theme, liveMatches.length,
                  upcomingMatches.length, filteredMatches.length),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(leftColumnLeagues.length, (index) {
                    final leagueId = leftColumnLeagues[index];
                    final league = data.leagues.firstWhere(
                        (l) => l.id == leagueId,
                        orElse: () => SoccerLeague(
                            id: leagueId,
                            name: leagueId.toUpperCase(),
                            shortName: leagueId.toUpperCase(),
                            country: ''));
                    final matches = grouped[leagueId]!;
                    return KeyedSubtree(
                      key: ValueKey('league_${_selectedLeagueId}_$leagueId'),
                      child: AppAnimations.staggeredSlideIn(
                        index: index * 2 + 1,
                        child:
                            _buildLeagueSection(league, matches, data, theme),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(rightColumnLeagues.length, (index) {
                    final leagueId = rightColumnLeagues[index];
                    final league = data.leagues.firstWhere(
                        (l) => l.id == leagueId,
                        orElse: () => SoccerLeague(
                            id: leagueId,
                            name: leagueId.toUpperCase(),
                            shortName: leagueId.toUpperCase(),
                            country: ''));
                    final matches = grouped[leagueId]!;
                    return KeyedSubtree(
                      key: ValueKey('league_${_selectedLeagueId}_$leagueId'),
                      child: AppAnimations.staggeredSlideIn(
                        index: index * 2 + 2,
                        child:
                            _buildLeagueSection(league, matches, data, theme),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ]),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == 0) {
            return KeyedSubtree(
              key: ValueKey('summary_$_selectedLeagueId'),
              child: AppAnimations.staggeredSlideIn(
                index: 0,
                child: _buildMatchesSummary(theme, liveMatches.length,
                    upcomingMatches.length, filteredMatches.length),
              ),
            );
          }

          final leagueId = leagueIds[index - 1];
          final league = data.leagues.firstWhere((l) => l.id == leagueId,
              orElse: () => SoccerLeague(
                  id: leagueId,
                  name: leagueId.toUpperCase(),
                  shortName: leagueId.toUpperCase(),
                  country: ''));
          final matches = grouped[leagueId]!;

          return KeyedSubtree(
            key: ValueKey('league_${_selectedLeagueId}_$leagueId'),
            child: AppAnimations.staggeredSlideIn(
              index: index,
              child: _buildLeagueSection(league, matches, data, theme),
            ),
          );
        },
        childCount: leagueIds.length + 1,
      ),
    );
  }

  Widget _buildMatchesSummary(
      ThemeData theme, int liveCount, int upcomingCount, int totalCount) {
    final isDark = theme.brightness == Brightness.dark;
    final hasLive = liveCount > 0;
    final finishedCount = totalCount - liveCount - upcomingCount;

    return Container(
      margin: const EdgeInsets.only(bottom: 16, top: 4),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          // Live chip
          if (hasLive) ...[
            _buildInfoChip(
              theme,
              Icons.flash_on_rounded,
              '$liveCount en vivo',
              theme.colorScheme.error,
              theme.colorScheme.error.withValues(alpha: 0.08),
            ),
            const SizedBox(width: 8),
          ],
          // Upcoming chip
          if (upcomingCount > 0)
            _buildInfoChip(
              theme,
              Icons.schedule_rounded,
              '$upcomingCount próx.',
              theme.colorScheme.primary,
              theme.colorScheme.primary.withValues(alpha: 0.06),
            ),
          if (upcomingCount > 0 && finishedCount > 0) const SizedBox(width: 8),
          // Finished chip
          if (finishedCount > 0)
            _buildInfoChip(
              theme,
              Icons.check_circle_outline_rounded,
              '$finishedCount fin.',
              isDark ? AppTheme.darkText3 : AppTheme.lightText3,
              (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
            ),
          const Spacer(),
          // Total
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black)
                  .withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$totalCount total',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: theme.hintColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(ThemeData theme, IconData icon, String label,
      Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeagueSection(SoccerLeague league, List<SoccerMatch> matches,
      SoccerData data, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final liveMatchesInLeague = matches.where((m) => m.isLive).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBg1 : AppTheme.lightBg1,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? AppTheme.darkBorder.withValues(alpha: 0.5)
              : AppTheme.lightBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // League Header with gradient
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.03),
                  Colors.transparent,
                ],
              ),
            ),
            child: Row(
              children: [
                if (league.logoUrl != null)
                  Container(
                    width: 36,
                    height: 36,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: league.logoUrl!,
                      fit: BoxFit.contain,
                      errorWidget: (context, url, error) => const Icon(
                          Icons.emoji_events_rounded,
                          color: Colors.amber,
                          size: 18),
                    ),
                  )
                else
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.emoji_events_rounded,
                        color: Colors.amber, size: 18),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        league.name,
                        style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            league.country.toUpperCase(),
                            style: GoogleFonts.spaceGrotesk(
                              fontWeight: FontWeight.w700,
                              fontSize: 9,
                              letterSpacing: 1.0,
                              color: theme.hintColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.hintColor.withValues(alpha: 0.3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${matches.length} ${matches.length == 1 ? 'partido' : 'partidos'}',
                            style: GoogleFonts.spaceGrotesk(
                              fontWeight: FontWeight.w600,
                              fontSize: 9,
                              color: theme.hintColor.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Live indicator for this league
                if (liveMatchesInLeague > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _AnimatedLiveDot(
                            color: theme.colorScheme.error, size: 5),
                        const SizedBox(width: 4),
                        Text(
                          '$liveMatchesInLeague',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.error,
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
                ? AppTheme.darkBorder.withValues(alpha: 0.3)
                : AppTheme.lightBorder.withValues(alpha: 0.5),
          ),

          Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              matches.length,
              (index) => SoccerMatchCard(
                match: matches[index],
                data: data,
                isLast: index == matches.length - 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(SoccerProvider provider, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.06),
                shape: BoxShape.circle,
                border: Border.all(
                    color: theme.colorScheme.error.withValues(alpha: 0.1)),
              ),
              child: Icon(Icons.cloud_off_rounded,
                  size: 56,
                  color: theme.colorScheme.error.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 28),
            Text(
              '¡Vaya! Hubo un problema',
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'No pudimos conectar con los servidores. Por favor, intenta de nuevo.',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                  color: theme.hintColor, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => provider.retry(),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text('REINTENTAR',
                    style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.w800, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.brightness == Brightness.dark
                      ? AppTheme.darkBg
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, {String? message}) {
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: 0.04),
              ),
              child: Icon(Icons.sports_soccer_rounded,
                  size: 56, color: theme.hintColor.withValues(alpha: 0.3)),
            ),
            const SizedBox(height: 24),
            Text(
              message ?? 'No hay partidos programados',
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: theme.hintColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tan pronto como se confirmen nuevos encuentros, aparecerán aquí.',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                  color: theme.hintColor.withValues(alpha: 0.6),
                  fontSize: 13,
                  height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionFooter(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      theme.dividerColor.withValues(alpha: 0.15),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Icon(Icons.sports_soccer_rounded,
                    size: 14, color: theme.dividerColor.withValues(alpha: 0.2)),
              ),
              Container(
                width: 40,
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.dividerColor.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          RichText(
            text: TextSpan(
              style: GoogleFonts.spaceGrotesk(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.0,
                color: theme.hintColor.withValues(alpha: 0.25),
              ),
              children: [
                const TextSpan(text: 'PIVOTE '),
                TextSpan(
                  text: 'SPORTS',
                  style: TextStyle(
                      color: theme.colorScheme.primary.withValues(alpha: 0.4)),
                ),
                const TextSpan(text: ' PLATFORM'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated pulsing live dot
class _AnimatedLiveDot extends StatefulWidget {
  final Color color;
  final double size;

  const _AnimatedLiveDot({required this.color, this.size = 6});

  @override
  State<_AnimatedLiveDot> createState() => _AnimatedLiveDotState();
}

class _AnimatedLiveDotState extends State<_AnimatedLiveDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
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
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: _animation.value),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: _animation.value * 0.5),
                blurRadius: 4,
                spreadRadius: 0,
              ),
            ],
          ),
        );
      },
    );
  }
}
