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

    final hasStarted = _timeLeft == Duration.zero;

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: theme.cardColor.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.12),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.06),
              blurRadius: 16,
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
            const SizedBox(width: 14),
            // Text + Countdown stacked for mejor legibilidad
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasStarted
                      ? 'MUNDIAL 2026 EN JUEGO'
                      : 'Cuenta regresiva Mundial 2026',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                if (hasStarted)
                  Row(
                    children: [
                      Icon(
                        Icons.sports_soccer_rounded,
                        size: 16,
                        color: primaryColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Partidos y resultados en tiempo real',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      _buildTimeUnit(context, days.toString(), 'DÍAS'),
                      _buildSeparator(context),
                      _buildTimeUnit(
                          context, hours.toString().padLeft(2, '0'), 'HS'),
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
          ],
        ),
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