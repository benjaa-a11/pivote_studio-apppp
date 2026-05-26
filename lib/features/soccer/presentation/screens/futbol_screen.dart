import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pivote/features/soccer/data/models/soccer_models.dart';
import 'package:pivote/features/soccer/presentation/providers/soccer_provider.dart';
import 'package:pivote/features/soccer/presentation/widgets/world_cup_countdown.dart';
import 'package:pivote/features/soccer/presentation/widgets/soccer_match_card.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/shared/widgets/common/pivote_loader.dart';

class FutbolScreen extends StatefulWidget {
  const FutbolScreen({super.key});

  @override
  State<FutbolScreen> createState() => _FutbolScreenState();
}

class _FutbolScreenState extends State<FutbolScreen>
    with SingleTickerProviderStateMixin {
  String _selectedLeagueId = 'all';
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // FWC-26 accent colors
  static const Color _fwcOrange = Color(0xFFE83600);
  static const Color _fwcPurple = Color(0xFF6B00CC);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }
 
  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

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
              // Header with title and live badge
              SliverToBoxAdapter(
                child: _buildScreenHeader(theme, soccerProvider),
              ),
              // World Cup Countdown Hero
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: WorldCupCountdown(),
                ),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? AppTheme.darkBorder.withValues(alpha: 0.15)
                : AppTheme.lightBorder.withValues(alpha: 0.3),
            width: 1.2,
          ),
        ),
      ),
      child: Row(
        children: [
          // Colored accent bar
          Container(
            width: 4,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_fwcOrange, _fwcPurple],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Soccer icon container (Unified & polished)
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _fwcOrange.withValues(alpha: isDark ? 0.22 : 0.14),
                  _fwcOrange.withValues(alpha: isDark ? 0.06 : 0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _fwcOrange.withValues(alpha: isDark ? 0.35 : 0.25),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _fwcOrange.withValues(alpha: isDark ? 0.08 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.sports_soccer,
              size: 20,
              color: _fwcOrange,
            ),
          ),
          const SizedBox(width: 12),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
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
                const SizedBox(height: 2),
                Text(
                  'FIFA World Cup 26™ & más',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.darkText3 : AppTheme.lightText3,
                  ),
                ),
              ],
            ),
          ),
          // Live count badge
          if (liveCount > 0) _buildLiveCountBadge(theme, liveCount),
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
      height: 100,
      margin: const EdgeInsets.only(top: 12, bottom: 16),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: data.leagues.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
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
          _fadeController.reset();
          _fadeController.forward();
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.12)
                  : (isDark ? AppTheme.darkBg2 : AppTheme.lightBg2),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                width: isSelected ? 2.5 : 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                        blurRadius: 12,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
            child: Center(
              child: isAll
                  ? Icon(
                      Icons.apps_rounded,
                      size: 22,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.hintColor,
                    )
                  : logoUrl != null
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: logoUrl,
                            width: 36,
                            height: 36,
                            fit: BoxFit.contain,
                            placeholder: (context, url) =>
                                const SizedBox(width: 20, height: 20),
                            errorWidget: (context, url, error) => Icon(
                                Icons.sports_soccer_outlined,
                                color: theme.hintColor,
                                size: 22),
                          ),
                        )
                      : Icon(Icons.sports_soccer_outlined,
                          color: theme.hintColor, size: 22),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 64,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? theme.colorScheme.primary : theme.hintColor,
              ),
            ),
          ),
          // Match count indicator
          if (isSelected && matchCount > 0)
            Container(
              margin: const EdgeInsets.only(top: 3),
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary,
              ),
            ),
        ],
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

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == 0) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: _buildMatchesSummary(theme, liveMatches.length,
                  upcomingMatches.length, filteredMatches.length),
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

          return FadeTransition(
            opacity: _fadeAnimation,
            child: _buildLeagueSection(league, matches, data, theme),
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

          ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: matches.length,
            itemBuilder: (context, index) => SoccerMatchCard(
              match: matches[index],
              data: data,
              isLast: index == matches.length - 1,
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
