import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/core/services/image_cache_helper.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/features/favorites/data/services/viewing_history_service.dart';
import 'package:pivote/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:pivote/features/profile/presentation/widgets/profile_design_system.dart';
import 'package:pivote/features/video/data/models/channel.dart';
import 'package:pivote/features/video/presentation/providers/channel_provider.dart';
import 'package:pivote/features/video/presentation/screens/player_screen.dart';
import 'package:pivote/shared/widgets/app_notifications.dart';
import 'package:pivote/shared/widgets/common/app_dialogs.dart';
import 'package:pivote/shared/widgets/common/app_state_views.dart';
import 'package:pivote/shared/widgets/common/loading_shimmer.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Channel> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final ids = await ViewingHistoryService.getTopChannels();
    if (!mounted) return;
    final provider = context.read<ChannelProvider>();
    final resolved = <Channel>[];
    for (final id in ids) {
      for (final channel in provider.allChannels) {
        if (channel.id == id) {
          resolved.add(channel);
          break;
        }
      }
    }
    if (mounted) {
      setState(() {
        _items = resolved;
        _loading = false;
      });
    }
  }

  Future<void> _clear() async {
    final ok = await AppDialogs.showConfirm(
      context: context,
      title: '¿Vaciar historial?',
      message:
          'Se eliminarán los canales reproducidos recientemente en este dispositivo.',
      confirmLabel: 'Vaciar historial',
      cancelLabel: 'Cancelar',
      isDestructive: true,
      type: AppDialogType.error,
    );
    if (ok != true) return;
    await HapticFeedback.mediumImpact();
    await ViewingHistoryService.clearHistory();
    if (!mounted) return;
    await _load();
    if (!mounted) return;
    AppNotifications.showInfo(context, 'Historial vaciado correctamente');
  }

  @override
  Widget build(BuildContext context) {
    return ProfileSubsectionScaffold(
      title: 'Historial',
      subtitle: 'Reproducidos recientemente',
      children: [
        if (_loading)
          const PivoteHistorySkeleton(itemCount: 6)
        else if (_items.isEmpty)
          const AppStateView.empty(
            icon: Icons.history_rounded,
            title: 'Historial vacío',
            subtitle:
                'Los canales que reproduzcas aparecerán acá para volver a verlos rápido.',
            compact: true,
          )
        else ...[
          AppAnimations.staggeredSlideIn(
            index: 0,
            child: ProfileGroupCard(
              children: [
                for (final channel in _items) _buildChannelRow(context, channel),
              ],
            ),
          ),
          AppAnimations.staggeredSlideIn(
            index: 1,
            child: ProfileActionButton(
              label: 'Vaciar historial',
              variant: ProfileButtonVariant.danger,
              onTap: _clear,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildChannelRow(BuildContext context, Channel channel) {
    final isDark = AppTheme.isDark(context);
    final favProvider = context.watch<FavoritesProvider>();
    final isFav = favProvider.isFavorite(channel.id);
    final logo = channel.getLogoUrl(isDark);

    return ProfileGroupRow(
      horizontalGap: 14,
      leading: Container(
        width: 44,
        height: 44,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppTheme.surface2(context),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppTheme.border(context)),
        ),
        child: logo.isNotEmpty
            ? CachedNetworkImage(
                key: ValueKey<String>(logo),
                cacheManager: ImageCacheHelper.logoCacheManager,
                imageUrl: logo,
                fit: BoxFit.contain,
                memCacheWidth: 100,
                placeholder: (_, __) => const PivoteShimmer(
                  child: PivoteShimmerBone(width: 28, height: 18),
                ),
                errorWidget: (_, __, ___) => Icon(
                  Icons.tv_rounded,
                  size: 20,
                  color: AppTheme.textTertiary(context),
                ),
              )
            : Icon(
                Icons.tv_rounded,
                size: 20,
                color: AppTheme.textTertiary(context),
              ),
      ),
      title: channel.name,
      subtitle: channel.category,
      trailing: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          favProvider.toggleFavorite(channel);
        },
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            size: 20,
            color: isFav
                ? AppTheme.danger(context)
                : AppTheme.textTertiary(context),
          ),
        ),
      ),
      showChevron: true,
      onTap: () {
        Navigator.push(
          context,
          AppAnimations.createFadeRoute(PlayerScreen(channel: channel)),
        );
      },
    );
  }
}
