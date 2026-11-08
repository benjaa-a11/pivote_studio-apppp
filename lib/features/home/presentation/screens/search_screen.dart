import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/features/home/data/services/search_service.dart';
import 'package:pivote/features/home/presentation/widgets/search_filter_chips.dart';
import 'package:pivote/features/home/presentation/widgets/search_radio_tile.dart';
import 'package:pivote/features/home/presentation/widgets/search_match_tile.dart';
import 'package:pivote/features/profile/presentation/widgets/profile_design_system.dart';
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

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounceTimer;

  SearchFilterTab _selectedTab = SearchFilterTab.all;
  List<String> _searchHistory = [];

  static const List<Map<String, dynamic>> _quickCategories = [
    {
      'name': 'Deportes',
      'subtitle': 'Canales en vivo',
      'icon': Icons.sports_soccer_rounded,
      'type': 'category',
    },
    {
      'name': 'Noticias',
      'subtitle': 'Actualidad 24/7',
      'icon': Icons.newspaper_rounded,
      'type': 'category',
    },
    {
      'name': 'Entretenimiento',
      'subtitle': 'Series y cine',
      'icon': Icons.movie_filter_rounded,
      'type': 'category',
    },
    {
      'name': 'Música',
      'subtitle': 'TV y conciertos',
      'icon': Icons.music_note_rounded,
      'type': 'category',
    },
    {
      'name': 'Radios',
      'subtitle': 'Emisoras FM/AM',
      'icon': Icons.radio_rounded,
      'type': 'tab_radios',
    },
    {
      'name': 'Fútbol Hoy',
      'subtitle': 'Agenda y canales',
      'icon': Icons.stadium_rounded,
      'type': 'tab_soccer',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
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
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 140), () {
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
    await _loadHistory();
  }

  Future<void> _confirmClearAllHistory() async {
    final palette = ProfilePalette.of(context);
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: ProfileGroupCard(
              padding: const EdgeInsets.all(22),
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: palette.dangerBg,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(
                      Icons.delete_sweep_rounded,
                      size: 24,
                      color: palette.danger,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  '¿Borrar búsquedas recientes?',
                  textAlign: TextAlign.center,
                  style: AppFont.primary(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: palette.text,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Se eliminará todo tu historial de búsqueda guardado en este dispositivo.',
                  textAlign: TextAlign.center,
                  style: AppFont.primary(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: palette.muted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Material(
                        color: palette.iconBox,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: InkWell(
                          onTap: () => Navigator.pop(ctx, false),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            child: Center(
                              child: Text(
                                'Cancelar',
                                style: AppFont.primary(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: palette.text,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Material(
                        color: palette.dangerBg,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: InkWell(
                          onTap: () => Navigator.pop(ctx, true),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(
                                color: palette.dangerBorder,
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Borrar todo',
                                style: AppFont.primary(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: palette.danger,
                                ),
                              ),
                            ),
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

    if (confirmed == true && mounted) {
      await SearchService.clearSearchHistory();
      await _loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = ProfilePalette.of(context);
    final channelProvider = context.watch<ChannelProvider>();
    final radioProvider = context.watch<RadioProvider>();
    final soccerProvider = context.watch<SoccerProvider>();

    final query = _searchController.text.trim();
    final isSearching = query.isNotEmpty;

    final filteredChannels =
        _getFilteredChannels(channelProvider.allChannels, query);
    final filteredRadios = _getFilteredRadios(radioProvider.radios, query);
    final filteredMatches =
        _getFilteredMatches(soccerProvider.soccerData, query);

    final totalCount = filteredChannels.length +
        filteredRadios.length +
        filteredMatches.length;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          context.read<ChannelProvider>().searchChannels('');
        }
      },
      child: Scaffold(
        backgroundColor: palette.bg,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                children: [
                  _buildSearchHeader(context, palette, isSearching),
                  if (isSearching) ...[
                    const SizedBox(height: 6),
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
                    const SizedBox(height: 8),
                  ],
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: isSearching
                          ? _buildSearchResults(
                              context: context,
                              palette: palette,
                              query: query,
                              channels: filteredChannels,
                              radios: filteredRadios,
                              matches: filteredMatches,
                              soccerData: soccerProvider.soccerData,
                            )
                          : _buildDiscoveryView(
                              context: context,
                              channelProvider: channelProvider,
                              radioProvider: radioProvider,
                              soccerProvider: soccerProvider,
                              palette: palette,
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
    List<radio_model.Radio> radios,
    String query,
  ) {
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

  Widget _buildSearchHeader(
    BuildContext context,
    ProfilePalette palette,
    bool isSearching,
  ) {
    final hasFocus = _searchFocusNode.hasFocus;
    final hPad = AppResponsive.screenHorizontalPadding(context);

    return Padding(
      padding: hPad.add(const EdgeInsets.only(top: 10, bottom: 8)),
      child: Row(
        children: [
          Material(
            color: palette.card,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                context.read<ChannelProvider>().searchChannels('');
                Navigator.pop(context);
              },
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: palette.border, width: 1),
                ),
                alignment: Alignment.center,
                child: ProfileSvgIcons.svg(
                  ProfileSvgIcons.chevronLeft,
                  size: 18,
                  color: palette.text,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 46,
              decoration: BoxDecoration(
                color: palette.card,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: hasFocus ? palette.accent : palette.border,
                  width: hasFocus ? 1.4 : 1,
                ),
                boxShadow: palette.cardShadow,
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Icon(
                    Icons.search_rounded,
                    size: 19,
                    color: hasFocus ? palette.accent : palette.muted,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: _onQueryChanged,
                      onSubmitted: _executeSearch,
                      textInputAction: TextInputAction.search,
                      cursorColor: palette.accent,
                      style: AppFont.primary(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: palette.text,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: false,
                        hintText: 'Buscar canal, radio o partido...',
                        hintStyle: AppFont.primary(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: palette.muted,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (isSearching)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Material(
                        color: palette.iconBox,
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _clearSearch();
                          },
                          customBorder: const CircleBorder(),
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: palette.muted,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoveryView({
    required BuildContext context,
    required ChannelProvider channelProvider,
    required RadioProvider radioProvider,
    required SoccerProvider soccerProvider,
    required ProfilePalette palette,
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
    final hPad = AppResponsive.screenHorizontalPadding(context);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: hPad.add(const EdgeInsets.only(top: 8, bottom: 36)),
      children: [
        if (_searchHistory.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const ProfileSectionTitle('Búsquedas recientes', first: true),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _confirmClearAllHistory,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Text(
                      'Borrar todo',
                      style: AppFont.primary(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: palette.danger,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _searchHistory.map((item) {
              return Container(
                decoration: BoxDecoration(
                  color: palette.card,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: palette.border, width: 1),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _executeSearch(item),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 7, 8, 7),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.history_rounded,
                            size: 14,
                            color: palette.muted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            item,
                            style: AppFont.primary(
                              fontSize: 12.8,
                              fontWeight: FontWeight.w600,
                              color: palette.text,
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => _removeHistoryItem(item),
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: palette.iconBox,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                size: 12,
                                color: palette.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],
        ProfileSectionTitle(
          'Explorar por categoría',
          first: _searchHistory.isEmpty,
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: AppResponsive.channelColumns(context),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.35,
          ),
          itemCount: _quickCategories.length,
          itemBuilder: (context, index) {
            final cat = _quickCategories[index];
            final IconData icon = cat['icon'] as IconData;
            final String name = cat['name'] as String;
            final String subtitle = cat['subtitle'] as String;
            final String type = cat['type'] as String;

            return Container(
              decoration: BoxDecoration(
                color: palette.card,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: palette.border, width: 1),
                boxShadow: palette.cardShadow,
              ),
              clipBehavior: Clip.antiAlias,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
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
                  splashColor: Colors.transparent,
                  highlightColor: palette.cardPressed,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: palette.iconBox,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Icon(
                            icon,
                            size: 19,
                            color: palette.text,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppFont.primary(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.15,
                                  color: palette.text,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppFont.primary(
                                  fontSize: 11.2,
                                  fontWeight: FontWeight.w500,
                                  color: palette.muted,
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
          },
        ),
        if (liveOrScheduledMatches.isNotEmpty && soccerData != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const ProfileSectionTitle('Partidos de hoy'),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: GestureDetector(
                  onTap: () {
                    _executeSearch('Fútbol');
                    setState(() => _selectedTab = SearchFilterTab.soccer);
                  },
                  child: Text(
                    'Ver todos',
                    style: AppFont.primary(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: palette.muted,
                    ),
                  ),
                ),
              ),
            ],
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: liveOrScheduledMatches.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              return SearchMatchTile(
                match: liveOrScheduledMatches[index],
                soccerData: soccerData,
              );
            },
          ),
        ],
        if (topChannels.isNotEmpty) ...[
          const ProfileSectionTitle('Canales recomendados'),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: AppResponsive.channelGridDelegate(
              context,
              aspectRatio: 1.12,
              spacing: 12,
            ),
            itemCount: topChannels.length,
            itemBuilder: (context, index) {
              return ChannelCard(channel: topChannels[index]);
            },
          ),
        ],
        if (topRadios.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const ProfileSectionTitle('Radios destacadas'),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: GestureDetector(
                  onTap: () {
                    _executeSearch('Radio');
                    setState(() => _selectedTab = SearchFilterTab.radios);
                  },
                  child: Text(
                    'Ver todas',
                    style: AppFont.primary(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: palette.muted,
                    ),
                  ),
                ),
              ),
            ],
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: topRadios.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              return SearchRadioTile(radio: topRadios[index]);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildSearchResults({
    required BuildContext context,
    required ProfilePalette palette,
    required String query,
    required List<Channel> channels,
    required List<radio_model.Radio> radios,
    required List<SoccerMatch> matches,
    required SoccerData? soccerData,
  }) {
    final totalResults = channels.length + radios.length + matches.length;

    if (totalResults == 0) {
      return _buildNoResults(palette, query);
    }

    final hPad = AppResponsive.screenHorizontalPadding(context);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: hPad.add(const EdgeInsets.only(top: 4, bottom: 10)),
            child: Row(
              children: [
                Text(
                  '$totalResults ${totalResults == 1 ? 'resultado' : 'resultados'} para ',
                  style: AppFont.primary(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: palette.muted,
                  ),
                ),
                Flexible(
                  child: Text(
                    '"$query"',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFont.primary(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: palette.text,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_selectedTab == SearchFilterTab.all) ...[
          if (matches.isNotEmpty && soccerData != null) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: hPad.add(const EdgeInsets.only(top: 6, bottom: 8)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const ProfileSectionTitle('Fútbol y partidos', first: true),
                    if (matches.length > 3)
                      GestureDetector(
                        onTap: () => setState(
                          () => _selectedTab = SearchFilterTab.soccer,
                        ),
                        child: Text(
                          'Ver todos (${matches.length})',
                          style: AppFont.primary(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: palette.muted,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: hPad,
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
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
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
          ],
          if (channels.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: hPad.add(const EdgeInsets.only(top: 6, bottom: 8)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const ProfileSectionTitle('Canales de TV', first: true),
                    if (channels.length > 6)
                      GestureDetector(
                        onTap: () => setState(
                          () => _selectedTab = SearchFilterTab.channels,
                        ),
                        child: Text(
                          'Ver todos (${channels.length})',
                          style: AppFont.primary(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: palette.muted,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: hPad,
              sliver: SliverGrid(
                gridDelegate: AppResponsive.channelGridDelegate(
                  context,
                  aspectRatio: 1.12,
                  spacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => ChannelCard(channel: channels[index]),
                  childCount: channels.length > 6 ? 6 : channels.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
          if (radios.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: hPad.add(const EdgeInsets.only(top: 6, bottom: 8)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const ProfileSectionTitle('Radios emisoras', first: true),
                    if (radios.length > 4)
                      GestureDetector(
                        onTap: () => setState(
                          () => _selectedTab = SearchFilterTab.radios,
                        ),
                        child: Text(
                          'Ver todas (${radios.length})',
                          style: AppFont.primary(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: palette.muted,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: hPad,
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SearchRadioTile(radio: radios[index]),
                    );
                  },
                  childCount: radios.length > 4 ? 4 : radios.length,
                ),
              ),
            ),
          ],
        ] else if (_selectedTab == SearchFilterTab.channels) ...[
          if (channels.isEmpty)
            _buildSectionEmptyState(
              palette,
              'Sin canales encontrados',
              'No hay canales de TV que coincidan con "$query".',
            )
          else
            SliverPadding(
              padding: hPad.add(const EdgeInsets.only(top: 4, bottom: 24)),
              sliver: SliverGrid(
                gridDelegate: AppResponsive.channelGridDelegate(
                  context,
                  aspectRatio: 1.12,
                  spacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => ChannelCard(channel: channels[index]),
                  childCount: channels.length,
                ),
              ),
            ),
        ] else if (_selectedTab == SearchFilterTab.radios) ...[
          if (radios.isEmpty)
            _buildSectionEmptyState(
              palette,
              'Sin radios encontradas',
              'No hay emisoras de radio que coincidan con "$query".',
            )
          else
            SliverPadding(
              padding: hPad.add(const EdgeInsets.only(top: 4, bottom: 24)),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SearchRadioTile(radio: radios[index]),
                    );
                  },
                  childCount: radios.length,
                ),
              ),
            ),
        ] else if (_selectedTab == SearchFilterTab.soccer) ...[
          if (matches.isEmpty || soccerData == null)
            _buildSectionEmptyState(
              palette,
              'Sin partidos encontrados',
              'No hay partidos o equipos que coincidan con "$query".',
            )
          else
            SliverPadding(
              padding: hPad.add(const EdgeInsets.only(top: 4, bottom: 24)),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
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
    ProfilePalette palette,
    String title,
    String subtitle,
  ) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ProfileGroupCard(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: palette.iconBox,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  size: 26,
                  color: palette.muted,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppFont.primary(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: palette.text,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: AppFont.primary(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: palette.muted,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoResults(ProfilePalette palette, String query) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ProfileGroupCard(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: palette.iconBox,
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 30,
                color: palette.muted,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Sin resultados para "$query"',
              textAlign: TextAlign.center,
              style: AppFont.primary(
                fontSize: 17.5,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.25,
                color: palette.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Prueba con otra palabra clave o explora las categorías sugeridas.',
              textAlign: TextAlign.center,
              style: AppFont.primary(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: palette.muted,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            Material(
              color: palette.primaryBtnBg,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: InkWell(
                onTap: _clearSearch,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 11,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.refresh_rounded,
                        size: 17,
                        color: palette.primaryBtnText,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        'Limpiar búsqueda',
                        style: AppFont.primary(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: palette.primaryBtnText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
