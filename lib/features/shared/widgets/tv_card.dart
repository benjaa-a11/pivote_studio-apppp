import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class TvCard extends StatefulWidget {
  final String imageUrl;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final double width;
  final double aspectRatio;
  final bool isLive;

  const TvCard({
    super.key,
    required this.imageUrl,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.width = 200,
    this.aspectRatio = 16 / 9,
    this.isLive = false,
  });

  @override
  State<TvCard> createState() => _TvCardState();
}

class _TvCardState extends State<TvCard> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Scale animation factor
    final scale = _isFocused ? 1.1 : 1.0;

    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: _isFocused ? 20 : 10,
          vertical: 10), // Extra padding for scale
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Container
          InkWell(
            onTap: widget.onTap,
            focusNode: _focusNode,
            borderRadius: BorderRadius.circular(12),
            child: AnimatedScale(
              scale: scale,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: Container(
                width: widget.width,
                height: widget.width / widget.aspectRatio,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _isFocused
                      ? [
                          BoxShadow(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.4),
                            blurRadius: 15,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          )
                        ],
                  border: _isFocused
                      ? Border.all(color: theme.colorScheme.primary, width: 2)
                      : Border.all(color: Colors.transparent, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                      10), // Slightly smaller than container for border
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: widget.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: Colors.grey[800]!,
                          highlightColor: Colors.grey[700]!,
                          child: Container(color: Colors.black),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[900],
                          child: const Icon(Icons.broken_image,
                              color: Colors.grey),
                        ),
                      ),

                      // Gradient overlay for text readability if title is ON the image (optional)
                      // For now, we put title below, but a subtle gradient always looks nice
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black26,
                            ],
                            stops: [0.7, 1.0],
                          ),
                        ),
                      ),

                      if (widget.isLive)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'LIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Title Area
          SizedBox(
            width: widget.width,
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: theme.textTheme.bodyMedium!.copyWith(
                fontWeight: _isFocused ? FontWeight.bold : FontWeight.normal,
                color: _isFocused
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: _isFocused ? 14 : 13,
              ),
              child: Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          if (widget.subtitle != null)
            SizedBox(
              width: widget.width,
              child: Text(
                widget.subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}
