import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pivote/features/video/data/models/channel.dart';
import 'package:pivote/features/video/data/services/epg_service.dart';
import 'package:pivote/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:pivote/features/video/presentation/providers/channel_provider.dart';
import 'package:pivote/features/video/presentation/widgets/video_player_widget.dart';
import 'package:pivote/features/video/presentation/widgets/channel_card.dart';
import 'package:pivote/shared/widgets/app_notifications.dart';
import 'package:pivote/shared/widgets/common/pivote_loader.dart';
import 'package:pivote/core/services/app_activity_service.dart';
import 'package:pivote/core/services/image_cache_helper.dart';
import 'package:pivote/features/profile/presentation/screens/diagnostics_screen.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';

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
  final GlobalKey _videoPlayerKey = GlobalKey();
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
        backgroundColor:
            isLandscape ? Colors.black : theme.scaffoldBackgroundColor,
        body: Column(
          children: [
            // Top Bar (solo en vertical)
            if (!isLandscape)
              SafeArea(
                bottom: false,
                child: _buildHeader(context, theme, isDark),
              ),

            // Video Player Viewport — posición FIJA en el árbol para que NUNCA se desmonte al rotar
            if (isLandscape)
              Expanded(
                child: Container(
                  color: Colors.black,
                  child: VideoPlayerWidget(
                    key: _videoPlayerKey,
                    channel: _currentChannel,
                  ),
                ),
              )
            else
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

            // Scrollable Content (solo en vertical)
            if (!isLandscape)
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
                        color: AppTheme.border(context),
                      ),
                      _buildChannelActions(context, theme, isDark),
                      Divider(
                        height: 1,
                        color: AppTheme.border(context),
                      ),
                      _buildChannelInfo(context, theme, isDark),
                      _buildRelatedChannelsGrid(context, theme, isDark),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme, bool isDark) {
    final horizontalPad = AppResponsive.horizontalPadding(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: horizontalPad, vertical: 8),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.border(context),
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
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.surface1(context),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: AppTheme.border(context),
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

          // Favorite Button (Single clean button on right)
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
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.surface1(context),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: isFavorite
                            ? AppColors.live.withValues(alpha: 0.4)
                            : AppTheme.border(context),
                      ),
                    ),
                    child: Icon(
                      isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isFavorite
                          ? AppColors.live
                          : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      size: 20,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChannelHeader(
      BuildContext context, ThemeData theme, bool isDark) {
    final primaryColor = AppTheme.accent(context);
    final logoUrl = _currentChannel.getLogoUrl(isDark);
    final horizontalPad = AppResponsive.horizontalPadding(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPad, 20, horizontalPad, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Channel Logo with elevation/shadow
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: isDark ? AppColors.ink2 : Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: AppTheme.border(context),
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
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Hero(
                  tag: 'channel_logo_${_currentChannel.id}',
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
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _currentChannel.name,
                  style: AppFont.primary(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                    height: 1.2,
                    color: (_currentChannel.type == 'evento' ||
                            _currentChannel.evento != null)
                        ? AppColors.warning
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
                        color: primaryColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _currentChannel.category.toUpperCase(),
                        style: AppFont.primary(
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
                          color: AppTheme.surface1(context),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.border(context),
                          ),
                        ),
                        child: Text(
                          _currentChannel.quality!,
                          style: AppFont.primary(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textSecondary(context),
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

  // Channel Action Buttons Bar (Clean 2-button layout: Diagnóstico & Reportar)
  Widget _buildChannelActions(
      BuildContext context, ThemeData theme, bool isDark) {
    final horizontalPad = AppResponsive.horizontalPadding(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPad, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: _actionButton(
              icon: Icons.speed_rounded,
              label: 'Diagnóstico',
              accent: AppColors.secondary,
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
          const SizedBox(width: 12),
          Expanded(
            child: _actionButton(
              icon: Icons.report_problem_outlined,
              label: 'Reportar Canal',
              accent: AppColors.warning,
              isDark: isDark,
              onTap: () {
                HapticFeedback.lightImpact();
                _showReportModal(context);
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
      color: AppTheme.surface1(context),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: AppTheme.border(context),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: accent, size: 19),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppFont.primary(
                  fontSize: 12,
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

  // ══════════════════════════════════════════════════════════════════════════
  // ADVANCED & ANIMATED REPORT MODAL
  // ══════════════════════════════════════════════════════════════════════════
  void _showReportModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      useSafeArea: true,
      builder: (ctx) => _ReportModalSheet(
        channelName: _currentChannel.name,
        onSubmit: (reason) {
          AppNotifications.showSuccess(
            context,
            'Reporte de señal enviado. ¡Gracias por avisarnos!',
          );
        },
      ),
    );
  }

  Widget _buildChannelInfo(BuildContext context, ThemeData theme, bool isDark) {
    if (_currentChannel.type == 'evento' || _currentChannel.evento != null) {
      return _buildEventCameras(context);
    }

    final horizontalPad = AppResponsive.horizontalPadding(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPad, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_currentChannel.description.isNotEmpty) ...[
            Text(
              _currentChannel.description,
              style: AppFont.primary(
                height: 1.5,
                fontSize: 13.5,
                color: AppTheme.textSecondary(context),
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
    final primaryColor = AppTheme.accent(context);

    if (_isLoadingGuide) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardSurface(context),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: AppTheme.border(context),
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
                style: AppFont.primary(
                  fontSize: 13,
                  color: AppTheme.textSecondary(context),
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
          color: AppColors.error.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: AppColors.error.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 20,
              color: AppColors.error,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No se pudo obtener la programación.',
                style: AppFont.primary(
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
        color: AppTheme.cardSurface(context),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppTheme.border(context),
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
                    style: AppFont.primary(
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
                color: AppTheme.textSecondary(context),
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
                          color: primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          slot.time,
                          style: AppFont.primary(
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
                          style: AppFont.primary(
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
    final horizontalPad = AppResponsive.horizontalPadding(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPad, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.videocam_rounded,
                  color: AppColors.warning,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'TRANSMISIÓN MULTICÁMARA',
                  style: AppFont.primary(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.warning,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 240,
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
              style: AppFont.primary(
                height: 1.5,
                fontSize: 13.5,
                color: AppTheme.textSecondary(context),
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
              ? dominantColor.withValues(alpha: 0.16)
              : AppTheme.cardSurface(context),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected
                ? dominantColor
                : AppTheme.border(context),
            width: isSelected ? 1.6 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: dominantColor.withValues(alpha: 0.28),
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
                    color: isSelected
                        ? AppColors.live
                        : AppTheme.textSecondary(context),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    nombre,
                    style: AppFont.primary(
                      fontSize: 12.5,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: AppTheme.textPrimary(context),
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
                  style: AppFont.primary(
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
      return AppColors.warning;
    } else if (tipo.toLowerCase().contains("exclusiva") ||
        tipo.toLowerCase().contains("dormitorio")) {
      return const Color(0xFF8B5CF6);
    } else if (tipo.toLowerCase().contains("jardin") ||
        tipo.toLowerCase().contains("playa")) {
      return AppColors.success;
    } else if (tipo.toLowerCase().contains("confesionario")) {
      return AppColors.live;
    }
    return AppColors.secondary;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // RELATED CHANNELS (Adaptive Grid with Home Screen ChannelCard design)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildRelatedChannelsGrid(
      BuildContext context, ThemeData theme, bool isDark) {
    final channelProvider = context.watch<ChannelProvider>();
    final allChannels = channelProvider.channels;

    // 1. Get up to 4 channels in the same category
    final related = allChannels
        .where((c) =>
            c.id != _currentChannel.id &&
            c.category.trim().toLowerCase() ==
                _currentChannel.category.trim().toLowerCase())
        .toList();

    final List<Channel> fourChannels = [];
    fourChannels.addAll(related.take(4));

    // 2. If fewer than 4, backfill with other available channels
    if (fourChannels.length < 4) {
      for (final ch in allChannels) {
        if (ch.id != _currentChannel.id &&
            !fourChannels.any((existing) => existing.id == ch.id)) {
          fourChannels.add(ch);
          if (fourChannels.length == 4) break;
        }
      }
    }

    if (fourChannels.isEmpty) return const SizedBox.shrink();

    final primaryColor = AppTheme.accent(context);
    final horizontalPad = AppResponsive.horizontalPadding(context);

    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPad),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cambio Rápido de Canal',
                  style: AppFont.primary(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
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
                    _currentChannel.category,
                    style: AppFont.primary(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: horizontalPad),
            gridDelegate: AppResponsive.channelGridDelegate(context),
            itemCount: fourChannels.length,
            itemBuilder: (context, index) {
              final ch = fourChannels[index];
              return ChannelCard(
                channel: ch,
                onTap: () => _switchChannel(ch),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// MODERN REPORT MODAL SHEET
// ════════════════════════════════════════════════════════════════════════════
class _ReportModalSheet extends StatefulWidget {
  final String channelName;
  final ValueChanged<String> onSubmit;

  const _ReportModalSheet({
    required this.channelName,
    required this.onSubmit,
  });

  @override
  State<_ReportModalSheet> createState() => _ReportModalSheetState();
}

class _ReportModalSheetState extends State<_ReportModalSheet> {
  int _selectedReasonIndex = 0;
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _reasons = const [
    {
      'title': 'Canal caído / Sin señal',
      'desc': 'Pantalla negra o error de reproducción continuo',
      'icon': Icons.signal_cellular_connected_no_internet_0_bar_rounded,
      'color': AppColors.live,
    },
    {
      'title': 'Audio desfasado o mudo',
      'desc': 'Sin sonido o el audio no coincide con el video',
      'icon': Icons.volume_off_rounded,
      'color': AppColors.warning,
    },
    {
      'title': 'Cortes constantes / Buffering',
      'desc': 'La transmisión se congela o carga muy lento',
      'icon': Icons.motion_photos_paused_rounded,
      'color': AppColors.secondary,
    },
    {
      'title': 'Baja calidad / Imagen defectuosa',
      'desc': 'Pixelado excesivo o resolución incorrecta',
      'icon': Icons.hd_rounded,
      'color': Color(0xFF8B5CF6),
    },
    {
      'title': 'Canal equivocado',
      'desc': 'El contenido no coincide con el canal',
      'icon': Icons.alt_route_rounded,
      'color': AppColors.success,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.ink1 : Colors.white,
        borderRadius: AppRadius.sheetAll,
        border: Border.all(
          color: AppTheme.border(context),
        ),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  Icons.report_problem_rounded,
                  color: AppColors.warning,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reportar Problema',
                      style: AppFont.primary(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      widget.channelName,
                      style: AppFont.primary(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Reason Options
          ...List.generate(_reasons.length, (index) {
            final reason = _reasons[index];
            final isSelected = _selectedReasonIndex == index;
            final color = reason['color'] as Color;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: isSelected
                    ? color.withValues(alpha: isDark ? 0.16 : 0.08)
                    : AppTheme.surface1(context),
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedReasonIndex = index);
                  },
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: isSelected
                            ? color.withValues(alpha: 0.7)
                            : AppTheme.border(context),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          reason['icon'] as IconData,
                          color: isSelected
                              ? color
                              : AppTheme.textSecondary(context),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                reason['title'] as String,
                                style: AppFont.primary(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                reason['desc'] as String,
                                style: AppFont.primary(
                                  fontSize: 10.5,
                                  color: AppTheme.textSecondary(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle_rounded,
                            color: color,
                            size: 18,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 12),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isSubmitting
                  ? null
                  : () async {
                      unawaited(HapticFeedback.mediumImpact());
                      setState(() => _isSubmitting = true);
                      final nav = Navigator.of(context);
                      await Future.delayed(const Duration(milliseconds: 350));
                      if (mounted) {
                        nav.pop();
                        widget.onSubmit(
                          _reasons[_selectedReasonIndex]['title'] as String,
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent(context),
                foregroundColor: AppTheme.onAccent(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.onAccent(context)),
                      ),
                    )
                  : Text(
                      'Enviar Reporte',
                      style: AppFont.primary(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                        color: AppTheme.onAccent(context),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
