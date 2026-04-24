import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:pivote/features/video/presentation/providers/channel_provider.dart';
import 'package:pivote/features/video/presentation/widgets/channel_card.dart';
import 'package:pivote/features/home/presentation/widgets/search_header.dart';
import 'package:pivote/features/soccer/presentation/widgets/matches_hero.dart';
import 'package:pivote/features/video/data/models/channel.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const ClampingScrollPhysics(),
          slivers: [
            // Floating Search Header
            SliverAppBar(
              floating: true,
              snap: true,
              elevation: 0,
              backgroundColor: theme.scaffoldBackgroundColor,
              automaticallyImplyLeading: false,
              toolbarHeight: 65,
              flexibleSpace: const FlexibleSpaceBar(
                background: SearchHeader(),
              ),
            ),

            // Hero de partidos
            const SliverToBoxAdapter(
              child: MatchesHero(),
            ),

            // Grid de canales
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
