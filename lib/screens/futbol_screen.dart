import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/soccer_models.dart';
import '../providers/soccer_provider.dart';
import '../widgets/world_cup_countdown.dart';
import '../widgets/soccer_match_card.dart';

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
    final isDark = theme.brightness == Brightness.dark;
    final soccerProvider = context.watch<SoccerProvider>();

    // Define Jungle Green colors based on theme
    final jungleBackground =
        isDark ? const Color(0xFF062C24) : const Color(0xFFF3F4F6);
    final jungleHeader =
        isDark ? const Color(0xFF022C22) : const Color(0xFF0F4C3A);
    final jungleSubHeader =
        isDark ? const Color(0xFF063F33) : const Color(0xFF135D49);

    return Scaffold(
      backgroundColor: jungleBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(theme, jungleHeader, jungleSubHeader),
            _buildTabs(theme, soccerProvider, jungleHeader),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: _buildContent(soccerProvider, theme, jungleBackground),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
      ThemeData theme, Color headerColor, Color subHeaderColor) {
    return Column(
      children: [
        // World Cup Countdown - Original but fits the theme
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          color: theme.scaffoldBackgroundColor, // Keep it on neutral background
          child: const Center(child: WorldCupCountdown()),
        ),
        // Date Navigation Row
        Container(
          color: subHeaderColor,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 14, color: Colors.white),
              ),
              const SizedBox(width: 20),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'HOY',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down_rounded,
                      color: Colors.white),
                ],
              ),
              const SizedBox(width: 20),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabs(
      ThemeData theme, SoccerProvider provider, Color backgroundColor) {
    final liveCount =
        provider.soccerData?.matches.where((m) => m.isLive).length ?? 0;

    return Container(
      color: backgroundColor,
      child: Row(
        children: [
          _buildTabItem('TODOS', true, theme),
          _buildTabItem('VIVO ($liveCount)', false, theme, isLive: true),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, bool isSelected, ThemeData theme,
      {bool isLive = false}) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.transparent,
            ),
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : Colors.white60,
                letterSpacing: 1.0,
              ),
            ),
          ),
          Container(
            height: 3,
            color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
      SoccerProvider provider, ThemeData theme, Color backgroundColor) {
    if (provider.isLoading && provider.soccerData == null) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF10B981)));
    }

    if (provider.error != null && provider.soccerData == null) {
      return _buildErrorState(provider, theme);
    }

    final soccerData = provider.soccerData;
    if (soccerData == null || soccerData.matches.isEmpty) {
      return _buildEmptyState(theme);
    }

    return RefreshIndicator(
      color: const Color(0xFF10B981),
      onRefresh: () => provider.fetchData(),
      child: CustomScrollView(
        key: const ValueKey('soccer_scroll_view'),
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _buildLeagueCarousel(soccerData, theme),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: _buildMatchesList(soccerData, theme, backgroundColor),
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

  Widget _buildMatchesList(
      SoccerData data, ThemeData theme, Color backgroundColor) {
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

          return _buildLeagueSection(
              league, matches, data, theme, backgroundColor);
        },
        childCount: leagueIds.length,
      ),
    );
  }

  Widget _buildLeagueSection(SoccerLeague league, List<SoccerMatch> matches,
      SoccerData data, ThemeData theme, Color backgroundColor) {
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF0F4C3A) : Colors.white;
    final borderColor = isDark ? const Color(0xFF0A3A2F) : Colors.grey[300];
    final headerColor =
        isDark ? const Color(0xFF0B382B) : const Color(0xFFF3F4F6);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor ?? Colors.transparent,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(
                bottom: BorderSide(
                    color: borderColor ?? Colors.transparent, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.emoji_events_rounded,
                    color: Colors.amber, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    league.name.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 0.5,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                Icon(Icons.expand_less_rounded,
                    color: isDark ? Colors.white38 : Colors.black38, size: 20),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const ClampingScrollPhysics(),
            itemCount: matches.length,
            itemBuilder: (context, index) => SoccerMatchCard(
              match: matches[index],
              data: data,
              onTap: () {},
            ),
          ),
          // Footer Link as in HTML
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            width: double.infinity,
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(12)),
              border: Border(
                top: BorderSide(
                    color: borderColor ?? Colors.transparent, width: 0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'SECCIÓN DE ${league.shortName.toUpperCase()}',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded,
                    color: Color(0xFF10B981), size: 14),
              ],
            ),
          ),
        ],
      ),
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
                const TextSpan(text: ' v1.5.0'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
