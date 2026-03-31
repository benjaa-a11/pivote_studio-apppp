import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Clean professional loading overlay for all video players.
///
/// Renders a solid black background with a centered, animated loading
/// indicator.  No blur, no transparency — the widget sits flush with
/// the player canvas so it never leaks over the navigation header.
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
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Animated ring spinner ──────────────────────────────
            SizedBox(
              width: 52,
              height: 52,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer glow ring
                  AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (context, child) {
                      return Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: primary.withAlpha(
                                (30 * _pulseAnim.value).toInt()),
                            width: 3,
                          ),
                        ),
                      );
                    },
                  ),
                  // Actual spinner
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      strokeCap: StrokeCap.round,
                      valueColor: AlwaysStoppedAnimation(primary),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Message ──────────────────────────────────────────
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (context, _) {
                return Opacity(
                  opacity: _pulseAnim.value,
                  child: Text(
                    widget.message,
                    style: GoogleFonts.dmSans(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),

            // ── Sub-message (retry info) ─────────────────────────
            if (widget.subMessage != null) ...[
              const SizedBox(height: 6),
              Text(
                widget.subMessage!,
                style: GoogleFonts.dmSans(
                  color: Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            // ── Server badge ─────────────────────────────────────
            if (widget.serverInfo != null) ...[
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(8),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: Colors.white.withAlpha(15), width: 1),
                ),
                child: Text(
                  'Servidor ${widget.serverInfo}',
                  style: GoogleFonts.dmSans(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
