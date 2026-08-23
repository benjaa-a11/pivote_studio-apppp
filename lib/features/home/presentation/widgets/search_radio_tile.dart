import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pivote/features/radio/data/models/radio.dart' as radio_model;
import 'package:pivote/features/radio/presentation/providers/audio_manager.dart';
import 'package:pivote/features/radio/presentation/screens/radio_player_screen.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/core/services/image_cache_helper.dart';

class SearchRadioTile extends StatelessWidget {
  final radio_model.Radio radio;

  const SearchRadioTile({super.key, required this.radio});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.isDark;
    final audioManager = context.watch<AudioManager>();
    final isCurrent = audioManager.currentRadio?.id == radio.id;
    final isPlaying = isCurrent && audioManager.isPlaying;
    final isLoading = isCurrent && audioManager.isLoading;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  RadioPlayerScreen(radio: radio),
              transitionDuration: const Duration(milliseconds: 300),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position: animation.drive(
                    Tween(
                      begin: const Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).chain(CurveTween(curve: Curves.easeOutCubic)),
                  ),
                  child: child,
                );
              },
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark
                ? (isCurrent
                    ? theme.colorScheme.primary.withValues(alpha: 0.1)
                    : AppTheme.darkBg2.withValues(alpha: 0.7))
                : (isCurrent
                    ? theme.colorScheme.primary.withValues(alpha: 0.08)
                    : theme.colorScheme.surface),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCurrent
                  ? theme.colorScheme.primary.withValues(alpha: 0.4)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.07)
                      : Colors.black.withValues(alpha: 0.06)),
              width: isCurrent ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              // Radio Logo with glowing ring when playing
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isPlaying
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: radio.logoUrl.isNotEmpty
                          ? CachedNetworkImage(
                              key: ValueKey<String>(radio.logoUrl),
                              cacheManager: ImageCacheHelper.logoCacheManager,
                              imageUrl: radio.logoUrl,
                              fit: BoxFit.cover,
                              memCacheWidth: 120,
                              placeholder: (context, url) => Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Icon(
                                Icons.radio_rounded,
                                size: 24,
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.6),
                              ),
                            )
                          : Icon(
                              Icons.radio_rounded,
                              size: 24,
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.6),
                            ),
                    ),
                  ),
                  if (isPlaying)
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.graphic_eq_rounded,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),

              // Title and category
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      radio.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: isCurrent
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (radio.frequency.isNotEmpty) ...[
                          Text(
                            radio.frequency,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Text(
                            radio.category ?? 'Radio en Vivo',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Direct Play/Pause Quick Action Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => audioManager.playRadio(radio),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isPlaying
                          ? theme.colorScheme.primary
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.07)
                              : theme.colorScheme.primary
                                  .withValues(alpha: 0.08)),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isLoading
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: isPlaying
                                    ? Colors.white
                                    : theme.colorScheme.primary,
                              ),
                            )
                          : Icon(
                              isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              size: 22,
                              color: isPlaying
                                  ? Colors.white
                                  : theme.colorScheme.primary,
                            ),
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
}
