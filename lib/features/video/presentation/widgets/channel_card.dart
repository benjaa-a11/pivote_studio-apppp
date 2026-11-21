import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/core/services/image_cache_helper.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:pivote/features/video/data/models/channel.dart';
import 'package:pivote/features/video/presentation/providers/channel_provider.dart';
import 'package:pivote/features/video/presentation/screens/player_screen.dart';
import 'package:pivote/shared/widgets/common/loading_shimmer.dart';
import 'package:pivote/shared/widgets/common/pivote_surfaces.dart';

class ChannelCard extends StatelessWidget {
  final Channel channel;
  final VoidCallback? onTap;

  const ChannelCard({
    super.key,
    required this.channel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoritesProvider>(
      builder: (context, favoritesProvider, child) {
        final isDark = AppTheme.isDark(context);
        final isEvent = channel.type == 'evento' || channel.evento != null;
        final isFav = favoritesProvider.isFavorite(channel.id);
        final accent = AppTheme.accent(context);
        final danger = AppTheme.danger(context);

        return PivoteDiffusedCard(
          borderRadius: AppRadius.card,
          glowColor: isEvent ? accent : accent,
          glowAlignment: const Alignment(0.0, -0.75),
          glowRadius: 1.05,
          glowOpacity: isEvent ? 1.45 : 0.72,
          highlighted: isEvent,
          onTap: () {
            Provider.of<ChannelProvider>(context, listen: false)
                .recordView(channel);

            if (onTap != null) {
              onTap!();
            } else {
              Navigator.push(
                context,
                AppAnimations.createRoute(PlayerScreen(channel: channel)),
              );
            }
          },
          child: Column(
            children: [
              // Zona superior: escenario difuminado del logo
              Expanded(
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Center(
                        child: Hero(
                          tag: 'channel_logo_${channel.id}',
                          child: _buildChannelLogo(context, isDark),
                        ),
                      ),
                    ),
                    if (isEvent)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accentDim(context),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.40),
                            ),
                          ),
                          child: Text(
                            'EVENTO',
                            style: AppFont.mono(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              color: accent,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Divisor hairline 1px estilo MatchesHero
              Divider(
                height: 1,
                thickness: 1,
                color: AppTheme.border(context),
              ),

              // Zona inferior: nombre, categoría y favorito
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
                color: isDark
                    ? AppColors.darkBg1.withValues(alpha: 0.55)
                    : AppColors.lightBg1.withValues(alpha: 0.85),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      channel.name,
                      style: AppFont.primary(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        letterSpacing: -0.25,
                        height: 1.15,
                        color: isEvent ? accent : AppTheme.textPrimary(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            channel.category,
                            style: AppFont.primary(
                              color: AppTheme.textTertiary(context),
                              fontSize: 11.2,
                              fontWeight: FontWeight.w600,
                              height: 1.15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isFav)
                          Icon(
                            Icons.favorite_rounded,
                            size: 13.5,
                            color: danger,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChannelLogo(BuildContext context, bool isDark) {
    final logoUrl = channel.getLogoUrl(isDark);

    if (logoUrl.isEmpty || !logoUrl.startsWith('http')) {
      return _buildPlaceholder(context);
    }

    return CachedNetworkImage(
      key: ValueKey<String>(logoUrl),
      cacheManager: ImageCacheHelper.logoCacheManager,
      imageUrl: logoUrl,
      fit: BoxFit.contain,
      alignment: Alignment.center,
      filterQuality: FilterQuality.medium,
      imageBuilder: (context, imageProvider) => Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: imageProvider,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ),
      placeholder: (context, url) => const PivoteShimmer(
        child: PivoteShimmerBone(
          width: 66,
          height: 34,
          borderRadius: AppRadius.xs,
        ),
      ),
      errorWidget: (context, url, error) => _buildPlaceholder(context),
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 100),
      memCacheWidth: 200,
      memCacheHeight: 200,
      maxWidthDiskCache: 200,
      maxHeightDiskCache: 200,
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Center(
      child: Icon(
        Icons.tv_rounded,
        size: 36,
        color: AppTheme.textTertiary(context),
      ),
    );
  }
}
