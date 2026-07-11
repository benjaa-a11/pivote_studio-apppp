import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:pivote/features/video/presentation/providers/channel_provider.dart';
import 'package:pivote/features/video/presentation/widgets/channel_card.dart';
import 'package:pivote/features/home/presentation/widgets/unified_home_header.dart';
import 'package:pivote/features/video/data/models/channel.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/core/animations/app_animations.dart';

class HomeScreen extends StatefulWidget {
  /// Se mantiene por compatibilidad con MainScreen (bottom-nav host).
  /// Ya no se usa internamente: el discovery row que lo consumía fue
  /// removido de Inicio en el rediseño 5.0.0.
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
    // Animación de entrada única al montar la pantalla (no se repite en
    // rebuilds posteriores, ya que el pull-to-refresh fue removido y el
    // controller no vuelve a dispararse).
    _entranceController = AnimationController(
      vsync: this,
      duration: AppAnimations.slow,
    );
    _fade = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.035),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    ));
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: CustomScrollView(
              // Pull-to-refresh deshabilitado a propósito: interrumpía la
              // fluidez del scroll. Los providers (canales, fútbol) ya se
              // mantienen frescos por su propia lógica interna.
              physics: const ClampingScrollPhysics(),
              slivers: [
                // Header premium unificado (saludo, buscador y hero de partidos)
                const SliverToBoxAdapter(
                  child: UnifiedHomeHeader(),
                ),

                // Título de sección, reacciona a la categoría activa
                SliverToBoxAdapter(
                  child: Consumer<ChannelProvider>(
                    builder: (context, provider, child) {
                      return _buildSectionTitle(theme, provider.selectedCategory);
                    },
                  ),
                ),

                // Grid de canales
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
                  sliver: Consumer<ChannelProvider>(
                    builder: (context, channelProvider, child) {
                      final isLoading = channelProvider.isLoading;
                      final channels = isLoading
                          ? List.generate(
                              8,
                              (index) => Channel(
                                    id: 'dummy',
                                    name: 'Channel Name',
                                    logoUrl: [''],
                                    streamUrl: [StreamSource(url: '')],
                                    category: 'General',
                                    description: 'Description',
                                  ))
                          : channelProvider.channels;

                      if (!isLoading && channels.isEmpty) {
                        return SliverToBoxAdapter(
                          child: _buildEmptyState(context, channelProvider),
                        );
                      }

                      return SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.05,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
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
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String selectedCategory) {
    final title =
        selectedCategory == 'Todos' ? 'Todos los canales' : selectedCategory;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
      child: Text(
        title,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: theme.colorScheme.onSurface,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  Widget _buildEmptyState(
      BuildContext context, ChannelProvider channelProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.15),
                    Theme.of(context)
                        .colorScheme
                        .secondary
                        .withValues(alpha: 0.15),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.tv_off_rounded,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'No se encontraron canales',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Intenta ajustar tus filtros o realiza\nuna nueva búsqueda',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                    height: 1.5,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                channelProvider.clearFilters();
              },
              icon: const Icon(Icons.refresh_rounded, size: 22),
              label: const Text('Limpiar filtros'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
