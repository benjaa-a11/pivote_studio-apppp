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

  // Modern category metadata
  static final List<Map<String, dynamic>> _quickCategories = [
    {
      'name': 'Deportes',
      'icon': Icons.sports_soccer_rounded,
      'color': const Color(0xFF10B981), // Emerald
    },
    {
      'name': 'Noticias',
      'icon': Icons.newspaper_rounded,
      'color': const Color(0xFF3B82F6), // Blue
    },
    {
      'name': 'Música',
      'icon': Icons.music_note_rounded,
      'color': const Color(0xFFA855F7), // Purple
    },
    {
      'name': 'Películas',
      'icon': Icons.movie_rounded,
      'color': const Color(0xFFF59E0B), // Amber
    },
    {
      'name': 'Infantil',
      'icon': Icons.child_care_rounded,
      'color': const Color(0xFFEC4899), // Pink
    },
    {
      'name': 'Radio',
      'icon': Icons.radio_rounded,
      'color': const Color(0xFF6366F1), // Indigo
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
            child: Column(
              children: [
                // ─── Modern Sticky Header ───
                _buildSearchHeader(context, theme, isDark, isSearching),

                // ─── Body Content ───
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: isSearching
                        ? _buildSearchResults(channelProvider, theme, isDark, query)
                        : _buildDiscoveryView(channelProvider, theme, isDark),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Modern Header with back button & glowing focused input bar
  Widget _buildSearchHeader(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    bool isSearching,
  ) {
    final hasFocus = _searchFocusNode.hasFocus;

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
                width: 42,
                height: 42,
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

          // Search Field
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 46,
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.darkBg2
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: hasFocus
                      ? theme.colorScheme.primary
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.08)),
                  width: hasFocus ? 1.5 : 1,
                ),
                boxShadow: hasFocus
                    ? AppShadows.glow(theme.colorScheme.primary, alpha: 0.15)
                    : [],
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: _onQueryChanged,
                onSubmitted: _executeSearch,
                textInputAction: TextInputAction.search,
                cursorColor: theme.colorScheme.primary,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'Buscar canal, deporte o categoría...',
                  hintStyle: GoogleFonts.spaceGrotesk(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: hasFocus
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          onPressed: _clearSearch,
                        )
                      : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Discovery View when search query is empty
  Widget _buildDiscoveryView(
    ChannelProvider provider,
    ThemeData theme,
    bool isDark,
  ) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
              TextButton(
                onPressed: () async {
                  await SearchService.clearSearchHistory();
                  _loadHistory();
                },
                child: Text(
                  'Borrar todo',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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
          const SizedBox(height: 24),
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
            childAspectRatio: 1.15,
          ),
          itemCount: _quickCategories.length,
          itemBuilder: (context, index) {
            final cat = _quickCategories[index];
            final Color color = cat['color'] as Color;
            final IconData icon = cat['icon'] as IconData;
            final String name = cat['name'] as String;

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _executeSearch(name),
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
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, size: 20, color: color),
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
        const SizedBox(height: 24),

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

  /// Live Search Results View
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
            physics: const BouncingScrollPhysics(),
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
