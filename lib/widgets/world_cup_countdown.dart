import 'dart:async';
import 'package:flutter/material.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    final days = _timeLeft.inDays;
    final hours = _timeLeft.inHours % 24;
    final minutes = _timeLeft.inMinutes % 60;
    final seconds = _timeLeft.inSeconds % 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // FIFA 2026 Logo with subtle glow
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withValues(alpha: 0.05),
                ),
              ),
              Image.asset(
                isDark
                    ? 'assets/FWC-26/2026-FIFA-World-Cup256x-white.png'
                    : 'assets/FWC-26/2026-FIFA-World-Cup256x-black.png',
                height: 38,
                fit: BoxFit.contain,
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Vertical Divider
          Container(
            width: 1.5,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  primaryColor.withValues(alpha: 0.0),
                  primaryColor.withValues(alpha: 0.3),
                  primaryColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Countdown UI
          Row(
            children: [
              _buildTimeUnit(context, days.toString(), 'DÍAS'),
              _buildSeparator(context),
              _buildTimeUnit(context, hours.toString().padLeft(2, '0'), 'HS'),
              _buildSeparator(context),
              _buildTimeUnit(
                  context, minutes.toString().padLeft(2, '0'), 'MIN'),
              _buildSeparator(context),
              _buildTimeUnit(
                  context, seconds.toString().padLeft(2, '0'), 'SEG'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeUnit(BuildContext context, String value, String label) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ScaleTransition(
          scale: _pulseAnimation,
          child: Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: primaryColor,
              letterSpacing: -0.5,
            ),
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 8,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildSeparator(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        ':',
        style: theme.textTheme.titleMedium?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
