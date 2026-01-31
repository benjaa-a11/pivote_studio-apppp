import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../models/radio.dart' as model;
import '../providers/radio_provider.dart';
import '../providers/audio_manager.dart';
import '../config/app_animations.dart';
import 'radio_player_screen.dart';
import 'package:just_audio/just_audio.dart';

class RadiosScreen extends StatefulWidget {
  const RadiosScreen({super.key});

  @override
  State<RadiosScreen> createState() => _RadiosScreenState();
}

class _RadiosScreenState extends State<RadiosScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            _buildFilters(context),
            Expanded(
              child: _buildStationList(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                  ),
                  image: const DecorationImage(
                    image: CachedNetworkImageProvider(
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuBeZBVApXA4Kn_nPhRbesiswLugllFqjCiSNCE2rgAhnhLSB7_PBBO4c2RMxP5vktIAm3hJr-8swvSv0FAe33wZxm3StSXsyPrBXtW3PTReju-hN50ydr0_IZNuwOZIZnFAeUBdCYrzfWkO1tzL78aL6ssmKhPcr1e2tYoWnAdWSSPQ7GdHeXLoz_ZPcHl0wOo5Bu3ZOINYpaJJjKZaIewAFx0sVvw6OcJpPhhsv45rxVzpOPYNIPSpAXsIaDHyKl9II_h59cWjXvHB',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() => _isSearching = !_isSearching);
                  if (!_isSearching) {
                    _searchController.clear();
                    context.read<RadioProvider>().searchStations('');
                  }
                },
                icon: Icon(
                  _isSearching ? Icons.close : Icons.search,
                  color: theme.colorScheme.onSurface,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_isSearching)
            AppAnimations.smoothFadeIn(
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Buscar emisora...',
                  hintStyle: theme.textTheme.bodyMedium,
                  filled: true,
                  fillColor:
                      theme.colorScheme.onSurface.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                onChanged: (value) =>
                    context.read<RadioProvider>().searchStations(value),
              ),
            )
          else
            Text(
              'Emisoras',
              style: theme.textTheme.displayLarge,
            ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    final radioProvider = context.watch<RadioProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 45,
      margin: const EdgeInsets.only(bottom: 24),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: radioProvider.categories.length,
        itemBuilder: (context, index) {
          final category = radioProvider.categories[index];
          final isSelected = radioProvider.selectedCategory == category;

          return AnimatedContainer(
            duration: AppAnimations.fast,
            margin: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () => radioProvider.setCategory(category),
              borderRadius: BorderRadius.circular(25),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.1),
                  ),
                ),
                child: Center(
                  child: Text(
                    category.toUpperCase(),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: isSelected
                          ? (isDark ? Colors.white : Colors.white)
                          : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 10,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStationList(BuildContext context) {
    final radioProvider = context.watch<RadioProvider>();
    final theme = Theme.of(context);

    if (radioProvider.isLoading) {
      return _buildSkeletonList();
    }

    if (radioProvider.error != null) {
      return Center(
        child: Text(
          radioProvider.error!,
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    if (radioProvider.stations.isEmpty) {
      return Center(
        child: Text(
          'No se encontraron emisoras',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
      itemCount: radioProvider.stations.length,
      separatorBuilder: (context, index) => const SizedBox(height: 24),
      itemBuilder: (context, index) {
        final station = radioProvider.stations[index];
        return AppAnimations.staggeredListItem(
          index: index,
          child: _StationRow(station: station),
        );
      },
    );
  }

  Widget _buildSkeletonList() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: 5,
      separatorBuilder: (context, index) => const SizedBox(height: 24),
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.05),
        highlightColor: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.1),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 150,
                    height: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 100,
                    height: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StationRow extends StatelessWidget {
  final model.Radio station;

  const _StationRow({required this.station});

  @override
  Widget build(BuildContext context) {
    final audioManager = context.watch<AudioManager>();
    final isPlaying = audioManager.currentStation?.id == station.id;

    return StreamBuilder<PlayerState>(
      stream: audioManager.playerStateStream,
      builder: (context, snapshot) {
        final actualPlaying = isPlaying && (snapshot.data?.playing ?? false);
        final isLoading = isPlaying &&
            snapshot.data?.processingState == ProcessingState.loading;

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RadioPlayerScreen(station: station),
              ),
            );
          },
          child: Row(
            children: [
              _buildLogo(),
              const SizedBox(width: 20),
              _buildInfo(),
              _buildActions(context, actualPlaying, isLoading),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogo() {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1a1a1a) : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: station.logoUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
              ),
              errorWidget: (context, url, error) => Icon(
                Icons.radio,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfo() {
    return Expanded(
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                station.name,
                style: theme.textTheme.titleLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                station.frequency,
                style: theme.textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActions(BuildContext context, bool isPlaying, bool isLoading) {
    final audioManager = context.read<AudioManager>();
    final theme = Theme.of(context);

    return Row(
      children: [
        IconButton(
          onPressed: () {
            // Favoritos logic (placeholder for now as per user request to keep filters)
            // But we can integrate it with a simple notification
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Función de favoritos próximamente')),
            );
          },
          icon: Icon(
            Icons.favorite_border,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            size: 20,
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: () =>
              isPlaying ? audioManager.pause() : audioManager.play(station),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onSurface,
                      ),
                    )
                  : Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: theme.colorScheme.onSurface,
                      size: 24,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
