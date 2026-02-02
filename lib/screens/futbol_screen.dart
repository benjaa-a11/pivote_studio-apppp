import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/soccer_models.dart';
import '../providers/soccer_provider.dart';
import '../widgets/match_details_sheet.dart';
import '../widgets/world_cup_countdown.dart';

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
        child: Column(
          children: [
            _buildHeader(theme),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: _buildContent(soccerProvider, theme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerTheme.color ??
                theme.dividerColor.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          WorldCupCountdown(),
        ],
      ),
    );
  }

  Widget _buildContent(SoccerProvider provider, ThemeData theme) {
    if (provider.isLoading && provider.soccerData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null && provider.soccerData == null) {
      return _buildErrorState(provider, theme);
    }

    final soccerData = provider.soccerData;
    if (soccerData == null || soccerData.matches.isEmpty) {
      return _buildEmptyState(theme);
    }

    return RefreshIndicator(
      onRefresh: () => provider.fetchData(),
      child: CustomScrollView(
        key: const ValueKey('soccer_scroll_view'),
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _buildLeagueCarousel(soccerData, theme),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: _buildMatchesList(soccerData, theme),
          ),
          SliverToBoxAdapter(child: _buildVersionFooter(theme)),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _buildLeagueCarousel(SoccerData data, ThemeData theme) {
    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: data.leagues.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: 20),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildLeagueItem(
              'all',
              'Todo',
              null,
              theme,
              isAll: true,
            );
          }
          final league = data.leagues[index - 1];
          return _buildLeagueItem(
            league.id,
            league.shortName,
            league.logoUrl,
            theme,
          );
        },
      ),
    );
  }

  Widget _buildLeagueItem(
      String id, String label, String? logoUrl, ThemeData theme,
      {bool isAll = false}) {
    final isSelected = _selectedLeagueId == id;

    return GestureDetector(
      onTap: () => setState(() => _selectedLeagueId = id),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.15)
                  : theme.cardColor,
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : (theme.dividerTheme.color ?? theme.dividerColor)
                        .withValues(alpha: 0.2),
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                        blurRadius: 10,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
            child: Center(
              child: isAll
                  ? Icon(
                      Icons.grid_view_rounded,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    )
                  : logoUrl != null
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: logoUrl,
                            width: 38,
                            height: 38,
                            fit: BoxFit.contain,
                            placeholder: (context, url) =>
                                const SizedBox(width: 20, height: 20),
                            errorWidget: (context, url, error) => Icon(
                                Icons.sports_soccer_outlined,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.4)),
                          ),
                        )
                      : Icon(Icons.sports_soccer_outlined,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.4)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.7),
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

    // Group matches by league
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

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final leagueId = leagueIds[index];
          final league = data.leagues.firstWhere((l) => l.id == leagueId,
              orElse: () => SoccerLeague(
                  id: leagueId,
                  name: leagueId.toUpperCase(),
                  shortName: leagueId.toUpperCase(),
                  country: ''));
          final matches = grouped[leagueId]!;

          return _buildLeagueSection(league, matches, data, theme);
        },
        childCount: leagueIds.length,
      ),
    );
  }

  Widget _buildLeagueSection(SoccerLeague league, List<SoccerMatch> matches,
      SoccerData data, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (theme.dividerTheme.color ?? theme.dividerColor)
              .withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.3),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                if (league.logoUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CachedNetworkImage(
                      imageUrl: league.logoUrl!,
                      width: 24,
                      height: 24,
                      fit: BoxFit.contain,
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.emoji_events, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    league.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.1,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              itemCount: matches.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) =>
                  _buildMatchCard(matches[index], data, theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(SoccerMatch match, SoccerData data, ThemeData theme) {
    final homeTeam = data.teams.firstWhere((t) => t.id == match.homeTeamId,
        orElse: () => SoccerTeam(
            id: '', name: match.homeTeam, shortName: match.homeTeam));
    final awayTeam = data.teams.firstWhere((t) => t.id == match.awayTeamId,
        orElse: () => SoccerTeam(
            id: '', name: match.awayTeam, shortName: match.awayTeam));

    final isLive = match.isLive;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showMatchDetails(match, data),
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              // Header: Stage and Status
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      match.stage.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.hintColor.withValues(alpha: 0.5),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    _buildStatusBadge(match, theme),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Main content: Teams and Score/Time
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildTeamCol(homeTeam, theme),
                    Expanded(
                      child: Column(
                        children: [
                          if (isLive || match.isFinished)
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildScoreText(
                                        match.score.isNotEmpty
                                            ? match.score[0].toString()
                                            : '0',
                                        isLive,
                                        theme),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12),
                                      child: Text('-',
                                          style: theme.textTheme.headlineMedium
                                              ?.copyWith(
                                                  color: theme
                                                      .colorScheme.primary
                                                      .withValues(alpha: 0.5),
                                                  fontWeight: FontWeight.w900)),
                                    ),
                                    _buildScoreText(
                                        match.score.isNotEmpty &&
                                                match.score.length > 1
                                            ? match.score[1].toString()
                                            : '0',
                                        isLive,
                                        theme),
                                  ],
                                ),
                                if (isLive) _buildLiveTimeBadge(match, theme),
                              ],
                            )
                          else
                            Column(
                              children: [
                                Text(
                                  'HOY',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.0,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatStartTime(match.startTime),
                                  style:
                                      theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    _buildTeamCol(awayTeam, theme),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Footer: TV Channels
              if (match.tvChannels.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withValues(alpha: 0.03),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.live_tv_rounded,
                          size: 14,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          match.tvChannels.join(' • '),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
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

  String _formatStartTime(String startTime) {
    // Input format: "28-01-2026 17:00"
    try {
      final parts = startTime.split(' ');
      if (parts.length > 1) {
        return parts[1];
      }
    } catch (e) {
      debugPrint('Error formatting time: $e');
    }
    return startTime;
  }

  Widget _buildLiveTimeBadge(SoccerMatch match, ThemeData theme) {
    String displayTime = match.time;
    final ts = match.timeStatus.toLowerCase();
    if (ts.contains('et') || ts.contains('entretiempo')) {
      displayTime = 'Entretiempo';
    }

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        displayTime,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildTeamCol(SoccerTeam team, ThemeData theme) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            child: team.logoUrl != null
                ? Hero(
                    tag: 'team_${team.id}',
                    child: CachedNetworkImage(
                      imageUrl: team.logoUrl!,
                      height: 48,
                      width: 48,
                      fit: BoxFit.contain,
                      placeholder: (context, url) =>
                          const SizedBox(width: 48, height: 48),
                      errorWidget: (context, url, error) => Icon(
                          Icons.sports_soccer_outlined,
                          size: 32,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.2)),
                    ),
                  )
                : Icon(Icons.sports_soccer_outlined,
                    size: 32,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
          ),
          const SizedBox(height: 10),
          Text(
            team.shortName,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: -0.2,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildScoreText(String score, bool isLive, ThemeData theme) {
    return Text(
      score,
      style: theme.textTheme.displayMedium?.copyWith(
        fontWeight: FontWeight.w900,
        color: isLive ? theme.colorScheme.primary : theme.colorScheme.onSurface,
        fontSize: 36,
        letterSpacing: -1,
      ),
    );
  }

  Widget _buildStatusBadge(SoccerMatch match, ThemeData theme) {
    final isLive = match.isLive;
    final isFinished = match.isFinished;
    final isScheduled = match.isScheduled;

    Color badgeColor = theme.dividerColor.withValues(alpha: 0.05);
    Color textColor = theme.hintColor.withValues(alpha: 0.4);
    String statusText = match.status;

    if (isLive) {
      badgeColor = Colors.red.withValues(alpha: 0.08);
      textColor = Colors.red;
      statusText = 'EN VIVO';
    } else if (isScheduled) {
      badgeColor = theme.colorScheme.primary.withValues(alpha: 0.08);
      textColor = theme.colorScheme.primary;
      statusText = 'PRÓXIMO';
    } else if (isFinished) {
      statusText = 'FINALIZADO';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLive) ...[
            _buildPulseDot(),
            const SizedBox(width: 6),
          ],
          Text(
            statusText.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w900,
              fontSize: 9,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPulseDot() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      builder: (context, value, child) {
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: value),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: value * 0.5),
                blurRadius: 4,
                spreadRadius: 2,
              ),
            ],
          ),
        );
      },
      onEnd:
          () {}, // Handled by repeating logic if needed, but simple pulse for now
    );
  }

  Widget _buildErrorState(SoccerProvider provider, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 64,
                color: theme.colorScheme.error.withValues(alpha: 0.5)),
            const SizedBox(height: 24),
            Text(
              '¡Ups! Algo salió mal',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'No pudimos cargar los resultados de fútbol en este momento.',
              style:
                  theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => provider.retry(),
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('REINTENTAR'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, {String? message}) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_soccer_outlined,
                size: 80, color: theme.dividerColor.withValues(alpha: 0.1)),
            const SizedBox(height: 24),
            Text(
              message ?? 'No hay partidos disponibles',
              style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.hintColor, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (message == null)
              Text(
                'Vuelve más tarde para ver los resultados en vivo.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.hintColor.withValues(alpha: 0.7)),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionFooter(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 20,
                height: 1,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(
                  Icons.sports_soccer,
                  size: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                ),
              ),
              Container(
                width: 20,
                height: 1,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
              ),
            ],
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              children: [
                const TextSpan(text: 'PIVOTE '),
                TextSpan(
                  text: 'SPORT',
                  style: TextStyle(
                    color: theme.colorScheme.primary.withValues(alpha: 0.4),
                  ),
                ),
                const TextSpan(text: ' v1.4.0'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMatchDetails(SoccerMatch match, SoccerData data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MatchDetailsSheet(
        matchId: match.id,
      ),
    );
  }
}
