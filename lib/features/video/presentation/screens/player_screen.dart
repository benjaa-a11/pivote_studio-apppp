import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pivote/features/video/data/models/channel.dart';
import 'package:pivote/features/video/data/services/epg_service.dart';
import 'package:pivote/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:pivote/features/video/presentation/providers/channel_provider.dart';
import 'package:pivote/features/video/presentation/widgets/video_player_widget.dart';
import 'package:pivote/shared/widgets/app_notifications.dart';
import 'package:pivote/shared/widgets/common/pivote_loader.dart';
import 'package:pivote/core/services/app_activity_service.dart';
import 'package:pivote/core/services/image_cache_helper.dart';
import 'package:pivote/features/profile/presentation/screens/diagnostics_screen.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/core/theme/app_theme.dart';

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
  Key _videoPlayerKey = GlobalKey();
  late Channel _currentChannel;
  int _selectedCameraId = -1;

  // Programación (EPG)
  bool _isLoadingGuide = false;
  String? _guideError;
  List<ChannelProgramSlot> _guideSlots = const [];

  @override
  void initState() {
    super.initState();
    _currentChannel = widget.channel;

    Future.delayed(Duration.zero, () {
      if (mounted) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);

        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: SystemUiOverlay.values,
        );

        try {
          Provider.of<AppActivityService>(context, listen: false)
              .trackChannelWatch();
        } catch (e) {
          debugPrint('Error tracking channel watch: $e');
        }
      }
    });

    if ((_currentChannel.guid ?? '').trim().isNotEmpty) {
      _loadGuide();
    }
  }

  @override
  void dispose() {
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

  void _switchChannel(Channel channel) {
    if (_currentChannel.id == channel.id) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _currentChannel = channel;
      _selectedCameraId = -1;
      _videoPlayerKey = GlobalKey();
      _guideSlots = const [];
      _guideError = null;
    });
    if ((_currentChannel.guid ?? '').trim().isNotEmpty) {
      _loadGuide();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: !isLandscape,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && isLandscape) {
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
        backgroundColor: isLandscape
            ? Colors.black
            : theme.scaffoldBackgroundColor,
        body: isLandscape
            ? _buildLandscapeLayout()
            : SafeArea(
                child: _buildPortraitLayout(context, theme, isDark),
              ),
      ),
    );
  }

  // Landscape Layout (Full Immersive)
  Widget _buildLandscapeLayout() {
    return VideoPlayerWidget(
      key: _videoPlayerKey,
      channel: _currentChannel,
    );
  }

  // Portrait Layout
  Widget _buildPortraitLayout(BuildContext context, ThemeData theme, bool isDark) {
    return Column(
      children: [
        // Top Bar
        _buildHeader(context, theme, isDark),

        // Video Player Viewport
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            color: Colors.black,
            child: VideoPlayerWidget(
              key: _videoPlayerKey,
              channel: _currentChannel,
            ),
          ),
        ),

        // Scrollable Content
        Expanded(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildChannelHeader(context, theme, isDark),
                Divider(
                  height: 1,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                ),
                _buildChannelActions(context, theme, isDark),
                Divider(
                  height: 1,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                ),
                _buildChannelInfo(context, theme, isDark),
                _buildRelatedChannelsCarousel(context, theme, isDark),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme, bool isDark) {
    final primaryColor = isDark ? AppTheme.darkAccent : theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.04),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.darkBg2
                      : theme.colorScheme.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : theme.colorScheme.primary.withValues(alpha: 0.12),
                  ),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),

          // Live Pill Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'TRANSMISIÓN EN VIVO',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),

          // Actions: Diagnostics + Favorite
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      AppAnimations.createRoute(
                        const DiagnosticsScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.darkBg2
                          : theme.colorScheme.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : theme.colorScheme.primary.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Icon(
                      Icons.speed_rounded,
                      color: primaryColor,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Consumer<FavoritesProvider>(
                builder: (context, favoritesProvider, child) {
                  final isFavorite =
                      favoritesProvider.isFavorite(_currentChannel.id);
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        favoritesProvider.toggleFavorite(_currentChannel);
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppTheme.darkBg2
                              : theme.colorScheme.primary
                                  .withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : theme.colorScheme.primary
                                    .withValues(alpha: 0.12),
                          ),
                        ),
                        child: Icon(
                          isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: isFavorite
                              ? const Color(0xFFEF4444)
                              : theme.colorScheme.onSurface
                                  .withValues(alpha: 0.7),
                          size: 20,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChannelHeader(
      BuildContext context, ThemeData theme, bool isDark) {
    final primaryColor = isDark ? AppTheme.darkAccent : theme.colorScheme.primary;
    final logoUrl = _currentChannel.getLogoUrl(isDark);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Channel Logo with elevation/shadow
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.darkBg2
                  : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : primaryColor.withValues(alpha: 0.18),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: logoUrl.isNotEmpty
                    ? CachedNetworkImage(
                        key: ValueKey<String>(logoUrl),
                        cacheManager: ImageCacheHelper.logoCacheManager,
                        imageUrl: logoUrl,
                        fit: BoxFit.contain,
                        memCacheWidth: 150,
                        errorWidget: (context, error, stackTrace) => Icon(
                          Icons.tv_rounded,
                          size: 32,
                          color: primaryColor,
                        ),
                      )
                    : Icon(
                        Icons.tv_rounded,
                        size: 32,
                        color: primaryColor,
                      ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _currentChannel.name,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                    height: 1.2,
                    color: (_currentChannel.type == 'evento' ||
                            _currentChannel.evento != null)
                        ? const Color(0xFFF59E0B)
                        : theme.colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _currentChannel.category.toUpperCase(),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          color: primaryColor,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    if (_currentChannel.quality != null &&
                        _currentChannel.quality!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _currentChannel.quality!,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: theme.hintColor,
                          ),
                        ),
                      ),
                    if (_currentChannel.streamUrl.length > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5B8CFF).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_currentChannel.streamUrl.length} Servidores',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF5B8CFF),
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

  // Channel Action Buttons Bar
  Widget _buildChannelActions(
      BuildContext context, ThemeData theme, bool isDark) {
    final primaryColor = isDark ? AppTheme.darkAccent : theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Consumer<FavoritesProvider>(
            builder: (context, favs, _) {
              final isFav = favs.isFavorite(_currentChannel.id);
              return Expanded(
                child: _actionButton(
                  icon: isFav
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  label: isFav ? 'Favorito' : 'Guardar',
                  accent: isFav ? const Color(0xFFEF4444) : primaryColor,
                  isDark: isDark,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    favs.toggleFavorite(_currentChannel);
                  },
                ),
              );
            },
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _actionButton(
              icon: Icons.speed_rounded,
              label: 'Diagnóstico',
              accent: const Color(0xFF5B8CFF),
              isDark: isDark,
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  AppAnimations.createRoute(const DiagnosticsScreen()),
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _actionButton(
              icon: Icons.report_problem_outlined,
              label: 'Reportar',
              accent: const Color(0xFFE58B46),
              isDark: isDark,
              onTap: () {
                HapticFeedback.lightImpact();
                AppNotifications.showSuccess(
                    context, 'Reporte enviado. Verificaremos la señal.');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color accent,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isDark ? AppTheme.darkBg2 : Colors.black.withValues(alpha: 0.03),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: accent, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChannelInfo(
      BuildContext context, ThemeData theme, bool isDark) {
    if (_currentChannel.type == 'evento' || _currentChannel.evento != null) {
      return _buildEventCameras(context);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_currentChannel.description.isNotEmpty) ...[
            Text(
              _currentChannel.description,
              style: GoogleFonts.spaceGrotesk(
                height: 1.5,
                fontSize: 13.5,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 20),
          ],
          if ((_currentChannel.guid ?? '').trim().isNotEmpty)
            _buildProgramGuideSection(context),
        ],
      ),
    );
  }

  Widget _buildProgramGuideSection(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark ? AppTheme.darkAccent : theme.colorScheme.primary;

    if (_isLoadingGuide) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: PivoteLoader(
                size: 18,
                strokeWidth: 2,
                color: primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Cargando guía de programación...',
                style: GoogleFonts.spaceGrotesk(
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.error.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.error.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 20,
              color: theme.colorScheme.error,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No se pudo obtener la programación.',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            IconButton(
              onPressed: _loadGuide,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              color: primaryColor,
            ),
          ],
        ),
      );
    }

    if (_guideSlots.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
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
                    color: primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Programación del Canal',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: _loadGuide,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                color: theme.hintColor,
                tooltip: 'Actualizar',
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._guideSlots.take(5).map(
                (slot) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          slot.time,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          slot.title,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final camaras = widget.channel.camaras ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37).withAlpha(30),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD4AF37), width: 1),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.videocam_rounded,
                    color: Color(0xFFD4AF37), size: 16),
                SizedBox(width: 8),
                Text(
                  'TRANSMISIÓN MULTICÁMARA',
                  style: TextStyle(
                    fontSize: 10.5,
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
            itemCount: camaras.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildCameraSelector(
                  id: -1,
                  nombre: "Transmisión Principal",
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
          const SizedBox(height: 20),
          if (_currentChannel.description.isNotEmpty)
            Text(
              _currentChannel.description,
              style: GoogleFonts.spaceGrotesk(
                height: 1.5,
                fontSize: 13.5,
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
          _videoPlayerKey = GlobalKey();
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
              : (isDark ? AppTheme.darkBg2 : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? dominantColor
                : (isDark ? Colors.white.withAlpha(25) : Colors.black.withAlpha(20)),
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
                    color: isSelected ? Colors.red : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    nombre,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12.5,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
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
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 8.5,
                    color: dominantColor,
                    fontWeight: FontWeight.w800,
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
      return const Color(0xFFD4AF37);
    } else if (tipo.toLowerCase().contains("exclusiva") ||
        tipo.toLowerCase().contains("dormitorio")) {
      return const Color(0xFF8A2BE2);
    } else if (tipo.toLowerCase().contains("jardin") ||
        tipo.toLowerCase().contains("playa")) {
      return const Color(0xFFF5DEB3);
    } else if (tipo.toLowerCase().contains("confesionario")) {
      return Colors.redAccent;
    }
    return const Color(0xFF1E90FF);
  }

  // Related Channels Carousel
  Widget _buildRelatedChannelsCarousel(
      BuildContext context, ThemeData theme, bool isDark) {
    final channelProvider = context.watch<ChannelProvider>();
    final allChannels = channelProvider.channels;

    // Channels in the same category or others
    final related = allChannels
        .where((c) =>
            c.id != _currentChannel.id &&
            (c.category.toLowerCase() ==
                _currentChannel.category.toLowerCase()))
        .toList();

    final displayList = related.isNotEmpty
        ? related
        : allChannels.where((c) => c.id != _currentChannel.id).take(10).toList();

    if (displayList.isEmpty) return const SizedBox.shrink();

    final primaryColor = isDark ? AppTheme.darkAccent : theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cambio Rápido de Canal',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  _currentChannel.category,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: displayList.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final ch = displayList[index];
                final logo = ch.getLogoUrl(isDark);

                return Material(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () => _switchChannel(ch),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 140,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: logo.isNotEmpty
                                  ? CachedNetworkImage(
                                      key: ValueKey<String>(logo),
                                      cacheManager:
                                          ImageCacheHelper.logoCacheManager,
                                      imageUrl: logo,
                                      fit: BoxFit.contain,
                                      memCacheWidth: 80,
                                      errorWidget: (_, __, ___) => Icon(
                                        Icons.tv_rounded,
                                        color: primaryColor,
                                        size: 20,
                                      ),
                                    )
                                  : Icon(
                                      Icons.tv_rounded,
                                      color: primaryColor,
                                      size: 20,
                                    ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            ch.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
