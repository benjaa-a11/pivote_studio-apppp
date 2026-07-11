import 'package:flutter/material.dart';
import 'package:pivote/core/animations/app_animations.dart';

class LoadingShimmer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const LoadingShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 16,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppAnimations.shimmer(
      child: Container(
        width: width,
        height: height,
        margin: margin,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  // Convenient skeleton for a Channel Card
  static Widget channelCardPlaceholder() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LoadingShimmer(width: double.infinity, height: 120, borderRadius: 24),
        SizedBox(height: 12),
        LoadingShimmer(width: 100, height: 16, borderRadius: 8),
        SizedBox(height: 6),
        LoadingShimmer(width: 60, height: 12, borderRadius: 6),
      ],
    );
  }

  // Skeleton for a List Item (Match, Profile option, etc.)
  static Widget listItemPlaceholder() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          LoadingShimmer(width: 50, height: 50, borderRadius: 12),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LoadingShimmer(width: 140, height: 16, borderRadius: 8),
                SizedBox(height: 8),
                LoadingShimmer(width: 80, height: 12, borderRadius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Skeleton for Soccer Match Card
  static Widget matchCardPlaceholder() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child:
          LoadingShimmer(width: double.infinity, height: 100, borderRadius: 20),
    );
  }
}
