import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pivote/core/animations/app_animations.dart';
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
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final ids = await ViewingHistoryService.getTopChannels();
    if (!mounted) return;
    final provider = context.read<ChannelProvider>();
    final resolved = ids.map((id) => provider.channels.where((c) => c.id == id).cast<Channel?>().firstOrNull).whereType<Channel>().toList();
    setState(() { _items = resolved; _loading = false; });
  }

  Future<void> _clear() async {
    final ok = await AppDialogs.showConfirm(context: context, title: '¿Limpiar historial?', message: 'Se eliminarán los canales vistos recientemente de este dispositivo.', confirmLabel: 'Limpiar', cancelLabel: 'Cancelar', isDestructive: true, type: AppDialogType.error);
    if (ok != true) return;
    await ViewingHistoryService.clearHistory();
    if (!mounted) return;
    await _load();
    AppNotifications.showInfo(context, 'Historial limpiado');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PivoteAppBar(
        title: 'Historial',
        subtitle: _items.isEmpty ? 'Tus reproducciones recientes' : '${_items.length} canales vistos',
        actions: [
          if (_items.isNotEmpty)
            IconButton(tooltip: 'Limpiar historial', onPressed: _clear, icon: Icon(Icons.delete_sweep_rounded, color: theme.colorScheme.error)),
        ],
      ),
      body: _loading
          ? const Center(child: PivoteLoader(size: 40))
          : _items.isEmpty
              ? _empty(context)
              : RefreshIndicator.adaptive(
                  onRefresh: _load,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 9),
                    itemBuilder: (_, index) => AppAnimations.staggeredSlideIn(index: index, child: _card(context, _items[index])),
                  ),
                ),
    );
  }

  Widget _card(BuildContext context, Channel channel) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final logo = channel.getLogoUrl(dark);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: () => Navigator.push(context, AppAnimations.createFadeRoute(PlayerScreen(channel: channel))),
        borderRadius: BorderRadius.circular(19),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(19), border: Border.all(color: theme.dividerColor.withValues(alpha: .07))),
          child: Row(children: [
            Container(width: 62, height: 62, padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: .07), borderRadius: BorderRadius.circular(16)), child: logo.isNotEmpty ? Image.network(logo, fit: BoxFit.contain, errorBuilder: (_, __, ___) => Icon(Icons.tv_rounded, color: theme.colorScheme.primary)) : Icon(Icons.tv_rounded, color: theme.colorScheme.primary)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(channel.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.spaceGrotesk(fontSize: 14.5, fontWeight: FontWeight.w900)), const SizedBox(height: 4), Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4), decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: .08), borderRadius: BorderRadius.circular(7)), child: Text(channel.category.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.spaceGrotesk(fontSize: 8.5, fontWeight: FontWeight.w900, color: theme.colorScheme.primary, letterSpacing: .8)))])),
            const SizedBox(width: 8),
            Container(width: 34, height: 34, decoration: BoxDecoration(color: theme.colorScheme.onSurface.withValues(alpha: .05), shape: BoxShape.circle), child: Icon(Icons.play_arrow_rounded, size: 19, color: theme.colorScheme.onSurface.withValues(alpha: .75))),
          ]),
        ),
      ),
    );
  }

  Widget _empty(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    return Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 38), child: Column(mainAxisSize: MainAxisSize.min, children: [Container(width: 78, height: 78, decoration: BoxDecoration(color: accent.withValues(alpha: .08), borderRadius: BorderRadius.circular(24)), child: Icon(Icons.history_rounded, size: 38, color: accent)), const SizedBox(height: 18), Text('Todavía no hay historial', textAlign: TextAlign.center, style: GoogleFonts.spaceGrotesk(fontSize: 21, fontWeight: FontWeight.w900, letterSpacing: -.4)), const SizedBox(height: 7), Text('Los canales que reproduzcas aparecerán acá para volver a encontrarlos rápidamente.', textAlign: TextAlign.center, style: GoogleFonts.spaceGrotesk(fontSize: 11.5, fontWeight: FontWeight.w600, color: theme.hintColor, height: 1.45)), const SizedBox(height: 18), ElevatedButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.explore_rounded, size: 17), label: const Text('Explorar Pivote'))])));
  }
}
