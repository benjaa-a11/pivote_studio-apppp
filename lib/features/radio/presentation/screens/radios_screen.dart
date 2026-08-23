import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:pivote/features/radio/presentation/providers/radio_provider.dart';
import 'package:pivote/features/radio/presentation/providers/audio_manager.dart';
import 'package:pivote/features/radio/data/models/radio.dart' as radio_model;
import 'package:pivote/features/radio/presentation/screens/radio_player_screen.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/core/services/image_cache_helper.dart';

class RadiosScreen extends StatefulWidget {
  const RadiosScreen({super.key});

  @override
  State<RadiosScreen> createState() => _RadiosScreenState();
}

class _RadiosScreenState extends State<RadiosScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchVisible = false;
  String _selectedCategory = 'Todas';
  bool _showOnlyFavorites = false;

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final radioProvider = context.watch<RadioProvider>();
    final audioManager = context.watch<AudioManager>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            RefreshIndicator(
              color: isDark ? AppTheme.darkAccent : theme.colorScheme.primary,
              backgroundColor: isDark ? AppTheme.darkBg2 : theme.colorScheme.surface,
              onRefresh: () => radioProvider.loadRadiosFromFirestore(),
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                slivers: [
                  // ─── Header con buscador y stats ───
                  _buildSliverHeader(context, theme, isDark, radioProvider),

                  // ─── Categorías y Filtro de Favoritos ───
                  SliverToBoxAdapter(
                    child: _buildCategoryChips(context, theme, isDark, radioProvider),
                  ),

                  // ─── Lista de Emisoras ───
                  _buildSliverRadioList(context, theme, isDark, radioProvider, audioManager),

                  // Espacio adicional si el mini reproductor está activo
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: audioManager.currentRadio != null ? 120 : 80,
                    ),
                  ),
                ],
              ),
            ),

            // ─── Mini-Player Flotante Inferior ───
            if (audioManager.currentRadio != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: _buildFloatingMiniPlayer(context, theme, isDark, audioManager),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Sliver Header ───
  Widget _buildSliverHeader(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    RadioProvider radioProvider,
  ) {
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
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
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
                    // Título e indicador
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppTheme.darkAccent.withValues(alpha: 0.12)
                                : theme.colorScheme.primary.withValues(alpha: 0.1),
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
                              'Radio en Vivo',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                color: textColor,
                              ),
                            ),
                            Text(
                              '${radioProvider.radios.length} emisoras disponibles',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: textColor.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),

                    // Botón de búsqueda local
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _isSearchVisible = !_isSearchVisible;
                            if (!_isSearchVisible) {
                              _searchController.clear();
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: _isSearchVisible
                                ? (isDark
                                    ? AppTheme.darkAccent
                                    : theme.colorScheme.primary)
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : Colors.black.withValues(alpha: 0.04)),
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
                    ),
                  ],
                ),

                // Campo de búsqueda expandible
                if (_isSearchVisible) ...[
                  const SizedBox(height: 10),
                  Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkBg2 : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.08),
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      cursorColor:
                          isDark ? AppTheme.darkAccent : theme.colorScheme.primary,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Filtrar por nombre o frecuencia...',
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

  // ─── Category Chips ───
  Widget _buildCategoryChips(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    RadioProvider radioProvider,
  ) {
    final categories = ['Todas', ...radioProvider.categories.where((c) => c != 'Todas')];

    return Container(
      height: 44,
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        itemCount: categories.length + 1, // +1 para el botón de favoritas
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            // Chip de Favoritas
            final isSelected = _showOnlyFavorites;
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _showOnlyFavorites = !_showOnlyFavorites;
                  });
                },
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFEF4444)
                        : (isDark
                            ? AppTheme.darkBg2
                            : theme.colorScheme.surface),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFEF4444)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.06)),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 14,
                        color: isSelected ? Colors.white : const Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Favoritas',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final category = categories[index - 1];
          final isSelected = !_showOnlyFavorites && _selectedCategory == category;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _showOnlyFavorites = false;
                  _selectedCategory = category;
                });
              },
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark
                          ? AppTheme.darkAccent
                          : theme.colorScheme.primary)
                      : (isDark
                          ? AppTheme.darkBg2
                          : theme.colorScheme.surface),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: isSelected
                        ? (isDark
                            ? AppTheme.darkAccent
                            : theme.colorScheme.primary)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06)),
                  ),
                  boxShadow: isSelected
                      ? AppShadows.glow(
                          isDark
                              ? AppTheme.darkAccent
                              : theme.colorScheme.primary,
                          alpha: 0.25)
                      : [],
                ),
                child: Center(
                  child: Text(
                    category,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected
                          ? (isDark ? Colors.black : Colors.white)
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Radio List ───
  Widget _buildSliverRadioList(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    RadioProvider radioProvider,
    AudioManager audioManager,
  ) {
    final isLoading = radioProvider.isLoading;
    var list = radioProvider.radios;

    // Filter by favorites
    if (_showOnlyFavorites) {
      list = radioProvider.favoriteRadios;
    } else if (_selectedCategory != 'Todas') {
      list = list.where((r) => r.category == _selectedCategory).toList();
    }

    // Filter by local search text
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((r) {
        return r.name.toLowerCase().contains(query) ||
            r.frequency.toLowerCase().contains(query) ||
            (r.category ?? '').toLowerCase().contains(query);
      }).toList();
    }

    if (isLoading) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildSkeletonTile(theme, isDark),
            childCount: 6,
          ),
        ),
      );
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
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.darkAccent.withValues(alpha: 0.1)
                        : theme.colorScheme.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.radio_rounded,
                    size: 32,
                    color: isDark
                        ? AppTheme.darkAccent
                        : theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _showOnlyFavorites
                      ? 'Sin radios favoritas'
                      : 'Sin emisoras encontradas',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _showOnlyFavorites
                      ? 'Guarda tus emisoras favoritas tocando el icono de corazón.'
                      : 'Intenta con otra búsqueda o categoría.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12.5,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final radio = list[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildModernRadioCard(
                context,
                radio,
                audioManager,
                radioProvider,
                theme,
                isDark,
              ),
            );
          },
          childCount: list.length,
        ),
      ),
    );
  }

  Widget _buildSkeletonTile(ThemeData theme, bool isDark) {
    return Skeletonizer(
      enabled: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkBg2 : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 140,
                    height: 16,
                    color: Colors.grey.shade800,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 80,
                    height: 12,
                    color: Colors.grey.shade800,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Modern Radio Card ───
  Widget _buildModernRadioCard(
    BuildContext context,
    radio_model.Radio radio,
    AudioManager audioManager,
    RadioProvider radioProvider,
    ThemeData theme,
    bool isDark,
  ) {
    final isCurrent = audioManager.currentRadio?.id == radio.id;
    final isPlaying = isCurrent && audioManager.isPlaying;
    final isLoading = isCurrent && audioManager.isLoading;
    final isFav = radio.isFavorite;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  RadioPlayerScreen(radio: radio),
              transitionDuration: const Duration(milliseconds: 300),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position: animation.drive(
                    Tween(
                      begin: const Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).chain(CurveTween(curve: Curves.easeOutCubic)),
                  ),
                  child: child,
                );
              },
            ),
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark
                ? (isCurrent
                    ? (isPlaying
                        ? AppTheme.darkAccent.withValues(alpha: 0.1)
                        : AppTheme.darkBg2)
                    : AppTheme.darkBg2.withValues(alpha: 0.75))
                : (isCurrent
                    ? theme.colorScheme.primary.withValues(alpha: 0.08)
                    : theme.colorScheme.surface),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isCurrent
                  ? (isDark
                      ? AppTheme.darkAccent.withValues(alpha: 0.5)
                      : theme.colorScheme.primary.withValues(alpha: 0.4))
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.07)
                      : Colors.black.withValues(alpha: 0.06)),
              width: isCurrent ? 1.5 : 1,
            ),
            boxShadow: isCurrent && isPlaying
                ? AppShadows.glow(
                    isDark ? AppTheme.darkAccent : theme.colorScheme.primary,
                    alpha: 0.2)
                : [],
          ),
          child: Row(
            children: [
              // Radio Logo
              Hero(
                tag: 'radio_tile_logo_${radio.id}',
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: isPlaying
                              ? (isDark
                                  ? AppTheme.darkAccent
                                  : theme.colorScheme.primary)
                              : Colors.transparent,
                          width: 1.6,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: radio.logoUrl.isNotEmpty
                            ? CachedNetworkImage(
                                key: ValueKey<String>(radio.logoUrl),
                                cacheManager: ImageCacheHelper.logoCacheManager,
                                imageUrl: radio.logoUrl,
                                fit: BoxFit.cover,
                                memCacheWidth: 140,
                                placeholder: (context, url) => Center(
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: isDark
                                          ? AppTheme.darkAccent
                                          : theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Icon(
                                  Icons.radio_rounded,
                                  size: 24,
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.5),
                                ),
                              )
                            : Icon(
                                Icons.radio_rounded,
                                size: 24,
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.5),
                              ),
                      ),
                    ),
                    if (isPlaying)
                      Positioned(
                        bottom: 3,
                        right: 3,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppTheme.darkAccent
                                : theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.graphic_eq_rounded,
                            size: 10,
                            color: isDark ? Colors.black : Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Station Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      radio.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: isCurrent
                            ? (isDark
                                ? AppTheme.darkAccent
                                : theme.colorScheme.primary)
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (radio.frequency.isNotEmpty) ...[
                          Text(
                            radio.frequency,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Text(
                            radio.category ?? 'En Vivo',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppTheme.darkAccent.withValues(alpha: 0.8)
                                  : theme.colorScheme.primary
                                      .withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Favorite Heart Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    radioProvider.toggleFavorite(radio);
                  },
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      isFav
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 20,
                      color: isFav
                          ? const Color(0xFFEF4444)
                          : theme.colorScheme.onSurface.withValues(alpha: 0.35),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),

              // Play / Pause Quick Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    audioManager.playRadio(radio);
                  },
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isPlaying
                          ? (isDark
                              ? AppTheme.darkAccent
                              : theme.colorScheme.primary)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : theme.colorScheme.primary
                                  .withValues(alpha: 0.08)),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isLoading
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: isPlaying
                                    ? (isDark ? Colors.black : Colors.white)
                                    : (isDark
                                        ? AppTheme.darkAccent
                                        : theme.colorScheme.primary),
                              ),
                            )
                          : Icon(
                              isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              size: 22,
                              color: isPlaying
                                  ? (isDark ? Colors.black : Colors.white)
                                  : (isDark
                                      ? AppTheme.darkAccent
                                      : theme.colorScheme.primary),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Floating Mini-Player ───
  Widget _buildFloatingMiniPlayer(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    AudioManager audioManager,
  ) {
    final radio = audioManager.currentRadio!;
    final isPlaying = audioManager.isPlaying;
    final isLoading = audioManager.isLoading;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  RadioPlayerScreen(radio: radio),
              transitionDuration: const Duration(milliseconds: 300),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position: animation.drive(
                    Tween(
                      begin: const Offset(0.0, 1.0),
                      end: Offset.zero,
                    ).chain(CurveTween(curve: Curves.easeOutCubic)),
                  ),
                  child: child,
                );
              },
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.darkBg1.withValues(alpha: 0.92)
                    : theme.colorScheme.surface.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? AppTheme.darkAccent.withValues(alpha: 0.35)
                      : theme.colorScheme.primary.withValues(alpha: 0.25),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Station logo small
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: radio.logoUrl.isNotEmpty
                          ? CachedNetworkImage(
                              key: ValueKey<String>(radio.logoUrl),
                              cacheManager: ImageCacheHelper.logoCacheManager,
                              imageUrl: radio.logoUrl,
                              fit: BoxFit.cover,
                              memCacheWidth: 100,
                            )
                          : Icon(
                              Icons.radio_rounded,
                              size: 22,
                              color: isDark
                                  ? AppTheme.darkAccent
                                  : theme.colorScheme.primary,
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            if (isPlaying) ...[
                              Icon(
                                Icons.graphic_eq_rounded,
                                size: 13,
                                color: isDark
                                    ? AppTheme.darkAccent
                                    : theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Expanded(
                              child: Text(
                                radio.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          radio.frequency.isNotEmpty
                              ? radio.frequency
                              : (radio.category ?? 'Radio en Vivo'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Play/Pause Action
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        audioManager.playRadio(radio);
                      },
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppTheme.darkAccent
                              : theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: isLoading
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: isDark ? Colors.black : Colors.white,
                                  ),
                                )
                              : Icon(
                                  isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  size: 20,
                                  color: isDark ? Colors.black : Colors.white,
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Stop / Dismiss Action
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        audioManager.stop();
                      },
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
