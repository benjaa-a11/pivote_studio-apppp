import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:pivote/features/home/presentation/widgets/search_radio_tile.dart';
import 'package:pivote/features/profile/presentation/widgets/profile_design_system.dart';
import 'package:pivote/features/radio/presentation/providers/radio_provider.dart';
import 'package:pivote/features/video/presentation/providers/channel_provider.dart';
import 'package:pivote/features/video/presentation/widgets/channel_card.dart';
import 'package:pivote/shared/widgets/app_notifications.dart';
import 'package:pivote/shared/widgets/common/app_dialogs.dart';

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
          'Esta acción eliminará todos los canales de tu lista de favoritos.',
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
    final palette = ProfilePalette.of(context);
    final canPop = Navigator.of(context).canPop();
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final hPad = AppResponsive.screenHorizontalPadding(context);

    return Scaffold(
      backgroundColor: palette.bg,
      body: Consumer3<ChannelProvider, FavoritesProvider, RadioProvider>(
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
                    padding: hPad.add(EdgeInsets.only(top: topPad + 10)),
                    sliver: SliverToBoxAdapter(
                      child: ProfileSubHeader(
                        title: 'Favoritos',
                        showBackButton: canPop,
                        trailing: favoriteChannels.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  _showClearDialog(context, favoritesProvider);
                                },
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: palette.dangerBg,
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.sm),
                                    border: Border.all(
                                      color: palette.dangerBorder,
                                      width: 1,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.delete_outline_rounded,
                                    size: 19,
                                    color: palette.danger,
                                  ),
                                ),
                              )
                            : const SizedBox(width: 40, height: 40),
                      ),
                    ),
                  ),
                  if (totalCount == 0)
                    SliverPadding(
                      padding: hPad,
                      sliver: SliverToBoxAdapter(
                        child: AppAnimations.staggeredSlideIn(
                          index: 0,
                          child: _buildEmptyCard(context, palette, canPop),
                        ),
                      ),
                    )
                  else ...[
                    SliverPadding(
                      padding: hPad.add(const EdgeInsets.only(bottom: 4)),
                      sliver: SliverToBoxAdapter(
                        child: AppAnimations.staggeredSlideIn(
                          index: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: palette.card,
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              border:
                                  Border.all(color: palette.border, width: 1),
                              boxShadow: palette.cardShadow,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _FavSummaryStat(
                                    value: '${favoriteChannels.length}',
                                    label: 'Canales TV',
                                  ),
                                ),
                                Expanded(
                                  child: _FavSummaryStat(
                                    value: '${favoriteRadios.length}',
                                    label: 'Emisoras',
                                  ),
                                ),
                                Expanded(
                                  child: _FavSummaryStat(
                                    value: '$totalCount',
                                    label: 'Total',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (favoriteChannels.isNotEmpty) ...[
                      SliverPadding(
                        padding: hPad,
                        sliver: const SliverToBoxAdapter(
                          child: ProfileSectionTitle('Canales guardados'),
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
                            (context, index) {
                              return ChannelCard(
                                channel: favoriteChannels[index],
                              );
                            },
                            childCount: favoriteChannels.length,
                          ),
                        ),
                      ),
                    ],
                    if (favoriteRadios.isNotEmpty) ...[
                      SliverPadding(
                        padding: hPad,
                        sliver: const SliverToBoxAdapter(
                          child: ProfileSectionTitle('Radios favoritas'),
                        ),
                      ),
                      SliverPadding(
                        padding: hPad,
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: SearchRadioTile(
                                  radio: favoriteRadios[index],
                                ),
                              );
                            },
                            childCount: favoriteRadios.length,
                          ),
                        ),
                      ),
                    ],
                  ],
                  SliverToBoxAdapter(
                    child: SizedBox(height: math.max(96, bottomPad + 88)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyCard(
    BuildContext context,
    ProfilePalette palette,
    bool canPop,
  ) {
    return Column(
      children: [
        ProfileGroupCard(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
          children: [
            Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: palette.iconBox,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.favorite_border_rounded,
                    size: 26,
                    color: palette.accent,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Sin favoritos aún',
                  style: AppFont.primary(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: palette.text,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tocá el ícono de corazón en cualquier canal o emisora de radio para guardarlo acá.',
                  textAlign: TextAlign.center,
                  style: AppFont.primary(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: palette.muted,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ],
        ),
        if (canPop)
          ProfileActionButton(
            label: 'Explorar canales',
            variant: ProfileButtonVariant.soft,
            onTap: () => Navigator.of(context).maybePop(),
          ),
      ],
    );
  }
}

class _FavSummaryStat extends StatelessWidget {
  final String value;
  final String label;

  const _FavSummaryStat({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ProfilePalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: AppFont.primary(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: palette.text,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: AppFont.primary(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: palette.muted,
            ),
          ),
        ],
      ),
    );
  }
}
