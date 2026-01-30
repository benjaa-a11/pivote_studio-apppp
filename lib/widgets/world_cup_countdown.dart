import 'dart:async';
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

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;

    final days = _timeLeft.inDays;
    final hours = _timeLeft.inHours % 24;
    final minutes = _timeLeft.inMinutes % 60;
    final seconds = _timeLeft.inSeconds % 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // FIFA 2026 Logo
          Image.asset(
            isDark
                ? 'assets/FWC-26/2026-FIFA-World-Cup256x-white.png'
                : 'assets/FWC-26/2026-FIFA-World-Cup256x-black.png',
            height: 42,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 12),
          // Vertical Divider
          Container(
            width: 1,
            height: 30,
            color: accentColor.withValues(alpha: 0.2),
          ),
          const SizedBox(width: 12),
          // Countdown UI
          Row(
            children: [
              _buildTimeUnit(days.toString(), 'DÍAS', accentColor),
              _buildSeparator(accentColor),
              _buildTimeUnit(
                  hours.toString().padLeft(2, '0'), 'HS', accentColor),
              _buildSeparator(accentColor),
              _buildTimeUnit(
                  minutes.toString().padLeft(2, '0'), 'MIN', accentColor),
              _buildSeparator(accentColor),
              _buildTimeUnit(
                  seconds.toString().padLeft(2, '0'), 'SEG', accentColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeUnit(String value, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ScaleTransition(
          scale: _pulseAnimation,
          child: Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 7,
            fontWeight: FontWeight.w800,
            color: Colors.grey.withValues(alpha: 0.6),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSeparator(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        ':',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: color.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
