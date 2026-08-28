import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
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

        return ApplePressable(
          scaleDownFactor: 0.95,
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Smart Sort: Registrar vista antes de navegar
            Provider.of<ChannelProvider>(context, listen: false)
                .recordView(channel);

            if (onTap != null) {
              onTap!();
            } else {
              Navigator.push(
                context,
                AppAnimations.createRoute(
                    PlayerScreen(channel: channel)),
              );
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: isEvent
                  ? const Color(0xFF0C0E12)
                  : (isDark ? AppTheme.darkCard : Colors.white),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isEvent
                    ? const Color(0xFFD4AF37)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06)),
                width: isEvent ? 1.8 : 1.0,
              ),
              boxShadow: isEvent
                  ? [
                      BoxShadow(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.25),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : AppShadows.appleDepth(context, elevation: 0.6),
            ),
            child: Column(
              children: [
                // Logo del canal
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isEvent
                          ? Colors.transparent
                          : (isDark
                              ? AppTheme.darkCard
                              : AppTheme.lightBg2),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(15),
                      ),
                    ),
                    child: Center(
                      child: _buildChannelLogo(context, isDark),
                    ),
                  ),
                ),
                // Info del canal
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                  decoration: BoxDecoration(
                    color: isEvent
                        ? const Color(0xFF07080A)
                        : (isDark
                            ? theme.scaffoldBackgroundColor
                            : AppTheme.lightBg1),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(15),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        channel.name,
                        style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          letterSpacing: -0.3,
                          color: isEvent
                              ? const Color(0xFFD4AF37)
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
                              style: GoogleFonts.spaceGrotesk(
                                color: isEvent
                                    ? Colors.white70
                                    : (isDark
                                        ? AppTheme.darkText3
                                        : AppTheme.lightText3),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Favorite indicator
                          if (favoritesProvider.isFavorite(channel.id))
                            const Icon(
                              Icons.favorite_rounded,
                              size: 14,
                              color: Colors.redAccent,
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
      placeholder: (context, url) => _buildLoadingShimmer(context),
      errorWidget: (context, url, error) => _buildPlaceholder(context),
      fadeInDuration: const Duration(milliseconds: 250),
      fadeOutDuration: const Duration(milliseconds: 100),
      memCacheWidth: 200,
      memCacheHeight: 200,
      maxWidthDiskCache: 200,
      maxHeightDiskCache: 200,
    );
  }

  Widget _buildLoadingShimmer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[850]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[800]! : Colors.grey[100]!,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Icon(
        Icons.tv_rounded,
        size: 48,
        color: isDark ? Colors.grey[700] : Colors.grey[400],
      ),
    );
  }
}
