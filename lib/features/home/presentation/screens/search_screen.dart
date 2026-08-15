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
      duration: const Duration(milliseconds: 360),
    );
    _fade = CurvedAnimation(
      parent: _introController,
      curve: Curves.easeOutCubic,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, .03),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _introController,
      curve: Curves.easeOutCubic,
    ));

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
    setState(() {});
    context.read<ChannelProvider>().setSearchQuery(value);
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
    setState(() {});
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
    final query = _searchController.text.trim();
    final searching = query.isNotEmpty;

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) context.read<ChannelProvider>().clearFilters();
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
                      duration: const Duration(milliseconds: 180),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: searching
                          ? _ResultsView(
                              key: const ValueKey('results'),
                              provider: provider,
                              theme: theme,
                              query: query,
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
    final surface = isDark
        ? const Color(0xFF101722)
        : theme.colorScheme.surface;
    final iconColor = theme.colorScheme.onSurface.withValues(alpha: .52);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onClose,
              child: SizedBox(
                width: 42,
                height: 42,
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
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(17),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? .16 : .045),
                    blurRadius: 18,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: onChanged,
                onSubmitted: (value) => onSubmitted(value),
                textInputAction: TextInputAction.search,
                cursorColor: theme.colorScheme.primary,
                cursorWidth: 2,
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
                  prefixIcon: Icon(Icons.search_rounded, size: 20, color: iconColor),
                  suffixIcon: searching
                      ? IconButton(
                          onPressed: onClear,
                          icon: Icon(Icons.close_rounded, size: 18, color: iconColor),
                          splashRadius: 20,
                        )
                      : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
        Text(
          'Explorá Pivote',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1.05,
            letterSpacing: -.5,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'Encontrá canales, categorías y contenido rápidamente.',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface.withValues(alpha: .55),
            height: 1.35,
          ),
        ),
        if (history.isNotEmpty) ...[
          const SizedBox(height: 26),
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
              return InkWell(
                onTap: () => onSearch(item),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF101722)
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: theme.colorScheme.onSurface.withValues(alpha: .06),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history_rounded, size: 15, color: theme.colorScheme.primary),
                      const SizedBox(width: 7),
                      Text(
                        item,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 28),
        _SectionHeader(title: 'Categorías', color: theme.colorScheme.onSurface),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _SearchScreenState._categories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.7,
          ),
          itemBuilder: (context, index) {
            final item = _SearchScreenState._categories[index];
            return InkWell(
              onTap: () => onSearch(item.label),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF101722)
                      : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.onSurface.withValues(alpha: .06),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: .09),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(item.icon, size: 18, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 18, color: theme.colorScheme.onSurface.withValues(alpha: .28)),
                  ],
                ),
              ),
            );
          },
        ),
      ],
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
      return const Center(child: CircularProgressIndicator());
    }

    final results = provider.channels;

    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: .08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.search_off_rounded, size: 34, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 16),
              Text(
                'No encontramos resultados',
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 7),
              Text(
                'No hay coincidencias para “$query”. Probá con otro término.',
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface.withValues(alpha: .52),
                ),
              ),
            ],
          ),
        ),
      );
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
                style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '${results.length}',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: .92,
            ),
            itemCount: results.length,
            itemBuilder: (context, index) => ChannelCard(channel: results[index]),
          ),
        ),
      ],
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (trailing != null)
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
              child: Text(
                trailing!,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: color,
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
