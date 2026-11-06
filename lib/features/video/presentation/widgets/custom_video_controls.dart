import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
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
        return const Color(0xFF10B981);
      case ServerType.dash:
        return const Color(0xFF3B82F6);
      case ServerType.web:
        return const Color(0xFFF59E0B);
      case ServerType.unknown:
        return const Color(0xFF8B5CF6);
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
  bool _controlsLocked = false;
  bool _isMenuOpen = false;
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
    if (_isMenuOpen) return;
    if (_showControls) {
      setState(() {
        _showControls = false;
      });
      _fadeController.reverse();
    }
  }

  void _scheduleAutoHide() {
    _hideTimer?.cancel();
    if (_isMenuOpen) return;

    _hideTimer = Timer(_inactivityTimeout, () {
      if (!mounted || _isMenuOpen) return;
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
  // Server Selector Modal / Popover
  // ═══════════════════════════════════════

  Future<void> _openServerSelector() async {
    final servers = widget.serverList ??
        List.generate(
          widget.totalServers.clamp(1, 20),
          (i) => ServerInfo(
            index: i,
            label: 'Opción ${i + 1}',
            type: ServerType.unknown,
          ),
        );

    if (servers.isEmpty) return;

    _hideTimer?.cancel();
    setState(() {
      _isMenuOpen = true;
    });

    HapticFeedback.mediumImpact();

    final selectedIndex = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _ServerSelectorSheet(
        channelName: widget.channelName,
        servers: servers,
        currentServerIndex: (widget.currentServer - 1).clamp(0, servers.length - 1),
      ),
    );

    if (!mounted) return;
    setState(() {
      _isMenuOpen = false;
    });

    if (selectedIndex != null) {
      HapticFeedback.selectionClick();
      widget.onServerSelect?.call(selectedIndex);
    }

    _scheduleAutoHide();
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
                          color: isPlaying
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (isPlaying
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444))
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
                  _scheduleAutoHide();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    final hasServers = widget.totalServers > 0;

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

            // Botón de Servidores con diseño moderno y despliegue limpio
            if (hasServers)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _openServerSelector,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.dns_rounded,
                          color: AppTheme.darkAccent,
                          size: 15,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.totalServers > 1
                              ? 'Servidor ${widget.currentServer}/${widget.totalServers}'
                              : 'Servidor 1',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.1,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_up_rounded,
                          color: Colors.white70,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            if (hasServers) const SizedBox(width: 10),

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

// ════════════════════════════════════════════════════════════════════════════
// SERVER SELECTOR BOTTOM SHEET (Clean & Professional UI)
// ════════════════════════════════════════════════════════════════════════════

class _ServerSelectorSheet extends StatelessWidget {
  final String channelName;
  final List<ServerInfo> servers;
  final int currentServerIndex;

  const _ServerSelectorSheet({
    required this.channelName,
    required this.servers,
    required this.currentServerIndex,
  });

  @override
  Widget build(BuildContext context) {
    final maxSheetHeight = MediaQuery.of(context).size.height * 0.65;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 460,
          maxHeight: maxSheetHeight,
        ),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          decoration: BoxDecoration(
            color: const Color(0xFF14161D),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 16, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: AppTheme.darkAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.dns_rounded,
                        color: AppTheme.darkAccent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Seleccionar Servidor',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Si una señal presenta cortes, prueba otra opción',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white60,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),

              Divider(
                height: 1,
                color: Colors.white.withValues(alpha: 0.08),
              ),

              // Server Options List
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                  itemCount: servers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final srv = servers[index];
                    final isCurrent = srv.index == currentServerIndex;

                    return Material(
                      color: isCurrent
                          ? AppTheme.darkAccent.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(srv.index),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isCurrent
                                  ? AppTheme.darkAccent.withValues(alpha: 0.8)
                                  : Colors.white.withValues(alpha: 0.07),
                              width: isCurrent ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Server number badge
                              Container(
                                width: 32,
                                height: 32,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? AppTheme.darkAccent
                                      : Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${srv.index + 1}',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    color: isCurrent
                                        ? Colors.white
                                        : Colors.white70,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Label & Subtitle
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Servidor ${srv.index + 1}',
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (srv.label.isNotEmpty &&
                                        srv.label.toLowerCase() !=
                                            'servidor ${srv.index + 1}' &&
                                        srv.label.toLowerCase() !=
                                            'opción ${srv.index + 1}')
                                      Text(
                                        srv.label,
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white60,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),

                              // Status indicator
                              if (isCurrent)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981)
                                        .withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF10B981),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'ACTIVO',
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          color: const Color(0xFF10B981),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                const Icon(
                                  Icons.play_circle_outline_rounded,
                                  color: Colors.white54,
                                  size: 20,
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
        ),
      ),
    );
  }
}
