import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/features/video/presentation/providers/channel_provider.dart';
import 'package:pivote/shared/widgets/common/pivote_surfaces.dart';

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
              return PivoteFilterPill(
                label: category,
                selected: isSelected,
                onTap: () => provider.filterByCategory(category),
              );
            },
          ),
        );
      },
    );
  }
}
