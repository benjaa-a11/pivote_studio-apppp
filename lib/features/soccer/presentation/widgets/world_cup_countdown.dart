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
  late AnimationController _floatController;
  late AnimationController _entryController;

  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _blinkAnimation;
  late Animation<double> _floatAnimation;
  late Animation<double> _entryAnimation;

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

  // FWC-26 Official Brand Colors (extracted from background image)
  static const Color _fwcOrange = Color(0xFFE83600);
  static const Color _fwcCyan = Color(0xFF3DFFC8);
  static const Color _fwcPurple = Color(0xFF6B00CC);
  static const Color _fwcLime = Color(0xFFC8FF00);
  static const Color _fwcWhite = Color(0xFFFFFFFF);

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
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _entryAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    );
    _entryController.forward();

    // Pulse animation for countdown numbers
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Shimmer animation
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
    _shimmerAnimation = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    // Blink animation for separators
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat(reverse: true);
    _blinkAnimation = Tween<double>(begin: 0.15, end: 1.0).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );

    // Float animation for logo
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -3.0, end: 3.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
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
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(_entryAnimation),
        child: _buildCard(days, hours, minutes, seconds, hasStarted),
      ),
    );
  }

  Widget _buildCard(
      int days, int hours, int minutes, int seconds, bool hasStarted) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Stack(
        children: [
          // === BACKGROUND IMAGE ===
          Positioned.fill(
            child: Image.asset(
              'assets/FWC-26/fwc-26-background.png',
              fit: BoxFit.cover,
            ),
          ),

          // === DARK OVERLAY for readability ===
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xCC000000), // 80% black top-left
                    Color(0xBB000000), // 73% mid
                    Color(0x99000000), // 60% bottom-right
                  ],
                ),
              ),
            ),
          ),

          // === SHIMMER OVERLAY ===
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _shimmerAnimation,
              builder: (context, _) {
                return CustomPaint(
                  painter: _ShimmerPainter(
                    shimmerPosition: _shimmerAnimation.value,
                    color: _fwcCyan,
                  ),
                );
              },
            ),
          ),

          // === ACCENT BORDER ===
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: _fwcCyan.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),

          // === MAIN CONTENT ===
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(hasStarted),
                const SizedBox(height: 6),
                _buildTagline(),
                const SizedBox(height: 12),
                if (hasStarted)
                  _buildTournamentStarted()
                else
                  _buildCountdownSection(days, hours, minutes, seconds),
                const SizedBox(height: 12),
                _buildHostCityTicker(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool hasStarted) {
    return Row(
      children: [
        // FIFA Logo with float animation
        AnimatedBuilder(
          animation: _floatAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _floatAnimation.value),
              child: child,
            );
          },
          child: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.4),
              border: Border.all(
                color: _fwcCyan.withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _fwcCyan.withValues(alpha: 0.25),
                  blurRadius: 16,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Image.asset(
              'assets/FWC-26/2026-FIFA-World-Cup256x-white.png',
              height: 30,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Title block
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _fwcCyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _fwcCyan.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Text(
                  hasStarted ? '🏆 EN CURSO' : '⏱ CUENTA REGRESIVA',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.8,
                    color: _fwcCyan,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'FIFA WORLD CUP 26™',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: _fwcWhite,
                    letterSpacing: 0.2,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Host flags column
        Column(
          children: [
            _buildFlagPill('🇺🇸', 'USA'),
            const SizedBox(height: 4),
            _buildFlagPill('🇲🇽', 'MEX'),
            const SizedBox(height: 4),
            _buildFlagPill('🇨🇦', 'CAN'),
          ],
        ),
      ],
    );
  }

  Widget _buildFlagPill(String flag, String code) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _fwcWhite.withValues(alpha: 0.1),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(flag, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 3),
          Text(
            code,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: _fwcWhite.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagline() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.black.withValues(alpha: 0.35),
            border: Border.all(
              color: _fwcLime.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Text(
            'WE ARE 26 • 48 SELECCIONES',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
              color: _fwcLime,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorDot(Color color) {
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.6),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildTournamentStarted() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _fwcCyan.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: _fwcCyan.withValues(alpha: 0.15),
            blurRadius: 20,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _fwcOrange.withValues(alpha: 0.2),
              border: Border.all(color: _fwcOrange.withValues(alpha: 0.4)),
            ),
            child: const Icon(Icons.sports_soccer_rounded,
                color: _fwcOrange, size: 24),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¡El torneo ha comenzado!',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _fwcWhite,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Canadá · México · Estados Unidos',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _fwcWhite.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownSection(
      int days, int hours, int minutes, int seconds) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double cardWidth = 56;
        double cardHeight = 60;
        double fontSize = 22;
        double labelSize = 8;
        double separatorGap = 6;

        if (constraints.maxWidth < 340) {
          cardWidth = 50;
          cardHeight = 56;
          fontSize = 18;
          labelSize = 7;
          separatorGap = 4;
        } else if (constraints.maxWidth < 300) {
          cardWidth = 42;
          cardHeight = 48;
          fontSize = 16;
          labelSize = 6;
          separatorGap = 3;
        }

        return FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTimeCard(
                  days.toString(), 'DÍAS', cardWidth, cardHeight, fontSize,
                  labelSize, _fwcCyan),
              SizedBox(width: separatorGap),
              _buildBlinkingSeparator(cardHeight),
              SizedBox(width: separatorGap),
              _buildTimeCard(
                  hours.toString().padLeft(2, '0'), 'HRS', cardWidth,
                  cardHeight, fontSize, labelSize, _fwcOrange),
              SizedBox(width: separatorGap),
              _buildBlinkingSeparator(cardHeight),
              SizedBox(width: separatorGap),
              _buildTimeCard(
                  minutes.toString().padLeft(2, '0'), 'MIN', cardWidth,
                  cardHeight, fontSize, labelSize, _fwcLime),
              SizedBox(width: separatorGap),
              _buildBlinkingSeparator(cardHeight),
              SizedBox(width: separatorGap),
              _buildTimeCard(
                  seconds.toString().padLeft(2, '0'), 'SEG', cardWidth,
                  cardHeight, fontSize, labelSize, _fwcPurple),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimeCard(String value, String label, double width, double height,
      double fontSize, double labelSize, Color accentColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.55),
                    Colors.black.withValues(alpha: 0.40),
                  ],
                ),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.35),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.2),
                    blurRadius: 16,
                    spreadRadius: -2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Subtle top shine
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: height * 0.4,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.06),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Bottom accent line
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 2.5,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(16)),
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            accentColor.withValues(alpha: 0.6),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Number
                  Center(
                    child: ScaleTransition(
                      scale: _pulseAnimation,
                      child: Text(
                        value,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w900,
                          color: _fwcWhite,
                          letterSpacing: -1.5,
                          height: 1.0,
                          shadows: [
                            Shadow(
                              color: accentColor.withValues(alpha: 0.5),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: labelSize,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.8,
            color: accentColor.withValues(alpha: 0.9),
            shadows: [
              Shadow(
                color: accentColor.withValues(alpha: 0.4),
                blurRadius: 6,
              ),
            ],
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
            _buildSepDot(),
            const SizedBox(height: 7),
            _buildSepDot(),
          ],
        ),
      ),
    );
  }

  Widget _buildSepDot() {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        color: _fwcWhite.withValues(alpha: 0.7),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _fwcWhite.withValues(alpha: 0.3),
            blurRadius: 5,
          ),
        ],
      ),
    );
  }

  Widget _buildHostCityTicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _fwcWhite.withValues(alpha: 0.08),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on_rounded,
              size: 11, color: _fwcOrange.withValues(alpha: 0.8)),
          const SizedBox(width: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.5),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Text(
              _hostCities[_currentCityIndex],
              key: ValueKey<int>(_currentCityIndex),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: _fwcWhite.withValues(alpha: 0.8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 1,
            height: 10,
            color: _fwcWhite.withValues(alpha: 0.15),
          ),
          const SizedBox(width: 8),
          Text(
            '16 SEDES',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: _fwcCyan.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer overlay painter
class _ShimmerPainter extends CustomPainter {
  final double shimmerPosition;
  final Color color;

  _ShimmerPainter({required this.shimmerPosition, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.transparent,
          color.withValues(alpha: 0.05),
          Colors.transparent,
        ],
        stops: [
          (shimmerPosition - 0.4).clamp(0.0, 1.0),
          shimmerPosition.clamp(0.0, 1.0),
          (shimmerPosition + 0.4).clamp(0.0, 1.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _ShimmerPainter oldDelegate) {
    return oldDelegate.shimmerPosition != shimmerPosition;
  }
}
