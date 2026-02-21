import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:pivote/features/video/presentation/providers/channel_provider.dart';
import 'package:pivote/features/home/data/services/search_service.dart';
import 'package:pivote/features/video/presentation/widgets/channel_card.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:google_fonts/google_fonts.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<String> _searchHistory = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    // Auto focus search on open
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _searchFocusNode.requestFocus();
    });
  }

  Future<void> _loadSearchHistory() async {
    final history = await SearchService.getSearchHistory();
    if (mounted) {
      setState(() {
        _searchHistory = history;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
    });
    Provider.of<ChannelProvider>(context, listen: false).searchChannels(query);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final channelProvider = Provider.of<ChannelProvider>(context);

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          Provider.of<ChannelProvider>(context, listen: false)
              .searchChannels('');
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.darkBg : Colors.white,
        body: Column(
          children: [
            // Glassmorphic Header (Not Positioned anymore to avoid overlap)
            _buildGlassHeader(context, isDark),

            // Content
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: _isSearching
                    ? _buildSearchResults(channelProvider, isDark)
                    : _buildInitialState(channelProvider, isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassHeader(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final topPadding = MediaQuery.of(context).padding.top;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 16),
          decoration: BoxDecoration(
            color:
                (isDark ? Colors.black : Colors.white).withValues(alpha: 0.7),
            border: Border(
              bottom: BorderSide(
                color: (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: 0.05),
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon:
                        const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    style: IconButton.styleFrom(
                      backgroundColor: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.05),
                      padding: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Buscar',
                    style: GoogleFonts.syne(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                height: 52,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white12
                      : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: 0.05),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: _onSearch,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Encuentra canales por nombre...',
                    hintStyle: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      fontWeight: FontWeight.w500,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: theme.colorScheme.primary.withValues(alpha: 0.6),
                      size: 22,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _onSearch('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInitialState(ChannelProvider provider, bool isDark) {
    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      children: [
        if (_searchHistory.isNotEmpty) ...[
          AppAnimations.staggeredSlideIn(
            index: 0,
            child:
                _buildSectionHeader('Búsquedas recientes', onAction: () async {
              await SearchService.clearSearchHistory();
              _loadSearchHistory();
            }),
          ),
          const SizedBox(height: 12),
          AppAnimations.staggeredSlideIn(
            index: 1,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _searchHistory
                  .take(6)
                  .map((query) => _buildHistoryChip(query))
                  .toList(),
            ),
          ),
          const SizedBox(height: 32),
        ],

        // Quick Filters Section
        AppAnimations.staggeredSlideIn(
          index: _searchHistory.isEmpty ? 0 : 2,
          child: _buildSectionHeader('Categorías rápidas'),
        ),
        const SizedBox(height: 12),
        AppAnimations.staggeredSlideIn(
          index: _searchHistory.isEmpty ? 1 : 3,
          child: SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCategoryChip('Deportes', Icons.sports_soccer),
                _buildCategoryChip('Noticias', Icons.newspaper),
                _buildCategoryChip('Música', Icons.music_note),
                _buildCategoryChip('Películas', Icons.movie),
                _buildCategoryChip('Infantil', Icons.child_care),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),

        AppAnimations.staggeredSlideIn(
          index: _searchHistory.isEmpty ? 2 : 4,
          child: _buildSectionHeader('Canales populares'),
        ),
        const SizedBox(height: 20),
        _buildPopularChannels(provider),
      ],
    );
  }

  Widget _buildCategoryChip(String label, IconData icon) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: () {
          _searchController.text = label;
          _onSearch(label);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? theme.cardColor : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onAction}) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
        if (onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
            ),
            child: Text(
              'Limpiar',
              style: GoogleFonts.dmSans(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHistoryChip(String query) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return InkWell(
      onTap: () {
        _searchController.text = query;
        _onSearch(query);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded,
                size: 14,
                color: theme.colorScheme.primary.withValues(alpha: 0.7)),
            const SizedBox(width: 8),
            Text(
              query,
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularChannels(ChannelProvider provider) {
    final channels = provider.allChannels.take(6).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: channels.length,
      itemBuilder: (context, index) {
        return AppAnimations.staggeredSlideIn(
          index: index + 3,
          child: ChannelCard(channel: channels[index]),
        );
      },
    );
  }

  Widget _buildSearchResults(ChannelProvider provider, bool isDark) {
    final channels = provider.channels;
    final theme = Theme.of(context);

    if (channels.isEmpty) {
      return Center(
        child: AppAnimations.scaleIn(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.search_off_rounded,
                    size: 50,
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'No hay resultados',
                  style: GoogleFonts.syne(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Intenta con palabras diferentes o revisa la ortografía para encontrar el canal.',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    height: 1.5,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: channels.length,
      itemBuilder: (context, index) {
        return AppAnimations.staggeredSlideIn(
          index: index,
          child: ChannelCard(channel: channels[index]),
        );
      },
    );
  }
}
