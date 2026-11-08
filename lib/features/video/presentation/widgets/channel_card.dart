import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:pivote/features/video/data/models/channel.dart';
import 'package:pivote/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:pivote/features/video/presentation/providers/channel_provider.dart';
import 'package:pivote/features/video/presentation/screens/player_screen.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/core/services/image_cache_helper.dart';
import 'package:pivote/shared/widgets/common/apple_pressable.dart';

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
        final theme = Theme.of(context);
        final isDark = theme.isDark;
        final isEvent = channel.type == 'evento' || channel.evento != null;
        final isFav = favoritesProvider.isFavorite(channel.id);

        return ApplePressable(
          scaleDownFactor: 0.96,
          borderRadius: BorderRadius.circular(AppRadius.card),
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
          child: Container(
            decoration: BoxDecoration(
              color: isEvent
                  ? AppColors.ink0
                  : (isDark ? AppTheme.darkCard : AppTheme.lightBg1),
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                color: isEvent
                    ? AppColors.gold.withValues(alpha: 0.85)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : AppTheme.lightBorder),
                width: isEvent ? 1.6 : 1.0,
              ),
              boxShadow: isEvent
                  ? [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.22),
                        blurRadius: 16,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : AppShadows.appleDepth(context, elevation: 0.7),
            ),
            child: Column(
              children: [
                // Zona superior: Escenario del logo
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isEvent
                          ? AppColors.ink1.withValues(alpha: 0.55)
                          : (isDark ? AppTheme.darkCard : AppTheme.lightBg2),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppRadius.card - 1),
                      ),
                    ),
                    child: Center(
                      child: Hero(
                        tag: 'channel_logo_${channel.id}',
                        child: _buildChannelLogo(context, isDark),
                      ),
                    ),
                  ),
                ),

                // Divisor sutil entre escenario y pie
                Container(
                  height: 1,
                  color: isEvent
                      ? AppColors.gold.withValues(alpha: 0.18)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : AppTheme.lightBorder.withValues(alpha: 0.7)),
                ),

                // Zona inferior: Nombre, categoría y favorito
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(12, 8.5, 12, 10),
                  decoration: BoxDecoration(
                    color: isEvent
                        ? AppColors.ink0
                        : (isDark ? AppTheme.darkBg1 : AppTheme.lightBg1),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(AppRadius.card - 1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        channel.name,
                        style: AppFont.primary(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          letterSpacing: -0.3,
                          height: 1.15,
                          color: isEvent
                              ? AppColors.gold
                              : theme.colorScheme.onSurface,
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
                                color: isEvent
                                    ? AppColors.slate400
                                    : AppTheme.textTertiary(context),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                height: 1.15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isFav)
                            const Icon(
                              Icons.favorite_rounded,
                              size: 14,
                              color: AppColors.live,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChannelLogo(BuildContext context, bool isDark) {
    final logoUrl = channel.getLogoUrl(isDark);

    if (logoUrl.isEmpty || !logoUrl.startsWith('http')) {
      return _buildPlaceholder(context, isDark);
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
      placeholder: (context, url) => _buildLoadingShimmer(context, isDark),
      errorWidget: (context, url, error) => _buildPlaceholder(context, isDark),
      fadeInDuration: const Duration(milliseconds: 220),
      fadeOutDuration: const Duration(milliseconds: 100),
      memCacheWidth: 200,
      memCacheHeight: 200,
      maxWidthDiskCache: 200,
      maxHeightDiskCache: 200,
    );
  }

  Widget _buildLoadingShimmer(BuildContext context, bool isDark) {
    return Shimmer.fromColors(
      baseColor: isDark ? AppTheme.darkBg3 : AppTheme.lightBg3,
      highlightColor: isDark ? AppTheme.darkBg4 : AppTheme.lightBg1,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context, bool isDark) {
    return Center(
      child: Icon(
        Icons.tv_rounded,
        size: 42,
        color: isDark ? AppTheme.darkText3 : AppTheme.lightText3,
      ),
    );
  }
}
