import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:pivote/features/video/presentation/providers/channel_provider.dart';
import 'package:pivote/features/video/presentation/widgets/channel_card.dart';
import 'package:pivote/features/home/presentation/widgets/unified_home_header.dart';
import 'package:pivote/features/video/data/models/channel.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/shared/widgets/common/app_state_views.dart';

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
      begin: const Offset(0, 0.03),
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
    final theme = Theme.of(context);
    final hPad = AppResponsive.screenHorizontalPadding(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
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

                // Encabezado de sección de canales
                SliverToBoxAdapter(
                  child: Consumer<ChannelProvider>(
                    builder: (context, channelProvider, _) {
                      final category = channelProvider.selectedCategory;
                      final count = channelProvider.channels.length;
                      return Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 4),
                        child: AppSectionTitle(
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

                // Grilla adaptativa de canales
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
                      final channels = isLoading
                          ? List.generate(
                              8,
                              (index) => Channel(
                                id: 'dummy_$index',
                                name: 'Canal en vivo',
                                logoUrl: const [''],
                                streamUrl: [StreamSource(url: '')],
                                category: 'Deportes',
                                description: 'Transmisión en vivo',
                              ),
                            )
                          : channelProvider.channels;

                      if (!isLoading && channels.isEmpty) {
                        return SliverToBoxAdapter(
                          child: AppStateView.empty(
                            icon: Icons.tv_off_rounded,
                            title: 'No se encontraron canales',
                            subtitle:
                                'Ajusta los filtros de categoría o realiza una nueva búsqueda.',
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
                          (context, index) {
                            final card = ChannelCard(channel: channels[index]);
                            return Skeletonizer(
                              enabled: isLoading,
                              child: card,
                            );
                          },
                          childCount: channels.length,
                        ),
                      );
                    },
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 104)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
