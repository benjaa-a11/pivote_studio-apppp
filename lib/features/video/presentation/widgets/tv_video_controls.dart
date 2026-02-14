import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pivote/features/video/presentation/widgets/unified_video_controller.dart';

class TvVideoControls extends StatefulWidget {
  final UnifiedVideoController controller;
  final String channelName;
  final VoidCallback onFullScreenToggle;
  final bool isFullScreen;
  final String aspectRatioLabel;
  final VoidCallback onAspectRatioChange;
  final VoidCallback onMuteToggle;
  final bool isMuted;
  final int currentServer;
  final int totalServers;

  const TvVideoControls({
    super.key,
    required this.controller,
    required this.channelName,
    required this.onFullScreenToggle,
    required this.isFullScreen,
    required this.aspectRatioLabel,
    required this.onAspectRatioChange,
    required this.onMuteToggle,
    required this.isMuted,
    required this.currentServer,
    required this.totalServers,
  });

  @override
  State<TvVideoControls> createState() => _TvVideoControlsState();
}

class _TvVideoControlsState extends State<TvVideoControls> {
  bool _isVisible = true;
  Timer? _hideTimer;

  final FocusNode _playPauseFocus = FocusNode();
  final FocusNode _muteFocus = FocusNode();
  final FocusNode _aspectRatioFocus = FocusNode();
  final FocusNode _serverFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _startHideTimer();
    // Auto-focus play button when controls appear
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playPauseFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _playPauseFocus.dispose();
    _muteFocus.dispose();
    _aspectRatioFocus.dispose();
    _serverFocus.dispose();
    super.dispose();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 5), () {
      if (mounted &&
          _isVisible &&
          !(_playPauseFocus.hasFocus ||
              _muteFocus.hasFocus ||
              _aspectRatioFocus.hasFocus ||
              _serverFocus.hasFocus)) {
        // Only hide if no button is focused? Actually in TV it's better to show if any interaction happens.
        // But we usually want to hide after some time.
        setState(() => _isVisible = false);
      } else if (mounted && _isVisible) {
        // If something is focused, restart timer
        _startHideTimer();
      }
    });
  }

  void _showControls() {
    if (!_isVisible) {
      setState(() => _isVisible = true);
      _playPauseFocus.requestFocus();
    }
    _startHideTimer();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _showControls,
        child: Focus(
          onKeyEvent: (node, event) {
            _showControls();
            return KeyEventResult.ignored;
          },
          child: const SizedBox.expand(),
        ),
      );
    }

    final theme = Theme.of(context);

    return PopScope(
      canPop: !_isVisible,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isVisible) {
          setState(() => _isVisible = false);
        }
      },
      child: GestureDetector(
        onTap: _showControls,
        behavior: HitTestBehavior.opaque,
        child: FocusableActionDetector(
          onShowFocusHighlight: (show) => _showControls(),
          child: Container(
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
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // Top Bar: Channel Info
                Positioned(
                  top: 40,
                  left: 40,
                  right: 40,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back,
                            color: Colors.white, size: 32),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.channelName,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Servidor ${widget.currentServer}/${widget.totalServers}",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom Bar: Controls
                Positioned(
                  bottom: 60,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      // Playback Controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildControlButton(
                            focusNode: _muteFocus,
                            icon: widget.isMuted
                                ? Icons.volume_off
                                : Icons.volume_up,
                            onPressed: widget.onMuteToggle,
                            label: widget.isMuted ? "Unmute" : "Mute",
                          ),
                          const SizedBox(width: 40),
                          _buildControlButton(
                            focusNode: _playPauseFocus,
                            icon: widget.controller.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            onPressed: () {
                              if (widget.controller.isPlaying) {
                                widget.controller.pause();
                              } else {
                                widget.controller.play();
                              }
                              setState(() {});
                              _startHideTimer();
                            },
                            isLarge: true,
                            label: widget.controller.isPlaying
                                ? "Pausar"
                                : "Reproducir",
                          ),
                          const SizedBox(width: 40),
                          _buildControlButton(
                            focusNode: _aspectRatioFocus,
                            icon: Icons.aspect_ratio,
                            onPressed: widget.onAspectRatioChange,
                            label: widget.aspectRatioLabel,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required FocusNode focusNode,
    required IconData icon,
    required VoidCallback onPressed,
    String? label,
    bool isLarge = false,
  }) {
    return _TvControlItem(
      focusNode: focusNode,
      icon: icon,
      onPressed: onPressed,
      label: label,
      isLarge: isLarge,
    );
  }
}

class _TvControlItem extends StatefulWidget {
  final FocusNode focusNode;
  final IconData icon;
  final VoidCallback onPressed;
  final String? label;
  final bool isLarge;

  const _TvControlItem({
    required this.focusNode,
    required this.icon,
    required this.onPressed,
    this.label,
    this.isLarge = false,
  });

  @override
  State<_TvControlItem> createState() => _TvControlItemState();
}

class _TvControlItemState extends State<_TvControlItem> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = widget.focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = widget.isLarge ? 80.0 : 60.0;
    final iconSize = widget.isLarge ? 48.0 : 32.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          focusNode: widget.focusNode,
          onTap: widget.onPressed,
          borderRadius: BorderRadius.circular(size / 2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isFocused ? Colors.white : Colors.black45,
              border: _isFocused
                  ? Border.all(color: theme.colorScheme.primary, width: 3)
                  : null,
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.5),
                          blurRadius: 15)
                    ]
                  : null,
            ),
            child: Icon(
              widget.icon,
              size: iconSize,
              color: _isFocused ? Colors.black : Colors.white,
            ),
          ),
        ),
        if (widget.label != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.label!,
            style: TextStyle(
              color: _isFocused ? Colors.white : Colors.white70,
              fontSize: 12,
              fontWeight: _isFocused ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ],
    );
  }
}
