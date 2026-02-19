import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import 'package:pivote/features/video/presentation/widgets/unified_video_controller.dart';
import 'package:pivote/features/video/presentation/widgets/video_loading_widget.dart';
import 'package:google_fonts/google_fonts.dart';

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
// CUSTOM VIDEO CONTROLS v5.0
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
  bool _showAspectRatioToast = false;
  bool _controlsLocked = false;

  Timer? _hideTimer;
  Timer? _aspectRatioToastTimer;
  Timer? _controlsInteractionTimer;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _toastController;
  late Animation<double> _toastAnimation;
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

    _toastController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _toastAnimation = CurvedAnimation(
      parent: _toastController,
      curve: Curves.easeOutBack,
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
    _aspectRatioToastTimer?.cancel();
    _controlsInteractionTimer?.cancel();
    _fadeController.dispose();
    _toastController.dispose();
    _bufferingController.dispose();
    widget.controller.removeListener(_videoListener);
    super.dispose();
  }

  // ═══════════════════════════════════════
  // Visibility
  // ═══════════════════════════════════════

  void _toggleControls() {
    if (_controlsLocked) return;
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

    _hideTimer = Timer(const Duration(seconds: 5), () {
      if (mounted &&
          widget.controller.isPlaying &&
          !widget.controller.isBuffering &&
          _showControls &&
          !_controlsLocked) {
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
    _controlsLocked = true;
    _controlsInteractionTimer = Timer(const Duration(milliseconds: 300), () {
      _controlsLocked = false;
    });
  }

  void _showAspectRatioChangeToast() {
    _aspectRatioToastTimer?.cancel();
    setState(() => _showAspectRatioToast = true);
    _toastController.forward(from: 0.0);
    _aspectRatioToastTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) {
        _toastController.reverse().then((_) {
          if (mounted) setState(() => _showAspectRatioToast = false);
        });
      }
    });
  }

  // ═══════════════════════════════════════
  // Server Picker
  // ═══════════════════════════════════════

  void _openServerPicker() {
    if (widget.serverList == null || widget.serverList!.isEmpty) return;

    HapticFeedback.mediumImpact();
    _hideTimer?.cancel();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _ServerPickerSheet(
        servers: widget.serverList!,
        currentIndex: widget.currentServer - 1,
        onSelect: (idx) {
          Navigator.pop(ctx);
          widget.onServerSelect?.call(idx);
          _onControlInteraction();
        },
      ),
    ).then((_) => _startHideTimer());
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

            // Aspect ratio toast
            if (_showAspectRatioToast && widget.isFullScreen)
              _buildAspectRatioToast(),

            // Controls
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
        opacity:
            _bufferingController.drive(CurveTween(curve: Curves.easeIn)),
        child: const VideoLoadingWidget(
          message: 'Cargando...',
          isBuffering: true,
        ),
      ),
    );
  }

  Widget _buildAspectRatioToast() {
    return Center(
      child: ScaleTransition(
        scale: _toastAnimation,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(230),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withAlpha(153),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withAlpha(77),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.aspect_ratio_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                widget.aspectRatioLabel,
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
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
            Colors.black.withValues(alpha: 0.75),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withValues(alpha: 0.85),
          ],
          stops: const [0.0, 0.2, 0.75, 1.0],
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          const Spacer(),
          const Spacer(),
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
                icon: Icons.arrow_back_rounded,
                onPressed: () {
                  _onControlInteraction();
                  widget.onFullScreenToggle!();
                },
                size: 22,
                padding: const EdgeInsets.all(8),
              ),
              const SizedBox(width: 12),
            ],

            // Channel name + live indicator + server badge
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.channelName,
                    style: GoogleFonts.montserrat(
                      fontSize: widget.isFullScreen ? 17 : 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      // Live dot
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: widget.controller.isPlaying
                              ? Colors.red
                              : Colors.grey,
                          shape: BoxShape.circle,
                          boxShadow: widget.controller.isPlaying
                              ? [
                                  BoxShadow(
                                    color: Colors.red.withAlpha(128),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        'EN VIVO',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: widget.controller.isPlaying
                              ? Colors.white
                              : Colors.white60,
                          letterSpacing: 1.0,
                        ),
                      ),
                      // Server badge
                      if (widget.totalServers > 1) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withAlpha(140),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.white.withAlpha(51),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            '${widget.currentServer}/${widget.totalServers}',
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                              color: Colors.white,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                      // Error indicator
                      if (widget.controller.hasError) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 16,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // 3-dot server menu
            if (widget.totalServers > 1 && widget.serverList != null)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _buildServerMenuButton(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildServerMenuButton() {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      decoration: BoxDecoration(
        color: primary.withAlpha(180),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: primary.withAlpha(255), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: primary.withAlpha(80),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _onControlInteraction();
            _openServerPicker();
          },
          borderRadius: BorderRadius.circular(10),
          splashColor: Colors.white.withAlpha(51),
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(
              Icons.more_vert_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Row(
          children: [
            _buildControlSvg(
              assetPath: widget.isMuted
                  ? 'assets/icons/volume_off_16.svg'
                  : 'assets/icons/volume_16.svg',
              onPressed: () {
                _onControlInteraction();
                HapticFeedback.mediumImpact();
                widget.onMuteToggle?.call();
              },
              size: 20,
            ),
            if (widget.isFullScreen) ...[
              const SizedBox(width: 12),
              _buildControlButton(
                icon: Icons.aspect_ratio_rounded,
                label: widget.aspectRatioLabel,
                onPressed: () {
                  _onControlInteraction();
                  HapticFeedback.mediumImpact();
                  widget.onAspectRatioChange?.call();
                  _showAspectRatioChangeToast();
                },
                size: 19,
              ),
            ],
            const Spacer(),
            if (widget.onFullScreenToggle != null)
              _buildControlSvg(
                assetPath: widget.isFullScreen
                    ? 'assets/icons/player/salir-pantalla-completa.svg'
                    : 'assets/icons/player/pantalla-completa.svg',
                onPressed: () {
                  _onControlInteraction();
                  HapticFeedback.mediumImpact();
                  widget.onFullScreenToggle!();
                },
                size: 20,
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
        color: Colors.black.withAlpha(140),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withAlpha(64), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(77),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          splashColor: Colors.white.withAlpha(51),
          highlightColor: Colors.white.withAlpha(26),
          child: Padding(
            padding: padding ??
                const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: size),
                if (label != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: Colors.white,
                      letterSpacing: 0.5,
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

  Widget _buildControlSvg({
    required String assetPath,
    required VoidCallback onPressed,
    double size = 20,
    EdgeInsets? padding,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(140),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withAlpha(64), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(77),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          splashColor: Colors.white.withAlpha(51),
          highlightColor: Colors.white.withAlpha(26),
          child: Padding(
            padding: padding ??
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: SvgPicture.asset(
              assetPath,
              width: size,
              height: size,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════
// SERVER PICKER BOTTOM SHEET
// ════════════════════════════════════════

class _ServerPickerSheet extends StatelessWidget {
  final List<ServerInfo> servers;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  const _ServerPickerSheet({
    required this.servers,
    required this.currentIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.52,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(60),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.dns_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  'Seleccionar Servidor',
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withAlpha(40),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withAlpha(80),
                    ),
                  ),
                  child: Text(
                    '${servers.length} servidores',
                    style: GoogleFonts.montserrat(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: Colors.white.withAlpha(15),
          ),
          // Server list
          Flexible(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              shrinkWrap: true,
              itemCount: servers.length,
              itemBuilder: (ctx, i) => _ServerTile(
                server: servers[i],
                isActive: servers[i].index == currentIndex,
                onTap: () => onSelect(servers[i].index),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServerTile extends StatelessWidget {
  final ServerInfo server;
  final bool isActive;
  final VoidCallback onTap;

  const _ServerTile({
    required this.server,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final typeColor = server.typeColor(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? primary.withAlpha(30) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? primary.withAlpha(100) : Colors.transparent,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: primary.withAlpha(40),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Number circle
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isActive ? primary : Colors.white.withAlpha(15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${server.index + 1}',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Label
                Expanded(
                  child: Text(
                    server.label,
                    style: GoogleFonts.montserrat(
                      color: isActive ? Colors.white : Colors.white70,
                      fontSize: 14,
                      fontWeight:
                          isActive ? FontWeight.w700 : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                // Type badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: typeColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: typeColor.withAlpha(120),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    server.typeLabel,
                    style: GoogleFonts.montserrat(
                      color: typeColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Active checkmark
                if (isActive)
                  Icon(
                    Icons.check_circle_rounded,
                    color: primary,
                    size: 18,
                  )
                else
                  const SizedBox(width: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}