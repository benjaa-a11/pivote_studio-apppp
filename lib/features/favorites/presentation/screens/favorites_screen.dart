import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:pivote/features/video/presentation/providers/channel_provider.dart';
import 'package:pivote/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:pivote/features/video/presentation/widgets/channel_card.dart';
import 'package:pivote/shared/widgets/common/app_dialogs.dart';
import 'package:google_fonts/google_fonts.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                // Floating Header
                SliverAppBar(
                  floating: true,
                  snap: true,
                  elevation: 0,
                  backgroundColor: theme.scaffoldBackgroundColor,
                  automaticallyImplyLeading: false,
                  centerTitle: false,
                  titleSpacing: 20,
                  title: Text(
                    'Favoritos',
                    style: GoogleFonts.montserrat(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  actions: [
                    if (favoriteChannels.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFE7714D)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: const Color(0xFFE7714D)
                                        .withValues(alpha: 0.2)),
                              ),
                              child: IconButton(
                                onPressed: () => _showClearDialog(
                                    context, favoritesProvider),
                                icon: const Icon(Icons.delete_outline_rounded,
                                    color: Color(0xFFE7714D)),
                                padding: EdgeInsets.zero,
                                tooltip: 'Limpiar favoritos',
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                if (favoriteChannels.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(context),
                  )
                else ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    sliver: SliverToBoxAdapter(
                      child: _buildCounter(context, favoriteChannels.length),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.05,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
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
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCounter(BuildContext context, int count) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.stars_rounded,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              '$count ${count == 1 ? 'CANAL' : 'CANALES'}',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_rounded,
                size: 72,
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Aún no tienes favoritos',
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Agrega tus canales preferidos para acceder rápidamente a ellos en cualquier momento.',
              style: GoogleFonts.montserrat(
                color: isDark ? Colors.grey[500] : Colors.grey[600],
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                try {
                  DefaultTabController.of(context).animateTo(0);
                } catch (e) {
                  // Fallback
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                'EXPLORAR CANALES',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
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
            content: Text(
              'Lista de favoritos limpia',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
            ),
            backgroundColor: theme.colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }
}
