import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pivote/features/home/presentation/widgets/search_radio_tile.dart';
import 'package:pivote/features/radio/presentation/providers/radio_provider.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/shared/widgets/common/apple_pressable.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.isDark;
    final radioProvider = context.watch<RadioProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: isDark ? AppTheme.darkAccent : theme.colorScheme.primary,
          backgroundColor:
              isDark ? AppTheme.darkBg2 : theme.colorScheme.surface,
          strokeWidth: 2.5,
          onRefresh: () => radioProvider.loadRadiosFromFirestore(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // ─── Header con buscador y stats ───
              _buildSliverHeader(theme, isDark, radioProvider.radios.length),

              // ─── Pestañas de Categorías & Favoritos ───
              SliverToBoxAdapter(
                child: _buildCategoryPills(radioProvider, theme, isDark),
              ),

              // ─── Grid / Lista de Emisoras ───
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: _buildRadiosList(radioProvider, theme, isDark),
              ),

              // Espacio inferior estándar
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header ───
  Widget _buildSliverHeader(ThemeData theme, bool isDark, int totalCount) {
    final textColor = theme.colorScheme.onSurface;

    return SliverAppBar(
      floating: true,
      snap: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      toolbarHeight: _isSearchVisible ? 120 : 64,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppMaterials.blurRegular,
            sigmaY: AppMaterials.blurRegular,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor
                  .withValues(alpha: isDark ? 0.85 : 0.90),
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.05),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isDark
                                ? AppTheme.darkAccent
                                : theme.colorScheme.primary)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.radio_rounded,
                        size: 20,
                        color: isDark
                            ? AppTheme.darkAccent
                            : theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Radios En Vivo',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: textColor,
                          ),
                        ),
                        Text(
                          '$totalCount emisoras disponibles',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: textColor.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),

                    // Search Button with ApplePressable
                    ApplePressable(
                      scaleDownFactor: 0.90,
                      onTap: () {
                        setState(() {
                          _isSearchVisible = !_isSearchVisible;
                          if (!_isSearchVisible) {
                            _searchController.clear();
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: AppAnimations.appleSpringEase,
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: _isSearchVisible
                              ? (isDark
                                  ? AppTheme.darkAccent
                                  : theme.colorScheme.primary)
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.05)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _isSearchVisible
                              ? Icons.close_rounded
                              : Icons.search_rounded,
                          size: 19,
                          color: _isSearchVisible
                              ? (isDark ? Colors.black : Colors.white)
                              : textColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),

                // Search Input Field
                if (_isSearchVisible) ...[
                  const SizedBox(height: 10),
                  Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color:
                          isDark ? AppTheme.darkBg2 : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.08),
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() {}),
                      cursorColor: isDark
                          ? AppTheme.darkAccent
                          : theme.colorScheme.primary,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Buscar emisora por nombre o frecuencia...',
                        hintStyle: GoogleFonts.spaceGrotesk(
                          fontSize: 12.5,
                          color: textColor.withValues(alpha: 0.4),
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          size: 18,
                          color: isDark
                              ? AppTheme.darkAccent
                              : theme.colorScheme.primary,
                        ),
                        prefixIconConstraints:
                            const BoxConstraints(minWidth: 36, minHeight: 36),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 11),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Category Pills ───
  Widget _buildCategoryPills(
    RadioProvider provider,
    ThemeData theme,
    bool isDark,
  ) {
    final categories = [
      'Todas',
      'Favoritas',
      ...provider.categories.where((c) => c != 'Todas')
    ];
    final favCount = provider.radios.where((r) => r.isFavorite).length;

    return Container(
      height: 42,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == cat;
          final isFavPill = cat == 'Favoritas';

          return ApplePressable(
            scaleDownFactor: 0.94,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            onTap: () {
              setState(() => _selectedCategory = cat);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: AppAnimations.appleSpringEase,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? AppTheme.darkAccent : theme.colorScheme.primary)
                    : (isDark
                        ? AppTheme.darkBg2.withValues(alpha: 0.85)
                        : Colors.white),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : AppTheme.lightBorder),
                  width: 1.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: (isDark
                                  ? AppTheme.darkAccent
                                  : theme.colorScheme.primary)
                              .withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: isDark ? 0.18 : 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isFavPill) ...[
                    Icon(
                      Icons.favorite_rounded,
                      size: 14,
                      color: isSelected
                          ? (isDark ? Colors.black : Colors.white)
                          : const Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    cat,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12.5,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected
                          ? (isDark ? Colors.black : Colors.white)
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  if (isFavPill && favCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.black.withValues(alpha: 0.2)
                            : const Color(0xFFEF4444).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$favCount',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: isSelected
                              ? (isDark ? Colors.black : Colors.white)
                              : const Color(0xFFEF4444),
                        ),
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

  // ─── Radios List / Grid ───
  Widget _buildRadiosList(
    RadioProvider provider,
    ThemeData theme,
    bool isDark,
  ) {
    if (provider.isLoading && provider.radios.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: CircularProgressIndicator(
            color: isDark ? AppTheme.darkAccent : theme.colorScheme.primary,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    var list = provider.radios;

    // Filter by category / favorites
    if (_selectedCategory == 'Favoritas') {
      list = list.where((r) => r.isFavorite).toList();
    } else if (_selectedCategory != 'Todas') {
      list = list.where((r) => r.category == _selectedCategory).toList();
    }

    // Filter by search query
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((r) {
        return r.name.toLowerCase().contains(query) ||
            r.frequency.toLowerCase().contains(query) ||
            (r.category ?? '').toLowerCase().contains(query);
      }).toList();
    }

    if (list.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _selectedCategory == 'Favoritas'
                      ? Icons.favorite_border_rounded
                      : Icons.radio_rounded,
                  size: 48,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  _selectedCategory == 'Favoritas'
                      ? 'Sin emisoras favoritas'
                      : 'No se encontraron radios',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _selectedCategory == 'Favoritas'
                      ? 'Toca el corazón en cualquier emisora para guardarla aquí.'
                      : 'Prueba con otra categoría o término de búsqueda.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final radio = list[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SearchRadioTile(radio: radio),
          );
        },
        childCount: list.length,
      ),
    );
  }
}
