import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/features/video/presentation/providers/channel_provider.dart';
import 'package:pivote/shared/widgets/common/apple_pressable.dart';

class CategoryChipsRow extends StatelessWidget {
  const CategoryChipsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChannelProvider>(
      builder: (context, provider, child) {
        final categories = provider.categories;
        if (categories.length <= 1) return const SizedBox.shrink();

        return SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            padding: AppResponsive.screenHorizontalPadding(context),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = provider.selectedCategory == category;
              return _CategoryChip(
                label: category,
                isSelected: isSelected,
                onTap: () => provider.filterByCategory(category),
              );
            },
          ),
        );
      },
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.isDark;
    final accent = theme.colorScheme.primary;
    // ignore: unused_local_variable
    final onAccent = AppTheme.onAccent(context);

    return ApplePressable(
      scaleDownFactor: 0.94,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: AppAnimations.appleSpringEase,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.accentBg : accent)
              : (isDark ? AppColors.darkBg2 : AppTheme.lightBg1),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: isSelected
                ? AppColors.accent
                : (isDark
                    ? AppColors.darkBorder2
                    : AppTheme.lightBorder),
            width: isSelected ? 1.2 : 1.0,
          ),
          boxShadow: isSelected
              ? AppShadows.glow(accent, alpha: isDark ? 0.28 : 0.14)
              : null,
        ),
        child: Text(
          label,
          style: AppFont.primary(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
            letterSpacing: -0.15,
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.darkText2 : AppTheme.lightText2),
          ),
        ),
      ),
    );
  }
}
