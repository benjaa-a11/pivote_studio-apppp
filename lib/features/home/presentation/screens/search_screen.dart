import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
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
  List<String> _searchHistory = [];

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  // Modern category metadata — gradient pairs read better than flat fills.
  static final List<Map<String, dynamic>> _quickCategories = [
    {
      'name': 'Deportes',
      'icon': Icons.sports_soccer_rounded,
      'colors': const [Color(0xFF10B981), Color(0xFF059669)],
    },
    {
      'name': 'Noticias',
      'icon': Icons.newspaper_rounded,
      'colors': const [Color(0xFF3B82F6), Color(0xFF2563EB)],
    },
    {
      'name': 'Música',
      'icon': Icons.music_note_rounded,
      'colors': const [Color(0xFFA855F7), Color(0xFF9333EA)],
    },
    {
      'name': 'Películas',
      'icon': Icons.movie_rounded,
      'colors': const [Color(0xFFF59E0B), Color(0xFFD97706)],
    },
    {
      'name': 'Infantil',
      'icon': Icons.child_care_rounded,
      'colors': const [Color(0xFFEC4899), Color(0xFFDB2777)],
    },
    {
      'name': 'Radio',
      'icon': Icons.radio_rounded,
      'colors': const [Color(0xFF6366F1), Color(0xFF4F46E5)],
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
    _searchController.dispose();
    _searchFocusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    setState(() {});
    final provider = context.read<ChannelProvider>();
    provider.searchChannels(query);
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
    _onQueryChanged('');
    context.read<ChannelProvider>().clearFilters();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.isDark;
    final channelProvider = context.watch<ChannelProvider>();
    final query = _searchController.text.trim();
    final isSearching = query.isNotEmpty;

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
                              channelProvider, theme, isDark, query)
                          : _buildDiscoveryView(channelProvider, theme, isDark),
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

  /// Modern header with back button and a properly-clipped, glowing
  /// focused search field (no more mismatched fill/border artifacts).
  Widget _buildSearchHeader(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    bool isSearching,
  ) {
    final hasFocus = _searchFocusNode.hasFocus;
    final fieldRadius = BorderRadius.circular(AppRadius.md + 2); // 16px

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
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

          // Search field — clipped to the same radius as its container so
          // no internal fill/highlight can ever spill past the rounded
          // corners, and `filled/fillColor` are explicitly disabled so the
          // theme-wide InputDecorationTheme can't paint a mismatched
          // rectangular background underneath.
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              height: 52,
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.darkBg2
                    : theme.colorScheme.surface,
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
                    hintText: 'Buscar canal, deporte o categoría...',
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

  /// Discovery view when search query is empty.
  Widget _buildDiscoveryView(
    ChannelProvider provider,
    ThemeData theme,
    bool isDark,
  ) {
    return ListView(
      // Clamping instead of bouncing — matches the rest of the app, no
      // rubber-band overscroll on this screen anymore.
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        // ─── History Section ───
        if (_searchHistory.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Búsquedas recientes',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () async {
                    await SearchService.clearSearchHistory();
                    _loadHistory();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
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
                        Icon(
                          Icons.history_rounded,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          h,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 26),
        ],

        // ─── Quick Categories ───
        Text(
          'Categorías rápidas',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.1,
          ),
          itemCount: _quickCategories.length,
          itemBuilder: (context, index) {
            final cat = _quickCategories[index];
            final List<Color> colors = cat['colors'] as List<Color>;
            final IconData icon = cat['icon'] as IconData;
            final String name = cat['name'] as String;

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _executeSearch(name),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.darkBg2
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
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
                        width: 38,
                        height: 38,
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
                        child: Icon(icon, size: 19, color: colors[0]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        name,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
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

        // ─── Featured / Popular Channels ───
        Text(
          'Canales recomendados',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
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
          itemCount: provider.allChannels.take(6).length,
          itemBuilder: (context, index) {
            final channel = provider.allChannels.take(6).toList()[index];
            return ChannelCard(channel: channel);
          },
        ),
      ],
    );
  }

  /// Live search results view.
  Widget _buildSearchResults(
    ChannelProvider provider,
    ThemeData theme,
    bool isDark,
    String query,
  ) {
    final channels = provider.channels;

    if (channels.isEmpty) {
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
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  size: 38,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Sin resultados',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No encontramos nada para "$query".\nPrueba con otra palabra o categoría.',
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  elevation: 0,
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
        // Result count banner
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            '${channels.length} ${channels.length == 1 ? 'resultado encontrado' : 'resultados encontrados'}',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
        ),

        // Grid of results
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            physics: const ClampingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.05,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: channels.length,
            itemBuilder: (context, index) {
              return ChannelCard(channel: channels[index]);
            },
          ),
        ),
      ],
    );
  }
}
