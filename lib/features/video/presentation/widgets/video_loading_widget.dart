import 'package:flutter/material.dart';
import 'package:pivote/shared/widgets/common/pivote_loader.dart';

/// Clean professional loading overlay for all video players.
///
/// Renders a solid black background with a centered, animated loading
/// indicator.  No blur, no transparency — the widget sits flush with
/// the player canvas so it never leaks over the navigation header.
class VideoLoadingWidget extends StatelessWidget {
  final bool isBuffering;

  const VideoLoadingWidget({
    super.key,
    String message = '',
    String? subMessage,
    String? serverInfo,
    VoidCallback? onRetry,
    this.isBuffering = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isBuffering ? Colors.transparent : Colors.black,
      child: const Center(
        child: PivoteLoader(
          size: 45,
          strokeWidth: 4.5,
        ),
      ),
    );
  }
}
