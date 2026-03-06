import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Clean professional loading overlay
class VideoLoadingWidget extends StatefulWidget {
  final String message;
  final String? subMessage;
  final String? serverInfo;
  final VoidCallback? onRetry;
  final bool isBuffering;

  const VideoLoadingWidget({
    super.key,
    this.message = 'Conectando...',
    this.subMessage,
    this.serverInfo,
    this.onRetry,
    this.isBuffering = false,
  });

  @override
  State<VideoLoadingWidget> createState() => _VideoLoadingWidgetState();
}

class _VideoLoadingWidgetState extends State<VideoLoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SizedBox.expand(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: Colors.black.withAlpha(100),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation(primary),
                    ),
                  ),
                  if (widget.serverInfo != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(150),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withAlpha(20), width: 1),
                      ),
                      child: Text(
                        'Servidor ${widget.serverInfo}',
                        style: GoogleFonts.dmSans(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
