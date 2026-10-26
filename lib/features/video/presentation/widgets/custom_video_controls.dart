import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/features/video/presentation/widgets/unified_video_controller.dart';
import 'package:pivote/features/video/presentation/widgets/video_loading_widget.dart';

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
        return Colors.greenAccent.shade400;
      case ServerType.dash:
        return Colors.blueAccent.shade200;
      case ServerType.web:
        return Colors.orangeAccent.shade200;
      case ServerType.unknown:
        return Colors.grey.shade400;
    }
  }
}

// ════════════════════════════════════════
// CUSTOM VIDEO CONTROLS (Clean Edition)
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
    with TickerProviderStateMixin {
  bool _showControls = true;
  bool _controlsLocked = false;

  Timer? _hideTimer;
  Timer? _controlsInteractionTimer;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _bufferingController;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _bufferingController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    widget.controller.addListener(_videoListener);
    _startHideTimer();
    _fadeController.forward();
  }

  void _videoListener() {
    if (!mounted) return;

    if (widget.controller.isBuffering) {
      if (!_bufferingController.isAnimating &&
          _bufferingController.value < 1.0) {
        _bufferingController.forward();
      }
    } else {
      if (_bufferingController.value > 0.0) {
        _bufferingController.stop();
        _bufferingController.reset();
      }
    }

    if (widget.controller.isPlaying &&
        !widget.controller.isBuffering &&
        _showControls &&
        !_controlsLocked) {
      _startHideTimer();
    }

    setState(() {});
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controlsInteractionTimer?.cancel();
    _fadeController.dispose();
    _bufferingController.dispose();
    widget.controller.removeListener(_videoListener);
    super.dispose();
  }

  // ═══════════════════════════════════════
  // Visibility
  // ═══════════════════════════════════════

  void _toggleControls() {
    if (_controlsLocked) {
      // In locked mode, tapping shows/hides the unlock button
      setState(() {
        _showControls = !_showControls;
        if (_showControls) {
          _fadeController.forward();
          _startHideTimer();
        } else {
          _fadeController.reverse();
          _hideTimer?.cancel();
        }
      });
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _showControls = !_showControls;
      if (_showControls) {
        _fadeController.forward();
        _startHideTimer();
      } else {
        _fadeController.reverse();
        _hideTimer?.cancel();
      }
    });
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    if (!widget.controller.isPlaying || widget.controller.isBuffering) return;

    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted &&
          widget.controller.isPlaying &&
          !widget.controller.isBuffering &&
          _showControls) {
        setState(() {
          _showControls = false;
          _fadeController.reverse();
        });
      }
    });
  }

  void _onControlInteraction() {
    _controlsInteractionTimer?.cancel();
    if (!_showControls) {
      setState(() {
        _showControls = true;
        _fadeController.forward();
      });
    }
    _startHideTimer();
  }

  // ═══════════════════════════════════════
  // Build
  // ═══════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleControls,
      child: Container(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Buffering overlay
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: widget.controller.isBuffering
                  ? _buildBufferingIndicator()
                  : const SizedBox.shrink(),
            ),

            // Controls Overlay
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

  Widget _buildBufferingIndicator() {
    return Center(
      child: FadeTransition(
        opacity: _bufferingController.drive(CurveTween(curve: Curves.easeIn)),
        child: const VideoLoadingWidget(
          message: 'Sintonizando señal…',
          isBuffering: true,
        ),
      ),
    );
  }

  Widget _buildControls() {
    if (_controlsLocked) {
      return Center(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.75),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: IconButton(
            icon: const Icon(Icons.lock_outline_rounded,
                color: Colors.white, size: 28),
            tooltip: 'Desbloquear pantalla',
            onPressed: () {
              HapticFeedback.mediumImpact();
              setState(() {
                _controlsLocked = false;
              });
              _onControlInteraction();
            },
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.8),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withValues(alpha: 0.85),
          ],
          stops: const [0.0, 0.22, 0.72, 1.0],
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
                    style: GoogleFonts.spaceGrotesk(
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
                          color: widget.controller.isPlaying
                              ? const Color(0xFF10B981)
                              : Colors.red,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (widget.controller.isPlaying
                                      ? const Color(0xFF10B981)
                                      : Colors.red)
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
                        style: GoogleFonts.spaceGrotesk(
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

            // Lock screen button in fullscreen
            if (widget.isFullScreen)
              IconButton(
                icon: const Icon(Icons.lock_open_rounded,
                    color: Colors.white70, size: 20),
                tooltip: 'Bloquear controles',
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _controlsLocked = true;
                  });
                },
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
                    color: Colors.black.withValues(alpha: 0.5),
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

            // Server Selector (if multi-server)
            if (widget.serverList != null && widget.serverList!.isNotEmpty)
              PopupMenuButton<int>(
                initialValue: widget.currentServer - 1,
                tooltip: 'Seleccionar Servidor',
                color: const Color(0xFF1E1E24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                onSelected: (idx) {
                  _onControlInteraction();
                  HapticFeedback.selectionClick();
                  widget.onServerSelect?.call(idx);
                },
                itemBuilder: (context) {
                  return widget.serverList!.map((srv) {
                    final isCurrent = (widget.currentServer - 1) == srv.index;
                    return PopupMenuItem<int>(
                      value: srv.index,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color:
                                  srv.typeColor(context).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              srv.typeLabel,
                              style: TextStyle(
                                color: srv.typeColor(context),
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              srv.label,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12.5,
                                fontWeight: isCurrent
                                    ? FontWeight.w900
                                    : FontWeight.w600,
                                color: isCurrent
                                    ? AppTheme.darkAccent
                                    : Colors.white,
                              ),
                            ),
                          ),
                          if (isCurrent)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppTheme.darkAccent,
                              size: 16,
                            ),
                        ],
                      ),
                    );
                  }).toList();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.dns_rounded,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 5),
                      Text(
                        'S${widget.currentServer}',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (widget.serverList != null && widget.serverList!.isNotEmpty)
              const SizedBox(width: 10),

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
                      color: Colors.black.withValues(alpha: 0.5),
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
                    style: GoogleFonts.spaceGrotesk(
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
