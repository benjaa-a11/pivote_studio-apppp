import 'package:flutter/material.dart';
import '../../data/models/vod_content.dart';
import '../../data/services/vod_service.dart';
import 'content_details_screen.dart';

class CinemaScreen extends StatefulWidget {
  const CinemaScreen({super.key});

  @override
  State<CinemaScreen> createState() => _CinemaScreenState();
}

class _CinemaScreenState extends State<CinemaScreen>
    with SingleTickerProviderStateMixin {
  final VodService _vodService = VodService();
  late TabController _tabController;

  // State
  List<VodContent> _featuredContent = [];
  List<VodContent> _displayContent = [];
  bool _isLoading = true;
  ContentType _selectedType = ContentType.movie;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadInitialData();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;

    ContentType newType;
    switch (_tabController.index) {
      case 0:
        newType = ContentType.movie;
        break;
      case 1:
        newType = ContentType.series;
        break;
      case 2:
        newType = ContentType.program;
        break;
      default:
        newType = ContentType.movie;
    }

    if (newType != _selectedType) {
      setState(() {
        _selectedType = newType;
        _isLoading = true;
      });
      _loadContent(newType);
    }
  }

  Future<void> _loadInitialData() async {
    final featured = await _vodService.getFeaturedContent();
    if (mounted) {
      setState(() {
        _featuredContent = featured;
      });
      _loadContent(_selectedType);
    }
  }

  Future<void> _loadContent(ContentType type) async {
    final content = await _vodService.getContentByType(type);
    if (mounted) {
      setState(() {
        _displayContent = content;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark Navy
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          _buildFeaturedSection(),
          _buildCategories(),
          _buildContentGrid(),
          const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      pinned: true,
      backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.9),
      elevation: 0,
      title: const Text(
        'CINE',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
          fontSize: 24,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white70),
          onPressed: () {
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildFeaturedSection() {
    if (_featuredContent.isEmpty && !_isLoading) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Text(
              'Destacados',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const BouncingScrollPhysics(),
              itemCount: _isLoading ? 3 : _featuredContent.length,
              itemBuilder: (context, index) {
                if (_isLoading) return _buildFeaturedSkeleton();

                final content = _featuredContent[index];
                return _buildFeaturedCard(content);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedCard(VodContent content) {
    return GestureDetector(
      onTap: () => _openPlayer(content),
      child: Container(
        width: 320,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(
            image: NetworkImage(content.backdropUrl ?? content.posterUrl ?? ''),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withValues(alpha: 0.9),
                Colors.black.withValues(alpha: 0.1),
              ],
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  content.type == ContentType.movie
                      ? 'PELÍCULA'
                      : content.type == ContentType.series
                          ? 'SERIE'
                          : 'PROGRAMA',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                content.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverAppBarDelegate(
        TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.primary,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'PELÍCULAS'),
            Tab(text: 'SERIES'),
            Tab(text: 'PROGRAMAS'),
          ],
        ),
      ),
    );
  }

  Widget _buildContentGrid() {
    if (_isLoading) {
      return SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverGrid(
          gridDelegate: _getGridDelegate(),
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildGridSkeleton(),
            childCount: 8,
          ),
        ),
      );
    }

    if (_displayContent.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Text(
            'No se encontró contenido',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: _getGridDelegate(),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final content = _displayContent[index];
            return _buildContentCard(content);
          },
          childCount: _displayContent.length,
        ),
      ),
    );
  }

  SliverGridDelegate _getGridDelegate() {
    final width = MediaQuery.of(context).size.width;
    int crossAxisCount = 2;
    if (width > 600) crossAxisCount = 3;
    if (width > 900) crossAxisCount = 4;
    if (width > 1200) crossAxisCount = 6;

    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 0.68,
    );
  }

  Widget _buildContentCard(VodContent content) {
    return GestureDetector(
      onTap: () => _openPlayer(content),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: NetworkImage(content.posterUrl ?? ''),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            content.genres.join(', '),
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _openPlayer(VodContent content) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ContentDetailsScreen(content: content),
      ),
    );
  }

  // SKELETONS

  Widget _buildFeaturedSkeleton() {
    return Container(
      width: 320,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _buildGridSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 14,
          width: 100,
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ],
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFF0F172A),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
