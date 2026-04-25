import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pivote/features/video/presentation/providers/channel_provider.dart';
import 'package:pivote/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:pivote/features/video/presentation/widgets/channel_card.dart';
import 'package:pivote/shared/widgets/common/app_dialogs.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pivote/shared/widgets/common/pivote_loader.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Consumer2<ChannelProvider, FavoritesProvider>(
          builder: (context, channelProvider, favoritesProvider, child) {
            final favoriteChannels = favoritesProvider.getSortedFavorites(
              channelProvider.allChannels,
            );

            return CustomScrollView(
              physics: const ClampingScrollPhysics(),
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: _buildHeader(context, theme, isDark, favoritesProvider,
                      favoriteChannels.length),
                ),

                // Content
                if (favoriteChannels.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(context, theme, isDark),
                  )
                else ...[
                  // Stats bar
                  SliverToBoxAdapter(
                    child: _buildStatsBar(
                        context, theme, isDark, favoriteChannels.length),
                  ),

                  // Channel grid
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.05,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return ChannelCard(
                            channel: favoriteChannels[index],
                          );
                        },
                        childCount: favoriteChannels.length,
                      ),
                    ),
                  ),

                  // Sync indicator
                  if (favoritesProvider.isSyncing)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: PivoteLoader(
                                strokeWidth: 1.5,
                                color: theme.hintColor.withValues(alpha: 0.3),
                                size: 12,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Sincronizando...',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: theme.hintColor.withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Footer
                  SliverToBoxAdapter(
                    child: _buildFooter(theme),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme, bool isDark,
      FavoritesProvider favoritesProvider, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 4),
      child: Row(
        children: [
          // Icon
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.15),
                  theme.colorScheme.primary.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.favorite_rounded,
              size: 18,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Favoritos',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (count > 0)
                  Text(
                    'Tu colección personal',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.hintColor,
                    ),
                  ),
              ],
            ),
          ),
          // Delete button
          if (count > 0)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showClearDialog(context, favoritesProvider),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.error.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: theme.colorScheme.error.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsBar(
      BuildContext context, ThemeData theme, bool isDark, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
      child: Row(
        children: [
          // Count chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.stars_rounded,
                  size: 13,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  '$count ${count == 1 ? 'canal' : 'canales'}',
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Sort indicator
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sort_rounded,
                  size: 14, color: theme.hintColor.withValues(alpha: 0.4)),
              const SizedBox(width: 4),
              Text(
                'Recientes primero',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: theme.hintColor.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Decorative icon
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: 0.03),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.04),
                ),
              ),
              child: Icon(
                Icons.favorite_border_rounded,
                size: 56,
                color: theme.hintColor.withValues(alpha: 0.2),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Sin favoritos aún',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Mantén presionado cualquier canal o toca el ícono de corazón para agregarlo aquí.',
              style: GoogleFonts.spaceGrotesk(
                color: theme.hintColor,
                fontSize: 13,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            // Explore button
            SizedBox(
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () {
                  try {
                    DefaultTabController.of(context).animateTo(0);
                  } catch (e) {
                    // Fallback
                  }
                },
                icon: const Icon(Icons.explore_rounded, size: 18),
                label: Text(
                  'Explorar canales',
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: isDark ? AppTheme.darkBg : Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 30,
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      theme.dividerColor.withValues(alpha: 0.12),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.favorite_rounded,
                    size: 10, color: theme.hintColor.withValues(alpha: 0.15)),
              ),
              Container(
                width: 30,
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.dividerColor.withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Sincronizado con tu cuenta',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: theme.hintColor.withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearDialog(
      BuildContext context, FavoritesProvider favoritesProvider) async {
    final theme = Theme.of(context);
    final confirmed = await AppDialogs.showConfirm(
      context: context,
      title: '¿Limpiar favoritos?',
      message:
          'Esta acción eliminará todos los canales de tu lista de acceso rápido.',
      confirmLabel: 'Eliminar',
      cancelLabel: 'Cancelar',
      isDestructive: true,
      type: AppDialogType.error,
    );

    if (confirmed == true) {
      await favoritesProvider.clearAllFavorites();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Text(
                  'Lista de favoritos limpia',
                  style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: theme.colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }
}
