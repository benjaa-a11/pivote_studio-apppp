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
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  late DateTime _targetDate;
  Duration _timeLeft = Duration.zero;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    // World Cup 2026 starts June 11, 2026
    _targetDate = DateTime(2026, 6, 11);
    _calculateTimeLeft();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _calculateTimeLeft();
        });
      }
    });

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
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
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = _timeLeft.inDays;
    final hours = _timeLeft.inHours % 24;
    final minutes = _timeLeft.inMinutes % 60;
    final seconds = _timeLeft.inSeconds % 60;

    final hasStarted = _timeLeft == Duration.zero;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0EA5E9).withValues(alpha: 0.15),
                Colors.white.withValues(alpha: 0.05),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                blurRadius: 32,
                spreadRadius: -10,
              ),
            ],
          ),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo & Title
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
                child: Image.asset(
                  'assets/FWC-26/2026-FIFA-World-Cup256x-white.png',
                  height: 48,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasStarted ? 'MUNDIAL 2026' : 'CUENTA REGRESIVA',
                    style: GoogleFonts.syne(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.0,
                      color: const Color(0xFF0EA5E9),
                    ),
                  ),
                  Text(
                    'FIFA WORLD CUP™',
                    style: GoogleFonts.syne(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),
          // Countdown
          if (hasStarted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sports_soccer_rounded,
                      color: Color(0xFF0EA5E9), size: 22),
                  const SizedBox(width: 10),
                  Text(
                    '¡El torneo ha comenzado!',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                // Adjust sizing based on available width
                double boxSize = 64;
                double fontSize = 24;
                if (constraints.maxWidth < 320) {
                  boxSize = 54;
                  fontSize = 20;
                }
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildModernTimeUnit(days.toString(), 'DÍAS', boxSize, fontSize),
                    _buildModernSeparator(boxSize),
                    _buildModernTimeUnit(
                        hours.toString().padLeft(2, '0'), 'HS', boxSize, fontSize),
                    _buildModernSeparator(boxSize),
                    _buildModernTimeUnit(
                        minutes.toString().padLeft(2, '0'), 'MIN', boxSize, fontSize),
                    _buildModernSeparator(boxSize),
                    _buildModernTimeUnit(
                        seconds.toString().padLeft(2, '0'), 'SEG', boxSize, fontSize),
                  ],
                );
              },
            ),
        ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernTimeUnit(
      String value, String label, double boxSize, double fontSize) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: boxSize,
          height: boxSize + 10,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0EA5E9).withValues(alpha: 0.15),
                blurRadius: 15,
                spreadRadius: -5,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _pulseAnimation,
                child: Text(
                  value,
                  style: GoogleFonts.syne(
                    fontSize: fontSize + 2,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: const Color(0xFF0EA5E9).withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildModernSeparator(double boxSize) {
    return Container(
      height: boxSize + 30,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Center(
        child: Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFF0EA5E9).withValues(alpha: 0.4),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}