import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pivote/features/movies/data/models/movie.dart';
import 'package:pivote/features/movies/presentation/screens/movie_player_screen.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/animations/app_animations.dart';

class MovieDetailScreen extends StatelessWidget {
  final Movie movie;

  const MovieDetailScreen({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      body: Stack(
        children: [
          // 1. Immersive Blurry Background
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: movie.backdropUrl,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => Container(
                color: isDark ? AppTheme.darkBg1 : AppTheme.lightBg1,
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.4, 0.9, 1.0],
                    colors: [
                      Colors.black.withValues(alpha: 0.35),
                      isDark
                          ? AppTheme.darkBg.withValues(alpha: 0.6)
                          : AppTheme.lightBg.withValues(alpha: 0.6),
                      isDark ? AppTheme.darkBg : AppTheme.lightBg,
                      isDark ? AppTheme.darkBg : AppTheme.lightBg,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 2. Action Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 1,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                // Premium Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.darkAccentDim,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.darkAccent.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'ULTRA HD',
                    style: GoogleFonts.spaceGrotesk(
                      color: AppTheme.darkAccent,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Scrollable Content
          Positioned.fill(
            top: MediaQuery.of(context).padding.top + 70,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Poster + Title Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Poster
                      Container(
                        width: 120,
                        height: 180,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CachedNetworkImage(
                            imageUrl: movie.posterUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),

                      // Meta Block
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              movie.title,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                height: 1.15,
                                color: isDark ? Colors.white : AppTheme.lightText,
                                letterSpacing: -0.6,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Year & Duration row
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 13,
                                  color: isDark ? AppTheme.darkText2 : AppTheme.lightText2,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${movie.year}',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppTheme.darkText2 : AppTheme.lightText2,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Icon(
                                  Icons.schedule_rounded,
                                  size: 13,
                                  color: isDark ? AppTheme.darkText2 : AppTheme.lightText2,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  movie.duration,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppTheme.darkText2 : AppTheme.lightText2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Rating Stars
                            _buildRatingStars(movie.rating),
                            const SizedBox(height: 6),
                            Text(
                              '${movie.rating.toStringAsFixed(1)} / 5.0 calificacion',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppTheme.darkText3 : AppTheme.lightText3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Genre Tags
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: movie.genres.map((genre) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppTheme.darkBg2.withValues(alpha: 0.6)
                              : AppTheme.lightBg2.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? AppTheme.darkBorder.withValues(alpha: 0.4)
                                : AppTheme.lightBorder,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          genre,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : AppTheme.lightText2,
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 28),

                  // 4. Large Action Play Button
                  AppAnimations.smoothFadeIn(
                    duration: const Duration(milliseconds: 400),
                    child: Center(
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.darkAccent,
                              AppTheme.darkAccent.withValues(alpha: 0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.darkAccent.withValues(alpha: 0.35),
                              blurRadius: 15,
                              spreadRadius: 1,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            HapticFeedback.heavyImpact();
                            Navigator.push(
                              context,
                              AppAnimations.createFadeRoute(
                                MoviePlayerScreen(movie: movie),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: AppTheme.darkBg,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.play_arrow_rounded,
                                size: 28,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'REPRODUCIR PELÍCULA',
                                style: GoogleFonts.spaceGrotesk(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Synopsis Header
                  _buildSectionHeader(theme, 'Sinopsis', isDark),
                  const SizedBox(height: 10),
                  Text(
                    movie.description,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      height: 1.6,
                      color: isDark ? AppTheme.darkText2 : AppTheme.lightText2,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Cast Header
                  _buildSectionHeader(theme, 'Reparto Principal', isDark),
                  const SizedBox(height: 14),
                  // Actor listing in a premium list
                  SizedBox(
                    height: 90,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: movie.cast.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 14),
                      itemBuilder: (context, index) {
                        final actor = movie.cast[index];
                        return _buildActorItem(actor, isDark);
                      },
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Directors Header
                  _buildSectionHeader(theme, 'Dirección', isDark),
                  const SizedBox(height: 12),
                  Row(
                    children: movie.directors.map((director) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkBg1 : AppTheme.lightBg1,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? AppTheme.darkBorder.withValues(alpha: 0.3)
                                : AppTheme.lightBorder,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.camera_outdoor_rounded,
                              size: 14,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              director,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppTheme.lightText,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, bool isDark) {
    return Row(
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
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppTheme.lightText,
          ),
        ),
      ],
    );
  }

  Widget _buildRatingStars(double rating) {
    // scale 1-5
    final activeStars = rating.round();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final isFilled = index < activeStars;
        return Icon(
          Icons.star_rounded,
          color: isFilled ? AppTheme.darkAccent : Colors.white24,
          size: 18,
        );
      }),
    );
  }

  Widget _buildActorItem(String name, bool isDark) {
    final initials = name.split(' ').map((n) => n[0]).take(2).join().toUpperCase();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Glass avatar
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.04),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.1),
            ),
          ),
          child: Center(
            child: Text(
              initials,
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w900,
                fontSize: 14,
                color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 76,
          child: Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
