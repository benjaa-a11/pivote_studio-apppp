import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pivote/features/video/presentation/providers/channel_provider.dart';
import 'package:pivote/features/home/presentation/widgets/tv_hero_section.dart';
import 'package:pivote/features/home/presentation/widgets/tv_content_row.dart';
import 'package:pivote/features/shared/widgets/tv_card.dart';
import 'package:pivote/features/video/presentation/screens/player_screen.dart';
import 'package:pivote/features/video/data/models/channel.dart';

class TvHomeScreen extends StatelessWidget {
  const TvHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChannelProvider>(
      builder: (context, channelProvider, child) {
        if (channelProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final channels = channelProvider.allChannels;
        if (channels.isEmpty) {
          return _buildEmptyState(context);
        }

        // Featured Channel (Use the first one or logic to pick one)
        final featuredChannel = channels.first;

        // Get categories excluding 'Todos' if possible, or just raw categories
        final categories =
            channelProvider.categories.where((c) => c != 'Todos').toList();

        // Ensure "Deportes" or "General" comes first if available
        if (categories.contains('Deportes')) {
          categories.remove('Deportes');
          categories.insert(0, 'Deportes');
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Section
              TvHeroSection(
                channel: featuredChannel,
                onWatchNow: () => _navigateToPlayer(context, featuredChannel),
              ),

              const SizedBox(height: 20),

              // Recent / Popular (Mock logic using allChannels for now)
              TvContentRow(
                title: "Populares",
                items: channels.take(10).toList(),
                itemBuilder: (context, item, index) {
                  final channel = item as Channel;
                  return TvCard(
                    imageUrl: channel.getLogoUrl(
                        Theme.of(context).brightness == Brightness.dark),
                    title: channel.name,
                    subtitle: channel.category,
                    onTap: () => _navigateToPlayer(context, channel),
                  );
                },
              ),

              // Categories
              ...categories.map((category) {
                final categoryChannels =
                    channels.where((c) => c.category == category).toList();
                if (categoryChannels.isEmpty) return const SizedBox.shrink();

                return TvContentRow(
                  title: category,
                  items: categoryChannels,
                  itemBuilder: (context, item, index) {
                    final channel = item as Channel;
                    return TvCard(
                      imageUrl: channel.getLogoUrl(
                          Theme.of(context).brightness == Brightness.dark),
                      title: channel.name,
                      onTap: () => _navigateToPlayer(context, channel),
                      width: 180, // Slightly smaller for categories
                    );
                  },
                );
              }),

              const SizedBox(height: 50), // Bottom padding
            ],
          ),
        );
      },
    );
  }

  void _navigateToPlayer(BuildContext context, Channel channel) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayerScreen(channel: channel),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.tv_off,
              size: 64, color: Colors.white.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          const Text("No hay contenido disponible",
              style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
