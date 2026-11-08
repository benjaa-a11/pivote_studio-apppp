import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';

class LoadingShimmer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const LoadingShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AppRadius.card,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? AppTheme.darkBg2 : AppTheme.lightBg2;
    final highlightColor = isDark ? AppTheme.darkBg3 : AppTheme.lightBg1;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      period: const Duration(milliseconds: 1400),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : AppTheme.lightBorder,
          ),
        ),
      ),
    );
  }
}

class LoadingShimmerList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const LoadingShimmerList({
    super.key,
    this.itemCount = 6,
    this.itemHeight = 140,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: AppResponsive.screenHorizontalPadding(context)
          .add(const EdgeInsets.symmetric(vertical: 16)),
      gridDelegate: AppResponsive.channelGridDelegate(context),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return LoadingShimmer(
          width: double.infinity,
          height: itemHeight,
          borderRadius: AppRadius.card,
        );
      },
    );
  }
}
