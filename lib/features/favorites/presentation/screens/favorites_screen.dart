import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:pivote/features/home/presentation/widgets/search_radio_tile.dart';
import 'package:pivote/features/radio/presentation/providers/radio_provider.dart';
import 'package:pivote/features/video/presentation/providers/channel_provider.dart';
import 'package:pivote/features/video/presentation/widgets/channel_card.dart';
import 'package:pivote/shared/widgets/app_notifications.dart';
import 'package:pivote/shared/widgets/common/app_dialogs.dart';
import 'package:pivote/shared/widgets/common/app_state_views.dart';
import 'package:pivote/shared/widgets/common/pivote_surfaces.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  Future<void> _showClearDialog(
    BuildContext context,
    FavoritesProvider favoritesProvider,
  ) async {
    final confirmed = await AppDialogs.showConfirm(
      context: context,
      title: '¿Limpiar favoritos?',
      message:
          'Esta acción eliminará todos los canales guardados en tu lista de favoritos.',
      confirmLabel: 'Eliminar',
      cancelLabel: 'Cancelar',
      isDestructive: true,
      type: AppDialogType.error,
    );

    if (confirmed == true) {
      await favoritesProvider.clearAllFavorites();
      if (context.mounted) {
        AppNotifications.showInfo(context, 'Lista de favoritos limpia');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final hPad = AppResponsive.screenHorizontalPadding(context);

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: PivoteAmbientBackdrop(
        child: Consumer3<ChannelProvider, FavoritesProvider, RadioProvider>(
          builder: (
            context,
            channelProvider,
            favoritesProvider,
            radioProvider,
            child,
          ) {
            final favoriteChannels = favoritesProvider.getSortedFavorites(
              channelProvider.allChannels,
            );
            final favoriteRadios =
                radioProvider.radios.where((r) => r.isFavorite).toList();
            final totalCount = favoriteChannels.length + favoriteRadios.length;

            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: CustomScrollView(
                  physics: const ClampingScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: hPad.add(EdgeInsets.only(top: topPad + 6)),
                      sliver: SliverToBoxAdapter(
                        child: PivoteSubHeader(
                          title: 'Favoritos',
                          showBackButton: canPop,
                          trailing: favoriteChannels.isNotEmpty
                              ? PivoteIconButton(
                                  icon: Icons.delete_outline_rounded,
                                  danger: true,
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    _showClearDialog(
                                      context,
                                      favoritesProvider,
                                    );
                                  },
                                )
                              : const SizedBox(width: 42, height: 42),
                        ),
                      ),
                    ),
                    if (totalCount == 0)
                      SliverPadding(
                        padding: hPad,
                        sliver: SliverToBoxAdapter(
                          child: AppAnimations.staggeredSlideIn(
                            index: 0,
                            child: AppStateView.empty(
                              icon: Icons.favorite_border_rounded,
                              title: 'Sin favoritos aún',
                              subtitle:
                                  'Tocá el ícono de corazón en cualquier canal o emisora de radio para guardarlo acá.',
                              actionLabel: canPop ? 'Explorar canales' : null,
                              actionIcon: Icons.explore_rounded,
                              onAction: canPop
                                  ? () => Navigator.of(context).maybePop()
                                  : null,
                            ),
                          ),
                        ),
                      )
                    else ...[
                      SliverPadding(
                        padding: hPad.add(const EdgeInsets.only(bottom: 10)),
                        sliver: SliverToBoxAdapter(
                          child: AppAnimations.staggeredSlideIn(
                            index: 0,
                            child: PivoteDiffusedCard(
                              borderRadius: AppRadius.lg,
                              glowColor: AppTheme.danger(context),
                              secondaryGlowColor: AppTheme.accent(context),
                              glowAlignment: const Alignment(-0.85, -0.5),
                              secondaryGlowAlignment: const Alignment(0.85, 0.5),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 14,
                              ),
                              child: IntrinsicHeight(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _FavSummaryStat(
                                        value: '${favoriteChannels.length}',
                                        label: 'Canales TV',
                                      ),
                                    ),
                                    VerticalDivider(
                                      width: 1,
                                      thickness: 1,
                                      color: AppTheme.border(context),
                                    ),
                                    Expanded(
                                      child: _FavSummaryStat(
                                        value: '${favoriteRadios.length}',
                                        label: 'Emisoras',
                                      ),
                                    ),
                                    VerticalDivider(
                                      width: 1,
                                      thickness: 1,
                                      color: AppTheme.border(context),
                                    ),
                                    Expanded(
                                      child: _FavSummaryStat(
                                        value: '$totalCount',
                                        label: 'Total',
                                        highlight: true,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (favoriteChannels.isNotEmpty) ...[
                        SliverPadding(
                          padding:
                              hPad.add(const EdgeInsets.only(top: 10, bottom: 12)),
                          sliver: SliverToBoxAdapter(
                            child: PivoteSectionHeader(
                              title: 'Canales guardados',
                              badgeText: '${favoriteChannels.length}',
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: hPad,
                          sliver: SliverGrid(
                            gridDelegate: AppResponsive.channelGridDelegate(
                              context,
                              aspectRatio: 1.12,
                              spacing: 12,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => ChannelCard(
                                channel: favoriteChannels[index],
                              ),
                              childCount: favoriteChannels.length,
                            ),
                          ),
                        ),
                      ],
                      if (favoriteRadios.isNotEmpty) ...[
                        SliverPadding(
                          padding:
                              hPad.add(const EdgeInsets.only(top: 22, bottom: 12)),
                          sliver: SliverToBoxAdapter(
                            child: PivoteSectionHeader(
                              title: 'Radios favoritas',
                              badgeText: '${favoriteRadios.length}',
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: hPad,
                          sliver: SliverList.separated(
                            itemCount: favoriteRadios.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) => SearchRadioTile(
                              radio: favoriteRadios[index],
                            ),
                          ),
                        ),
                      ],
                    ],
                    SliverToBoxAdapter(
                      child: SizedBox(height: math.max(96, bottomPad + 48)),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FavSummaryStat extends StatelessWidget {
  final String value;
  final String label;
  final bool highlight;

  const _FavSummaryStat({
    required this.value,
    required this.label,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppFont.mono(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: highlight
                ? AppTheme.accent(context)
                : AppTheme.textPrimary(context),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: AppFont.primary(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textTertiary(context),
          ),
        ),
      ],
    );
  }
}
