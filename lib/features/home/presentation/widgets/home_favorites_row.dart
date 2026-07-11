import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:pivote/features/video/presentation/providers/channel_provider.dart';
import 'package:pivote/features/video/presentation/widgets/channel_card.dart';

/// "Tus favoritos" row — only renders when the user actually has favorite
/// channels. Reuses ChannelCard untouched, just wrapped to a fixed width
/// for horizontal scrolling.
class HomeFavoritesRow extends StatelessWidget {
  const HomeFavoritesRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<FavoritesProvider, ChannelProvider>(
      builder: (context, favoritesProvider, channelProvider, child) {
        final favorites =
            favoritesProvider.getSortedFavorites(channelProvider.allChannels);

        if (favorites.isEmpty) return const SizedBox.shrink();

        final theme = Theme.of(context);
        final isDark = theme.isDark;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
              child: Row(
                children: [
                  Icon(Icons.favorite_rounded,
                      size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Tus favoritos',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${favorites.length}',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppTheme.darkText3 : AppTheme.lightText3,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 148,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: favorites.length,
                separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
                itemBuilder: (context, index) {
                  return SizedBox(
                    width: 130,
                    child: ChannelCard(channel: favorites[index]),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
