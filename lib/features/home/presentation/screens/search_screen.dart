import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pivote/features/video/presentation/providers/channel_provider.dart';
import 'package:pivote/features/home/data/services/search_service.dart';
import 'package:pivote/features/video/presentation/widgets/channel_card.dart';
import 'package:pivote/core/theme/app_theme.dart';
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
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
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
    _animationController.dispose();
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final channelProvider = Provider.of<ChannelProvider>(context);

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          Provider.of<ChannelProvider>(context, listen: false)
              .searchChannels('');
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Column(
          children: [
            // Premium Search Header
            _buildSearchHeader(context, theme, isDark),

            // Content
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
                child: _isSearching
                    ? _buildSearchResults(channelProvider, theme, isDark)
                    : _buildInitialState(channelProvider, theme, isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader(
      BuildContext context, ThemeData theme, bool isDark) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(16, topPadding + 10, 16, 14),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? AppTheme.darkBorder.withValues(alpha: 0.25)
                : AppTheme.lightBorder.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Top row: Back + Title
          Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkBg2 : AppTheme.lightBg2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? AppTheme.darkBorder.withValues(alpha: 0.3)
                          : AppTheme.lightBorder,
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 15,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Buscar',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (_isSearching)
                      Text(
                        '${Provider.of<ChannelProvider>(context).channels.length} resultados',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary.withValues(alpha: 0.7),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search field
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkBg2 : AppTheme.lightBg2,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _searchFocusNode.hasFocus
                    ? theme.colorScheme.primary.withValues(alpha: 0.5)
                    : (isDark
                        ? AppTheme.darkBorder.withValues(alpha: 0.25)
                        : AppTheme.lightBorder),
                width: _searchFocusNode.hasFocus ? 1.5 : 1,
              ),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: (q) {
                _onSearch(q);
                setState(() {});
              },
              onSubmitted: _onSearch,
              textInputAction: TextInputAction.search,
              autofocus: false,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'Buscar canales, categorías...',
                hintStyle: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  color: theme.hintColor.withValues(alpha: 0.45),
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 12, right: 8),
                  child: Icon(
                    Icons.search_rounded,
                    color: _searchFocusNode.hasFocus
                        ? theme.colorScheme.primary
                        : theme.hintColor.withValues(alpha: 0.45),
                    size: 20,
                  ),
                ),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 40, maxHeight: 40),
                suffixIcon: _searchController.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: theme.hintColor,
                          ),
                        ),
                      )
                    : null,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialState(
      ChannelProvider provider, ThemeData theme, bool isDark) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        children: [
          // Search History
          if (_searchHistory.isNotEmpty) ...[
            _buildSectionHeader(theme, 'Recientes', icon: Icons.history_rounded,
                onAction: () async {
              await SearchService.clearSearchHistory();
              _loadSearchHistory();
            }),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _searchHistory
                  .take(8)
                  .map((query) => _buildHistoryChip(query, theme, isDark))
                  .toList(),
            ),
            const SizedBox(height: 28),
          ],

          // Quick Categories
          _buildSectionHeader(theme, 'Categorías',
              icon: Icons.category_rounded),
          const SizedBox(height: 12),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: [
                _buildCategoryChip(
                    'Deportes', Icons.sports_soccer, theme, isDark),
                _buildCategoryChip(
                    'Noticias', Icons.newspaper_rounded, theme, isDark),
                _buildCategoryChip(
                    'Música', Icons.music_note_rounded, theme, isDark),
                _buildCategoryChip(
                    'Películas', Icons.movie_rounded, theme, isDark),
                _buildCategoryChip(
                    'Infantil', Icons.child_care_rounded, theme, isDark),
                _buildCategoryChip(
                    'Documentales', Icons.public_rounded, theme, isDark),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Popular Channels
          _buildSectionHeader(theme, 'Populares',
              icon: Icons.trending_up_rounded),
          const SizedBox(height: 16),
          _buildPopularChannels(provider),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title,
      {IconData? icon, VoidCallback? onAction}) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon,
              size: 16,
              color: theme.colorScheme.primary.withValues(alpha: 0.7)),
          const SizedBox(width: 8),
        ],
        Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const Spacer(),
        if (onAction != null)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: Text(
                  'Limpiar',
                  style: GoogleFonts.spaceGrotesk(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHistoryChip(String query, ThemeData theme, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _searchController.text = query;
          _onSearch(query);
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkBg2 : AppTheme.lightBg2,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark
                  ? AppTheme.darkBorder.withValues(alpha: 0.3)
                  : AppTheme.lightBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history_rounded,
                  size: 13, color: theme.hintColor.withValues(alpha: 0.5)),
              const SizedBox(width: 6),
              Text(
                query,
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(
      String label, IconData icon, ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          _searchController.text = label;
          _onSearch(label);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkBg2 : AppTheme.lightBg2,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? AppTheme.darkBorder.withValues(alpha: 0.25)
                  : AppTheme.lightBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 13,
                  color: theme.colorScheme.primary.withValues(alpha: 0.8)),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
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
        childAspectRatio: 1.05,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: channels.length,
      itemBuilder: (context, index) {
        return ChannelCard(channel: channels[index]);
      },
    );
  }

  Widget _buildSearchResults(
      ChannelProvider provider, ThemeData theme, bool isDark) {
    final channels = provider.channels;

    if (channels.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.04),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  size: 48,
                  color: theme.hintColor.withValues(alpha: 0.3),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Sin resultados',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Intenta con otras palabras o\nrevisa la ortografía.',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  height: 1.5,
                  color: theme.hintColor,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Results header + grid
    return Column(
      children: [
        // Results info bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.filter_list_rounded,
                  size: 15, color: theme.hintColor.withValues(alpha: 0.5)),
              const SizedBox(width: 8),
              Text(
                '${channels.length} ${channels.length == 1 ? 'canal encontrado' : 'canales encontrados'}',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.hintColor,
                ),
              ),
              const Spacer(),
              Text(
                '"${_searchController.text}"',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        Divider(
          height: 1,
          color: isDark
              ? AppTheme.darkBorder.withValues(alpha: 0.15)
              : AppTheme.lightBorder.withValues(alpha: 0.3),
        ),
        // Grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.05,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: channels.length,
            itemBuilder: (context, index) {
              return ChannelCard(channel: channels[index]);
            },
          ),
        ),
      ],
    );
  }
}
