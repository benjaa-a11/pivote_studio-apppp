import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/features/home/data/services/search_service.dart';
import 'package:pivote/features/home/presentation/widgets/search_filter_chips.dart';
import 'package:pivote/features/home/presentation/widgets/search_match_tile.dart';
import 'package:pivote/features/home/presentation/widgets/search_radio_tile.dart';
import 'package:pivote/features/radio/data/models/radio.dart' as radio_model;
import 'package:pivote/features/radio/presentation/providers/radio_provider.dart';
import 'package:pivote/features/soccer/data/models/soccer_models.dart';
import 'package:pivote/features/soccer/presentation/providers/soccer_provider.dart';
import 'package:pivote/features/video/data/models/channel.dart';
import 'package:pivote/features/video/presentation/providers/channel_provider.dart';
import 'package:pivote/features/video/presentation/widgets/channel_card.dart';
import 'package:pivote/shared/widgets/app_notifications.dart';
import 'package:pivote/shared/widgets/common/app_dialogs.dart';
import 'package:pivote/shared/widgets/common/app_state_views.dart';
import 'package:pivote/shared/widgets/common/apple_pressable.dart';
import 'package:pivote/shared/widgets/common/loading_shimmer.dart';
import 'package:pivote/shared/widgets/common/pivote_surfaces.dart';

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

  static const List<({String name, String subtitle, IconData icon, String type})>
      _quickCategories = [
    (
      name: 'Deportes',
      subtitle: 'Canales en vivo',
      icon: Icons.sports_soccer_rounded,
      type: 'category',
    ),
    (
      name: 'Noticias',
      subtitle: 'Actualidad 24/7',
      icon: Icons.newspaper_rounded,
      type: 'category',
    ),
    (
      name: 'Entretenimiento',
      subtitle: 'Series y cine',
      icon: Icons.movie_filter_rounded,
      type: 'category',
    ),
    (
      name: 'Música',
      subtitle: 'TV y conciertos',
      icon: Icons.music_note_rounded,
      type: 'category',
    ),
    (
      name: 'Radios',
      subtitle: 'Emisoras FM / AM',
      icon: Icons.radio_rounded,
      type: 'tab_radios',
    ),
    (
      name: 'Fútbol Hoy',
      subtitle: 'Agenda y señales',
      icon: Icons.stadium_rounded,
      type: 'tab_soccer',
    ),
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
      setState(() => _searchHistory = history);
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
    _debounceTimer = Timer(const Duration(milliseconds: 120), () {
      if (mounted) setState(() {});
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
    setState(() => _selectedTab = SearchFilterTab.all);
    context.read<ChannelProvider>().clearFilters();
  }

  Future<void> _removeHistoryItem(String item) async {
    await SearchService.removeSearchQuery(item);
    await _loadHistory();
  }

  Future<void> _confirmClearAllHistory() async {
    final confirmed = await AppDialogs.showConfirm(
      context: context,
      title: '¿Borrar búsquedas recientes?',
      message:
          'Se eliminará todo tu historial de búsqueda guardado en este dispositivo.',
      confirmLabel: 'Borrar todo',
      cancelLabel: 'Cancelar',
      isDestructive: true,
      type: AppDialogType.warning,
    );

    if (confirmed == true && mounted) {
      await SearchService.clearSearchHistory();
      await _loadHistory();
      if (mounted) {
        AppNotifications.showInfo(context, 'Historial de búsqueda borrado');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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

    final totalCount =
        filteredChannels.length + filteredRadios.length + filteredMatches.length;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          context.read<ChannelProvider>().searchChannels('');
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.bg(context),
        body: PivoteAmbientBackdrop(
          child: SafeArea(
            bottom: false,
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              behavior: HitTestBehavior.translucent,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: Column(
                    children: [
                      _buildSearchHeader(context, isSearching),
                      if (isSearching) ...[
                        const SizedBox(height: 6),
                        SearchFilterChips(
                          selectedTab: _selectedTab,
                          totalCount: totalCount,
                          channelsCount: filteredChannels.length,
                          radiosCount: filteredRadios.length,
                          soccerCount: filteredMatches.length,
                          onTabSelected: (tab) =>
                              setState(() => _selectedTab = tab),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: isSearching
                              ? _buildSearchResults(
                                  context: context,
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
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
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

  Widget _buildSearchHeader(BuildContext context, bool isSearching) {
    final hasFocus = _searchFocusNode.hasFocus;
    final hPad = AppResponsive.screenHorizontalPadding(context);
    final accent = AppTheme.accent(context);

    return Padding(
      padding: hPad.add(const EdgeInsets.only(top: 10, bottom: 8)),
      child: Row(
        children: [
          PivoteIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            iconSize: 17,
            onTap: () {
              context.read<ChannelProvider>().searchChannels('');
              Navigator.pop(context);
            },
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AnimatedContainer(
              duration: AppMotion.fast,
              height: 46,
              decoration: BoxDecoration(
                color: AppTheme.surface1(context),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: hasFocus ? accent : AppTheme.border(context),
                  width: hasFocus ? 1.4 : 1.0,
                ),
                boxShadow: hasFocus
                    ? AppShadows.glow(accent, alpha: 0.18)
                    : AppShadows.card(context),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Hero(
                    tag: 'search_icon',
                    child: Icon(
                      Icons.search_rounded,
                      size: 19,
                      color: hasFocus ? accent : AppTheme.textTertiary(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: _onQueryChanged,
                      onSubmitted: _executeSearch,
                      textInputAction: TextInputAction.search,
                      cursorColor: accent,
                      style: AppFont.primary(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary(context),
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: false,
                        hintText: 'Buscar canal, radio o partido...',
                        hintStyle: AppFont.primary(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textTertiary(context),
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
                      padding: const EdgeInsets.only(right: 8),
                      child: ApplePressable(
                        scaleDownFactor: 0.90,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        onTap: _clearSearch,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppTheme.surface2(context),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.border(context)),
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 15,
                            color: AppTheme.textSecondary(context),
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
  }) {
    final soccerData = soccerProvider.soccerData;
    final liveOrScheduledMatches = soccerData != null
        ? soccerData.matches
            .where((m) =>
                (m.isLive || m.isScheduled) &&
                !m.shouldRemoveFromHero &&
                !m.isAutoFinished)
            .take(3)
            .toList()
        : <SoccerMatch>[];

    final topChannels = channelProvider.allChannels.take(6).toList();
    final topRadios = radioProvider.radios.take(4).toList();
    final hPad = AppResponsive.screenHorizontalPadding(context);
    final accent = AppTheme.accent(context);
    final danger = AppTheme.danger(context);

    return CustomScrollView(
      key: const ValueKey('discovery'),
      physics: const ClampingScrollPhysics(),
      slivers: [
        if (_searchHistory.isNotEmpty)
          SliverPadding(
            padding: hPad.add(const EdgeInsets.only(top: 10)),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PivoteSectionHeader(
                    title: 'Búsquedas recientes',
                    trailing: GestureDetector(
                      onTap: _confirmClearAllHistory,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.dangerDim(context),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: danger.withValues(alpha: 0.30),
                          ),
                        ),
                        child: Text(
                          'Limpiar',
                          style: AppFont.primary(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: danger,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _searchHistory.map((item) {
                      return Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surface1(context),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(color: AppTheme.border(context)),
                        ),
                        child: InkWell(
                          onTap: () => _executeSearch(item),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(11, 7, 7, 7),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.history_rounded,
                                  size: 14,
                                  color: AppTheme.textTertiary(context),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  item,
                                  style: AppFont.primary(
                                    fontSize: 12.8,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary(context),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () => _removeHistoryItem(item),
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: AppTheme.surface2(context),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close_rounded,
                                      size: 12,
                                      color: AppTheme.textTertiary(context),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),

        // Explorar por categoría (Tarjetas difuminadas estilo MatchesHero)
        SliverPadding(
          padding: hPad.add(
            EdgeInsets.only(top: _searchHistory.isEmpty ? 10 : 0, bottom: 12),
          ),
          sliver: const SliverToBoxAdapter(
            child: PivoteSectionHeader(title: 'Explorar categorías'),
          ),
        ),
        SliverPadding(
          padding: hPad,
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: AppResponsive.channelColumns(context),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.25,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final cat = _quickCategories[index];
                final isHighlight = cat.type == 'tab_soccer';
                final glow = isHighlight ? danger : accent;

                return PivoteDiffusedCard(
                  borderRadius: AppRadius.card,
                  glowColor: glow,
                  glowAlignment: const Alignment(-0.85, -0.65),
                  glowOpacity: 0.95,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    if (cat.type == 'tab_radios') {
                      _executeSearch('Radio');
                      setState(() => _selectedTab = SearchFilterTab.radios);
                    } else if (cat.type == 'tab_soccer') {
                      _executeSearch('Fútbol');
                      setState(() => _selectedTab = SearchFilterTab.soccer);
                    } else {
                      _executeSearch(cat.name);
                    }
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isHighlight
                              ? AppTheme.dangerDim(context)
                              : AppTheme.accentDim(context),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(
                            color: glow.withValues(alpha: 0.28),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Icon(cat.icon, size: 19, color: glow),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cat.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppFont.primary(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                                color: AppTheme.textPrimary(context),
                              ),
                            ),
                            const SizedBox(height: 1.5),
                            Text(
                              cat.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppFont.primary(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textTertiary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
              childCount: _quickCategories.length,
            ),
          ),
        ),

        // Partidos de hoy
        if (liveOrScheduledMatches.isNotEmpty && soccerData != null) ...[
          SliverPadding(
            padding: hPad.add(const EdgeInsets.only(top: 22, bottom: 12)),
            sliver: SliverToBoxAdapter(
              child: PivoteSectionHeader(
                title: 'Partidos de hoy',
                badgeText: '${liveOrScheduledMatches.length}',
                isLive: liveOrScheduledMatches.any((m) => m.isLive),
                actionLabel: 'Ver todos',
                onActionTap: () {
                  _executeSearch('Fútbol');
                  setState(() => _selectedTab = SearchFilterTab.soccer);
                },
              ),
            ),
          ),
          SliverPadding(
            padding: hPad,
            sliver: SliverList.separated(
              itemCount: liveOrScheduledMatches.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) => SearchMatchTile(
                match: liveOrScheduledMatches[index],
                soccerData: soccerData,
              ),
            ),
          ),
        ],

        // Canales recomendados (con skeleton shimmer si está cargando)
        if (channelProvider.isLoading) ...[
          SliverPadding(
            padding: hPad.add(const EdgeInsets.only(top: 22, bottom: 12)),
            sliver: const SliverToBoxAdapter(
              child: PivoteSectionHeader(title: 'Canales recomendados'),
            ),
          ),
          SliverPadding(
            padding: hPad,
            sliver: const PivoteChannelGridSkeleton(itemCount: 4),
          ),
        ] else if (topChannels.isNotEmpty) ...[
          SliverPadding(
            padding: hPad.add(const EdgeInsets.only(top: 22, bottom: 12)),
            sliver: SliverToBoxAdapter(
              child: PivoteSectionHeader(
                title: 'Canales recomendados',
                badgeText: '${topChannels.length}',
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
                (context, index) => ChannelCard(channel: topChannels[index]),
                childCount: topChannels.length,
              ),
            ),
          ),
        ],

        // Radios destacadas
        if (topRadios.isNotEmpty) ...[
          SliverPadding(
            padding: hPad.add(const EdgeInsets.only(top: 22, bottom: 12)),
            sliver: SliverToBoxAdapter(
              child: PivoteSectionHeader(
                title: 'Radios destacadas',
                badgeText: '${topRadios.length}',
                actionLabel: 'Ver todas',
                onActionTap: () {
                  _executeSearch('Radio');
                  setState(() => _selectedTab = SearchFilterTab.radios);
                },
              ),
            ),
          ),
          SliverPadding(
            padding: hPad,
            sliver: SliverList.separated(
              itemCount: topRadios.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) =>
                  SearchRadioTile(radio: topRadios[index]),
            ),
          ),
        ],

        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  Widget _buildSearchResults({
    required BuildContext context,
    required String query,
    required List<Channel> channels,
    required List<radio_model.Radio> radios,
    required List<SoccerMatch> matches,
    required SoccerData? soccerData,
  }) {
    final totalResults = channels.length + radios.length + matches.length;
    if (totalResults == 0) {
      return AppStateView.empty(
        key: const ValueKey('no_results'),
        icon: Icons.search_off_rounded,
        title: 'Sin resultados para "$query"',
        subtitle:
            'Probá con otra palabra clave o explorá las categorías disponibles.',
        actionLabel: 'Limpiar búsqueda',
        actionIcon: Icons.refresh_rounded,
        onAction: _clearSearch,
      );
    }

    final hPad = AppResponsive.screenHorizontalPadding(context);

    return CustomScrollView(
      key: ValueKey('results_${_selectedTab.name}_$totalResults'),
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: hPad.add(const EdgeInsets.only(top: 4, bottom: 12)),
            child: Row(
              children: [
                Text(
                  '$totalResults ${totalResults == 1 ? 'resultado' : 'resultados'} para ',
                  style: AppFont.primary(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textTertiary(context),
                  ),
                ),
                Flexible(
                  child: Text(
                    '"$query"',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFont.primary(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_selectedTab == SearchFilterTab.all) ...[
          if (matches.isNotEmpty && soccerData != null) ...[
            SliverPadding(
              padding: hPad.add(const EdgeInsets.only(bottom: 10)),
              sliver: SliverToBoxAdapter(
                child: PivoteSectionHeader(
                  title: 'Fútbol y partidos',
                  badgeText: '${matches.length}',
                  actionLabel: matches.length > 3 ? 'Ver todos' : null,
                  onActionTap: matches.length > 3
                      ? () =>
                          setState(() => _selectedTab = SearchFilterTab.soccer)
                      : null,
                ),
              ),
            ),
            SliverPadding(
              padding: hPad,
              sliver: SliverList.separated(
                itemCount: matches.length > 3 ? 3 : matches.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) => SearchMatchTile(
                  match: matches[index],
                  soccerData: soccerData,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 18)),
          ],
          if (channels.isNotEmpty) ...[
            SliverPadding(
              padding: hPad.add(const EdgeInsets.only(bottom: 10)),
              sliver: SliverToBoxAdapter(
                child: PivoteSectionHeader(
                  title: 'Canales de TV',
                  badgeText: '${channels.length}',
                  actionLabel: channels.length > 6 ? 'Ver todos' : null,
                  onActionTap: channels.length > 6
                      ? () => setState(
                            () => _selectedTab = SearchFilterTab.channels,
                          )
                      : null,
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
            const SliverToBoxAdapter(child: SizedBox(height: 18)),
          ],
          if (radios.isNotEmpty) ...[
            SliverPadding(
              padding: hPad.add(const EdgeInsets.only(bottom: 10)),
              sliver: SliverToBoxAdapter(
                child: PivoteSectionHeader(
                  title: 'Radios emisoras',
                  badgeText: '${radios.length}',
                  actionLabel: radios.length > 4 ? 'Ver todas' : null,
                  onActionTap: radios.length > 4
                      ? () =>
                          setState(() => _selectedTab = SearchFilterTab.radios)
                      : null,
                ),
              ),
            ),
            SliverPadding(
              padding: hPad,
              sliver: SliverList.separated(
                itemCount: radios.length > 4 ? 4 : radios.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) =>
                    SearchRadioTile(radio: radios[index]),
              ),
            ),
          ],
        ] else if (_selectedTab == SearchFilterTab.channels) ...[
          if (channels.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: AppStateView.empty(
                icon: Icons.tv_off_rounded,
                title: 'Sin canales encontrados',
                subtitle: 'No hay canales de TV que coincidan con "$query".',
                compact: true,
              ),
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
            SliverFillRemaining(
              hasScrollBody: false,
              child: AppStateView.empty(
                icon: Icons.radio_rounded,
                title: 'Sin radios encontradas',
                subtitle: 'No hay emisoras que coincidan con "$query".',
                compact: true,
              ),
            )
          else
            SliverPadding(
              padding: hPad.add(const EdgeInsets.only(top: 4, bottom: 24)),
              sliver: SliverList.separated(
                itemCount: radios.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) =>
                    SearchRadioTile(radio: radios[index]),
              ),
            ),
        ] else if (_selectedTab == SearchFilterTab.soccer) ...[
          if (matches.isEmpty || soccerData == null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: AppStateView.empty(
                icon: Icons.sports_soccer_rounded,
                title: 'Sin partidos encontrados',
                subtitle: 'No hay partidos ni equipos que coincidan con "$query".',
                compact: true,
              ),
            )
          else
            SliverPadding(
              padding: hPad.add(const EdgeInsets.only(top: 4, bottom: 24)),
              sliver: SliverList.separated(
                itemCount: matches.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) => SearchMatchTile(
                  match: matches[index],
                  soccerData: soccerData,
                ),
              ),
            ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 36)),
      ],
    );
  }
}
