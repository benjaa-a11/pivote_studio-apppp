import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  late AnimationController _glowController;

  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _blinkAnimation;
  late Animation<double> _glowAnimation;

  // Host cities rotation
  int _currentCityIndex = 0;
  late Timer _cityTimer;

  static const List<String> _hostCities = [
    'New York/New Jersey',
    'Los Angeles',
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

  // FIFA 2026 Official Colors
  static const Color _fifaDarkNavy = Color(0xFF0A1128);
  static const Color _fifaRoyalBlue = Color(0xFF1B3A8C);
  static const Color _fifaElectricBlue = Color(0xFF304FFE);
  static const Color _fifaTeal = Color(0xFF00BCD4);
  static const Color _fifaGold = Color(0xFFFFD700);

  @override
  void initState() {
    super.initState();
    _targetDate = DateTime(2026, 6, 11);
    _calculateTimeLeft();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _calculateTimeLeft());
      }
    });

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
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    // Blink animation for separators
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _blinkAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );

    // Glow animation
    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.15, end: 0.4).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // City rotation timer
    _cityTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
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
    if (_timeLeft.isNegative) {
      _timeLeft = Duration.zero;
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _cityTimer.cancel();
    _pulseController.dispose();
    _shimmerController.dispose();
    _blinkController.dispose();
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

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _fifaTeal.withValues(alpha: _glowAnimation.value * 0.5),
                blurRadius: 30,
                spreadRadius: -5,
              ),
              BoxShadow(
                color: _fifaElectricBlue.withValues(
                    alpha: _glowAnimation.value * 0.3),
                blurRadius: 40,
                spreadRadius: -8,
              ),
            ],
          ),
          child: child,
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AnimatedBuilder(
          animation: _shimmerAnimation,
          builder: (context, child) {
            return CustomPaint(
              foregroundPainter: _ShimmerPainter(
                shimmerPosition: _shimmerAnimation.value,
              ),
              child: child,
            );
          },
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _fifaDarkNavy,
                  Color(0xFF0F1E4A),
                  _fifaRoyalBlue,
                ],
                stops: [0.0, 0.5, 1.0],
              ),
              border: Border.all(
                color: _fifaTeal.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Stack(
              children: [
                // Background decorative elements
                _buildBackgroundDecorations(),

                // Main content
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top: Host country flags + Logo + Title
                      _buildHeader(hasStarted),
                      const SizedBox(height: 6),

                      // Slogan
                      _buildSlogan(),
                      const SizedBox(height: 20),

                      // Countdown or started state
                      if (hasStarted)
                        _buildTournamentStarted()
                      else
                        _buildCountdownSection(days, hours, minutes, seconds),

                      const SizedBox(height: 16),

                      // Host cities rotation
                      _buildHostCityTicker(),
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

  Widget _buildBackgroundDecorations() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            // Top right circular glow
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _fifaTeal.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Bottom left glow
            Positioned(
              bottom: -20,
              left: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _fifaElectricBlue.withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Subtle grid pattern
            Positioned.fill(
              child: CustomPaint(
                painter: _GridPatternPainter(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool hasStarted) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Host country indicators
        _buildFlagDot(const Color(0xFFFF0000)), // Canada
        const SizedBox(width: 6),
        _buildFlagDot(const Color(0xFF006847)), // Mexico
        const SizedBox(width: 6),
        _buildFlagDot(const Color(0xFF002868)), // USA
        const SizedBox(width: 14),

        // FIFA Logo
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.08),
            border: Border.all(
              color: _fifaGold.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Image.asset(
            'assets/FWC-26/2026-FIFA-World-Cup256x-white.png',
            height: 36,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 14),

        // Title
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasStarted ? '¡EN CURSO!' : 'CUENTA REGRESIVA',
                style: GoogleFonts.dmSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                  color: _fifaTeal.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'FIFA WORLD CUP 26™',
                  style: GoogleFonts.syne(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFlagDot(Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      ),
    );
  }

  Widget _buildSlogan() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _fifaGold.withValues(alpha: 0.2),
          width: 1,
        ),
        color: _fifaGold.withValues(alpha: 0.06),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.stars_rounded,
              size: 12, color: _fifaGold.withValues(alpha: 0.8)),
          const SizedBox(width: 6),
          Text(
            'WE ARE 26',
            style: GoogleFonts.syne(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.5,
              color: _fifaGold.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.stars_rounded,
              size: 12, color: _fifaGold.withValues(alpha: 0.8)),
        ],
      ),
    );
  }

  Widget _buildTournamentStarted() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _fifaTeal.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _fifaTeal.withValues(alpha: 0.2),
            ),
            child: const Icon(Icons.sports_soccer_rounded,
                color: _fifaTeal, size: 24),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¡El torneo ha comenzado!',
                style: GoogleFonts.syne(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Canadá · México · Estados Unidos',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownSection(int days, int hours, int minutes, int seconds) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive sizing
        double cardWidth = 64;
        double cardHeight = 72;
        double fontSize = 26;
        double labelSize = 8;
        double separatorGap = 8;

        if (constraints.maxWidth < 340) {
          cardWidth = 52;
          cardHeight = 60;
          fontSize = 20;
          labelSize = 7;
          separatorGap = 5;
        } else if (constraints.maxWidth < 300) {
          cardWidth = 44;
          cardHeight = 52;
          fontSize = 18;
          labelSize = 6;
          separatorGap = 4;
        }

        return FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTimeCard(days.toString(), 'DÍAS', cardWidth, cardHeight,
                  fontSize, labelSize),
              SizedBox(width: separatorGap),
              _buildBlinkingSeparator(cardHeight),
              SizedBox(width: separatorGap),
              _buildTimeCard(hours.toString().padLeft(2, '0'), 'HRS', cardWidth,
                  cardHeight, fontSize, labelSize),
              SizedBox(width: separatorGap),
              _buildBlinkingSeparator(cardHeight),
              SizedBox(width: separatorGap),
              _buildTimeCard(minutes.toString().padLeft(2, '0'), 'MIN',
                  cardWidth, cardHeight, fontSize, labelSize),
              SizedBox(width: separatorGap),
              _buildBlinkingSeparator(cardHeight),
              SizedBox(width: separatorGap),
              _buildTimeCard(seconds.toString().padLeft(2, '0'), 'SEG',
                  cardWidth, cardHeight, fontSize, labelSize),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimeCard(String value, String label, double width, double height,
      double fontSize, double labelSize) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.14),
                    Colors.white.withValues(alpha: 0.06),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _fifaElectricBlue.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Horizontal split line (flip card effect)
                  Center(
                    child: Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  // Number
                  Center(
                    child: ScaleTransition(
                      scale: _pulseAnimation,
                      child: Text(
                        value,
                        style: GoogleFonts.syne(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -1,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: labelSize,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: _fifaTeal.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildBlinkingSeparator(double height) {
    return FadeTransition(
      opacity: _blinkAnimation,
      child: SizedBox(
        height: height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: _fifaGold.withValues(alpha: 0.8),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _fifaGold.withValues(alpha: 0.4),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: _fifaGold.withValues(alpha: 0.8),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _fifaGold.withValues(alpha: 0.4),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHostCityTicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.location_on_outlined,
            size: 11, color: Colors.white.withValues(alpha: 0.35)),
        const SizedBox(width: 6),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: Text(
            _hostCities[_currentCityIndex],
            key: ValueKey<int>(_currentCityIndex),
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '• 16 SEDES',
          style: GoogleFonts.dmSans(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: Colors.white.withValues(alpha: 0.25),
          ),
        ),
      ],
    );
  }
}

/// Shimmer overlay painter
class _ShimmerPainter extends CustomPainter {
  final double shimmerPosition;

  _ShimmerPainter({required this.shimmerPosition});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.04),
          Colors.transparent,
        ],
        stops: [
          (shimmerPosition - 0.3).clamp(0.0, 1.0),
          shimmerPosition.clamp(0.0, 1.0),
          (shimmerPosition + 0.3).clamp(0.0, 1.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _ShimmerPainter oldDelegate) {
    return oldDelegate.shimmerPosition != shimmerPosition;
  }
}

/// Subtle grid pattern painter
class _GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.015)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const spacing = 30.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
