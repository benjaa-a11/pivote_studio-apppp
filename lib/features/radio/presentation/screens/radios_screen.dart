import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/features/home/presentation/widgets/search_radio_tile.dart';
import 'package:pivote/features/profile/presentation/widgets/profile_design_system.dart';
import 'package:pivote/features/radio/presentation/providers/radio_provider.dart';

class RadiosScreen extends StatefulWidget {
  const RadiosScreen({super.key});

  @override
  State<RadiosScreen> createState() => _RadiosScreenState();
}

class _RadiosScreenState extends State<RadiosScreen> {
  String _selectedCategory = 'Todas';

  @override
  Widget build(BuildContext context) {
    final palette = ProfilePalette.of(context);
    final radioProvider = context.watch<RadioProvider>();
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final hPad = AppResponsive.screenHorizontalPadding(context);

    return Scaffold(
      backgroundColor: palette.bg,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: hPad.add(EdgeInsets.only(top: topPad + 10)),
                sliver: SliverToBoxAdapter(
                  child: _buildHeader(palette, radioProvider.radios.length),
                ),
              ),
              SliverToBoxAdapter(
                child: _buildCategoryPills(context, radioProvider, palette),
              ),
              SliverPadding(
                padding: hPad.add(const EdgeInsets.only(top: 6)),
                sliver: _buildRadiosList(radioProvider, palette),
              ),
              SliverToBoxAdapter(
                child: SizedBox(height: math.max(108, bottomPad + 92)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ProfilePalette palette, int totalCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 10, 2, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Radio en vivo',
            style: AppFont.primary(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.0,
              height: 1.05,
              color: palette.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            totalCount == 1
                ? '1 emisora disponible'
                : '$totalCount emisoras disponibles',
            style: AppFont.primary(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: palette.muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPills(
    BuildContext context,
    RadioProvider provider,
    ProfilePalette palette,
  ) {
    final categories = [
      'Todas',
      'Favoritas',
      ...provider.categories.where((c) => c != 'Todas'),
    ];
    final favCount = provider.radios.where((r) => r.isFavorite).length;

    return Container(
      height: 40,
      margin: const EdgeInsets.only(top: 4, bottom: 10),
      child: ListView.separated(
        padding: AppResponsive.screenHorizontalPadding(context),
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == cat;
          final isFavPill = cat == 'Favoritas';
          final fg = isSelected ? palette.primaryBtnText : palette.muted;

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedCategory = cat);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? palette.primaryBtnBg : palette.card,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: isSelected ? palette.primaryBtnBg : palette.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isFavPill) ...[
                    Icon(
                      Icons.favorite_rounded,
                      size: 14,
                      color: isSelected ? fg : AppColors.live,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    cat,
                    style: AppFont.primary(
                      fontSize: 13.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: fg,
                    ),
                  ),
                  if (isFavPill && favCount > 0) ...[
                    const SizedBox(width: 6),
                    Text(
                      '$favCount',
                      style: AppFont.primary(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: fg.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRadiosList(RadioProvider provider, ProfilePalette palette) {
    if (provider.isLoading && provider.radios.isEmpty) {
      // Placeholders estáticos: sin spinners.
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Container(
            height: 72,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: palette.border),
            ),
          ),
          childCount: 6,
        ),
      );
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
          child: ProfileGroupCard(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
            children: [
              Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: palette.iconBox,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      isFav
                          ? Icons.favorite_border_rounded
                          : Icons.radio_rounded,
                      size: 26,
                      color: palette.accent,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    isFav ? 'Sin emisoras favoritas' : 'No hay radios',
                    style: AppFont.primary(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: palette.text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isFav
                        ? 'Tocá el corazón en cualquier emisora para guardarla acá.'
                        : 'Probá con otra categoría.',
                    textAlign: TextAlign.center,
                    style: AppFont.primary(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: palette.muted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SearchRadioTile(
            key: ValueKey(list[index].id),
            radio: list[index],
          ),
        ),
        childCount: list.length,
      ),
    );
  }
}
