import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/core/services/image_cache_helper.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/features/radio/data/models/radio.dart' as radio_model;
import 'package:pivote/features/radio/presentation/providers/audio_manager.dart';
import 'package:pivote/features/radio/presentation/providers/radio_provider.dart';
import 'package:pivote/features/radio/presentation/screens/radio_player_screen.dart';
import 'package:pivote/shared/widgets/common/loading_shimmer.dart';
import 'package:pivote/shared/widgets/common/pivote_loader.dart';
import 'package:pivote/shared/widgets/common/pivote_surfaces.dart';

class SearchRadioTile extends StatelessWidget {
  final radio_model.Radio radio;

  const SearchRadioTile({super.key, required this.radio});

  void _openPlayer(BuildContext context) {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      AppAnimations.slideUpTransition(RadioPlayerScreen(radio: radio)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final audioManager = context.watch<AudioManager>();
    final radioProvider = context.watch<RadioProvider>();
    final accent = AppTheme.accent(context);
    final onAccent = AppTheme.onAccent(context);
    final danger = AppTheme.danger(context);

    final isCurrent = audioManager.currentRadio?.id == radio.id;
    final isPlaying = isCurrent && audioManager.isPlaying;
    final isLoading = isCurrent && audioManager.isLoading;

    return PivoteDiffusedCard(
      borderRadius: AppRadius.card,
      glowColor: accent,
      glowAlignment: const Alignment(-0.88, 0.0),
      glowOpacity: isCurrent ? 1.45 : 0.55,
      highlighted: isCurrent,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      onTap: () => _openPlayer(context),
      child: Row(
        children: [
          // Artwork de la emisora
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.surface2(context),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: isCurrent
                    ? accent.withValues(alpha: 0.45)
                    : AppTheme.border(context),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm - 1),
              child: Hero(
                tag: 'radio_tile_logo_${radio.id}',
                child: radio.logoUrl.isNotEmpty
                    ? CachedNetworkImage(
                        key: ValueKey<String>(radio.logoUrl),
                        cacheManager: ImageCacheHelper.logoCacheManager,
                        imageUrl: radio.logoUrl,
                        fit: BoxFit.cover,
                        memCacheWidth: 120,
                        placeholder: (_, __) => const PivoteShimmer(
                          child: PivoteShimmerBone(
                            width: 48,
                            height: 48,
                            borderRadius: AppRadius.sm,
                          ),
                        ),
                        errorWidget: (_, __, ___) => Icon(
                          Icons.radio_rounded,
                          size: 22,
                          color: AppTheme.textTertiary(context),
                        ),
                      )
                    : Icon(
                        Icons.radio_rounded,
                        size: 22,
                        color: AppTheme.textTertiary(context),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        radio.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFont.primary(
                          fontSize: 14.8,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: isCurrent
                              ? accent
                              : AppTheme.textPrimary(context),
                        ),
                      ),
                    ),
                    if (isPlaying) ...[
                      const SizedBox(width: 7),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3.5),
                Row(
                  children: [
                    if (radio.frequency.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? AppTheme.accentDim(context)
                              : AppTheme.surface2(context),
                          borderRadius: BorderRadius.circular(AppRadius.xxs),
                        ),
                        child: Text(
                          radio.frequency,
                          style: AppFont.mono(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: isCurrent
                                ? accent
                                : AppTheme.textSecondary(context),
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                    ],
                    Expanded(
                      child: Text(
                        radio.category ?? 'Radio en vivo',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFont.primary(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textTertiary(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.selectionClick();
              radioProvider.toggleFavorite(radio);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Icon(
                radio.isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                size: 19,
                color: radio.isFavorite ? danger : AppTheme.textTertiary(context),
              ),
            ),
          ),
          const SizedBox(width: 4),
          AnimatedContainer(
            duration: AppMotion.fast,
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isPlaying ? accent : AppTheme.surface2(context),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: isPlaying ? accent : AppTheme.border(context),
              ),
            ),
            alignment: Alignment.center,
            child: isLoading
                ? PivoteLoader(
                    size: 16,
                    strokeWidth: 2,
                    color: isPlaying ? onAccent : accent,
                  )
                : Icon(
                    isPlaying
                        ? Icons.graphic_eq_rounded
                        : Icons.play_arrow_rounded,
                    size: 20,
                    color: isPlaying ? onAccent : AppTheme.textPrimary(context),
                  ),
          ),
        ],
      ),
    );
  }
}
