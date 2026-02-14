import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pivote/features/video/data/models/channel.dart';

class TvHeroSection extends StatefulWidget {
  final Channel channel;
  final VoidCallback onWatchNow;

  const TvHeroSection({
    super.key,
    required this.channel,
    required this.onWatchNow,
  });

  @override
  State<TvHeroSection> createState() => _TvHeroSectionState();
}

class _TvHeroSectionState extends State<TvHeroSection> {
  final FocusNode _watchButtonFocus = FocusNode();
  bool _isWatchFocused = false;

  @override
  void initState() {
    super.initState();
    _watchButtonFocus.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _watchButtonFocus.removeListener(_onFocusChange);
    _watchButtonFocus.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isWatchFocused = _watchButtonFocus.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      height: size.height * 0.65,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image (Blurred or Darkened)
          CachedNetworkImage(
            imageUrl: widget.channel
                .getLogoUrl(isDark), // Ideally this would be a backdrop image
            fit: BoxFit.cover,
            color: Colors.black.withValues(alpha: 0.7),
            colorBlendMode: BlendMode.darken,
            errorWidget: (context, url, error) =>
                Container(color: Colors.black),
          ),

          // Gradient Overlay
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black87,
                  Colors.black,
                ],
                stops: [0.0, 0.6, 1.0],
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Tag / Category
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.channel.category.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  widget.channel.name,
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      const Shadow(
                        blurRadius: 10,
                        color: Colors.black,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Description
                SizedBox(
                  width: size.width * 0.5,
                  child: Text(
                    widget.channel.description.isNotEmpty
                        ? widget.channel.description
                        : "Disfruta de la mejor programación en vivo. Noticias, deportes, entretenimiento y más en un solo lugar.",
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 32),

                // Actions
                Row(
                  children: [
                    // Watch Now Button
                    ElevatedButton.icon(
                      focusNode: _watchButtonFocus,
                      onPressed: widget.onWatchNow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isWatchFocused
                            ? Colors.white
                            : theme.colorScheme.primary,
                        foregroundColor:
                            _isWatchFocused ? Colors.black : Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        elevation: _isWatchFocused ? 10 : 2,
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, size: 28),
                      label: const Text(
                        "VER AHORA",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
