import 'package:flutter/material.dart';
import 'package:pivote/shared/widgets/common/pivote_loader.dart';

/// Clean professional loading overlay for all video players.
///
/// Renders a solid black background with a centered, animated loading
/// indicator.  No blur, no transparency — the widget sits flush with
/// the player canvas so it never leaks over the navigation header.
class VideoLoadingWidget extends StatelessWidget {
  const VideoLoadingWidget({
    super.key,
    // Maintaining these params in case they're passed, but ignoring them
    String message = '',
    String? subMessage,
    String? serverInfo,
    VoidCallback? onRetry,
    bool isBuffering = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: const Center(
        child: PivoteLoader(
          size: 45,
          strokeWidth: 4.5,
        ),
      ),
    );
  }
}
