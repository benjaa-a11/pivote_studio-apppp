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
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchVisible = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = ProfilePalette.of(context);
    final radioProvider = context.watch<RadioProvider>();
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final hPad = AppResponsive.screenHorizontalPadding(context);

    return Scaffold(
      backgroundColor: palette.bg,
      body: RefreshIndicator(
        color: palette.accent,
        backgroundColor: palette.card,
        strokeWidth: 2.5,
        onRefresh: () => radioProvider.loadRadiosFromFirestore(),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: ClampingScrollPhysics(),
              ),
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
      ),
    );
  }

  Widget _buildHeader(ProfilePalette palette, int totalCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 8, 2, 10),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: palette.card,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: palette.border, width: 1),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.radio_rounded,
                  size: 19,
                  color: palette.accent,
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Radio en vivo',
                      textAlign: TextAlign.center,
                      style: AppFont.primary(
                        fontSize: 19.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: palette.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$totalCount emisoras disponibles',
                      textAlign: TextAlign.center,
                      style: AppFont.primary(
                        fontSize: 12.2,
                        fontWeight: FontWeight.w600,
                        color: palette.muted,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _isSearchVisible = !_isSearchVisible;
                    if (!_isSearchVisible) {
                      _searchController.clear();
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color:
                        _isSearchVisible ? palette.primaryBtnBg : palette.card,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                      color: _isSearchVisible
                          ? palette.primaryBtnBg
                          : palette.border,
                      width: 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    _isSearchVisible
                        ? Icons.close_rounded
                        : Icons.search_rounded,
                    size: 19,
                    color: _isSearchVisible
                        ? palette.primaryBtnText
                        : palette.text,
                  ),
                ),
              ),
            ],
          ),
          if (_isSearchVisible) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              decoration: BoxDecoration(
                color: palette.card,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: palette.border, width: 1),
                boxShadow: palette.cardShadow,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: palette.muted,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      onChanged: (_) => setState(() {}),
                      style: AppFont.primary(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: palette.text,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Buscar por nombre o frecuencia...',
                        hintStyle: AppFont.primary(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: palette.muted,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 11),
                      ),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      child: Icon(
                        Icons.cancel_rounded,
                        size: 18,
                        color: palette.muted,
                      ),
                    ),
                ],
              ),
            ),
          ],
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
      height: 38,
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

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedCategory = cat);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? palette.primaryBtnBg : palette.card,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: isSelected ? palette.primaryBtnBg : palette.border,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isFavPill) ...[
                    Icon(
                      Icons.favorite_rounded,
                      size: 14,
                      color: isSelected
                          ? palette.primaryBtnText
                          : AppColors.live,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    cat,
                    style: AppFont.primary(
                      fontSize: 12.8,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                      letterSpacing: -0.15,
                      color: isSelected ? palette.primaryBtnText : palette.text,
                    ),
                  ),
                  if (isFavPill && favCount > 0) ...[
                    const SizedBox(width: 6),
                    Text(
                      '$favCount',
                      style: AppFont.primary(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? palette.primaryBtnText.withValues(alpha: 0.85)
                            : palette.muted,
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
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: CircularProgressIndicator(
            color: palette.accent,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    var list = provider.radios;

    if (_selectedCategory == 'Favoritas') {
      list = list.where((r) => r.isFavorite).toList();
    } else if (_selectedCategory != 'Todas') {
      list = list.where((r) => r.category == _selectedCategory).toList();
    }

    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((r) {
        return r.name.toLowerCase().contains(query) ||
            r.frequency.toLowerCase().contains(query) ||
            (r.category ?? '').toLowerCase().contains(query);
      }).toList();
    }

    if (list.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: ProfileGroupCard(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
            children: [
              Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: palette.iconBox,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      _selectedCategory == 'Favoritas'
                          ? Icons.favorite_border_rounded
                          : Icons.radio_rounded,
                      size: 24,
                      color: palette.accent,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _selectedCategory == 'Favoritas'
                        ? 'Sin emisoras favoritas'
                        : 'No se encontraron radios',
                    style: AppFont.primary(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: palette.text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _selectedCategory == 'Favoritas'
                        ? 'Tocá el corazón en cualquier emisora para guardarla acá.'
                        : 'Probá con otra categoría o término de búsqueda.',
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
        (context, index) {
          final radio = list[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SearchRadioTile(radio: radio),
          );
        },
        childCount: list.length,
      ),
    );
  }
}
