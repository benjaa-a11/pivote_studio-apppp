import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/soccer_models.dart';
import '../services/soccer_service.dart';

class MatchDetailsScreen extends StatefulWidget {
  final SoccerMatch match;

  const MatchDetailsScreen({super.key, required this.match});

  @override
  State<MatchDetailsScreen> createState() => _MatchDetailsScreenState();
}

class _MatchDetailsScreenState extends State<MatchDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SoccerService _soccerService = SoccerService();
  MatchDetailData? _detailData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadMatchDetails();
  }

  Future<void> _loadMatchDetails() async {
    if (widget.match.detailsApiUrl == null) {
      setState(() {
        _isLoading = false;
        _error = 'No hay detalles disponibles para este partido';
      });
      return;
    }

    try {
      final data =
          await _soccerService.fetchMatchDetail(widget.match.detailsApiUrl!);
      if (mounted) {
        setState(() {
          _detailData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Error al cargar detalles: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: _isLoading
          ? _buildLoadingState(theme)
          : _error != null
              ? _buildErrorState(theme)
              : _buildContent(theme),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: theme.colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            'Cargando detalles...',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Ups! Algo salió mal',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style:
                  theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _loadMatchDetails();
              },
              child: const Text('Reintentar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(theme),
        SliverToBoxAdapter(
          child: _buildVenueInfo(theme),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _SliverAppBarDelegate(
            _buildTabBar(theme),
          ),
        ),
        SliverFillRemaining(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildTimelineTab(theme),
              _buildLineupsTab(theme),
              _buildStatsTab(theme),
              _buildH2HTab(theme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar(ThemeData theme) {
    final info = _detailData!.matchInfo;
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      stretch: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.cardColor.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_ios_new, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient Background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.2),
                    theme.scaffoldBackgroundColor,
                  ],
                ),
              ),
            ),
            // Match Score Info
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 100, 24, 24),
              child: Column(
                children: [
                  Text(
                    info.league.name.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    info.stage,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTeamHeader(info.teams['home']!, theme),
                      _buildScoreDisplay(info, theme),
                      _buildTeamHeader(info.teams['away']!, theme),
                    ],
                  ),
                  const Spacer(),
                  _buildStatusBadge(info, theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamHeader(MatchTeamInfo team, ThemeData theme) {
    return SizedBox(
      width: 100,
      child: Column(
        children: [
          Container(
              width: 70,
              height: 70,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Hero(
                tag: 'team_${team.id}',
                child: CachedNetworkImage(
                  imageUrl:
                      'https://pivote-api.vercel.app/api/v1/team-logo/${team.id}',
                  errorWidget: (_, __, ___) =>
                      const Icon(Icons.sports_soccer, size: 30),
                ),
              )),
          const SizedBox(height: 12),
          Text(
            team.shortName,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreDisplay(MatchInfo info, ThemeData theme) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              '${info.score['home'] ?? 0}',
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                ':',
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w300,
                  color: theme.hintColor.withValues(alpha: 0.5),
                ),
              ),
            ),
            Text(
              '${info.score['away'] ?? 0}',
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBadge(MatchInfo info, ThemeData theme) {
    final isLive = info.status.toLowerCase().contains('live') ||
        info.status.toLowerCase().contains('prog');
    final color = isLive ? theme.colorScheme.primary : theme.hintColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        info.gameTimeStatusToDisplay.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildVenueInfo(ThemeData theme) {
    final venue = _detailData!.matchInfo.venue;
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          _buildVenueRow(Icons.location_on_outlined,
              venue.stadiumName ?? 'Estadio no disponible', theme),
          if (venue.referee != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1),
            ),
            _buildVenueRow(
                Icons.person_outline, 'Árbitro: ${venue.referee}', theme),
          ],
          if (venue.broadcasters.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1),
            ),
            _buildVenueRow(Icons.tv, venue.broadcasters.join(', '), theme),
          ],
        ],
      ),
    );
  }

  Widget _buildVenueRow(IconData icon, String text, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurface),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(ThemeData theme) {
    return Container(
      color: theme.scaffoldBackgroundColor,
      child: TabBar(
        controller: _tabController,
        isScrollable: false,
        indicatorColor: theme.colorScheme.primary,
        indicatorWeight: 3,
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor: theme.hintColor,
        labelStyle:
            theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
        tabs: const [
          Tab(text: 'SUCESOS'),
          Tab(text: 'ALINEACIÓN'),
          Tab(text: 'STATS'),
          Tab(text: 'H2H'),
        ],
      ),
    );
  }

  // --- TABS ---

  Widget _buildTimelineTab(ThemeData theme) {
    final events = _detailData!.timeline.reversed.toList();
    if (events.isEmpty) {
      return _buildEmptyState(
          'No hay sucesos registrados', Icons.event_note, theme);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final isHome = event.team == 'home';

        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 300 + (index * 50)),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isHome) ...[
                  Expanded(child: _buildEventContent(event, true, theme)),
                  const SizedBox(width: 16),
                ] else ...[
                  const Expanded(child: SizedBox()),
                  const SizedBox(width: 16),
                ],
                Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _getEventColor(event.type, theme)
                            .withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          event.displayTime,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: _getEventColor(event.type, theme),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    if (index != events.length - 1)
                      Container(
                        width: 2,
                        height: 40,
                        color: theme.dividerColor.withValues(alpha: 0.1),
                      ),
                  ],
                ),
                if (!isHome) ...[
                  const SizedBox(width: 16),
                  Expanded(child: _buildEventContent(event, false, theme)),
                ] else ...[
                  const SizedBox(width: 16),
                  const Expanded(child: SizedBox()),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventContent(TimelineEvent event, bool isHome, ThemeData theme) {
    return Column(
      crossAxisAlignment:
          isHome ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isHome) _buildEventIcon(event.type, theme),
            const SizedBox(width: 8),
            Text(
              event.type == 'Substitution' ? 'Cambio' : event.type,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.hintColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            if (isHome) _buildEventIcon(event.type, theme),
          ],
        ),
        const SizedBox(height: 4),
        if (event.player != null)
          Text(
            event.player!,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        if (event.playerIn != null) ...[
          Text(
            'Entra: ${event.playerIn}',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.green),
          ),
          Text(
            'Sale: ${event.playerOut}',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.red),
          ),
        ],
        if (event.detail != null && event.type != 'Substitution')
          Text(
            event.detail!,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
      ],
    );
  }

  Widget _buildEventIcon(String type, ThemeData theme) {
    switch (type) {
      case 'Goal':
        return const Icon(Icons.sports_soccer, size: 16, color: Colors.green);
      case 'Yellow Card':
        return const Icon(Icons.rectangle, size: 16, color: Colors.amber);
      case 'Red Card':
        return const Icon(Icons.rectangle, size: 16, color: Colors.red);
      case 'Substitution':
        return const Icon(Icons.swap_vert, size: 16, color: Colors.blue);
      default:
        return Icon(Icons.info_outline, size: 16, color: theme.hintColor);
    }
  }

  Color _getEventColor(String type, ThemeData theme) {
    switch (type) {
      case 'Goal':
        return Colors.green;
      case 'Yellow Card':
        return Colors.amber;
      case 'Red Card':
        return Colors.red;
      case 'Substitution':
        return Colors.blue;
      default:
        return theme.colorScheme.primary;
    }
  }

  Widget _buildLineupsTab(ThemeData theme) {
    final lineups = _detailData!.lineups;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFormationHeader(lineups.home, lineups.away, theme),
          const SizedBox(height: 24),
          _buildLineupList(_detailData!.matchInfo.teams['home']!.shortName,
              lineups.home.starting, theme),
          const SizedBox(height: 32),
          _buildLineupList(_detailData!.matchInfo.teams['away']!.shortName,
              lineups.away.starting, theme),
        ],
      ),
    );
  }

  Widget _buildFormationHeader(
      TeamLineup home, TeamLineup away, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildFormationBadge(home.formation ?? 'N/A', theme),
        Text('FORMACIÓN',
            style: theme.textTheme.labelSmall
                ?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1)),
        _buildFormationBadge(away.formation ?? 'N/A', theme),
      ],
    );
  }

  Widget _buildFormationBadge(String formation, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        formation,
        style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildLineupList(
      String teamName, List<Player> players, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          teamName.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
              color: theme.hintColor,
              fontWeight: FontWeight.bold,
              letterSpacing: 1),
        ),
        const SizedBox(height: 12),
        ...players.map((p) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: theme.dividerColor.withValues(alpha: 0.05),
                child: Text('${p.jerseyNumber ?? ''}',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ),
              title: Text(p.name,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              subtitle: Text(p.formationPosition ?? p.position ?? '',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.hintColor)),
              trailing: p.isCaptain == true
                  ? Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle),
                      child: const Text('C',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    )
                  : null,
            )),
      ],
    );
  }

  Widget _buildStatsTab(ThemeData theme) {
    final stats = _detailData!.stats.raw;
    if (stats.isEmpty) {
      return _buildEmptyState(
          'No hay estadísticas disponibles', Icons.bar_chart, theme);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 300 + (index * 50)),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: _buildStatBar(stat, theme),
        );
      },
    );
  }

  Widget _buildStatBar(StatRawItem stat, ThemeData theme) {
    final homeVal = stat.values[0];
    final awayVal = stat.values[1];
    final homePerc = stat.percentages[0];
    final awayPerc = stat.percentages[1];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(homeVal,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              Text(stat.name.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.hintColor,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
              Text(awayVal,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              child: Row(
                children: [
                  Expanded(
                    flex: (homePerc * 100).toInt(),
                    child: Container(color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: (awayPerc * 100).toInt(),
                    child: Container(
                        color: theme.hintColor.withValues(alpha: 0.2)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildH2HTab(ThemeData theme) {
    final h2h = _detailData!.headToHead;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildH2HSummary(h2h.summary, theme),
        const SizedBox(height: 32),
        Text(
          'ÚLTIMOS ENFRENTAMIENTOS',
          style: theme.textTheme.labelSmall?.copyWith(
              color: theme.hintColor,
              fontWeight: FontWeight.bold,
              letterSpacing: 1),
        ),
        const SizedBox(height: 16),
        ...h2h.games.map((game) => _buildH2HGameItem(game, theme)),
      ],
    );
  }

  Widget _buildH2HSummary(H2HSummary summary, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'TOTAL: ${summary.totalGames} PARTIDOS',
            style: theme.textTheme.labelSmall
                ?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                  'Gana L', summary.homeWins, Colors.green, theme),
              _buildSummaryItem('Empates', summary.draws, Colors.amber, theme),
              _buildSummaryItem(
                  'Gana V', summary.awayWins, theme.colorScheme.primary, theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
      String label, int value, Color color, ThemeData theme) {
    return Column(
      children: [
        Text(
          '$value',
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w900, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor),
        ),
      ],
    );
  }

  Widget _buildH2HGameItem(H2HGame game, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(game.date,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.hintColor)),
              Text(game.leagueName ?? '',
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: Text(game.homeTeam,
                      textAlign: TextAlign.right,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold))),
              Container(
                width: 60,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: theme.dividerColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  game.score,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 2),
                ),
              ),
              Expanded(
                  child: Text(game.awayTeam,
                      textAlign: TextAlign.left,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String text, IconData icon, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: theme.hintColor.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(text,
              style:
                  theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final Widget _tabBar;

  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return _tabBar;
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
