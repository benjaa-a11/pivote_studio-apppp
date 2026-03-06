import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pivote/features/video/data/models/channel.dart';
import 'package:pivote/features/video/data/services/epg_service.dart';
import 'package:pivote/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:pivote/features/video/presentation/widgets/video_player_widget.dart';

class PlayerScreen extends StatefulWidget {
  final Channel channel;

  const PlayerScreen({
    super.key,
    required this.channel,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  // Key para preservar el estado del video player al re-inicializar
  Key _videoPlayerKey = GlobalKey();
  late Channel _currentChannel;
  int _selectedCameraId = -1; // -1 represents the main stream

  // Programación (EPG)
  bool _isLoadingGuide = false;
  String? _guideError;
  List<ChannelProgramSlot> _guideSlots = const [];

  @override
  void initState() {
    super.initState();
    _currentChannel = widget.channel;
    // Bloquear a portrait inicialmente
    Future.delayed(Duration.zero, () {
      if (mounted) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);

        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: SystemUiOverlay.values,
        );
      }
    });

    // Cargar programación si el canal tiene guid configurado
    if ((_currentChannel.guid ?? '').trim().isNotEmpty) {
      _loadGuide();
    }
  }

  @override
  void dispose() {
    // Restaurar todas las orientaciones al salir
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: !isLandscape,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && isLandscape) {
          // Si estamos en landscape, volver a portrait
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
          ]);
          SystemChrome.setEnabledSystemUIMode(
            SystemUiMode.manual,
            overlays: SystemUiOverlay.values,
          );
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? Colors.black : Colors.white,
        body: isLandscape
            ? _buildLandscapeLayout()
            : SafeArea(
                child: _buildPortraitLayout(context, isDark),
              ),
      ),
    );
  }

  // Layout en modo landscape (pantalla completa)
  Widget _buildLandscapeLayout() {
    return VideoPlayerWidget(
      key: _videoPlayerKey,
      channel: _currentChannel,
    );
  }

  // Layout en modo portrait
  Widget _buildPortraitLayout(BuildContext context, bool isDark) {
    return Column(
      children: [
        // Header más fino y elegante
        _buildHeader(context, isDark),

        // Reproductor de video (usando la misma key para preservar estado)
        AspectRatio(
          aspectRatio: 16 / 9,
          child: VideoPlayerWidget(
            key: _videoPlayerKey,
            channel: _currentChannel,
          ),
        ),

        // Contenido scrolleable
        Expanded(
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildChannelHeader(context),
                  Divider(
                    height: 1,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                  _buildChannelInfo(context),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Header minimalista y elegante
  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            iconSize: 28,
            style: IconButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Consumer<FavoritesProvider>(
            builder: (context, favoritesProvider, child) {
              final isFavorite =
                  favoritesProvider.isFavorite(_currentChannel.id);
              return IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  favoritesProvider.toggleFavorite(_currentChannel);
                },
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border_rounded,
                  color: isFavorite ? Colors.red : null,
                  size: 28,
                ),
                style: IconButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChannelHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Channel Logo with elevation/shadow
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.1),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _currentChannel.logoUrl.isNotEmpty
                  ? Image.network(
                      _currentChannel.getLogoUrl(isDark),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.tv_rounded,
                          size: 36,
                          color: isDark ? Colors.grey[700] : Colors.grey[400],
                        );
                      },
                    )
                  : Icon(
                      Icons.tv_rounded,
                      size: 36,
                      color: isDark ? Colors.grey[700] : Colors.grey[400],
                    ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _currentChannel.name,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                    height: 1.1,
                    color: (_currentChannel.type == 'evento' ||
                            _currentChannel.evento != null)
                        ? const Color(0xFFD4AF37) // Golden tone for event
                        : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _currentChannel.category.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.primary,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_currentChannel.quality != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _currentChannel.quality!,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelInfo(BuildContext context) {
    if (_currentChannel.type == 'evento' || _currentChannel.evento != null) {
      return _buildEventCameras(context);
    }

    // Diseño limpio sin cajas, solo texto bien tipografiado para canales normales
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _currentChannel.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                  fontSize: 15,
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withValues(alpha: 0.8),
                ),
          ),
          const SizedBox(height: 24),
          if ((_currentChannel.guid ?? '').trim().isNotEmpty)
            _buildProgramGuideSection(context),
        ],
      ),
    );
  }

  Widget _buildProgramGuideSection(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoadingGuide) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.02)
              : Colors.black.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Cargando programación del canal...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_guideError != null) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.error.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.error.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 18,
              color: theme.colorScheme.error,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No se pudo cargar la programación',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Toca para reintentar.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _loadGuide,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ],
        ),
      );
    }

    if (_guideSlots.isEmpty) {
      // No hay datos de guía para este canal
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.02)
            : Colors.black.withValues(alpha: 0.01),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Próxima programación',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: _loadGuide,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                tooltip: 'Actualizar programación',
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._guideSlots.take(5).map(
                (slot) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 64,
                        child: Text(
                          slot.time,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          slot.title,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 13,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.85),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Future<void> _loadGuide() async {
    final guid = (_currentChannel.guid ?? '').trim();
    if (guid.isEmpty) return;

    setState(() {
      _isLoadingGuide = true;
      _guideError = null;
    });

    try {
      final slots = await EpgService.fetchGuide(
        guid: guid,
        start: DateTime.now(),
      );
      if (!mounted) return;
      setState(() {
        _guideSlots = slots;
        _isLoadingGuide = false;
        _guideError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingGuide = false;
        _guideError = e.toString();
      });
    }
  }

  Widget _buildEventCameras(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final camaras = widget.channel.camaras ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37).withAlpha(30),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFD4AF37), width: 1),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.videocam_rounded,
                    color: Color(0xFFD4AF37), size: 16),
                SizedBox(width: 8),
                Text(
                  'EXCLUSIVO MULTICÁMARA',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD4AF37),
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: camaras.length + 1, // +1 for the main stream
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildCameraSelector(
                  id: -1,
                  nombre: "Gala / Principal",
                  url: widget.channel.streamUrl.first.url,
                  tipo: "principal",
                  isDark: isDark,
                );
              }
              final camara = camaras[index - 1];
              return _buildCameraSelector(
                id: camara.id,
                nombre: camara.nombre,
                url: camara.url,
                tipo: camara.tipo,
                isDark: isDark,
              );
            },
          ),
          const SizedBox(height: 24),
          if (_currentChannel.description.isNotEmpty)
            Text(
              _currentChannel.description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.6,
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
            ),
        ],
      ),
    );
  }

  Widget _buildCameraSelector({
    required int id,
    required String nombre,
    required String url,
    required String tipo,
    required bool isDark,
  }) {
    bool isSelected = _selectedCameraId == id;
    Color dominantColor = _getAmbientColor(tipo);

    return GestureDetector(
      onTap: () {
        if (isSelected) return;
        HapticFeedback.mediumImpact();

        setState(() {
          _selectedCameraId = id;
          // Forzar la creación de un nuevo widget de reproductor
          _videoPlayerKey = GlobalKey();
          // Modificar la URL del canal actual temporalmente
          _currentChannel = widget.channel.copyWith(
            name: "${widget.channel.name} - $nombre",
            streamUrl: [StreamSource(url: url)],
          );
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? dominantColor.withAlpha(40)
              : const Color(0xFF101010),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? dominantColor : Colors.white.withAlpha(30),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: dominantColor.withAlpha(80),
                    blurRadius: 10,
                    offset: const Offset(0, 0),
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.red : Colors.grey[700],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    nombre,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (tipo.isNotEmpty) ...[
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.only(left: 14),
                child: Text(
                  tipo.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    color: dominantColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Color _getAmbientColor(String tipo) {
    if (tipo.toLowerCase().contains("principal") ||
        tipo.toLowerCase().contains("gala")) {
      return const Color(0xFFD4AF37); // Dorado
    } else if (tipo.toLowerCase().contains("exclusiva") ||
        tipo.toLowerCase().contains("dormitorio")) {
      return const Color(0xFF8A2BE2); // Violeta Eléctrico
    } else if (tipo.toLowerCase().contains("jardin") ||
        tipo.toLowerCase().contains("playa")) {
      return const Color(0xFFF5DEB3); // Arena / Celeste
    } else if (tipo.toLowerCase().contains("confesionario")) {
      return Colors.redAccent;
    }
    return const Color(0xFF1E90FF); // Azul genérico
  }

  // Related channels methods removed as requested
}
