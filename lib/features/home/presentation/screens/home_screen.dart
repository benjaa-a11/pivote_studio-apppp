import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:pivote/features/video/presentation/providers/channel_provider.dart';
import 'package:pivote/features/video/presentation/widgets/channel_card.dart';
import 'package:pivote/features/home/presentation/widgets/unified_home_header.dart';
import 'package:pivote/features/home/presentation/widgets/quick_access_row.dart';
import 'package:pivote/features/home/presentation/widgets/category_chips_row.dart';
import 'package:pivote/features/home/presentation/widgets/home_favorites_row.dart';
import 'package:pivote/features/video/data/models/channel.dart';
import 'package:pivote/core/theme/app_tokens.dart';

class HomeScreen extends StatelessWidget {
  /// Lets Inicio jump to another bottom-nav tab (Fútbol/Películas/Radio)
  /// from the discovery row. Optional so HomeScreen still works standalone
  /// (e.g. in tests) if no navigation host is wired up.
  final void Function(int tabIndex)? onNavigateToTab;

  const HomeScreen({super.key, this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const ClampingScrollPhysics(),
          slivers: [
            // Unified Premium Header (Greeting, Search Button, and Matches Carousel/Banner)
            const SliverToBoxAdapter(
              child: UnifiedHomeHeader(),
            ),

            // Discovery row: Fútbol / Películas / Radio with live data
            SliverToBoxAdapter(
              child: QuickAccessRow(
                onNavigateToTab: onNavigateToTab ?? (_) {},
              ),
            ),

            // Category filter chips (only shows once channels are loaded)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: AppSpacing.sm),
                child: CategoryChipsRow(),
              ),
            ),

            // Favorites row (hides itself if there are none)
            const SliverToBoxAdapter(
              child: HomeFavoritesRow(),
            ),

            // Section title, reacts to the active category filter
            SliverToBoxAdapter(
              child: Consumer<ChannelProvider>(
                builder: (context, provider, child) {
                  return _buildSectionTitle(theme, provider.selectedCategory);
                },
              ),
            ),

            // Grid de canales
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
              sliver: Consumer<ChannelProvider>(
                builder: (context, channelProvider, child) {
                  final isLoading = channelProvider.isLoading;
                  final channels = isLoading
                      ? List.generate(
                          8,
                          (index) => Channel(
                                id: 'dummy',
                                name: 'Channel Name',
                                logoUrl: [''],
                                streamUrl: [StreamSource(url: '')],
                                category: 'General',
                                description: 'Description',
                              ))
                      : channelProvider.channels;

                  if (!isLoading && channels.isEmpty) {
                    return SliverToBoxAdapter(
                      child: _buildEmptyState(context, channelProvider),
                    );
                  }

                  return SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.05,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final card = ChannelCard(channel: channels[index]);
                        return Skeletonizer(
                          enabled: isLoading,
                          child: card,
                        );
                      },
                      childCount: channels.length,
                    ),
                  );
                },
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String selectedCategory) {
    final title =
        selectedCategory == 'Todos' ? 'Todos los canales' : selectedCategory;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
      child: Text(
        title,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: theme.colorScheme.onSurface,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  Widget _buildEmptyState(
      BuildContext context, ChannelProvider channelProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.15),
                    Theme.of(context)
                        .colorScheme
                        .secondary
                        .withValues(alpha: 0.15),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.tv_off_rounded,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'No se encontraron canales',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Intenta ajustar tus filtros o realiza\nuna nueva búsqueda',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                    height: 1.5,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                channelProvider.clearFilters();
              },
              icon: const Icon(Icons.refresh_rounded, size: 22),
              label: const Text('Limpiar filtros'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
