import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pivote/features/radio/presentation/providers/radio_provider.dart';
import 'package:pivote/features/radio/presentation/providers/audio_manager.dart';
import 'package:pivote/features/radio/data/models/radio.dart' as radio_model;
import 'package:pivote/features/radio/presentation/screens/radio_player_screen.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/services/image_cache_helper.dart';

class RadiosScreen extends StatefulWidget {
  const RadiosScreen({super.key});

  @override
  State<RadiosScreen> createState() => _RadiosScreenState();
}

class _RadiosScreenState extends State<RadiosScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const ClampingScrollPhysics(),
          slivers: [
            // Floating Header (Premium unified design)
            SliverAppBar(
              floating: true,
              snap: true,
              elevation: 0,
              backgroundColor: theme.scaffoldBackgroundColor,
              automaticallyImplyLeading: false,
              toolbarHeight: 72,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    border: Border(
                      bottom: BorderSide(
                        color: isDark
                            ? AppTheme.darkBorder.withValues(alpha: 0.15)
                            : AppTheme.lightBorder.withValues(alpha: 0.3),
                        width: 1.2,
                      ),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Radio Icon Container (Polished)
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary.withValues(alpha: isDark ? 0.22 : 0.14),
                              theme.colorScheme.primary.withValues(alpha: isDark ? 0.06 : 0.04),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.35 : 0.25),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.08 : 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.radio_rounded,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Title and Subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Radio',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.6,
                                color: textColor,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Emisoras de transmisión en vivo',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppTheme.darkText3 : AppTheme.lightText3,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Station count badge
                      Consumer<RadioProvider>(
                        builder: (context, provider, _) {
                          if (provider.isLoading || provider.radios.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '${provider.radios.length} VIVAS',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: theme.colorScheme.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Radio List Content
            _buildSliverRadioList(context, isDark),
          ],
        ),
      ),
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
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Icon(
                        Icons.radio_rounded,
                        size: 36,
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Sin emisoras disponibles',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Las emisoras aparecerán aquí cuando estén disponibles.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        color: Theme.of(context).hintColor.withValues(alpha: 0.6),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final radio = radios[index];
                final isLast = index == radios.length - 1;
                return Skeletonizer(
                  enabled: isLoading,
                  child: Column(
                    children: [
                      _buildRadioItem(context, radio, audioManager, isDark),
                      if (!isLast)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Divider(
                            height: 1,
                            thickness: 1,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.04),
                          ),
                        ),
                    ],
                  ),
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
    final textColor = Theme.of(context).colorScheme.onSurface;

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
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Row(
          children: [
            // Station Logo
            Hero(
              tag: 'radio_tile_logo_${radio.id}',
              child: Container(
                width: 56,
                height: 56,
                decoration: ShapeDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.04),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: radio.logoUrl.isNotEmpty
                      ? CachedNetworkImage(
                          // 🔧 FIX CRÍTICO: Usar logoCacheManager con User-Agent correcto
                          // Sin esto, los CDNs bloqueaban las requests con 403/404
                          key: ValueKey<String>(radio.logoUrl),
                          cacheManager: ImageCacheHelper.logoCacheManager,
                          imageUrl: radio.logoUrl,
                          fit: BoxFit.cover,
                          memCacheWidth: 150,
                          memCacheHeight: 150,
                          fadeInDuration: const Duration(milliseconds: 200),
                          fadeOutDuration: const Duration(milliseconds: 100),
                          placeholder: (context, _) => Shimmer.fromColors(
                            baseColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE8E8E8),
                            highlightColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE8E8E8),
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                          errorWidget: (context, _, __) => Icon(
                            Icons.radio_rounded,
                            size: 24,
                            color: isDark ? Colors.white24 : Colors.black26,
                          ),
                        )
                      : Icon(
                          Icons.radio_rounded,
                          size: 24,
                          color: isDark ? Colors.white24 : Colors.black26,
                        ),
                ),
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
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isCurrent
                          ? Theme.of(context).colorScheme.primary
                          : textColor,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    radio.frequency,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: textColor.withValues(alpha: 0.45),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Play indicator if current
            if (isCurrent && audioManager.isPlaying)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.graphic_eq_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
