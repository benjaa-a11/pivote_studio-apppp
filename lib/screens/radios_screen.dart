import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [
                          const Color(0xFF0F172A),
                          const Color(0xFF030712),
                        ]
                      : [
                          theme.colorScheme.primary.withValues(alpha: 0.05),
                          theme.scaffoldBackgroundColor,
                        ],
                  stops: const [0.0, 0.4],
                ),
              ),
            ),
          ),

          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(context, isDark),
              _buildRadioList(context),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    return SliverAppBar(
      expandedHeight: 140.0,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      stretch: true,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.blurBackground,
          StretchMode.zoomBackground
        ],
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Text(
          'Radio en Vivo',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 24,
            letterSpacing: -1,
          ),
        ),
      ),
    );
  }

  Widget _buildRadioList(BuildContext context) {
    return Consumer2<RadioProvider, AudioManager>(
      builder: (context, radioProvider, audioManager, child) {
        final isLoading = radioProvider.isLoading;
        final radios = isLoading
            ? List.generate(
                8,
                (_) => radio_model.Radio(
                    id: 'dummy',
                    name: 'Cargando emisora...',
                    frequency: '000.0 FM',
                    logoUrl: '',
                    streamUrl: []))
            : radioProvider.radios;

        if (!isLoading && radios.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(
                    FontAwesomeIcons.radio,
                    size: 64,
                    color: Colors.grey.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No se encontraron radios',
                    style: GoogleFonts.montserrat(
                      color: Colors.grey,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final radio = radios[index];
                return Skeletonizer(
                  enabled: isLoading,
                  child: FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _animationController,
                      curve: Interval(
                        (index / (radios.length + 1)).clamp(0, 1),
                        1.0,
                        curve: Curves.easeOut,
                      ),
                    ),
                    child: _buildRadioTile(
                        context, radio, audioManager, isLoading),
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

  Widget _buildRadioTile(BuildContext context, radio_model.Radio radio,
      AudioManager audioManager, bool isLoading) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCurrent = !isLoading && audioManager.currentRadio?.id == radio.id;
    final isPlaying = isCurrent && audioManager.isPlaying;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrent
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.withValues(alpha: 0.1)),
          width: 1.5,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (isLoading) return;
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      RadioPlayerScreen(radio: radio),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    const begin = Offset(0.0, 1.0);
                    const end = Offset.zero;
                    const curve = Curves.easeOutCubic;
                    var tween = Tween(begin: begin, end: end)
                        .chain(CurveTween(curve: curve));
                    return SlideTransition(
                        position: animation.drive(tween), child: child);
                  },
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Logo
                  Hero(
                    tag: 'radio_tile_logo_${radio.id}',
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: radio.logoUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, _) =>
                              Container(color: Colors.grey[isDark ? 900 : 200]),
                          errorWidget: (context, _, __) => Container(
                            color: Colors.grey[isDark ? 900 : 200],
                            child: const Icon(Icons.radio, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          radio.name,
                          style: GoogleFonts.montserrat(
                            color: isDark ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          radio.frequency,
                          style: GoogleFonts.montserrat(
                            color: Colors.grey,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status Icon
                  if (isCurrent)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: isPlaying
                          ? Icon(Icons.equalizer_rounded,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20)
                          : Icon(Icons.play_arrow_rounded,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20),
                    )
                  else
                    Icon(Icons.chevron_right_rounded,
                        color: Colors.grey.withValues(alpha: 0.5)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
