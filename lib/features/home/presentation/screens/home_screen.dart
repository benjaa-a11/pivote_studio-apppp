import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/features/home/presentation/widgets/unified_home_header.dart';
import 'package:pivote/features/video/presentation/providers/channel_provider.dart';
import 'package:pivote/features/video/presentation/widgets/channel_card.dart';
import 'package:pivote/shared/widgets/common/app_state_views.dart';
import 'package:pivote/shared/widgets/common/loading_shimmer.dart';
import 'package:pivote/shared/widgets/common/pivote_surfaces.dart';

class HomeScreen extends StatefulWidget {
  final void Function(int tabIndex)? onNavigateToTab;

  const HomeScreen({super.key, this.onNavigateToTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: AppAnimations.slow,
    );
    _fade = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.025),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutCubic,
      ),
    );
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hPad = AppResponsive.screenHorizontalPadding(context);

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: PivoteAmbientBackdrop(
        child: SafeArea(
          bottom: false,
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: CustomScrollView(
                physics: const ClampingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: UnifiedHomeHeader(
                      onNavigateToTab: widget.onNavigateToTab,
                    ),
                  ),

                  // Encabezado unificado de sección de canales
                  SliverToBoxAdapter(
                    child: Consumer<ChannelProvider>(
                      builder: (context, channelProvider, _) {
                        final category = channelProvider.selectedCategory;
                        final count = channelProvider.channels.length;
                        return Padding(
                          padding: const EdgeInsets.only(top: 10, bottom: 4),
                          child: PivoteSectionHeader(
                            title: category == 'Todos'
                                ? 'Canales en vivo'
                                : category,
                            badgeText:
                                channelProvider.isLoading ? null : '$count',
                            padding: hPad,
                          ),
                        );
                      },
                    ),
                  ),

                  // Grilla adaptativa de canales con Skeleton + Shimmer real
                  SliverPadding(
                    padding: hPad.add(
                      const EdgeInsets.only(
                        top: AppSpacing.sm,
                        bottom: AppSpacing.md,
                      ),
                    ),
                    sliver: Consumer<ChannelProvider>(
                      builder: (context, channelProvider, child) {
                        final isLoading = channelProvider.isLoading;
                        if (isLoading) {
                          return const PivoteChannelGridSkeleton(itemCount: 8);
                        }

                        final channels = channelProvider.channels;
                        if (channels.isEmpty) {
                          return SliverToBoxAdapter(
                            child: AppStateView.empty(
                              icon: Icons.tv_off_rounded,
                              title: 'No se encontraron canales',
                              subtitle:
                                  'Ajustá los filtros de categoría o realizá una nueva búsqueda.',
                              actionLabel: 'Mostrar todos',
                              actionIcon: Icons.refresh_rounded,
                              onAction: channelProvider.clearFilters,
                            ),
                          );
                        }

                        return SliverGrid(
                          gridDelegate: AppResponsive.channelGridDelegate(
                            context,
                            aspectRatio: 1.12,
                            spacing: 12,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) =>
                                ChannelCard(channel: channels[index]),
                            childCount: channels.length,
                          ),
                        );
                      },
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 110)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
