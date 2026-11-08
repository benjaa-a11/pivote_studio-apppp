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
    final onAccent = AppTheme.onAccent(context);

    return ApplePressable(
      scaleDownFactor: 0.94,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: AppAnimations.appleSpringEase,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? accent
              : (isDark ? AppTheme.darkBg2 : AppTheme.lightBg1),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isSelected
                ? accent
                : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppTheme.lightBorder),
            width: 1.0,
          ),
          boxShadow: isSelected
              ? AppShadows.glow(accent, alpha: isDark ? 0.22 : 0.14)
              : null,
        ),
        child: Text(
          label,
          style: AppFont.primary(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            letterSpacing: -0.15,
            color: isSelected ? onAccent : AppTheme.textSecondary(context),
          ),
        ),
      ),
    );
  }
}
