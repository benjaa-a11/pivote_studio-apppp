import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/radio_provider.dart';
import '../providers/audio_manager.dart';
import '../models/radio.dart' as radio_model;
import 'radio_player_screen.dart';

class RadiosScreen extends StatefulWidget {
  const RadiosScreen({super.key});

  @override
  State<RadiosScreen> createState() => _RadiosScreenState();
}

class _RadiosScreenState extends State<RadiosScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Floating Header
            SliverAppBar(
              floating: true,
              snap: true,
              elevation: 0,
              backgroundColor: theme.scaffoldBackgroundColor,
              automaticallyImplyLeading: false,
              titleSpacing: 24,
              title: Text(
                'Radio',
                style: GoogleFonts.montserrat(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  letterSpacing: -0.5,
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: _buildCategoryFilters(context, isDark),
              ),
            ),

            // Radio List Content
            _buildSliverRadioList(context, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilters(BuildContext context, bool isDark) {
    return Consumer<RadioProvider>(
      builder: (context, provider, _) {
        final categories = provider.categories;

        return Container(
          height: 44,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = provider.activeCategory == category;
              final textColor = isDark ? Colors.white : Colors.black;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => provider.setActiveCategory(category),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? Colors.white : Colors.black)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.05)),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : textColor.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      category.toUpperCase(),
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? Theme.of(context).colorScheme.surface
                            : textColor.withValues(alpha: 0.6),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSliverRadioList(BuildContext context, bool isDark) {
    return Consumer2<RadioProvider, AudioManager>(
      builder: (context, radioProvider, audioManager, child) {
        final isLoading = radioProvider.isLoading;
        final radios = isLoading
            ? List.generate(
                8,
                (i) => radio_model.Radio(
                    id: 'dummy_$i',
                    name: 'Cargando emisora...',
                    frequency: 'Cargando...',
                    logoUrl: '',
                    streamUrl: []))
            : radioProvider.radios;

        if (!isLoading && radios.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.radio_rounded,
                    size: 64,
                    color: isDark ? Colors.white10 : Colors.black12,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No se encontraron radios',
                    style: GoogleFonts.montserrat(
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final radio = radios[index];
                return Skeletonizer(
                  enabled: isLoading,
                  child: _buildRadioItem(context, radio, audioManager, isDark),
                );
              },
              childCount: radios.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildRadioItem(BuildContext context, radio_model.Radio radio,
      AudioManager audioManager, bool isDark) {
    final isCurrent = audioManager.currentRadio?.id == radio.id;
    final textColor = isDark ? Colors.white : Colors.black;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                RadioPlayerScreen(radio: radio),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: animation.drive(Tween(
                  begin: const Offset(0.0, 1.0),
                  end: Offset.zero,
                ).chain(CurveTween(curve: Curves.easeOutCubic))),
                child: child,
              );
            },
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        color: Colors.transparent, // For better hit testing
        child: Row(
          children: [
            // Station Logo
            Hero(
              tag: 'radio_tile_logo_${radio.id}',
              child: Container(
                width: 64,
                height: 64,
                decoration: ShapeDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  shadows: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: radio.logoUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, _) =>
                        Container(color: Colors.transparent),
                    errorWidget: (context, _, __) => Icon(
                      Icons.radio_rounded,
                      color: isDark
                          ? Colors.white24
                          : Colors.black12, // Fixed from black24
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            // Station Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    radio.name,
                    style: GoogleFonts.montserrat(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: isCurrent
                          ? Theme.of(context).primaryColor
                          : textColor,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    radio.frequency,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: textColor.withValues(alpha: 0.5),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Play/Chevron Icon
            Icon(
              Icons.chevron_right_rounded,
              color: textColor.withValues(alpha: 0.3),
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}
