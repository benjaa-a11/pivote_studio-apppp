import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/services/image_cache_helper.dart';
import 'package:pivote/features/favorites/data/services/viewing_history_service.dart';
import 'package:pivote/features/video/data/models/channel.dart';
import 'package:pivote/features/video/presentation/providers/channel_provider.dart';
import 'package:pivote/features/video/presentation/screens/player_screen.dart';
import 'package:pivote/shared/widgets/app_notifications.dart';
import 'package:pivote/shared/widgets/common/app_dialogs.dart';
import 'package:pivote/shared/widgets/common/pivote_app_bar.dart';
import 'package:pivote/shared/widgets/common/pivote_loader.dart';

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
      for (final channel in provider.channels) {
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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PivoteAppBar(
        title: 'Historial',
        subtitle: _items.isEmpty
            ? 'Tus reproducciones recientes'
            : '${_items.length} canales vistos recientemente',
        actions: [
          if (_items.isNotEmpty)
            IconButton(
              tooltip: 'Vaciar historial',
              onPressed: _clear,
              icon: Icon(Icons.delete_sweep_rounded,
                  color: theme.colorScheme.error, size: 22),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: PivoteLoader(size: 40))
          : _items.isEmpty
              ? _empty(context)
              : RefreshIndicator.adaptive(
                  onRefresh: _load,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: ClampingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 36),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, index) => AppAnimations.staggeredSlideIn(
                      index: index,
                      child: _card(context, _items[index]),
                    ),
                  ),
                ),
    );
  }

  Widget _card(BuildContext context, Channel channel) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor =
        isDark ? AppTheme.darkAccent : theme.colorScheme.primary;
    final logo = channel.getLogoUrl(isDark);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            AppAnimations.createFadeRoute(PlayerScreen(channel: channel)),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.04),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: logo.isNotEmpty
                      ? CachedNetworkImage(
                          key: ValueKey<String>(logo),
                          cacheManager: ImageCacheHelper.logoCacheManager,
                          imageUrl: logo,
                          fit: BoxFit.contain,
                          memCacheWidth: 120,
                          errorWidget: (_, __, ___) => Icon(
                            Icons.tv_rounded,
                            color: primaryColor,
                            size: 26,
                          ),
                        )
                      : Icon(
                          Icons.tv_rounded,
                          color: primaryColor,
                          size: 26,
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      channel.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            channel.category.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              color: primaryColor,
                              letterSpacing: .6,
                            ),
                          ),
                        ),
                        if (channel.quality != null &&
                            channel.quality!.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              channel.quality!,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: theme.hintColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  size: 22,
                  color: primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _empty(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor =
        isDark ? AppTheme.darkAccent : theme.colorScheme.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(Icons.history_rounded, size: 38, color: primaryColor),
            ),
            const SizedBox(height: 18),
            Text(
              'Historial vacío',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Los canales y transmisiones que reproduzcas se guardarán acá para encontrarlos al instante.',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.hintColor,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.explore_rounded, size: 18),
              label: const Text('Explorar Canales'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: isDark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
