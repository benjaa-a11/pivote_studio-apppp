import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/features/video/presentation/providers/channel_provider.dart';
import 'package:pivote/shared/widgets/common/apple_pressable.dart';

/// Horizontal pill-chip filter for channel categories.
///
/// The filtering logic (`ChannelProvider.filterByCategory`) already existed
/// in the codebase but had no UI anywhere in the app — categories were only
/// reachable through search. This surfaces them directly on Inicio.
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
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
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

    return ApplePressable(
      scaleDownFactor: 0.94,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: AppAnimations.appleSpringEase,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : (isDark
                  ? AppTheme.darkBg2.withValues(alpha: 0.85)
                  : Colors.white),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : AppTheme.lightBorder),
            width: 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.22),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            letterSpacing: -0.2,
            color: isSelected
                ? AppTheme.darkBg
                : theme.colorScheme.onSurface.withValues(alpha: 0.80),
          ),
        ),
      ),
    );
  }
}
