import 'package:flutter/material.dart';
import '../../data/models/vod_content.dart';
import '../widgets/vod_player_widget.dart';

class ContentDetailsScreen extends StatelessWidget {
  final VodContent content;

  const ContentDetailsScreen({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context),
          _buildContentInfo(context),
          if (content is Series) _buildSeasonsList(context, content as Series),
          if (content is Movie || content is Program) _buildPlayButton(context),
          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 400,
      pinned: true,
      backgroundColor: const Color(0xFF0F172A),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              content.backdropUrl ?? content.posterUrl ?? '',
              fit: BoxFit.cover,
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0xFF0F172A),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildContentInfo(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    content.year?.toString() ?? '2024',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  content.rating?.toString() ?? '8.5',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              content.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              content.genres.join(' • '),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Sinopsis',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              content.description ?? 'Sin descripción disponible.',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayButton(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: ElevatedButton.icon(
          onPressed: () => _playContent(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 8,
            shadowColor:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
          icon: const Icon(Icons.play_arrow_rounded, size: 28),
          label: const Text(
            'REPRODUCIR AHORA',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
        ),
      ),
    );
  }

  Widget _buildSeasonsList(BuildContext context, Series series) {
    if (series.seasons.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'No hay temporadas disponibles.',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final season = series.seasons[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                child: Text(
                  season.displayTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...season.episodes
                  .map((episode) => _buildEpisodeTile(context, episode)),
            ],
          );
        },
        childCount: series.seasons.length,
      ),
    );
  }

  Widget _buildEpisodeTile(BuildContext context, Episode episode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 100,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image:
                  NetworkImage(episode.thumbnailUrl ?? content.posterUrl ?? ''),
              fit: BoxFit.cover,
            ),
          ),
          child: const Center(
            child:
                Icon(Icons.play_circle_outline, color: Colors.white, size: 32),
          ),
        ),
        title: Text(
          'E${episode.episodeNumber} - ${episode.title}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          episode.durationMinutes != null
              ? '${episode.durationMinutes} min'
              : 'HD',
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        onTap: () => _playContent(context, episode: episode),
      ),
    );
  }

  void _playContent(BuildContext context, {Episode? episode}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          body: VodPlayerWidget(
            content: content,
            episode: episode,
          ),
        ),
      ),
    );
  }
}
