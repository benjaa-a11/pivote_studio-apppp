import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/features/video/data/models/channel.dart';
import 'package:pivote/features/video/data/services/drm_key_resolver.dart';
import 'package:pivote/features/video/presentation/screens/player_screen.dart';

// ════════════════════════════════════════════════════════════════════════════
// ExternalChannelsScreen v2.0 — Full DRM Support
// ════════════════════════════════════════════════════════════════════════════
//
// Descarga y reproduce todos los canales de Killerchannels.json incluyendo
// los protegidos con ClearKey DRM.
//
// Flujo para canales con DRM:
//   1. Lee drm_license_uri del JSON del catálogo
//   2. DrmKeyResolver.resolve() → GET/POST a la URL → parsea JWK → keys hex
//   3. Construye Channel con clearkeys → PlayerScreen → PivoShakaPlayer (ExoPlayer)
//   4. ExoPlayer configura ClearKey con las keys extraídas
// ════════════════════════════════════════════════════════════════════════════

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

  // Tracks channels currently resolving DRM keys
  final Set<String> _resolvingDrm = {};
  // Resolved DRM keys cache: channel URI → clearkeys map
  final Map<String, Map<String, String>> _resolvedKeys = {};
  // Channels that failed DRM resolution
  final Set<String> _drmFailed = {};

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  // ── Catalog Loading ───────────────────────────────────────────────────────

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

        final channels = <_ExtChannel>[];
        for (final rawCh in rawSamples) {
          if (rawCh is! Map) continue;
          final item = Map<String, dynamic>.from(rawCh);
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
              final k = entry.key.toString().trim();
              final v = entry.value.toString().trim();
              if (k.isNotEmpty && v.isNotEmpty) headers[k] = v;
            }
          }

          channels.add(_ExtChannel(
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

      // Pre-resolve DRM keys for current group in background
      _preResolveDrmForGroup(0);
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

  // ── DRM Pre-resolution ────────────────────────────────────────────────────

  /// Pre-resolve DRM keys for all channels in a group (background)
  void _preResolveDrmForGroup(int groupIndex) {
    if (groupIndex >= _groups.length) return;
    final channels = _groups[groupIndex].channels;
    for (final ch in channels) {
      if (ch.hasDrm && !_resolvedKeys.containsKey(ch.uri)) {
        _resolveDrmForChannel(ch);
      }
    }
  }

  /// Resolve DRM keys for a single channel, update state when done
  Future<void> _resolveDrmForChannel(_ExtChannel ch) async {
    if (_resolvingDrm.contains(ch.uri)) return;
    if (_resolvedKeys.containsKey(ch.uri)) return;

    if (mounted) setState(() => _resolvingDrm.add(ch.uri));

    try {
      final keys = await DrmKeyResolver.resolve(
        ch.drmLicenseUri,
        requestHeaders: ch.headers.isNotEmpty ? ch.headers : null,
      );

      if (!mounted) return;
      setState(() {
        _resolvingDrm.remove(ch.uri);
        if (keys != null && keys.isNotEmpty) {
          _resolvedKeys[ch.uri] = keys;
          _drmFailed.remove(ch.uri);
          debugPrint('✅ DRM resolved for ${ch.name}: $keys');
        } else {
          _drmFailed.add(ch.uri);
          debugPrint('⚠️ DRM resolution failed for ${ch.name}');
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _resolvingDrm.remove(ch.uri);
        _drmFailed.add(ch.uri);
      });
      debugPrint('❌ DRM resolver exception for ${ch.name}: $e');
    }
  }

  // ── Filtered channels ─────────────────────────────────────────────────────

  List<_ExtChannel> get _visibleChannels {
    if (_groups.isEmpty) return const [];
    final source = _groups[_selectedGroup].channels;
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return source;
    return source.where((c) => c.name.toLowerCase().contains(q)).toList();
  }

  // ── Open Channel ──────────────────────────────────────────────────────────

  Future<void> _openChannel(_ExtChannel item) async {
    // If channel has DRM and keys not yet resolved — resolve on demand
    if (item.hasDrm && !_resolvedKeys.containsKey(item.uri)) {
      // Show loading while resolving
      if (!_resolvingDrm.contains(item.uri)) {
        unawaited(_resolveDrmForChannel(item));
      }

      // Show resolving dialog
      if (mounted) {
        _showResolvingDialog(item);
        return;
      }
    }

    _launchPlayer(item);
  }

  void _launchPlayer(_ExtChannel item) {
    final resolvedClearkeys = _resolvedKeys[item.uri];
    final isDash = item.uri.toLowerCase().endsWith('.mpd') ||
        item.drmScheme.isNotEmpty;
    final streamType = item.hasDrm ? 'CLEARKEY' : (isDash ? 'dash' : 'hls');

    String? inlineKeysString;
    if (resolvedClearkeys != null && resolvedClearkeys.isNotEmpty) {
      inlineKeysString = resolvedClearkeys.entries
          .map((e) => 'kid:${e.key},k:${e.value}')
          .join(',');
    }

    final stream = StreamSource(
      url: item.uri,
      label: item.name,
      clearkeys: resolvedClearkeys,
      headers: item.headers.isNotEmpty ? item.headers : null,
      drmLicenseUri: inlineKeysString ??
          (item.drmLicenseUri.startsWith('http') ? null : item.drmLicenseUri),
    );

    final channel = Channel(
      id: 'ext_${Uri.encodeComponent(item.name)}',
      name: item.name,
      category: _groups.isNotEmpty ? _groups[_selectedGroup].name : 'Externos',
      logoUrl: item.icon.isNotEmpty ? [item.icon] : const [],
      streamUrl: [stream],
      description: 'Canal externo${item.hasDrm ? ' (DRM ClearKey)' : ''}.',
      type: streamType,
    );

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlayerScreen(channel: channel),
      ),
    );
  }

  // ── Resolving Dialog ──────────────────────────────────────────────────────

  void _showResolvingDialog(_ExtChannel ch) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          // Poll until resolved
          Future.delayed(const Duration(milliseconds: 400), () async {
            while (ctx.mounted && _resolvingDrm.contains(ch.uri)) {
              await Future<void>.delayed(const Duration(milliseconds: 300));
              if (ctx.mounted) setDialogState(() {});
            }
            if (ctx.mounted) {
              Navigator.of(ctx).pop();
              if (mounted) {
                if (_resolvedKeys.containsKey(ch.uri)) {
                  _launchPlayer(ch);
                } else {
                  // Keys not resolved — launch anyway, ExoPlayer will try
                  _launchPlayer(ch);
                }
              }
            }
          });

          final isResolving = _resolvingDrm.contains(ch.uri);
          final resolved = _resolvedKeys.containsKey(ch.uri);

          return AlertDialog(
            backgroundColor: const Color(0xFF13171D),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                if (isResolving) ...[
                  const CircularProgressIndicator(
                    color: AppTheme.darkAccent,
                    strokeWidth: 2.5,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Obteniendo claves DRM...',
                    style: GoogleFonts.spaceGrotesk(
                      color: AppTheme.darkText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ch.name,
                    style: GoogleFonts.spaceGrotesk(
                      color: AppTheme.darkText2,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ] else if (resolved) ...[
                  const Icon(Icons.check_circle_rounded,
                      color: AppTheme.darkAccent, size: 36),
                  const SizedBox(height: 12),
                  Text(
                    '¡Claves obtenidas!',
                    style: GoogleFonts.spaceGrotesk(
                      color: AppTheme.darkText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ] else ...[
                  const Icon(Icons.lock_open_rounded,
                      color: AppTheme.darkWarning, size: 36),
                  const SizedBox(height: 12),
                  Text(
                    'Intentando reproducir...',
                    style: GoogleFonts.spaceGrotesk(
                      color: AppTheme.darkText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final visible = _visibleChannels;
    final total = _groups.fold<int>(0, (sum, g) => sum + g.channels.length);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Canales externos',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800),
        ),
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
                    // Barra de búsqueda
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                      child: TextField(
                        onChanged: (v) => setState(() => _query = v),
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

                    // Selector de grupos
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
                            onSelected: (_) {
                              setState(() => _selectedGroup = index);
                              _preResolveDrmForGroup(index);
                            },
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          );
                        },
                      ),
                    ),

                    // Cabecera del grupo activo
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _groups[_selectedGroup].name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            '${visible.length} canales · $total en total',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11,
                              color: theme.hintColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Grid de canales
                    Expanded(
                      child: visible.isEmpty
                          ? Center(
                              child: Text(
                                'No hay canales con ese nombre.',
                                style: GoogleFonts.spaceGrotesk(
                                    color: theme.hintColor),
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 190,
                                mainAxisExtent: 148,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: visible.length,
                              itemBuilder: (context, index) =>
                                  _buildChannelCard(visible[index], theme, isDark),
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
            Text(
              _error ?? 'Error desconocido',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(height: 1.45),
            ),
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

  Widget _buildChannelCard(
      _ExtChannel channel, ThemeData theme, bool isDark) {
    final isResolving = _resolvingDrm.contains(channel.uri);
    final isResolved = _resolvedKeys.containsKey(channel.uri);
    final hasFailed = _drmFailed.contains(channel.uri);
    final hasDrm = channel.hasDrm;

    // DRM badge color
    Color? badgeColor;
    String? badgeText;
    if (hasDrm) {
      if (isResolving) {
        badgeColor = AppTheme.darkWarning;
        badgeText = 'DESBLOQUEANDO';
      } else if (isResolved) {
        badgeColor = AppTheme.darkAccent;
        badgeText = 'DESBLOQUEADO';
      } else if (hasFailed) {
        badgeColor = AppTheme.darkDanger;
        badgeText = 'DRM';
      } else {
        badgeColor = isDark ? theme.colorScheme.primary : theme.colorScheme.error;
        badgeText = 'PROTEGIDO';
      }
    }

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
            border: Border.all(
              color: isResolved && hasDrm
                  ? AppTheme.darkAccent.withValues(alpha: 0.35)
                  : theme.dividerColor.withValues(alpha: 0.13),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Center(
                      child: channel.icon.isEmpty
                          ? Icon(Icons.live_tv_rounded,
                              size: 38, color: theme.colorScheme.primary)
                          : CachedNetworkImage(
                              imageUrl: channel.icon,
                              fit: BoxFit.contain,
                              errorWidget: (_, __, ___) => Icon(
                                Icons.live_tv_rounded,
                                size: 38,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                    ),
                    if (isResolving)
                      const Positioned(
                        right: 0,
                        top: 0,
                        child: SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            color: AppTheme.darkWarning,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    if (isResolved && hasDrm)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: AppTheme.darkAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock_open_rounded,
                            color: Color(0xFF000000),
                            size: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                channel.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (badgeText != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    badgeText,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 7,
                      fontWeight: FontWeight.w900,
                      color: badgeColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Data Classes ─────────────────────────────────────────────────────────────

class _ChannelGroup {
  final String name;
  final List<_ExtChannel> channels;
  const _ChannelGroup({required this.name, required this.channels});
}

class _ExtChannel {
  final String name;
  final String uri;
  final String icon;
  final Map<String, String> headers;
  final String drmScheme;
  final String drmLicenseUri;

  const _ExtChannel({
    required this.name,
    required this.uri,
    required this.icon,
    required this.headers,
    required this.drmScheme,
    required this.drmLicenseUri,
  });

  bool get hasDrm => drmScheme.isNotEmpty || drmLicenseUri.isNotEmpty;
}
