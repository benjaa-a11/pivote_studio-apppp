import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pivote/features/movies/presentation/providers/movies_provider.dart';
import 'package:pivote/features/movies/presentation/widgets/movie_card.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/animations/app_animations.dart';


class MoviesSearchScreen extends StatefulWidget {
  const MoviesSearchScreen({super.key});

  @override
  State<MoviesSearchScreen> createState() => _MoviesSearchScreenState();
}

class _MoviesSearchScreenState extends State<MoviesSearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  List<String> _history = [];

  // Genre-based color palettes for category chips
  static final Map<String, List<Color>> _genreGradients = {
    'Acción': [const Color(0xFFFF416C), const Color(0xFFFF4B2B)],
    'Ciencia Ficción': [const Color(0xFF4776E6), const Color(0xFF8E54E9)],
    'Drama': [const Color(0xFF11998E), const Color(0xFF38EF7D)],
    'Suspenso': [const Color(0xFF373B44), const Color(0xFF4286F4)],
    'Animación': [const Color(0xFFF9D423), const Color(0xFFFF4E50)],
    'Aventura': [const Color(0xFF56AB2F), const Color(0xFFA8E063)],
    'Comedia': [const Color(0xFFFC5C7D), const Color(0xFF6A82FB)],
    'Historia': [const Color(0xFFB79891), const Color(0xFF94716B)],
    'Familia': [const Color(0xFF00C6FF), const Color(0xFF0072FF)],
    'Crimen': [const Color(0xFF870000), const Color(0xFF190A05)],
    'Biografía': [const Color(0xFFCB6C6C), const Color(0xFF8B2FC9)],
  };

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    _loadHistory();

    // auto-focus search field when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('movie_search_history') ?? [];
      setState(() {
        _history = saved;
      });
    } catch (e) {
      debugPrint('Error loading search history: $e');
    }
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('movie_search_history', _history);
    } catch (e) {
      debugPrint('Error saving search history: $e');
    }
  }

  void _addQueryToHistory(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      _history.remove(trimmed);
      _history.insert(0, trimmed);
      if (_history.length > 8) {
        _history.removeRange(8, _history.length);
      }
    });
    _saveHistory();
  }

  void _removeHistoryItem(String query) {
    setState(() {
      _history.remove(query);
    });
    _saveHistory();
  }

  void _clearAllHistory() {
    setState(() {
      _history.clear();
    });
    _saveHistory();
  }

  void _onSearchChanged(String query) {
    context.read<MoviesProvider>().setSearchQuery(query);
    setState(() {});
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<MoviesProvider>().setSearchQuery('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final moviesProvider = context.watch<MoviesProvider>();
    final isSearching = _searchController.text.isNotEmpty;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          // Clear the search filter when leaving
          context.read<MoviesProvider>().setSearchQuery('');
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Column(
          children: [
            // ── Premium Search Header ──
            _buildSearchHeader(context, theme, isDark),

            // ── Content (animated switch between initial & results) ──
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: isSearching
                    ? _buildResults(moviesProvider, theme, isDark)
                    : _buildInitialState(moviesProvider, theme, isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Search Header ──────────────────────────────────────────────────────────
  Widget _buildSearchHeader(BuildContext context, ThemeData theme, bool isDark) {
    final topPad = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(16, topPad + 12, 16, 16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button + title
          Row(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    context.read<MoviesProvider>().setSearchQuery('');
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
                    child: const Center(
                      child: Icon(Icons.arrow_back_ios_new_rounded, size: 14),
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
                      'Buscar Películas',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.6,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      Text(
                        '${context.watch<MoviesProvider>().movies.length} resultados encontrados',
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

          // Glowing search field
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 52,
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.darkBg2.withValues(alpha: 0.6)
                  : AppTheme.lightBg2.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _focusNode.hasFocus
                    ? theme.colorScheme.primary
                    : (isDark
                        ? AppTheme.darkBorder.withValues(alpha: 0.25)
                        : AppTheme.lightBorder),
                width: 1.5,
              ),
              boxShadow: _focusNode.hasFocus
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary
                            .withValues(alpha: isDark ? 0.22 : 0.12),
                        blurRadius: 20,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              onChanged: _onSearchChanged,
              onSubmitted: _addQueryToHistory,
              textInputAction: TextInputAction.search,
              cursorColor: theme.colorScheme.primary,
              cursorWidth: 2.2,
              cursorRadius: const Radius.circular(2),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'Título, género, director...',
                hintStyle: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  color: theme.hintColor.withValues(alpha: 0.45),
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 14, right: 10),
                  child: Icon(
                    Icons.movie_filter_rounded,
                    color: _focusNode.hasFocus
                        ? theme.colorScheme.primary
                        : theme.hintColor.withValues(alpha: 0.45),
                    size: 22,
                  ),
                ),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 40, maxHeight: 40),
                suffixIcon: _searchController.text.isNotEmpty
                    ? GestureDetector(
                        onTap: _clearSearch,
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      )
                    : null,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Initial State (genre grid + popular movies) ───────────────────────────
  Widget _buildInitialState(
      MoviesProvider provider, ThemeData theme, bool isDark) {
    final genres = provider.genres.where((g) => g != 'Todos').toList();
    final popular = provider.allMovies.take(6).toList();

    return FadeTransition(
      opacity: _fadeAnim,
      child: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          // Recent searches
          if (_history.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.history_rounded,
                            size: 18, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Búsquedas Recientes',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: _clearAllHistory,
                      child: Text(
                        'Limpiar todo',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverToBoxAdapter(
                child: SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(),
                    itemCount: _history.length,
                    itemBuilder: (context, index) {
                      final item = _history[index];
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: InputChip(
                          label: Text(
                            item,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          backgroundColor: isDark
                              ? AppTheme.darkBg2.withValues(alpha: 0.5)
                              : AppTheme.lightBg2.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: isDark
                                  ? AppTheme.darkBorder.withValues(alpha: 0.2)
                                  : AppTheme.lightBorder,
                            ),
                          ),
                          onPressed: () {
                            _searchController.text = item;
                            _onSearchChanged(item);
                            _addQueryToHistory(item);
                          },
                          onDeleted: () => _removeHistoryItem(item),
                          deleteIcon: Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],

          // Genre Quick Cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Row(
                children: [
                  Icon(Icons.grid_view_rounded,
                      size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Explorar por Género',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final genre = genres[index];
                  final gradient = _genreGradients[genre] ??
                      [Colors.grey.shade700, Colors.grey.shade900];
                  return _buildGenreCard(genre, gradient, provider);
                },
                childCount: genres.length,
              ),
            ),
          ),

          // Popular Movies
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
              child: Row(
                children: [
                  Icon(Icons.local_fire_department_rounded,
                      size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Películas Populares',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
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
                crossAxisCount: 3,
                childAspectRatio: 0.68,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => AppAnimations.staggeredSlideIn(
                  index: index,
                  child: MovieCard(movie: popular[index]),
                ),
                childCount: popular.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildGenreCard(
      String genre, List<Color> gradient, MoviesProvider provider) {
    return AppAnimations.smoothFadeIn(
      child: GestureDetector(
        onTap: () {
          _searchController.text = genre;
          _onSearchChanged(genre);
          _addQueryToHistory(genre);
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -10,
                bottom: -10,
                child: Icon(
                  Icons.movie_rounded,
                  size: 50,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    genre,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults(
      MoviesProvider provider, ThemeData theme, bool isDark) {
    final results = provider.movies;

    if (results.isEmpty) {
      return _buildNoResults(theme, isDark);
    }

    final query = _searchController.text.toLowerCase();
    final suggestions = provider.allMovies
        .where((m) => m.title.toLowerCase().contains(query) &&
            m.title.toLowerCase() != query)
        .take(3)
        .map((m) => m.title)
        .toList();

    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        // Results info bar
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.filter_list_rounded,
                    size: 16,
                    color: theme.colorScheme.primary.withValues(alpha: 0.7)),
                const SizedBox(width: 8),
                Text(
                  '${results.length} ${results.length == 1 ? 'película' : 'películas'} encontradas',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
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
        ),

        // Real-time suggestions row
        if (suggestions.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline_rounded,
                      size: 14, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Quizás quisiste decir:',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 28,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const ClampingScrollPhysics(),
                        itemCount: suggestions.length,
                        itemBuilder: (context, index) {
                          final suggestion = suggestions[index];
                          return GestureDetector(
                            onTap: () {
                              _searchController.text = suggestion;
                              _onSearchChanged(suggestion);
                              _addQueryToHistory(suggestion);
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.15),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  suggestion,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 10,
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
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
              childAspectRatio: 0.70,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => AppAnimations.smoothFadeIn(
                child: MovieCard(movie: results[index]),
              ),
              childCount: results.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  Widget _buildNoResults(ThemeData theme, bool isDark) {
    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary.withValues(alpha: 0.15),
                          Colors.transparent,
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.movie_filter_outlined,
                      size: 42,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Sin resultados',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No encontramos ninguna película que coincida con "${_searchController.text}".',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      height: 1.5,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  GestureDetector(
                    onTap: _clearSearch,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh_rounded,
                              size: 16, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Limpiar búsqueda',
                            style: GoogleFonts.spaceGrotesk(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
