import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pivote/features/home/data/services/search_service.dart';
import 'package:pivote/features/video/presentation/providers/channel_provider.dart';
import 'package:pivote/features/video/presentation/widgets/channel_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<String> _history = const [];
  late final AnimationController _introController;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  static const _categories = <_SearchCategory>[
    _SearchCategory('Deportes', Icons.sports_soccer_rounded),
    _SearchCategory('Noticias', Icons.newspaper_rounded),
    _SearchCategory('Música', Icons.music_note_rounded),
    _SearchCategory('Películas', Icons.movie_rounded),
    _SearchCategory('Infantil', Icons.child_care_rounded),
    _SearchCategory('Radio', Icons.radio_rounded),
  ];

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fade = CurvedAnimation(
      parent: _introController,
      curve: Curves.easeOutCubic,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, .025),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: Curves.easeOutCubic,
      ),
    );

    _loadHistory();
    _introController.forward();
  }

  Future<void> _loadHistory() async {
    final history = await SearchService.getSearchHistory();
    if (!mounted) return;
    setState(() => _history = history);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _introController.dispose();
    super.dispose();
  }

  void _updateQuery(String value) {
    context.read<ChannelProvider>().setSearchQuery(value);
    if (mounted) setState(() {});
  }

  Future<void> _submitQuery(String value) async {
    final query = value.trim();
    if (query.isEmpty) return;

    _searchController.value = TextEditingValue(
      text: query,
      selection: TextSelection.collapsed(offset: query.length),
    );
    context.read<ChannelProvider>().setSearchQuery(query);
    await SearchService.saveSearchQuery(query);
    await _loadHistory();
    _searchFocusNode.unfocus();

    if (mounted) setState(() {});
  }

  void _clearQuery() {
    _searchController.clear();
    context.read<ChannelProvider>().clearFilters();
    if (mounted) setState(() {});
  }

  void _close() {
    context.read<ChannelProvider>().clearFilters();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.watch<ChannelProvider>();
    final searching = _searchController.text.trim().isNotEmpty;

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          context.read<ChannelProvider>().clearFilters();
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: Column(
                children: [
                  _SearchTopBar(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    searching: searching,
                    theme: theme,
                    isDark: isDark,
                    onChanged: _updateQuery,
                    onSubmitted: _submitQuery,
                    onClear: _clearQuery,
                    onClose: _close,
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: searching
                          ? _ResultsView(
                              key: const ValueKey('results'),
                              provider: provider,
                              theme: theme,
                              query: _searchController.text.trim(),
                            )
                          : _DiscoveryView(
                              key: const ValueKey('discovery'),
                              history: _history,
                              theme: theme,
                              isDark: isDark,
                              onSearch: _submitQuery,
                              onClearHistory: () async {
                                await SearchService.clearSearchHistory();
                                await _loadHistory();
                              },
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
}

class _SearchTopBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool searching;
  final ThemeData theme;
  final bool isDark;
  final ValueChanged<String> onChanged;
  final Future<void> Function(String) onSubmitted;
  final VoidCallback onClear;
  final VoidCallback onClose;

  const _SearchTopBar({
    required this.controller,
    required this.focusNode,
    required this.searching,
    required this.theme,
    required this.isDark,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? const Color(0xFF111820) : theme.colorScheme.surface;
    final iconColor = theme.colorScheme.onSurface.withValues(alpha: .52);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onClose,
              child: SizedBox(
                width: 42,
                height: 46,
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 22,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Material(
              color: surface,
              elevation: 0,
              borderRadius: BorderRadius.circular(21),
              shadowColor: Colors.black.withValues(alpha: .08),
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(21),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: .07)
                        : theme.colorScheme.onSurface.withValues(alpha: .055),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? .16 : .035),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onChanged: onChanged,
                  onSubmitted: onSubmitted,
                  textInputAction: TextInputAction.search,
                  cursorColor: theme.colorScheme.primary,
                  cursorWidth: 2,
                  textCapitalization: TextCapitalization.none,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Buscar en Pivote',
                    hintStyle: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: iconColor,
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 5),
                      child: Icon(Icons.search_rounded, size: 20, color: iconColor),
                    ),
                    suffixIcon: searching
                        ? IconButton(
                            onPressed: onClear,
                            splashRadius: 19,
                            icon: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: iconColor,
                            ),
                          )
                        : null,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 4,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscoveryView extends StatelessWidget {
  final List<String> history;
  final ThemeData theme;
  final bool isDark;
  final ValueChanged<String> onSearch;
  final VoidCallback onClearHistory;

  const _DiscoveryView({
    super.key,
    required this.history,
    required this.theme,
    required this.isDark,
    required this.onSearch,
    required this.onClearHistory,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        _DiscoveryHero(theme: theme, isDark: isDark),
        if (history.isNotEmpty) ...[
          const SizedBox(height: 22),
          _SectionHeader(
            title: 'Recientes',
            trailing: 'Limpiar',
            color: theme.colorScheme.error,
            onTap: onClearHistory,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: history.take(8).map((item) {
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onSearch(item),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF111820) : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: theme.colorScheme.onSurface.withValues(alpha: .055),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 15,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          item,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 26),
        _SectionHeader(
          title: 'Explorá por categoría',
          color: theme.colorScheme.onSurface,
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 720 ? 3 : 2;
            final ratio = columns == 3 ? 1.65 : 1.95;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _SearchScreenState._categories.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 11,
                mainAxisSpacing: 11,
                childAspectRatio: ratio,
              ),
              itemBuilder: (context, index) {
                final item = _SearchScreenState._categories[index];
                return _CategoryCard(
                  item: item,
                  theme: theme,
                  isDark: isDark,
                  onTap: () => onSearch(item.label),
                  index: index,
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _DiscoveryHero extends StatelessWidget {
  final ThemeData theme;
  final bool isDark;

  const _DiscoveryHero({required this.theme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final accent = theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF172310), const Color(0xFF101711)]
              : [const Color(0xFFE8FFB8), const Color(0xFFF7FAF0)],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: accent.withValues(alpha: isDark ? .14 : .18)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: isDark ? .08 : .11),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -45,
            top: -55,
            child: Container(
              width: 165,
              height: 165,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: isDark ? .07 : .16),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.travel_explore_rounded, color: accent, size: 22),
              ),
              const SizedBox(height: 14),
              Text(
                'Explorá Pivote',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                  height: 1,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'Encontrá canales y contenido sin vueltas.',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withValues(alpha: .56),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  _HeroPill(
                    icon: Icons.bolt_rounded,
                    label: 'Búsqueda rápida',
                    color: accent,
                  ),
                  const SizedBox(width: 8),
                  _HeroPill(
                    icon: Icons.grid_view_rounded,
                    label: 'Categorías',
                    color: accent,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _HeroPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final _SearchCategory item;
  final ThemeData theme;
  final bool isDark;
  final VoidCallback onTap;
  final int index;

  const _CategoryCard({
    required this.item,
    required this.theme,
    required this.isDark,
    required this.onTap,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final accent = theme.colorScheme.primary;
    return Material(
      color: isDark ? const Color(0xFF111820) : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(21),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(21),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(21),
            border: Border.all(
              color: accent.withValues(alpha: .075),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? .10 : .025),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent.withValues(alpha: .15),
                      accent.withValues(alpha: .06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(item.icon, size: 19, color: accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: theme.hintColor.withValues(alpha: .45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultsView extends StatelessWidget {
  final ChannelProvider provider;
  final ThemeData theme;
  final String query;

  const _ResultsView({
    super.key,
    required this.provider,
    required this.theme,
    required this.query,
  });

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading && !provider.isInitialized) {
      return const _SearchLoadingView();
    }

    final results = provider.channels;

    if (results.isEmpty) {
      return _SearchEmptyView(query: query, theme: theme);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Text(
                'Resultados',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${results.length}',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.swipe_rounded,
                size: 14,
                color: theme.hintColor.withValues(alpha: .45),
              ),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 980
                  ? 4
                  : constraints.maxWidth >= 680
                      ? 3
                      : 2;
              final ratio = columns >= 4 ? .96 : .92;

              return GridView.builder(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                physics: const ClampingScrollPhysics(),
                cacheExtent: 650,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 11,
                  mainAxisSpacing: 11,
                  childAspectRatio: ratio,
                ),
                itemCount: results.length,
                itemBuilder: (context, index) => RepaintBoundary(
                  child: ChannelCard(channel: results[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SearchLoadingView extends StatelessWidget {
  const _SearchLoadingView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.builder(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
      itemCount: 6,
      itemBuilder: (_, index) => Container(
        height: 82,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

class _SearchEmptyView extends StatelessWidget {
  final String query;
  final ThemeData theme;

  const _SearchEmptyView({required this.query, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: .14),
                    theme.colorScheme.primary.withValues(alpha: .045),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 35,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 17),
            Text(
              'Sin resultados',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'No encontramos coincidencias para “$query”. Probá con otro término.',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: theme.hintColor,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;
  final Color color;
  final VoidCallback? onTap;

  const _SectionHeader({
    required this.title,
    required this.color,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: .1,
            ),
          ),
        ),
        if (trailing != null)
          Material(
            color: color.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Text(
                  trailing!,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SearchCategory {
  final String label;
  final IconData icon;

  const _SearchCategory(this.label, this.icon);
}
