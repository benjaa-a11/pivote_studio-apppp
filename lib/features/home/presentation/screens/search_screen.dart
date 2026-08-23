import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/features/home/data/services/search_service.dart';
import 'package:pivote/features/home/presentation/widgets/search_filter_chips.dart';
import 'package:pivote/features/home/presentation/widgets/search_radio_tile.dart';
import 'package:pivote/features/home/presentation/widgets/search_match_tile.dart';
import 'package:pivote/features/video/presentation/providers/channel_provider.dart';
import 'package:pivote/features/video/presentation/widgets/channel_card.dart';
import 'package:pivote/features/video/data/models/channel.dart';
import 'package:pivote/features/radio/presentation/providers/radio_provider.dart';
import 'package:pivote/features/radio/data/models/radio.dart' as radio_model;
import 'package:pivote/features/soccer/presentation/providers/soccer_provider.dart';
import 'package:pivote/features/soccer/data/models/soccer_models.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounceTimer;

  SearchFilterTab _selectedTab = SearchFilterTab.all;
  List<String> _searchHistory = [];

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  // Quick categories metadata with 2026 vibrance
  static final List<Map<String, dynamic>> _quickCategories = [
    {
      'name': 'Deportes',
      'icon': Icons.sports_soccer_rounded,
      'colors': const [Color(0xFF10B981), Color(0xFF059669)],
      'type': 'category',
    },
    {
      'name': 'Noticias',
      'icon': Icons.newspaper_rounded,
      'colors': const [Color(0xFF3B82F6), Color(0xFF2563EB)],
      'type': 'category',
    },
    {
      'name': 'Música',
      'icon': Icons.music_note_rounded,
      'colors': const [Color(0xFFA855F7), Color(0xFF9333EA)],
      'type': 'category',
    },
    {
      'name': 'Infantil',
      'icon': Icons.child_care_rounded,
      'colors': const [Color(0xFFEC4899), Color(0xFFDB2777)],
      'type': 'category',
    },
    {
      'name': 'Radios',
      'icon': Icons.radio_rounded,
      'colors': const [Color(0xFF6366F1), Color(0xFF4F46E5)],
      'type': 'tab_radios',
    },
    {
      'name': 'Fútbol Hoy',
      'icon': Icons.stadium_rounded,
      'colors': const [Color(0xFFEF4444), Color(0xFFDC2626)],
      'type': 'tab_soccer',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();

    _animController = AnimationController(
      vsync: this,
      duration: AppAnimations.normal,
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.02),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _animController.forward();

    _searchFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadHistory() async {
    final history = await SearchService.getSearchHistory();
    if (mounted) {
      setState(() {
        _searchHistory = history;
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _executeSearch(String query) {
    _searchController.text = query;
    _onQueryChanged(query);
    if (query.trim().isNotEmpty) {
      SearchService.saveSearchQuery(query.trim()).then((_) => _loadHistory());
    }
    _searchFocusNode.unfocus();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _selectedTab = SearchFilterTab.all;
    });
    context.read<ChannelProvider>().clearFilters();
  }

  Future<void> _removeHistoryItem(String item) async {
    await SearchService.removeSearchQuery(item);
    _loadHistory();
  }

  void _confirmClearAllHistory() {
    final theme = Theme.of(context);
    final isDark = theme.isDark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkBg2 : theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Icon(
                  Icons.delete_sweep_rounded,
                  size: 40,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 12),
                Text(
                  '¿Borrar todo el historial?',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Se eliminarán todas tus búsquedas recientes guardadas en este dispositivo.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Cancelar',
                          style: GoogleFonts.spaceGrotesk(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await SearchService.clearSearchHistory();
                          _loadHistory();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Borrar',
                          style: GoogleFonts.spaceGrotesk(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.isDark;
    final channelProvider = context.watch<ChannelProvider>();
    final radioProvider = context.watch<RadioProvider>();
    final soccerProvider = context.watch<SoccerProvider>();

    final query = _searchController.text.trim();
    final isSearching = query.isNotEmpty;

    // Filtered data
    final filteredChannels =
        _getFilteredChannels(channelProvider.allChannels, query);
    final filteredRadios = _getFilteredRadios(radioProvider.radios, query);
    final filteredMatches =
        _getFilteredMatches(soccerProvider.soccerData, query);

    final totalCount =
        filteredChannels.length + filteredRadios.length + filteredMatches.length;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          context.read<ChannelProvider>().searchChannels('');
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Column(
                children: [
                  // ─── Modern Sticky Header ───
                  _buildSearchHeader(context, theme, isDark, isSearching),

                  // ─── Dynamic Filter Chips (when searching) ───
                  if (isSearching) ...[
                    const SizedBox(height: 10),
                    SearchFilterChips(
                      selectedTab: _selectedTab,
                      totalCount: totalCount,
                      channelsCount: filteredChannels.length,
                      radiosCount: filteredRadios.length,
                      soccerCount: filteredMatches.length,
                      onTabSelected: (tab) {
                        setState(() {
                          _selectedTab = tab;
                        });
                      },
                    ),
                    const SizedBox(height: 6),
                  ],

                  // ─── Body Content ───
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                      child: isSearching
                          ? _buildSearchResults(
                              context: context,
                              theme: theme,
                              isDark: isDark,
                              query: query,
                              channels: filteredChannels,
                              radios: filteredRadios,
                              matches: filteredMatches,
                              soccerData: soccerProvider.soccerData,
                            )
                          : _buildDiscoveryView(
                              channelProvider: channelProvider,
                              radioProvider: radioProvider,
                              soccerProvider: soccerProvider,
                              theme: theme,
                              isDark: isDark,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Filters & Search Logic ───

  List<Channel> _getFilteredChannels(List<Channel> channels, String query) {
    if (query.isEmpty) return channels;
    final q = query.toLowerCase();
    return channels.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.category.toLowerCase().contains(q) ||
          c.description.toLowerCase().contains(q);
    }).toList();
  }

  List<radio_model.Radio> _getFilteredRadios(
      List<radio_model.Radio> radios, String query) {
    if (query.isEmpty) return radios;
    final q = query.toLowerCase();
    return radios.where((r) {
      return r.name.toLowerCase().contains(q) ||
          (r.category ?? '').toLowerCase().contains(q) ||
          r.frequency.toLowerCase().contains(q);
    }).toList();
  }

  List<SoccerMatch> _getFilteredMatches(SoccerData? soccerData, String query) {
    if (soccerData == null || query.isEmpty) return [];
    final q = query.toLowerCase();
    return soccerData.matches.where((m) {
      final homeName = m.homeTeam.toLowerCase();
      final awayName = m.awayTeam.toLowerCase();
      final leagueName = soccerData.leagues
          .firstWhere(
            (l) => l.id == m.leagueId,
            orElse: () =>
                SoccerLeague(id: '', name: '', country: '', shortName: ''),
          )
          .name
          .toLowerCase();
      final channelNames =
          m.tvChannels.map((c) => c.name.toLowerCase()).join(' ');

      return homeName.contains(q) ||
          awayName.contains(q) ||
          leagueName.contains(q) ||
          channelNames.contains(q);
    }).toList();
  }

  // ─── Search Header ───

  Widget _buildSearchHeader(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    bool isSearching,
  ) {
    final hasFocus = _searchFocusNode.hasFocus;
    final fieldRadius = BorderRadius.circular(AppRadius.md + 2);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Back button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                context.read<ChannelProvider>().searchChannels('');
                Navigator.pop(context);
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.darkBg2
                      : theme.colorScheme.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : theme.colorScheme.primary.withValues(alpha: 0.12),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.arrow_back_rounded,
                    size: 20,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Search field
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              height: 52,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkBg2 : theme.colorScheme.surface,
                borderRadius: fieldRadius,
                border: Border.all(
                  color: hasFocus
                      ? theme.colorScheme.primary
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.08)),
                  width: hasFocus ? 1.6 : 1,
                ),
                boxShadow: hasFocus
                    ? AppShadows.glow(theme.colorScheme.primary, alpha: 0.18)
                    : [],
              ),
              child: ClipRRect(
                borderRadius: fieldRadius,
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: _onQueryChanged,
                  onSubmitted: _executeSearch,
                  textInputAction: TextInputAction.search,
                  cursorColor: theme.colorScheme.primary,
                  cursorWidth: 2.2,
                  cursorRadius: const Radius.circular(2),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: false,
                    hintText: 'Buscar canal, radio o partido...',
                    hintStyle: GoogleFonts.spaceGrotesk(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: hasFocus
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    prefixIconConstraints:
                        const BoxConstraints(minWidth: 44, minHeight: 44),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Material(
                              color: Colors.transparent,
                              shape: const CircleBorder(),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: _clearSearch,
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                            ),
                          )
                        : null,
                    suffixIconConstraints:
                        const BoxConstraints(minWidth: 40, minHeight: 40),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Discovery View (When search is empty) ───

  Widget _buildDiscoveryView({
    required ChannelProvider channelProvider,
    required RadioProvider radioProvider,
    required SoccerProvider soccerProvider,
    required ThemeData theme,
    required bool isDark,
  }) {
    final soccerData = soccerProvider.soccerData;
    final liveOrScheduledMatches = soccerData != null
        ? soccerData.matches
            .where((m) =>
                (m.isLive || m.isScheduled) &&
                !m.shouldRemoveFromHero &&
                !m.isAutoFinished)
            .take(4)
            .toList()
        : <SoccerMatch>[];

    final topChannels = channelProvider.allChannels.take(6).toList();
    final topRadios = radioProvider.radios.take(4).toList();

    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // ─── Recent Searches Section ───
        if (_searchHistory.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Búsquedas recientes',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: _confirmClearAllHistory,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Text(
                      'Borrar todo',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _searchHistory.map((h) {
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _executeSearch(h),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.darkBg2
                          : theme.colorScheme.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          h,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => _removeHistoryItem(h),
                          child: Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],

        // ─── Quick Categories ───
        Row(
          children: [
            Icon(
              Icons.grid_view_rounded,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              'Explorar por Categoría',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.15,
          ),
          itemCount: _quickCategories.length,
          itemBuilder: (context, index) {
            final cat = _quickCategories[index];
            final List<Color> colors = cat['colors'] as List<Color>;
            final IconData icon = cat['icon'] as IconData;
            final String name = cat['name'] as String;
            final String type = cat['type'] as String;

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (type == 'tab_radios') {
                    _executeSearch('Radio');
                    setState(() => _selectedTab = SearchFilterTab.radios);
                  } else if (type == 'tab_soccer') {
                    _executeSearch('Fútbol');
                    setState(() => _selectedTab = SearchFilterTab.soccer);
                  } else {
                    _executeSearch(name);
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.darkBg2
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              colors[0].withValues(alpha: 0.22),
                              colors[1].withValues(alpha: 0.10),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, size: 18, color: colors[0]),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        name,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 26),

        // ─── Live / Featured Matches (if available) ───
        if (liveOrScheduledMatches.isNotEmpty && soccerData != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.sports_soccer_rounded,
                    size: 16,
                    color: Color(0xFFEF4444),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Partidos de Hoy',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  _executeSearch('Fútbol');
                  setState(() => _selectedTab = SearchFilterTab.soccer);
                },
                child: Text(
                  'Ver todos',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppTheme.darkAccent
                        : theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: liveOrScheduledMatches.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              return SearchMatchTile(
                match: liveOrScheduledMatches[index],
                soccerData: soccerData,
              );
            },
          ),
          const SizedBox(height: 26),
        ],

        // ─── Recommended TV Channels ───
        if (topChannels.isNotEmpty) ...[
          Row(
            children: [
              Icon(
                Icons.live_tv_rounded,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Canales recomendados',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.05,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: topChannels.length,
            itemBuilder: (context, index) {
              return ChannelCard(channel: topChannels[index]);
            },
          ),
          const SizedBox(height: 26),
        ],

        // ─── Featured Radios ───
        if (topRadios.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.radio_rounded,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Radios destacadas',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  _executeSearch('Radio');
                  setState(() => _selectedTab = SearchFilterTab.radios);
                },
                child: Text(
                  'Ver todas',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppTheme.darkAccent
                        : theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: topRadios.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              return SearchRadioTile(radio: topRadios[index]);
            },
          ),
        ],
      ],
    );
  }

  // ─── Search Results View ───

  Widget _buildSearchResults({
    required BuildContext context,
    required ThemeData theme,
    required bool isDark,
    required String query,
    required List<Channel> channels,
    required List<radio_model.Radio> radios,
    required List<SoccerMatch> matches,
    required SoccerData? soccerData,
  }) {
    final totalResults = channels.length + radios.length + matches.length;

    if (totalResults == 0) {
      return _buildNoResults(theme, isDark, query);
    }

    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        // Results Count Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Row(
              children: [
                Icon(
                  Icons.filter_list_rounded,
                  size: 15,
                  color:
                      isDark ? AppTheme.darkAccent : theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  '$totalResults ${totalResults == 1 ? 'resultado' : 'resultados'} para ',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                Flexible(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.darkAccent.withValues(alpha: 0.12)
                          : theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '"$query"',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppTheme.darkAccent
                            : theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Tab: ALL (Todos)
        if (_selectedTab == SearchFilterTab.all) ...[
          // Soccer Matches Section in All
          if (matches.isNotEmpty && soccerData != null) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Fútbol & Partidos (${matches.length})',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (matches.length > 2)
                      GestureDetector(
                        onTap: () => setState(
                            () => _selectedTab = SearchFilterTab.soccer),
                        child: Text(
                          'Ver todos',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppTheme.darkAccent
                                : theme.colorScheme.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SearchMatchTile(
                        match: matches[index],
                        soccerData: soccerData,
                      ),
                    );
                  },
                  childCount: matches.length > 3 ? 3 : matches.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
          ],

          // TV Channels Section in All
          if (channels.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Canales de TV (${channels.length})',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (channels.length > 4)
                      GestureDetector(
                        onTap: () => setState(
                            () => _selectedTab = SearchFilterTab.channels),
                        child: Text(
                          'Ver todos',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppTheme.darkAccent
                                : theme.colorScheme.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.05,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => ChannelCard(channel: channels[index]),
                  childCount: channels.length > 6 ? 6 : channels.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 18)),
          ],

          // Radios Section in All
          if (radios.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Radios Emisoras (${radios.length})',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (radios.length > 3)
                      GestureDetector(
                        onTap: () => setState(
                            () => _selectedTab = SearchFilterTab.radios),
                        child: Text(
                          'Ver todas',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppTheme.darkAccent
                                : theme.colorScheme.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SearchRadioTile(radio: radios[index]),
                    );
                  },
                  childCount: radios.length > 4 ? 4 : radios.length,
                ),
              ),
            ),
          ],
        ]

        // Tab: ONLY CHANNELS
        else if (_selectedTab == SearchFilterTab.channels) ...[
          if (channels.isEmpty)
            _buildSectionEmptyState(
              theme,
              'Sin canales encontrados',
              'No hay canales de TV que coincidan con "$query".',
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.05,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => ChannelCard(channel: channels[index]),
                  childCount: channels.length,
                ),
              ),
            ),
        ]

        // Tab: ONLY RADIOS
        else if (_selectedTab == SearchFilterTab.radios) ...[
          if (radios.isEmpty)
            _buildSectionEmptyState(
              theme,
              'Sin radios encontradas',
              'No hay emisoras de radio que coincidan con "$query".',
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SearchRadioTile(radio: radios[index]),
                    );
                  },
                  childCount: radios.length,
                ),
              ),
            ),
        ]

        // Tab: ONLY SOCCER
        else if (_selectedTab == SearchFilterTab.soccer) ...[
          if (matches.isEmpty || soccerData == null)
            _buildSectionEmptyState(
              theme,
              'Sin partidos encontrados',
              'No hay partidos o equipos que coincidan con "$query".',
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SearchMatchTile(
                        match: matches[index],
                        soccerData: soccerData,
                      ),
                    );
                  },
                  childCount: matches.length,
                ),
              ),
            ),
        ],

        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  Widget _buildSectionEmptyState(
      ThemeData theme, String title, String subtitle) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 40,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoResults(ThemeData theme, bool isDark, String query) {
    return Center(
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 38,
                color:
                    isDark ? AppTheme.darkAccent : theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Sin resultados',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No encontramos nada para "$query".\nPrueba con otra palabra o explora por categoría.',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _clearSearch,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Limpiar búsqueda'),
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
}
