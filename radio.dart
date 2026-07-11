import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class WorldCupCountdown extends StatefulWidget {
  const WorldCupCountdown({super.key});

  @override
  State<WorldCupCountdown> createState() => _WorldCupCountdownState();
}

class _WorldCupCountdownState extends State<WorldCupCountdown>
    with TickerProviderStateMixin {
  late Timer _timer;
  late DateTime _targetDate;
  Duration _timeLeft = Duration.zero;

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late AnimationController _blinkController;
  late AnimationController _floatController;
  late AnimationController _entryController;
  late AnimationController _glowController;

  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _blinkAnimation;
  late Animation<double> _floatAnimation;
  late Animation<double> _entryAnimation;
  late Animation<double> _glowAnimation;

  // Host cities rotation
  int _currentCityIndex = 0;
  late Timer _cityTimer;

  static const List<String> _hostCities = [
    'New York / New Jersey',
    'Los Ángeles',
    'Dallas',
    'Miami',
    'Atlanta',
    'Houston',
    'Philadelphia',
    'Seattle',
    'San Francisco',
    'Kansas City',
    'Boston',
    'Ciudad de México',
    'Guadalajara',
    'Monterrey',
    'Toronto',
    'Vancouver',
  ];

  // FWC-26 Official Brand Colors + Argentine Accent
  static const Color _fwcOrange = Color(0xFFFF4D00);
  static const Color _fwcCyan = Color(0xFF00FFD1);
  static const Color _fwcPurple = Color(0xFF8A00FF);
  static const Color _fwcLime = Color(0xFFD4FF00);
  static const Color _argBlue = Color(0xFF74ACDF); // Argentine sky blue

  @override
  void initState() {
    super.initState();
    _targetDate = DateTime(2026, 6, 11);
    _calculateTimeLeft();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _calculateTimeLeft());
    });

    // Entry animation
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _entryAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.elasticOut,
    );
    _entryController.forward();

    // Pulse animation for countdown numbers
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Shimmer animation
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat();
    _shimmerAnimation = Tween<double>(begin: -2.0, end: 3.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.linear),
    );

    // Glow breathing animation
    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.2, end: 0.6).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Blink animation for separators
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _blinkAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );

    // Float animation for logo
    _floatController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // City rotation timer
    _cityTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          _currentCityIndex = (_currentCityIndex + 1) % _hostCities.length;
        });
      }
    });
  }

  void _calculateTimeLeft() {
    final now = DateTime.now();
    _timeLeft = _targetDate.difference(now);
    if (_timeLeft.isNegative) _timeLeft = Duration.zero;
  }

  @override
  void dispose() {
    _timer.cancel();
    _cityTimer.cancel();
    _pulseController.dispose();
    _shimmerController.dispose();
    _blinkController.dispose();
    _floatController.dispose();
    _entryController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = _timeLeft.inDays;
    final hours = _timeLeft.inHours % 24;
    final minutes = _timeLeft.inMinutes % 60;
    final seconds = _timeLeft.inSeconds % 60;
    final hasStarted = _timeLeft == Duration.zero;

    return FadeTransition(
      opacity: _entryAnimation,
      child: ScaleTransition(
        scale: _entryAnimation,
        child: _buildCard(days, hours, minutes, seconds, hasStarted),
      ),
    );
  }

  Widget _buildCard(
      int days, int hours, int minutes, int seconds, bool hasStarted) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        final bool isCompact = maxWidth < 380;

        // Dynamically compute sizing for time boxes to ensure 100% responsivity
        final double horizontalPadding = isCompact ? 12 : 18;
        final double separatorsWidth = 3 * (isCompact ? 10 : 16);
        final double availableWidthForBoxes = maxWidth - (horizontalPadding * 2) - separatorsWidth;
        
        final double timeBoxWidth = (availableWidthForBoxes / 4).clamp(52.0, 75.0);
        final double timeBoxHeight = timeBoxWidth * 1.15;
        final double valueFontSize = (timeBoxWidth * 0.44).clamp(16.0, 30.0);
        final double labelFontSize = (timeBoxWidth * 0.16).clamp(8.0, 10.0);

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: _fwcCyan.withValues(alpha: 0.15),
                blurRadius: 40,
                spreadRadius: -10,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Stack(
              children: [
                // === DEEP SPACE FUTURISTIC GLOW BACKGROUND ===
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF070014), // Ultra deep space purple
                          Color(0xFF00081C), // Deep stadium blue
                          Color(0xFF00140E), // Deep field green/cyan
                        ],
                      ),
                    ),
                  ),
                ),

                // === BACKGROUND IMAGE OVERLAY (With glowing pitch fallback) ===
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.22,
                    child: Image.asset(
                      'assets/FWC-26/fwc-26-background.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return CustomPaint(
                          painter: _SoccerPitchPainter(),
                        );
                      },
                    ),
                  ),
                ),

                // === DYNAMIC RADIAL GLOW OVERLAY ===
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _glowAnimation,
                    builder: (context, _) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: const Alignment(-0.5, -0.6),
                            radius: 1.5,
                            colors: [
                              _fwcPurple.withValues(alpha: 0.35 * _glowAnimation.value),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.7),
                            ],
                            stops: const [0.0, 0.7, 1.0],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // === SHIMMER SWIPE ===
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _shimmerAnimation,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _PremiumShimmerPainter(
                          progress: _shimmerAnimation.value,
                          color: _fwcCyan,
                        ),
                      );
                    },
                  ),
                ),

                // === CONTENT ===
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: isCompact ? 16 : 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(hasStarted, isCompact),
                      SizedBox(height: isCompact ? 16 : 24),
                      _buildCountdownSection(
                        days,
                        hours,
                        minutes,
                        seconds,
                        hasStarted,
                        timeBoxWidth: timeBoxWidth,
                        timeBoxHeight: timeBoxHeight,
                        valueFontSize: valueFontSize,
                        labelFontSize: labelFontSize,
                        isCompact: isCompact,
                      ),
                      SizedBox(height: isCompact ? 16 : 24),
                      _buildFooter(isCompact),
                    ],
                  ),
                ),

                // === ARGENTINE ACCENT CORNER ===
                Positioned(
                  top: -15,
                  right: -15,
                  child: Transform.rotate(
                    angle: 0.4,
                    child: Container(
                      width: 60,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _argBlue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool hasStarted, bool isCompact) {
    return Row(
      children: [
        // Logo with float
        AnimatedBuilder(
          animation: _floatAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _floatAnimation.value),
              child: child,
            );
          },
          child: Container(
            padding: EdgeInsets.all(isCompact ? 6 : 10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.white.withValues(alpha: 0.1), Colors.transparent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Image.asset(
              'assets/FWC-26/2026-FIFA-World-Cup256x-white.png',
              height: isCompact ? 30 : 40,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) {
                return Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.white,
                  size: isCompact ? 18 : 24,
                );
              },
            ),
          ),
        ),
        SizedBox(width: isCompact ? 10 : 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasStarted ? 'EN CURSO' : 'CUENTA REGRESIVA',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: isCompact ? 8 : 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: isCompact ? 1.5 : 2.5,
                  color: _fwcCyan,
                ),
              ),
              Text(
                'WORLD CUP 26™',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: isCompact ? 18 : 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        // Argentine Mini-Flag (Subtle detail)
        Container(
          padding: EdgeInsets.symmetric(horizontal: isCompact ? 6 : 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _argBlue.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🇦🇷', style: TextStyle(fontSize: isCompact ? 10 : 12)),
              SizedBox(width: isCompact ? 2 : 4),
              Text(
                'ARG',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: isCompact ? 8 : 10,
                  fontWeight: FontWeight.bold,
                  color: _argBlue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCountdownSection(
    int days,
    int hours,
    int minutes,
    int seconds,
    bool hasStarted, {
    required double timeBoxWidth,
    required double timeBoxHeight,
    required double valueFontSize,
    required double labelFontSize,
    required bool isCompact,
  }) {
    if (hasStarted) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text(
          '¡EL MUNDIAL HA EMPEZADO!',
          style: GoogleFonts.spaceGrotesk(
            fontSize: isCompact ? 18 : 24,
            fontWeight: FontWeight.w900,
            color: _fwcLime,
            shadows: [Shadow(color: _fwcLime.withValues(alpha: 0.5), blurRadius: 20)],
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildTimeBox(
          days.toString(),
          'DÍAS',
          _fwcCyan,
          width: timeBoxWidth,
          height: timeBoxHeight,
          valueSize: valueFontSize,
          labelSize: labelFontSize,
        ),
        _buildSeparator(isCompact),
        _buildTimeBox(
          hours.toString().padLeft(2, '0'),
          'HORAS',
          _fwcOrange,
          width: timeBoxWidth,
          height: timeBoxHeight,
          valueSize: valueFontSize,
          labelSize: labelFontSize,
        ),
        _buildSeparator(isCompact),
        _buildTimeBox(
          minutes.toString().padLeft(2, '0'),
          'MIN',
          _fwcLime,
          width: timeBoxWidth,
          height: timeBoxHeight,
          valueSize: valueFontSize,
          labelSize: labelFontSize,
        ),
        _buildSeparator(isCompact),
        _buildTimeBox(
          seconds.toString().padLeft(2, '0'),
          'SEG',
          _fwcPurple,
          width: timeBoxWidth,
          height: timeBoxHeight,
          valueSize: valueFontSize,
          labelSize: labelFontSize,
        ),
      ],
    );
  }

  Widget _buildTimeBox(
    String value,
    String label,
    Color accentColor, {
    required double width,
    required double height,
    required double valueSize,
    required double labelSize,
  }) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: child,
            );
          },
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(width * 0.3),
              color: Colors.white.withValues(alpha: 0.05),
              border: Border.all(color: accentColor.withValues(alpha: 0.35), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.12),
                  blurRadius: 15,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(width * 0.3),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Center(
                  child: Text(
                    value,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: valueSize,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: labelSize,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: accentColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSeparator(bool isCompact) {
    return FadeTransition(
      opacity: _blinkAnimation,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isCompact ? 3 : 4,
            height: isCompact ? 3 : 4,
            decoration: const BoxDecoration(color: Colors.white30, shape: BoxShape.circle),
          ),
          SizedBox(height: isCompact ? 6 : 8),
          Container(
            width: isCompact ? 3 : 4,
            height: isCompact ? 3 : 4,
            decoration: const BoxDecoration(color: Colors.white30, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isCompact) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_on_rounded, size: isCompact ? 12 : 14, color: _fwcOrange),
          SizedBox(width: isCompact ? 6 : 8),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Text(
                _hostCities[_currentCityIndex].toUpperCase(),
                key: ValueKey(_currentCityIndex),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: isCompact ? 8.5 : 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white70,
                  letterSpacing: 1.0,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          SizedBox(width: isCompact ? 6 : 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _fwcCyan.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '16 SEDES',
              style: GoogleFonts.spaceGrotesk(
                fontSize: isCompact ? 7.5 : 8,
                fontWeight: FontWeight.w900,
                color: _fwcCyan,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumShimmerPainter extends CustomPainter {
  final double progress;
  final Color color;

  _PremiumShimmerPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.transparent,
          color.withValues(alpha: 0.1),
          color.withValues(alpha: 0.2),
          color.withValues(alpha: 0.1),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 0.5, 0.6, 1.0],
        transform: GradientRotation(progress * 2 * math.pi * 0.1),
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()
      ..moveTo(size.width * (progress - 0.5), 0)
      ..lineTo(size.width * progress, 0)
      ..lineTo(size.width * (progress + 0.5), size.height)
      ..lineTo(size.width * progress, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PremiumShimmerPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _SoccerPitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00FFD1).withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Outer boundary
    canvas.drawRect(Rect.fromLTWH(8, 8, size.width - 16, size.height - 16), paint);

    // Center line
    final double midX = size.width / 2;
    canvas.drawLine(Offset(midX, 8), Offset(midX, size.height - 8), paint);

    // Center circle
    canvas.drawCircle(Offset(midX, size.height / 2), size.height * 0.28, paint);
    canvas.drawCircle(Offset(midX, size.height / 2), 3, paint..style = PaintingStyle.fill);

    // Penalty areas
    final double areaHeight = size.height * 0.65;
    final double areaWidth = size.width * 0.15;
    final double areaY = (size.height - areaHeight) / 2;

    // Left area
    canvas.drawRect(Rect.fromLTWH(8, areaY, areaWidth, areaHeight), paint..style = PaintingStyle.stroke);
    // Right area
    canvas.drawRect(Rect.fromLTWH(size.width - 8 - areaWidth, areaY, areaWidth, areaHeight), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
