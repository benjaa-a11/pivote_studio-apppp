import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pivote/features/profile/presentation/widgets/profile_design_system.dart';
import 'package:pivote/features/radio/data/models/radio.dart' as radio_model;
import 'package:pivote/features/radio/presentation/providers/audio_manager.dart';
import 'package:pivote/features/radio/presentation/providers/radio_provider.dart';
import 'package:pivote/features/radio/presentation/screens/radio_player_screen.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/core/services/image_cache_helper.dart';

class SearchRadioTile extends StatefulWidget {
  final radio_model.Radio radio;

  const SearchRadioTile({super.key, required this.radio});

  @override
  State<SearchRadioTile> createState() => _SearchRadioTileState();
}

class _SearchRadioTileState extends State<SearchRadioTile> {
  bool _pressed = false;

  void _openPlayer(BuildContext context) {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      AppAnimations.slideUpTransition(RadioPlayerScreen(radio: widget.radio)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = ProfilePalette.of(context);
    final audioManager = context.watch<AudioManager>();
    final radioProvider = context.watch<RadioProvider>();
    final radio = widget.radio;

    final isCurrent = audioManager.currentRadio?.id == radio.id;
    final isPlaying = isCurrent && audioManager.isPlaying;
    final isLoading = isCurrent && audioManager.isLoading;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () => _openPlayer(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _pressed ? palette.cardPressed : palette.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isCurrent ? palette.text : palette.border,
            width: isCurrent ? 1.5 : 1.0,
          ),
          boxShadow: palette.cardShadow,
        ),
        child: Row(
          children: [
            // Station Logo Box (46x46, radius 14, iconBox background)
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: palette.iconBox,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: palette.border,
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Hero(
                  tag: 'radio_tile_logo_${radio.id}',
                  child: radio.logoUrl.isNotEmpty
                      ? CachedNetworkImage(
                          key: ValueKey<String>(radio.logoUrl),
                          cacheManager: ImageCacheHelper.logoCacheManager,
                          imageUrl: radio.logoUrl,
                          fit: BoxFit.cover,
                          memCacheWidth: 120,
                          placeholder: (context, url) => Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: palette.muted,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Icon(
                            Icons.radio_rounded,
                            size: 22,
                            color: palette.muted,
                          ),
                        )
                      : Icon(
                          Icons.radio_rounded,
                          size: 22,
                          color: palette.muted,
                        ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Station Name + Subtitle (Frequency • Category)
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
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                            color: palette.text,
                          ),
                        ),
                      ),
                      if (isPlaying) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFF3FD1A0),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    [
                      if (radio.frequency.isNotEmpty) radio.frequency,
                      radio.category ?? 'Radio en vivo',
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w400,
                      color: palette.muted,
                    ),
                  ),
                ],
              ),
            ),

            // Favorite Toggle Button
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
                  color: radio.isFavorite
                      ? const Color(0xFFEF4444)
                      : palette.chevron,
                ),
              ),
            ),
            const SizedBox(width: 4),

            // Play / Equalizer Button (38x38)
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isPlaying ? palette.primaryBtnBg : palette.iconBox,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: isLoading
                  ? SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isPlaying
                            ? palette.primaryBtnText
                            : palette.text,
                      ),
                    )
                  : Icon(
                      isPlaying
                          ? Icons.graphic_eq_rounded
                          : Icons.play_arrow_rounded,
                      size: 20,
                      color: isPlaying ? palette.primaryBtnText : palette.text,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
