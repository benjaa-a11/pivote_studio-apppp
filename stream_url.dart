import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/features/movies/data/models/movie.dart';
import 'package:pivote/shared/widgets/common/pivote_loader.dart';

/// Cinematic full-screen loading state shown before the first frame of the
/// movie is decoded. Uses the movie's backdrop + poster so the screen never
/// feels like a "dead" black hole while the stream negotiates — closer to
/// what Netflix/Disney+ show during initial buffering.
class MovieLoadingOverlay extends StatelessWidget {
  final Movie movie;
  final int retryAttempt;

  const MovieLoadingOverlay({
    super.key,
    required this.movie,
    this.retryAttempt = 0,
  });

  @override
  Widget build(BuildContext context) {
    final backdrop = movie.backdropUrl.isNotEmpty
        ? movie.backdropUrl
        : movie.posterUrl;

    return AnimatedSwitcher(
      duration: AppAnimations.slow,
      child: Container(
        key: const ValueKey('movie_loading_overlay'),
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Blurred backdrop ──
            if (backdrop.isNotEmpty)
              CachedNetworkImage(
                imageUrl: backdrop,
                fit: BoxFit.cover,
                fadeInDuration: AppAnimations.medium,
                errorWidget: (context, url, error) => const SizedBox.shrink(),
              ),
            if (backdrop.isNotEmpty)
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                child: Container(color: Colors.black.withValues(alpha: 0.55)),
              ),

            // ── Darkening vignette so text/poster stay legible ──
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.75),
                    Colors.black.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0.85),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),

            // ── Foreground content ──
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Poster with soft glow, framed like a marquee card
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 96,
                      height: 144,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.14),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.darkAccent.withValues(alpha: 0.18),
                            blurRadius: 30,
                            spreadRadius: -4,
                          ),
                        ],
                      ),
                      child: movie.posterUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: movie.posterUrl,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => Container(
                                color: AppTheme.darkBg3,
                                child: const Icon(
                                  Icons.movie_rounded,
                                  color: Colors.white24,
                                  size: 32,
                                ),
                              ),
                            )
                          : Container(
                              color: AppTheme.darkBg3,
                              child: const Icon(
                                Icons.movie_rounded,
                                color: Colors.white24,
                                size: 32,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  Text(
                    movie.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.syne(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 20),

                  const PivoteLoader(size: 34, strokeWidth: 3.2),
                  const SizedBox(height: 16),

                  Text(
                    retryAttempt > 0
                        ? 'Reintentando conexión ($retryAttempt)…'
                        : 'Preparando la reproducción…',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: retryAttempt > 0
                          ? AppTheme.darkWarning
                          : Colors.white54,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lightweight buffering indicator shown ON TOP of the frozen video frame
/// once playback has already started. Unlike [MovieLoadingOverlay], it never
/// hides the video — a professional player keeps the last frame visible and
/// just shows a small, unobtrusive spinner while it re-buffers.
class MovieBufferingSpinner extends StatelessWidget {
  const MovieBufferingSpinner({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: AnimatedOpacity(
          opacity: 1.0,
          duration: AppAnimations.fast,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              shape: BoxShape.circle,
            ),
            child: const PivoteLoader(size: 30, strokeWidth: 3),
          ),
        ),
      ),
    );
  }
}
