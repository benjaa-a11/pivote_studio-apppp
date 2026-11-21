import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/features/video/presentation/widgets/exo_player_widget.dart';
import 'package:pivote/shared/widgets/common/pivote_loader.dart';

// ════════════════════════════════════════
// SERVER INFO MODEL
// ════════════════════════════════════════

enum ServerType { hls, dash, web, unknown }

class ServerInfo {
  final int index;
  final String label;
  final ServerType type;

  const ServerInfo({
    required this.index,
    required this.label,
    required this.type,
  });

  String get typeLabel {
    switch (type) {
      case ServerType.hls:
        return 'HLS';
      case ServerType.dash:
        return 'DASH';
      case ServerType.web:
        return 'WEB';
      case ServerType.unknown:
        return 'AUTO';
    }
  }

  Color typeColor(BuildContext context) {
    switch (type) {
      case ServerType.hls:
        return AppColors.positive;
      case ServerType.dash:
        return AppColors.accent;
      case ServerType.web:
        return AppColors.warning;
      case ServerType.unknown:
        return AppColors.accentTint;
    }
  }
}

// ════════════════════════════════════════
// CUSTOM VIDEO CONTROLS (Pro Edition)
// ════════════════════════════════════════

class CustomVideoControls extends StatefulWidget {
  final UnifiedVideoController controller;
  final String channelName;
  final VoidCallback? onFullScreenToggle;
  final bool isFullScreen;
  final String aspectRatioLabel;
  final VoidCallback? onAspectRatioChange;
  final bool isMuted;
  final VoidCallback? onMuteToggle;
  final int currentServer;
  final int totalServers;
  final List<ServerInfo>? serverList;
  final ValueChanged<int>? onServerSelect;

  const CustomVideoControls({
    super.key,
    required this.controller,
    required this.channelName,
    this.onFullScreenToggle,
    this.isFullScreen = false,
    this.aspectRatioLabel = 'Auto',
    this.onAspectRatioChange,
    this.isMuted = false,
    this.onMuteToggle,
    this.currentServer = 1,
    this.totalServers = 1,
    this.serverList,
    this.onServerSelect,
  });

  @override
  State<CustomVideoControls> createState() => _CustomVideoControlsState();
}

class _CustomVideoControlsState extends State<CustomVideoControls>
    with SingleTickerProviderStateMixin {
  bool _showControls = true;
  bool _wasVideoActive = false;

  Timer? _hideTimer;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  static const Duration _inactivityTimeout = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 220),
      vsync: this,
      value: 1.0,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );

    widget.controller.addListener(_videoListener);
    _scheduleAutoHide();
  }

  @override
  void didUpdateWidget(covariant CustomVideoControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.channelName != widget.channelName ||
        oldWidget.currentServer != widget.currentServer) {
      // Al cambiar de canal o servidor, mostrar controles brevemente y programar auto-hide
      _revealControlsAndScheduleHide();
    }
  }

  void _videoListener() {
    if (!mounted) return;

    final isVideoActive = widget.controller.isPlaying ||
        widget.controller.firstFrameRendered ||
        widget.controller.isReady;

    // Apenas el video comienza a reproducirse por primera vez, iniciar cuenta regresiva de ocultamiento
    if (isVideoActive && !_wasVideoActive) {
      _wasVideoActive = true;
      _scheduleAutoHide();
    } else if (!isVideoActive) {
      _wasVideoActive = false;
    }

    setState(() {});
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _fadeController.dispose();
    widget.controller.removeListener(_videoListener);
    super.dispose();
  }

  // ═══════════════════════════════════════
  // Visibility & Inactivity Timer
  // ═══════════════════════════════════════

  void _toggleControls() {
    HapticFeedback.selectionClick();
    if (_showControls) {
      _hideControlsNow();
    } else {
      _revealControlsAndScheduleHide();
    }
  }

  void _revealControlsAndScheduleHide() {
    _hideTimer?.cancel();
    if (!_showControls) {
      setState(() {
        _showControls = true;
      });
      _fadeController.forward();
    }
    _scheduleAutoHide();
  }

  void _hideControlsNow() {
    _hideTimer?.cancel();
    if (_showControls) {
      setState(() {
        _showControls = false;
      });
      _fadeController.reverse();
    }
  }

  void _scheduleAutoHide() {
    _hideTimer?.cancel();

    _hideTimer = Timer(_inactivityTimeout, () {
      if (!mounted) return;
      final isVideoActive = widget.controller.isPlaying ||
          widget.controller.firstFrameRendered ||
          widget.controller.isReady;
      if (isVideoActive && _showControls) {
        setState(() {
          _showControls = false;
        });
        _fadeController.reverse();
      }
    });
  }

  void _onControlInteraction() {
    _revealControlsAndScheduleHide();
  }

  // ═══════════════════════════════════════
  // Build
  // ═══════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final bool showRebuffering = widget.controller.isBuffering &&
        (widget.controller.isReady || widget.controller.firstFrameRendered);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleControls,
      child: Container(
        color: Colors.transparent,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Indicador liviano de rebuffering (sin oscurecer el video)
            if (showRebuffering)
              const Center(
                child: IgnorePointer(
                  child: PivoteLoader(
                    size: 38,
                    strokeWidth: 3.5,
                  ),
                ),
              ),

            // Controles con animación suave y bloqueo de toques cuando están ocultos
            FadeTransition(
              opacity: _fadeAnimation,
              child: IgnorePointer(
                ignoring: !_showControls,
                child: _buildControls(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.78),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withValues(alpha: 0.84),
          ],
          stops: const [0.0, 0.25, 0.72, 1.0],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildHeader(),
          _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final isPlaying = widget.controller.isPlaying ||
        widget.controller.firstFrameRendered ||
        widget.controller.isReady;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: widget.isFullScreen ? 10 : 12,
        ),
        child: Row(
          children: [
            if (widget.isFullScreen && widget.onFullScreenToggle != null) ...[
              _buildControlButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onPressed: () {
                  _onControlInteraction();
                  widget.onFullScreenToggle!();
                },
                size: 16,
                padding: const EdgeInsets.all(10),
              ),
              const SizedBox(width: 12),
            ],

            // Channel name + live indicator
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.channelName,
                    style: AppFont.primary(
                      fontSize: widget.isFullScreen ? 17 : 15.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Live indicator dot
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: isPlaying
                              ? AppColors.darkAccent
                              : AppColors.live,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (isPlaying
                                      ? AppColors.darkAccent
                                      : AppColors.live)
                                  .withValues(alpha: 0.6),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'EN VIVO',
                        style: AppFont.primary(
                          fontWeight: FontWeight.w900,
                          fontSize: 10.5,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        child: Row(
          children: [
            // Mute / Volume Button (SVG)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  _onControlInteraction();
                  HapticFeedback.mediumImpact();
                  widget.onMuteToggle?.call();
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  child: SvgPicture.asset(
                    widget.isMuted
                        ? 'assets/icons/volume_off_16.svg'
                        : 'assets/icons/volume_16.svg',
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                    width: 18,
                    height: 18,
                  ),
                ),
              ),
            ),

            const Spacer(),

            // Fullscreen Toggle (SVG)
            if (widget.onFullScreenToggle != null)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    _onControlInteraction();
                    HapticFeedback.mediumImpact();
                    widget.onFullScreenToggle!();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    child: SvgPicture.asset(
                      widget.isFullScreen
                          ? 'assets/icons/player/salir-pantalla-completa.svg'
                          : 'assets/icons/player/pantalla-completa.svg',
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                      width: 18,
                      height: 18,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    double size = 20,
    String? label,
    EdgeInsets? padding,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: padding ??
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: size),
                if (label != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: AppFont.primary(
                      fontWeight: FontWeight.w700,
                      fontSize: 11.5,
                      color: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
