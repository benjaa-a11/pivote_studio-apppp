import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pivote/features/movies/presentation/providers/movies_provider.dart';
import 'package:pivote/features/movies/presentation/widgets/movie_card.dart';
import 'package:pivote/features/movies/data/models/movie.dart';
import 'package:pivote/features/movies/presentation/screens/movie_detail_screen.dart';
import 'package:pivote/features/movies/presentation/screens/movies_search_screen.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/animations/app_animations.dart';

class MoviesScreen extends StatefulWidget {
  const MoviesScreen({super.key});

  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> {
  final PageController _carouselController = PageController(viewportFraction: 0.92);
  int _activeCarouselIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load movies on screen entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MoviesProvider>().loadMovies();
    });
  }

  @override
  void dispose() {
    _carouselController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final moviesProvider = context.watch<MoviesProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: theme.colorScheme.primary,
          backgroundColor: theme.cardColor,
          strokeWidth: 2.5,
          onRefresh: () async {
            await moviesProvider.loadMovies(force: true);
            await moviesProvider.loadMovieFavorites();
          },
          child: CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: [
              // 1. Sleek Top Header
              SliverToBoxAdapter(
                child: _buildHeader(theme, isDark),
              ),

              // 2. Featured Banner Carousel (only if no genre filter)
              if (moviesProvider.selectedGenre == 'Todos' &&
                  !moviesProvider.isLoading &&
                  moviesProvider.featuredMovies.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildFeaturedCarousel(theme, isDark, moviesProvider.featuredMovies),
                ),

              // 4. Genre Filter Horizontal Carousel
              SliverToBoxAdapter(
                child: _buildGenreFilterCarousel(theme, isDark, moviesProvider),
              ),

              // 3. Continue Watching Row (only if selectedGenre == 'Todos')
              if (moviesProvider.selectedGenre == 'Todos' &&
                  !moviesProvider.isLoading &&
                  moviesProvider.resumeMovies.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _buildSectionTitle(theme, 'Seguir Viendo', isDark),
                ),
                SliverToBoxAdapter(
                  child: _buildResumeList(moviesProvider.resumeMovies, moviesProvider),
                ),
              ],

              // 3.5. My List Row (only if selectedGenre == 'Todos')
              if (moviesProvider.selectedGenre == 'Todos' &&
                  !moviesProvider.isLoading &&
                  moviesProvider.favoriteMovies.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _buildSectionTitle(theme, 'Mi Lista', isDark),
                ),
                SliverToBoxAdapter(
                  child: _buildFavoriteList(moviesProvider.favoriteMovies),
                ),
              ],

              // 4. Trending / Popular Row
              if (!moviesProvider.isLoading &&
                  moviesProvider.trendingMovies.isNotEmpty &&
                  moviesProvider.selectedGenre == 'Todos') ...[
                SliverToBoxAdapter(
                  child: _buildSectionTitle(theme, 'Tendencias Populares', isDark),
                ),
                SliverToBoxAdapter(
                  child: _buildTrendingList(moviesProvider.trendingMovies),
                ),
                SliverToBoxAdapter(
                  child: _buildSectionTitle(theme, 'Catálogo Completo', isDark),
                ),
              ],

              // 6. Skeletonized Main Movies Grid
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: _buildMoviesGrid(moviesProvider, isDark),
              ),

              // Extra padding at bottom
              const SliverToBoxAdapter(
                child: SizedBox(height: 40),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey).withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Cinema Icon Box with Gold/Neon Accent
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.darkAccent, Color(0xFFFF9F43)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.darkAccent.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.movie_creation_rounded,
              size: 24,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 14),
          // Titles
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'Películas',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: -0.6,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.darkAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppTheme.darkAccent.withValues(alpha: 0.3),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        'CATÁLOGO 4K',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppTheme.darkAccent : Colors.orange.shade900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Estrenos, Cine Premium & Colecciones',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.darkText3 : AppTheme.lightText3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Glassmorphism Search Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  AppAnimations.createFadeRoute(const MoviesSearchScreen()),
                );
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.darkBg2
                      : theme.colorScheme.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : theme.colorScheme.primary.withValues(alpha: 0.2),
                    width: 1.2,
                  ),
                ),
                child: Icon(
                  Icons.search_rounded,
                  size: 22,
                  color: isDark ? AppTheme.darkAccent : theme.colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildFeaturedCarousel(ThemeData theme, bool isDark, List<Movie> featured) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _carouselController,
            onPageChanged: (idx) {
              setState(() {
                _activeCarouselIndex = idx;
              });
            },
            itemCount: featured.length,
            itemBuilder: (context, index) {
              final movie = featured[index];
              return _buildCarouselItem(movie, isDark);
            },
          ),
        ),
        const SizedBox(height: 12),
        // Pagination Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(featured.length, (idx) {
            final isActive = _activeCarouselIndex == idx;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isActive ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: isActive
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.2),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildCarouselItem(Movie movie, bool isDark) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          AppAnimations.createRoute(MovieDetailScreen(movie: movie)),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Backdrop Blur Image
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: movie.backdropUrl,
                  fit: BoxFit.cover,
                ),
              ),

              // Solid shadow gradient
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.4, 1.0],
                      colors: [
                        Colors.black.withValues(alpha: 0.1),
                        Colors.black.withValues(alpha: 0.3),
                        Colors.black.withValues(alpha: 0.85),
                      ],
                    ),
                  ),
                ),
              ),

              // Title block & Badge
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.darkAccent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'DESTACADA',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 8,
                          color: AppTheme.darkBg,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      movie.title,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      movie.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenreFilterCarousel(ThemeData theme, bool isDark, MoviesProvider provider) {
    final list = provider.genres;

    return Container(
      height: 44,
      margin: const EdgeInsets.only(top: 14, bottom: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: list.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final genre = list[index];
          final isSelected = provider.selectedGenre == genre;

          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              provider.selectGenre(genre);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary.withValues(alpha: 0.15)
                    : (isDark ? AppTheme.darkBg2 : AppTheme.lightBg2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                  width: isSelected ? 1.8 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(alpha: 0.15),
                          blurRadius: 8,
                          spreadRadius: 1,
                        )
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  genre,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? theme.colorScheme.primary : theme.hintColor,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        children: [
          Container(
            width: 3.5,
            height: 16,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingList(List<Movie> trending) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: trending.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final movie = trending[index];
          return SizedBox(
            width: 110,
            child: MovieCard(movie: movie),
          );
        },
      ),
    );
  }

  Widget _buildResumeList(List<Movie> resumeList, MoviesProvider provider) {
    return SizedBox(
      height: 130,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: resumeList.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final movie = resumeList[index];
          final position = provider.getPlaybackPosition(movie.id);
          final duration = provider.getMovieDuration(movie.id);
          final progress = duration > Duration.zero 
              ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
              : 0.0;

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                AppAnimations.createRoute(MovieDetailScreen(movie: movie)),
              );
            },
            child: Container(
              width: 190,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.darkBorder.withValues(alpha: 0.25)
                      : AppTheme.lightBorder,
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: Theme.of(context).brightness == Brightness.dark ? 0.25 : 0.05,
                    ),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    // Backdrop image
                    Positioned.fill(
                      child: CachedNetworkImage(
                        imageUrl: movie.backdropUrl,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Container(
                          color: AppTheme.darkBg2,
                          child: const Icon(Icons.movie_rounded, color: Colors.white24, size: 32),
                        ),
                      ),
                    ),
                    // Dark gradient overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.0, 0.4, 1.0],
                            colors: [
                              Colors.black.withValues(alpha: 0.15),
                              Colors.black.withValues(alpha: 0.35),
                              Colors.black.withValues(alpha: 0.9),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Title and Progress info
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 10,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            movie.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 5),
                          // Tiny progress bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.darkAccent),
                              minHeight: 3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Play icon in the center
                    Positioned.fill(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.5),
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFavoriteList(List<Movie> favorites) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: favorites.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final movie = favorites[index];
          return SizedBox(
            width: 110,
            child: MovieCard(movie: movie),
          );
        },
      ),
    );
  }

  Widget _buildMoviesGrid(MoviesProvider provider, bool isDark) {
    final list = provider.movies;
    final isLoading = provider.isLoading;

    if (!isLoading && list.isEmpty) {
      return SliverToBoxAdapter(
        child: _buildEmptyState(context, provider),
      );
    }

    final dummyCount = isLoading ? 6 : list.length;

    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.70,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final card = isLoading
              ? MovieCard(
                  movie: Movie(
                    id: 'dummy',
                    title: 'Movie Title',
                    description: '',
                    posterUrl: '',
                    backdropUrl: '',
                    rating: 5.0,
                    year: 2026,
                    duration: '2h',
                    genres: [],
                    streamUrl: '',
                    cast: [],
                    directors: [],
                  ),
                )
              : MovieCard(movie: list[index]);

          return Skeletonizer(
            enabled: isLoading,
            child: card,
          );
        },
        childCount: dummyCount,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, MoviesProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                    Theme.of(context).colorScheme.secondary.withValues(alpha: 0.15),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.movie_filter_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No hay películas en este género',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Intentá seleccionar otro género o\nlimpiar el filtro activo.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                    height: 1.5,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: provider.clearFilters,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Limpiar filtros'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
