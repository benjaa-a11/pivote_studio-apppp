import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import 'package:pivote/features/video/presentation/widgets/unified_video_controller.dart';
import 'package:pivote/features/video/presentation/widgets/video_loading_widget.dart';
import 'package:google_fonts/google_fonts.dart';

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
  });

  @override
  State<CustomVideoControls> createState() => _CustomVideoControlsState();
}

class _CustomVideoControlsState extends State<CustomVideoControls>
    with TickerProviderStateMixin {
  bool _showControls = true;
  Timer? _hideTimer;
  bool _showAspectRatioToast = false;
  Timer? _aspectRatioToastTimer;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  late AnimationController _toastController;
  late Animation<double> _toastAnimation;

  @override
  void initState() {
    super.initState();

    // Animación de fade para controles
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    // Animación para toast
    _toastController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _toastAnimation = CurvedAnimation(
      parent: _toastController,
      curve: Curves.easeOutBack,
    );

    widget.controller.addListener(_videoListener);
    _startHideTimer();
    _fadeController.forward();
  }

  void _videoListener() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _aspectRatioToastTimer?.cancel();
    _fadeController.dispose();
    _toastController.dispose();
    widget.controller.removeListener(_videoListener);
    super.dispose();
  }

  void _toggleControls() {
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
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && widget.controller.isPlaying) {
        setState(() {
          _showControls = false;
          _fadeController.reverse();
        });
      }
    });
  }

  void _showAspectRatioChangeToast() {
    setState(() {
      _showAspectRatioToast = true;
    });

    _toastController.forward(from: 0.0);

    _aspectRatioToastTimer?.cancel();
    _aspectRatioToastTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _toastController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _showAspectRatioToast = false;
            });
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleControls,
      child: Container(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Indicador de buffering mejorado
            if (widget.controller.isBuffering) _buildBufferingIndicator(),

            // Toast de aspect ratio con animación (solo en fullscreen)
            if (_showAspectRatioToast && widget.isFullScreen)
              _buildAspectRatioToast(),

            // Controles con fade
            FadeTransition(
              opacity: _fadeAnimation,
              child: IgnorePointer(
                ignoring: _fadeAnimation.value < 0.1,
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
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 300),
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: const VideoLoadingWidget(
              message: 'Cargando...',
              isBuffering: true,
            ),
          );
        },
      ),
    );
  }

  Widget _buildAspectRatioToast() {
    return Center(
      child: ScaleTransition(
        scale: _toastAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(230),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withAlpha(153),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withAlpha(77),
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
                  fontWeight: FontWeight.w500,
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
            Colors.black.withValues(alpha: 0.7),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withValues(alpha: 0.8),
          ],
          stops: const [0.0, 0.2, 0.8, 1.0],
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          const Spacer(),
          // Center controls removed - live channels don't need play/pause
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
            // Botón de volver SOLO en fullscreen
            if (widget.isFullScreen && widget.onFullScreenToggle != null) ...[
              _buildControlButton(
                icon: Icons.arrow_back_rounded,
                onPressed: () {
                  widget.onFullScreenToggle!();
                  _startHideTimer();
                },
                size: 22,
                padding: const EdgeInsets.all(8),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.channelName,
                    style: GoogleFonts.montserrat(
                      fontSize: widget.isFullScreen ? 17 : 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      letterSpacing: 0.15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withAlpha(128),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        'EN VIVO',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: Colors.white70,
                          letterSpacing: 1.0,
                        ),
                      ),
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
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                              color: Colors.white,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
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
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Row(
          children: [
            // Botón de mute/unmute
            _buildControlSvg(
              assetPath: widget.isMuted
                  ? 'assets/icons/volume_off_16.svg'
                  : 'assets/icons/volume_16.svg',
              onPressed: () {
                widget.onMuteToggle?.call();
                _startHideTimer();
              },
              size: 20,
            ),
            // Botón de aspect ratio SOLO en fullscreen
            if (widget.isFullScreen) ...[
              const SizedBox(width: 12),
              _buildControlButton(
                icon: Icons.aspect_ratio_rounded,
                label: widget.aspectRatioLabel,
                onPressed: () {
                  widget.onAspectRatioChange?.call();
                  _showAspectRatioChangeToast();
                  _startHideTimer();
                },
                size: 19,
              ),
            ],
            const Spacer(),
            // Botón de fullscreen (siempre visible)
            if (widget.onFullScreenToggle != null)
              _buildControlSvg(
                assetPath: widget.isFullScreen
                    ? 'assets/icons/player/salir-pantalla-completa.svg'
                    : 'assets/icons/player/pantalla-completa.svg',
                onPressed: () {
                  widget.onFullScreenToggle!();
                  _startHideTimer();
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
        border: Border.all(
          color: Colors.white.withAlpha(64),
          width: 1,
        ),
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
          child: Padding(
            padding: padding ??
                EdgeInsets.symmetric(
                  horizontal: label != null ? 10 : 10,
                  vertical: 8,
                ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: size,
                ),
                if (label != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w500,
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
        border: Border.all(
          color: Colors.white.withAlpha(64),
          width: 1,
        ),
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
