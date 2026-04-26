import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pivote/features/radio/presentation/providers/radio_provider.dart';
import 'package:pivote/features/radio/presentation/providers/audio_manager.dart';
import 'package:pivote/features/radio/data/models/radio.dart' as radio_model;
import 'package:pivote/features/radio/presentation/screens/radio_player_screen.dart';

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
            // Floating Header
            SliverAppBar(
              floating: true,
              snap: true,
              elevation: 0,
              backgroundColor: theme.scaffoldBackgroundColor,
              automaticallyImplyLeading: false,
              titleSpacing: 24,
              title: Row(
                children: [
                  Text(
                    'Radio',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Consumer<RadioProvider>(
                    builder: (context, provider, _) {
                      if (provider.isLoading || provider.radios.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${provider.radios.length}',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      );
                    },
                  ),
                ],
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
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
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
                  child: CachedNetworkImage(
                    imageUrl: radio.logoUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, _) =>
                        Container(color: Colors.transparent),
                    errorWidget: (context, _, __) => Icon(
                      Icons.radio_rounded,
                      size: 24,
                      color: isDark ? Colors.white24 : Colors.black26,
                    ),
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
