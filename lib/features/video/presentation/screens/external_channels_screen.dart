import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:pivote/features/video/data/models/channel.dart';
import 'package:pivote/features/video/presentation/screens/player_screen.dart';

/// External catalog reader for the public Killerchannels JSON.
/// It intentionally treats DRM license URLs as license metadata and never
/// fetches, logs, or extracts keys from them.
class ExternalChannelsScreen extends StatefulWidget {
  const ExternalChannelsScreen({super.key});

  static const String catalogUrl =
      'https://raw.githubusercontent.com/ENZO800-ui/OndoTv.apk/main/Killerchannels.json';

  @override
  State<ExternalChannelsScreen> createState() => _ExternalChannelsScreenState();
}

class _ExternalChannelsScreenState extends State<ExternalChannelsScreen> {
  bool _loading = true;
  String? _error;
  List<_ChannelGroup> _groups = const [];
  String _query = '';
  int _selectedGroup = 0;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await http
          .get(Uri.parse(ExternalChannelsScreen.catalogUrl),
              headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        throw Exception('El catálogo respondió HTTP ${response.statusCode}.');
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! List) {
        throw const FormatException('El formato del catálogo no es válido.');
      }
      final groups = <_ChannelGroup>[];
      for (final rawGroup in decoded) {
        if (rawGroup is! Map) continue;
        final groupName = (rawGroup['name'] ?? 'Otros').toString().trim();
        final rawSamples = rawGroup['samples'];
        if (rawSamples is! List) continue;
        final channels = <_ExternalChannel>[];
        for (final rawChannel in rawSamples) {
          if (rawChannel is! Map) continue;
          final item = Map<String, dynamic>.from(rawChannel);
          final name = (item['name'] ?? '').toString().trim();
          final uri = (item['uri'] ?? item['url'] ?? '').toString().trim();
          if (name.isEmpty || uri.isEmpty) continue;
          final parsedUri = Uri.tryParse(uri);
          if (parsedUri == null ||
              !parsedUri.hasScheme ||
              !{'http', 'https'}.contains(parsedUri.scheme.toLowerCase())) {
            continue;
          }
          final headers = <String, String>{};
          final rawHeaders = item['headers'];
          if (rawHeaders is Map) {
            for (final entry in rawHeaders.entries) {
              final key = entry.key.toString().trim();
              final value = entry.value.toString().trim();
              if (key.isNotEmpty && value.isNotEmpty) {
                headers[key] = value;
              }
            }
          }
          channels.add(_ExternalChannel(
            name: name,
            uri: uri,
            icon: (item['icono'] ?? item['logo'] ?? '').toString(),
            headers: headers,
            drmScheme: (item['drm_scheme'] ?? '').toString().toLowerCase(),
            drmLicenseUri: (item['drm_license_uri'] ?? '').toString().trim(),
          ));
        }
        if (channels.isNotEmpty) {
          groups.add(_ChannelGroup(name: groupName, channels: channels));
        }
      }
      if (groups.isEmpty) {
        throw const FormatException('No se encontraron canales válidos.');
      }
      if (!mounted) return;
      setState(() {
        _groups = groups;
        _selectedGroup = 0;
        _loading = false;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'La conexión tardó demasiado. Revisá tu conexión e intentá de nuevo.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'No se pudo cargar la lista. ${e.toString().replaceFirst('Exception: ', '')}';
      });
    }
  }

  List<_ExternalChannel> get _visibleChannels {
    if (_groups.isEmpty) return const [];
    final source = _groups[_selectedGroup].channels;
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return source;
    return source.where((c) => c.name.toLowerCase().contains(q)).toList();
  }

  void _openChannel(_ExternalChannel item) {
    final uri = Uri.parse(item.uri);
    final isDash = uri.path.toLowerCase().endsWith('.mpd') ||
        item.drmScheme == 'clearkey' ||
        item.drmScheme == 'widevine';
    final hasProtectedMetadata =
        item.drmScheme.isNotEmpty || item.drmLicenseUri.isNotEmpty;

    if (hasProtectedMetadata) {
      _showProtectedStreamInfo(item);
      return;
    }

    final streamType = isDash ? 'dash' : 'hls';
    final channel = Channel(
      id: 'external_${Uri.encodeComponent(item.name)}',
      name: item.name,
      category: _groups[_selectedGroup].name,
      logoUrl: item.icon.isNotEmpty ? [item.icon] : const [],
      streamUrl: [
        StreamSource(
          url: item.uri,
          label: item.name,
          headers: item.headers.isEmpty ? null : item.headers,
        ),
      ],
      description: 'Canal del catálogo externo.',
      type: streamType,
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlayerScreen(channel: channel),
      ),
    );
  }

  void _showProtectedStreamInfo(_ExternalChannel channel) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Canal protegido', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800)),
        content: Text(
          '${channel.name} declara DRM (${channel.drmScheme.isEmpty ? 'esquema no especificado' : channel.drmScheme}). Para reproducirlo hace falta que el proveedor habilite una configuración de licencia compatible con ExoPlayer/Media3. Esta versión no descarga ni extrae claves temporales desde URLs.',
          style: GoogleFonts.spaceGrotesk(height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final visible = _visibleChannels;
    final total = _groups.fold<int>(0, (sum, group) => sum + group.channels.length);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Canales externos', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: 'Actualizar lista',
            onPressed: _loading ? null : _loadCatalog,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError(theme)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                      child: TextField(
                        onChanged: (value) => setState(() => _query = value),
                        decoration: InputDecoration(
                          hintText: 'Buscar canal...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          filled: true,
                          fillColor: theme.colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 44,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: _groups.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final selected = index == _selectedGroup;
                          return ChoiceChip(
                            label: Text(_groups[index].name),
                            selected: selected,
                            onSelected: (_) => setState(() => _selectedGroup = index),
                            labelStyle: GoogleFonts.spaceGrotesk(
                              fontWeight: FontWeight.w700,
                              color: selected
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface,
                            ),
                            selectedColor: theme.colorScheme.primary,
                            backgroundColor: theme.colorScheme.surface,
                            side: BorderSide(
                              color: selected
                                  ? theme.colorScheme.primary
                                  : theme.dividerColor.withValues(alpha: 0.18),
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _groups[_selectedGroup].name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w800),
                            ),
                          ),
                          Text(
                            '${visible.length} canales · $total en total',
                            style: GoogleFonts.spaceGrotesk(fontSize: 11, color: theme.hintColor, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: visible.isEmpty
                          ? Center(child: Text('No hay canales con ese nombre.', style: GoogleFonts.spaceGrotesk(color: theme.hintColor)))
                          : GridView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 190,
                                mainAxisExtent: 148,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: visible.length,
                              itemBuilder: (context, index) => _buildChannelCard(
                                visible[index], theme, isDark,
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildError(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 46, color: theme.hintColor),
            const SizedBox(height: 16),
            Text(_error ?? 'Error desconocido', textAlign: TextAlign.center, style: GoogleFonts.spaceGrotesk(height: 1.45)),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _loadCatalog,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelCard(_ExternalChannel channel, ThemeData theme, bool isDark) {
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => _openChannel(channel),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.13)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: channel.icon.isEmpty
                    ? Icon(Icons.live_tv_rounded, size: 38, color: theme.colorScheme.primary)
                    : CachedNetworkImage(
                        imageUrl: channel.icon,
                        fit: BoxFit.contain,
                        errorWidget: (_, __, ___) => Icon(Icons.live_tv_rounded, size: 38, color: theme.colorScheme.primary),
                      ),
              ),
              const SizedBox(height: 8),
              Text(
                channel.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface),
              ),
              if (channel.drmScheme.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('PROTEGIDO', style: GoogleFonts.spaceGrotesk(fontSize: 8, fontWeight: FontWeight.w900, color: isDark ? theme.colorScheme.primary : theme.colorScheme.error)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChannelGroup {
  final String name;
  final List<_ExternalChannel> channels;
  const _ChannelGroup({required this.name, required this.channels});
}

class _ExternalChannel {
  final String name;
  final String uri;
  final String icon;
  final Map<String, String> headers;
  final String drmScheme;
  final String drmLicenseUri;

  const _ExternalChannel({
    required this.name,
    required this.uri,
    required this.icon,
    required this.headers,
    required this.drmScheme,
    required this.drmLicenseUri,
  });
}
