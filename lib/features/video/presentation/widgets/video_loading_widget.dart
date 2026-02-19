import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Kick-style professional loading overlay v5.0
/// - Buffering: BackdropFilter blur + pulsing spinner badge
/// - Full loading: solid black + animated spinner
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
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _fadeCtrl;
  late Animation<double> _pulseAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _fadeCtrl = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..forward();

    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════
  // BUFFERING — Kick-style blur overlay
  // ═══════════════════════════════════════
  Widget _buildBufferingOverlay(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SizedBox.expand(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            color: Colors.black.withAlpha(100),
            child: Center(
              child: ScaleTransition(
                scale: _pulseAnim,
                child: _buildSpinnerBadge(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpinnerBadge(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(200),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withAlpha(40), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(120),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(
                        Colors.white.withAlpha(35),
                      ),
                    ),
                    CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Text(
                widget.message,
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
        if (widget.serverInfo != null) ...[
          const SizedBox(height: 10),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: primary.withAlpha(180),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: Colors.white.withAlpha(30), width: 0.5),
            ),
            child: Text(
              'Servidor ${widget.serverInfo}',
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ═══════════════════════════════════════
  // FULL LOADING — Solid black overlay
  // ═══════════════════════════════════════
  Widget _buildFullLoading(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _pulseAnim,
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation(
                          Colors.white.withAlpha(25),
                        ),
                      ),
                      CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation(primary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(10),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.white.withAlpha(20), width: 1),
                ),
                child: Text(
                  widget.message,
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (widget.serverInfo != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: primary.withAlpha(160),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Servidor ${widget.serverInfo}',
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
              if (widget.subMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  widget.subMessage!,
                  style: GoogleFonts.montserrat(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              if (widget.onRetry != null) ...[
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: widget.onRetry,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: primary, width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          color: primary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'REINTENTAR',
                          style: GoogleFonts.montserrat(
                            color: primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isBuffering) {
      return _buildBufferingOverlay(context);
    }
    return _buildFullLoading(context);
  }
}