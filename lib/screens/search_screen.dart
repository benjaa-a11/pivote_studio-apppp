import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/channel_provider.dart';
import '../services/search_service.dart';
import '../widgets/channel_card.dart';
import '../config/app_theme.dart';
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
          // Clear search when leaving the screen to avoid filtering HomeScreen
          Provider.of<ChannelProvider>(context, listen: false)
              .searchChannels('');
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.darkBackground : Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, isDark),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _isSearching
                      ? _buildSearchResults(channelProvider, isDark)
                      : _buildInitialState(channelProvider, isDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: isDark
                      ? theme.colorScheme.surface.withValues(alpha: 0.8)
                      : theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.4),
                  padding: const EdgeInsets.all(14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Buscar',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 56,
            decoration: BoxDecoration(
              color: isDark
                  ? theme.colorScheme.surface.withValues(alpha: 0.6)
                  : theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: 0.05),
                width: 1.5,
              ),
              boxShadow: isDark
                  ? []
                  : [
                      BoxShadow(
                        color:
                            theme.colorScheme.primary.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: _onSearch,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'Encuentra tus canales favoritos...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 15,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.search_rounded,
                    color: theme.colorScheme.primary,
                    size: 26,
                  ),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialState(ChannelProvider provider, bool isDark) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      children: [
        if (_searchHistory.isNotEmpty) ...[
          _buildSectionHeader('Búsquedas recientes', onAction: () async {
            await SearchService.clearSearchHistory();
            _loadSearchHistory();
          }),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _searchHistory
                .take(5)
                .map((query) => _buildHistoryChip(query))
                .toList(),
          ),
          const SizedBox(height: 32),
        ],
        _buildSectionHeader('Canales populares'),
        const SizedBox(height: 20),
        _buildPopularChannels(provider),
      ],
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onAction}) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: theme.colorScheme.onSurface,
          ),
        ),
        if (onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Limpiar',
              style: GoogleFonts.inter(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
                fontSize: 14,
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? theme.colorScheme.onSurface.withValues(alpha: 0.05)
              : theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded,
                size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              query,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
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
        childAspectRatio: 1.05,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: channels.length,
      itemBuilder: (context, index) {
        return ChannelCard(channel: channels[index]);
      },
    );
  }

  Widget _buildSearchResults(ChannelProvider provider, bool isDark) {
    final channels = provider.channels;
    final theme = Theme.of(context);

    if (channels.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: isDark
                      ? theme.colorScheme.primary.withValues(alpha: 0.05)
                      : theme.colorScheme.primary.withValues(alpha: 0.02),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  size: 64,
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'No encontramos resultados',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Prueba con otras palabras o revisa que no haya errores de escritura para encontrar el canal que buscas.',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  height: 1.5,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.05,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: channels.length,
      itemBuilder: (context, index) {
        return ChannelCard(channel: channels[index]);
      },
    );
  }
}
