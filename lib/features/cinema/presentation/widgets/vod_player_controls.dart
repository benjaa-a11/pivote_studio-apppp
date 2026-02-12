import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../data/models/vod_content.dart';

class VodPlayerControls extends StatelessWidget {
  final VideoPlayerController? controller;
  final String contentTitle;
  final String? episodeTitle;
  final Duration currentPosition;
  final Duration duration;
  final bool isPlaying;
  final bool isBuffering;
  final bool isFullScreen;
  final List<VideoServer> availableServers;
  final int currentServerIndex;
  final VoidCallback onPlayPause;
  final Function(Duration) onSeek;
  final Function(Duration) onSeekRelative;
  final VoidCallback onFullScreenToggle;
  final Function(int) onServerChange;

  const VodPlayerControls({
    super.key,
    required this.controller,
    required this.contentTitle,
    this.episodeTitle,
    required this.currentPosition,
    required this.duration,
    required this.isPlaying,
    required this.isBuffering,
    required this.isFullScreen,
    required this.availableServers,
    required this.currentServerIndex,
    required this.onPlayPause,
    required this.onSeek,
    required this.onSeekRelative,
    required this.onFullScreenToggle,
    required this.onServerChange,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Top Bar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.7),
                  Colors.transparent
                ],
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contentTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (episodeTitle != null)
                        Text(
                          episodeTitle!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.dns, color: Colors.white),
                  onPressed: () => _showServerDialog(context),
                ),
              ],
            ),
          ),
        ),

        // Center Play/Pause
        Center(
          child: isBuffering
              ? const CircularProgressIndicator()
              : IconButton(
                  iconSize: 64,
                  icon: Icon(
                    isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  onPressed: onPlayPause,
                ),
        ),

        // Bottom Bar
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.7),
                  Colors.transparent
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Seek Bar
                Row(
                  children: [
                    Text(
                      _formatDuration(currentPosition),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    Expanded(
                      child: Slider(
                        value: currentPosition.inMilliseconds.toDouble(),
                        max: duration.inMilliseconds.toDouble() > 0
                            ? duration.inMilliseconds.toDouble()
                            : 1.0,
                        onChanged: (value) {
                          onSeek(Duration(milliseconds: value.toInt()));
                        },
                        activeColor: Theme.of(context).colorScheme.primary,
                        inactiveColor: Colors.white24,
                      ),
                    ),
                    Text(
                      _formatDuration(duration),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
                // Bottom Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon:
                              const Icon(Icons.replay_10, color: Colors.white),
                          onPressed: () =>
                              onSeekRelative(const Duration(seconds: -10)),
                        ),
                        IconButton(
                          icon:
                              const Icon(Icons.forward_10, color: Colors.white),
                          onPressed: () =>
                              onSeekRelative(const Duration(seconds: 10)),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(
                        isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                        color: Colors.white,
                      ),
                      onPressed: onFullScreenToggle,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showServerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar Servidor'),
        backgroundColor: const Color(0xFF1E293B),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableServers.length,
            itemBuilder: (context, index) {
              final server = availableServers[index];
              final isSelected = index == currentServerIndex;
              return ListTile(
                leading: Icon(
                  Icons.dns,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.white70,
                ),
                title: Text(
                  server.name,
                  style: TextStyle(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  onServerChange(index);
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return d.inHours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }
}
