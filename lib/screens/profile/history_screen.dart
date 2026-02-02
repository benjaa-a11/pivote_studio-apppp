import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/channel_provider.dart';
import '../../services/viewing_history_service.dart';
import '../../models/channel.dart';
import '../../config/app_animations.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Channel> _historyChannels = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final historyIds = await ViewingHistoryService.getTopChannels();
    if (!mounted) return;
    final channelProvider =
        Provider.of<ChannelProvider>(context, listen: false);

    final channels = historyIds
        .map((id) => channelProvider.channels.firstWhere((c) => c.id == id,
            orElse: () => Channel(
                id: '',
                name: 'Canal Eliminado',
                category: '',
                logoUrl: [],
                streamUrl: [],
                description: '')))
        .where((c) => c.id.isNotEmpty)
        .toList();

    if (mounted) {
      setState(() {
        _historyChannels = channels;
        _isLoading = false;
      });
    }
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Limpiar Historial',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
        content: const Text(
            '¿Estás seguro de que deseas borrar todo tu historial de visualización?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Borrar Todo', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ViewingHistoryService.clearHistory();
      _loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Historial de Canales',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        actions: [
          if (_historyChannels.isNotEmpty)
            IconButton(
              onPressed: _clearHistory,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _historyChannels.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  itemCount: _historyChannels.length,
                  itemBuilder: (context, index) {
                    final channel = _historyChannels[index];
                    return AppAnimations.staggeredListItem(
                      index: index,
                      child: _buildHistoryCard(channel),
                    );
                  },
                ),
    );
  }

  Widget _buildHistoryCard(Channel channel) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final logoUrl = channel.getLogoUrl(isDark);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: logoUrl.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(logoUrl, fit: BoxFit.cover),
                )
              : Icon(Icons.tv, color: theme.colorScheme.primary),
        ),
        title: Text(
          channel.name,
          style:
              GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Text(
          channel.category,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () {
          // Navegar al reproductor (esto depende de cómo manejes la navegación)
          // Navigator.of(context).pushNamed('/player', arguments: channel);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.history_toggle_off,
                size: 64, color: Colors.grey.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 24),
          Text(
            'Tu historial está vacío',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text('Los canales que veas aparecerán aquí.'),
        ],
      ),
    );
  }
}
