import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/features/home/presentation/widgets/search_radio_tile.dart';
import 'package:pivote/features/radio/presentation/providers/radio_provider.dart';
import 'package:pivote/shared/widgets/common/app_state_views.dart';
import 'package:pivote/shared/widgets/common/loading_shimmer.dart';
import 'package:pivote/shared/widgets/common/pivote_surfaces.dart';

class RadiosScreen extends StatefulWidget {
  const RadiosScreen({super.key});

  @override
  State<RadiosScreen> createState() => _RadiosScreenState();
}

class _RadiosScreenState extends State<RadiosScreen> {
  String _selectedCategory = 'Todas';

  @override
  Widget build(BuildContext context) {
    final radioProvider = context.watch<RadioProvider>();
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final hPad = AppResponsive.screenHorizontalPadding(context);

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: PivoteAmbientBackdrop(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: CustomScrollView(
              physics: const ClampingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: hPad.add(EdgeInsets.only(top: topPad + 14)),
                  sliver: SliverToBoxAdapter(
                    child: _buildHeader(context, radioProvider.radios.length),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildCategoryPills(context, radioProvider),
                ),
                SliverPadding(
                  padding: hPad.add(const EdgeInsets.only(top: 6)),
                  sliver: _buildRadiosList(context, radioProvider),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(height: math.max(110, bottomPad + 94)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int totalCount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Radio',
                  style: AppFont.primary(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.7,
                    height: 1.05,
                    color: AppTheme.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  totalCount == 1
                      ? '1 emisora en vivo'
                      : '$totalCount emisoras en vivo',
                  style: AppFont.primary(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textTertiary(context),
                  ),
                ),
              ],
            ),
          ),
          if (totalCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.accentDim(context),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: AppTheme.accent(context).withValues(alpha: 0.30),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppTheme.accent(context),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'FM / AM',
                    style: AppFont.mono(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.accent(context),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryPills(BuildContext context, RadioProvider provider) {
    final categories = [
      'Todas',
      'Favoritas',
      ...provider.categories.where((c) => c != 'Todas'),
    ];
    final favCount = provider.radios.where((r) => r.isFavorite).length;

    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: AppResponsive.screenHorizontalPadding(context),
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isFavPill = cat == 'Favoritas';
          return PivoteFilterPill(
            label: cat,
            icon: isFavPill ? Icons.favorite_rounded : null,
            liveIcon: isFavPill,
            count: isFavPill && favCount > 0 ? favCount : null,
            selected: _selectedCategory == cat,
            onTap: () => setState(() => _selectedCategory = cat),
          );
        },
      ),
    );
  }

  Widget _buildRadiosList(BuildContext context, RadioProvider provider) {
    if (provider.isLoading && provider.radios.isEmpty) {
      return const PivoteRadioListSkeleton(itemCount: 7);
    }

    var list = provider.radios;
    if (_selectedCategory == 'Favoritas') {
      list = list.where((r) => r.isFavorite).toList();
    } else if (_selectedCategory != 'Todas') {
      list = list.where((r) => r.category == _selectedCategory).toList();
    }

    if (list.isEmpty) {
      final isFav = _selectedCategory == 'Favoritas';
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: AppStateView.empty(
            icon: isFav ? Icons.favorite_border_rounded : Icons.radio_rounded,
            title: isFav ? 'Sin emisoras favoritas' : 'No hay emisoras',
            subtitle: isFav
                ? 'Tocá el corazón en cualquier emisora para guardarla acá.'
                : 'Probá seleccionando otra categoría.',
            compact: true,
          ),
        ),
      );
    }

    return SliverList.separated(
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => SearchRadioTile(
        key: ValueKey(list[index].id),
        radio: list[index],
      ),
    );
  }
}
