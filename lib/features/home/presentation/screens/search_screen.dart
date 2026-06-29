import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pivote/features/video/presentation/providers/channel_provider.dart';
import 'package:pivote/features/home/data/services/search_service.dart';
import 'package:pivote/features/video/presentation/widgets/channel_card.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/animations/app_animations.dart';

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
  bool _isSearching = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Curated category palettes
  static final Map<String, List<Color>> _categoryGradients = {
    'Deportes': [const Color(0xFF00B4DB), const Color(0xFF0083B0)],      // Vibrant blue/cyan
    'Noticias': [const Color(0xFFED213A), const Color(0xFF93291E)],      // Crimson/red
    'Música': [const Color(0xFF8E2DE2), const Color(0xFF4A00E0)],        // Violet/indigo
    'Películas': [const Color(0xFF11998E), const Color(0xFF38EF7D)],     // Teal/green
    'Infantil': [const Color(0xFFF9D423), const Color(0xFFFF4E50)],      // Orange/amber
    'Documentales': [const Color(0xFF00C6FF), const Color(0xFF0072FF)],  // Deep sky blue
  };

  static final Map<String, IconData> _categoryIcons = {
    'Deportes': Icons.sports_soccer_rounded,
    'Noticias': Icons.newspaper_rounded,
    'Música': Icons.music_note_rounded,
    'Películas': Icons.movie_rounded,
    'Infantil': Icons.child_care_rounded,
    'Documentales': Icons.public_rounded,
  };

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();

    // Listen to focus changes to refresh search bar glow
    _searchFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadSearchHistory() async {
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
    _animationController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
    });
    Provider.of<ChannelProvider>(context, listen: false).searchChannels(query);
    if (query.isNotEmpty) {
      SearchService.saveSearchQuery(query).then((_) => _loadSearchHistory());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final channelProvider = Provider.of<ChannelProvider>(context);

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          Provider.of<ChannelProvider>(context, listen: false)
              .searchChannels('');
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Column(
          children: [
            // Premium Search Header
            _buildSearchHeader(context, theme, isDark),

            // Content
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
                child: _isSearching
                    ? _buildSearchResults(channelProvider, theme, isDark)
                    : _buildInitialState(channelProvider, theme, isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader(
      BuildContext context, ThemeData theme, bool isDark) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(16, topPadding + 12, 16, 16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? AppTheme.darkBorder.withValues(alpha: 0.15)
                : AppTheme.lightBorder.withValues(alpha: 0.3),
            width: 1.2,
          ),
        ),
      ),
      child: Column(
        children: [
          // Top row: Back + Title
          Row(
            children: [
              // Unified Back button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Provider.of<ChannelProvider>(context, listen: false)
                        .searchChannels('');
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.darkBg2.withValues(alpha: 0.5)
                          : AppTheme.lightBg2.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? AppTheme.darkBorder.withValues(alpha: 0.3)
                            : AppTheme.lightBorder,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 14,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Buscador',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.6,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (_isSearching)
                      Text(
                        '${Provider.of<ChannelProvider>(context).channels.length} canales encontrados',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Glowing Search field (Overhauled & shift-proof)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 54,
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.darkBg2.withValues(alpha: 0.6)
                  : AppTheme.lightBg2.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _searchFocusNode.hasFocus
                    ? theme.colorScheme.primary
                    : (isDark
                        ? AppTheme.darkBorder.withValues(alpha: 0.2)
                        : AppTheme.lightBorder),
                width: 1.5,
              ),
              boxShadow: _searchFocusNode.hasFocus
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary
                            .withValues(alpha: isDark ? 0.12 : 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: (q) {
                _onSearch(q);
                setState(() {});
              },
              onSubmitted: _onSearch,
              textInputAction: TextInputAction.search,
              autofocus: false,
              cursorColor: theme.colorScheme.primary,
              cursorWidth: 2.2,
              cursorRadius: const Radius.circular(2),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'Buscá canales, películas, categorías...',
                hintStyle: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  color: theme.hintColor.withValues(alpha: 0.45),
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 14, right: 10),
                  child: Icon(
                    Icons.search_rounded,
                    color: _searchFocusNode.hasFocus
                        ? theme.colorScheme.primary
                        : theme.hintColor.withValues(alpha: 0.45),
                    size: 22,
                  ),
                ),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 40, maxHeight: 40),
                suffixIcon: _searchController.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialState(
      ChannelProvider provider, ThemeData theme, bool isDark) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        children: [
          // Search History
          if (_searchHistory.isNotEmpty) ...[
            _buildSectionHeader(
              theme,
              'Búsquedas Recientes',
              icon: Icons.history_rounded,
              onAction: () async {
                await SearchService.clearSearchHistory();
                _loadSearchHistory();
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _searchHistory
                  .take(6)
                  .map((query) => _buildHistoryChip(query, theme, isDark))
                  .toList(),
            ),
            const SizedBox(height: 28),
          ],

          // Quick Categories
          _buildSectionHeader(theme, 'Explorar Categorías',
              icon: Icons.grid_view_rounded),
          const SizedBox(height: 14),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 2.3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: _categoryGradients.keys.map((cat) {
              return _buildPremiumCategoryCard(cat, theme, isDark);
            }).toList(),
          ),
          const SizedBox(height: 28),

          // Popular Channels
          _buildSectionHeader(theme, 'Canales Populares',
              icon: Icons.local_fire_department_rounded),
          const SizedBox(height: 16),
          _buildPopularChannels(provider),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title,
      {IconData? icon, VoidCallback? onAction}) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
        ],
        Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const Spacer(),
        if (onAction != null)
          GestureDetector(
            onTap: onAction,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withAlpha(15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Limpiar',
                style: GoogleFonts.spaceGrotesk(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHistoryChip(String query, ThemeData theme, bool isDark) {
    return AppAnimations.smoothFadeIn(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _searchController.text = query;
            _onSearch(query);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkBg2 : AppTheme.lightBg2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? AppTheme.darkBorder.withValues(alpha: 0.2)
                    : AppTheme.lightBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history_rounded,
                    size: 14, color: theme.colorScheme.primary.withAlpha(150)),
                const SizedBox(width: 6),
                Text(
                  query,
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumCategoryCard(String category, ThemeData theme, bool isDark) {
    final gradient = _categoryGradients[category] ?? [Colors.grey, Colors.blueGrey];
    final icon = _categoryIcons[category] ?? Icons.category_rounded;
    final accentColor = gradient.first;

    return AppAnimations.smoothFadeIn(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _searchController.text = category;
            _onSearch(category);
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark 
                    ? Colors.white.withValues(alpha: 0.06) 
                    : Colors.black.withValues(alpha: 0.05),
                width: 1.2,
              ),
            ),
            child: Stack(
              children: [
                // Soft background glow from icon
                Positioned(
                  right: -10,
                  bottom: -10,
                  child: Icon(
                    icon,
                    size: 60,
                    color: accentColor.withValues(alpha: isDark ? 0.06 : 0.04),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          icon,
                          size: 18,
                          color: accentColor,
                        ),
                      ),
                      Text(
                        category,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
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
  }

  Widget _buildPopularChannels(ChannelProvider provider) {
    final channels = provider.allChannels.take(6).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.05,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: channels.length,
      itemBuilder: (context, index) {
        return AppAnimations.smoothFadeIn(
          child: ChannelCard(channel: channels[index]),
        );
      },
    );
  }

  Widget _buildSearchResults(
      ChannelProvider provider, ThemeData theme, bool isDark) {
    final channels = provider.channels;

    if (channels.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Premium Circular gradient Search Off illustration
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            theme.colorScheme.primary.withAlpha(40),
                            Colors.transparent,
                          ]
                        : [
                            theme.colorScheme.primary.withAlpha(15),
                            Colors.transparent,
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.primary.withAlpha(30),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.search_off_rounded,
                      size: 32,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Sin Resultados',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No encontramos nada que coincida con "${_searchController.text}". ¡Intentá buscando otra cosa!',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  height: 1.5,
                  color: theme.colorScheme.onSurface.withAlpha(140),
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),

              // Proactive Smart Suggestions Section
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '💡 Quizás te interese...',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _buildSuggestionChip('Deportes', theme, isDark),
                  _buildSuggestionChip('Noticias', theme, isDark),
                  _buildSuggestionChip('Películas', theme, isDark),
                  _buildSuggestionChip('Música', theme, isDark),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Results header + grid
    return Column(
      children: [
        // Results info bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.filter_list_rounded,
                  size: 16, color: theme.colorScheme.primary.withAlpha(180)),
              const SizedBox(width: 8),
              Text(
                '${channels.length} ${channels.length == 1 ? 'canal encontrado' : 'canales encontrados'}',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface.withAlpha(160),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '"${_searchController.text}"',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(
          height: 1,
          color: isDark
              ? AppTheme.darkBorder.withValues(alpha: 0.1)
              : AppTheme.lightBorder.withValues(alpha: 0.2),
        ),
        // Grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            physics: const ClampingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.05,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: channels.length,
            itemBuilder: (context, index) {
              return AppAnimations.smoothFadeIn(
                child: ChannelCard(channel: channels[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionChip(String query, ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: () {
        _searchController.text = query;
        _onSearch(query);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withAlpha(15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.primary.withAlpha(30),
          ),
        ),
        child: Text(
          query,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
