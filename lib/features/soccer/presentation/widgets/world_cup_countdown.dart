import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Premium World Cup 2026 Countdown Banner.
///
/// Full-width gradient banner with card-style time tiles, FIFA logo,
/// smooth entry animation, and responsive layout.
class WorldCupCountdown extends StatefulWidget {
  const WorldCupCountdown({super.key});

  @override
  State<WorldCupCountdown> createState() => _WorldCupCountdownState();
}

class _WorldCupCountdownState extends State<WorldCupCountdown>
    with TickerProviderStateMixin {
  late Timer _timer;
  late final DateTime _targetDate;
  Duration _timeLeft = Duration.zero;

  late final AnimationController _entryCtrl;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  // Subtle second-tick animation
  late final AnimationController _tickCtrl;
  late final Animation<double> _tickFade;

  @override
  void initState() {
    super.initState();
    _targetDate = DateTime(2026, 6, 11); // FIFA World Cup 2026 kickoff
    _calculateTimeLeft();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _calculateTimeLeft());
    });

    // Entry animation
    _entryCtrl = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeIn = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _entryCtrl.forward();

    // Seconds tick pulse
    _tickCtrl = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    _tickFade = Tween<double>(begin: 1.0, end: 0.5).animate(
      CurvedAnimation(parent: _tickCtrl, curve: Curves.easeInOut),
    );
  }

  void _calculateTimeLeft() {
    final now = DateTime.now();
    _timeLeft = _targetDate.difference(now);
    if (_timeLeft.isNegative) _timeLeft = Duration.zero;
  }

  @override
  void dispose() {
    _timer.cancel();
    _entryCtrl.dispose();
    _tickCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    final days = _timeLeft.inDays;
    final hours = _timeLeft.inHours % 24;
    final minutes = _timeLeft.inMinutes % 60;
    final seconds = _timeLeft.inSeconds % 60;
    final hasStarted = _timeLeft == Duration.zero;

    return SlideTransition(
      position: _slideUp,
      child: FadeTransition(
        opacity: _fadeIn,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF0D1117),
                      Color.lerp(const Color(0xFF0D1117), primary, 0.08)!,
                      const Color(0xFF0D1117),
                    ]
                  : [
                      const Color(0xFFF8FAFC),
                      Color.lerp(const Color(0xFFF8FAFC), primary, 0.06)!,
                      const Color(0xFFF8FAFC),
                    ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: primary.withValues(alpha: isDark ? 0.15 : 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header: Logo + Title ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    isDark
                        ? 'assets/FWC-26/2026-FIFA-World-Cup256x-white.png'
                        : 'assets/FWC-26/2026-FIFA-World-Cup256x-black.png',
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasStarted
                            ? '¡EL MUNDIAL COMENZÓ!'
                            : 'COPA DEL MUNDO 2026',
                        style: GoogleFonts.syne(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasStarted
                            ? 'Seguí los partidos en vivo'
                            : 'Cuenta regresiva',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              if (!hasStarted) ...[
                const SizedBox(height: 20),

                // ── Time Tiles Row ──
                Row(
                  children: [
                    _TimeTile(
                      value: days.toString(),
                      label: 'DÍAS',
                      primary: primary,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _TimeTile(
                      value: hours.toString().padLeft(2, '0'),
                      label: 'HS',
                      primary: primary,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _TimeTile(
                      value: minutes.toString().padLeft(2, '0'),
                      label: 'MIN',
                      primary: primary,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    AnimatedBuilder(
                      animation: _tickFade,
                      builder: (context, child) => Opacity(
                        opacity: _tickFade.value,
                        child: child,
                      ),
                      child: _TimeTile(
                        value: seconds.toString().padLeft(2, '0'),
                        label: 'SEG',
                        primary: primary,
                        isDark: isDark,
                        isSeconds: true,
                      ),
                    ),
                  ],
                ),
              ],

              if (hasStarted) ...[
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sports_soccer_rounded,
                          size: 18, color: primary),
                      const SizedBox(width: 8),
                      Text(
                        'Partidos y resultados en tiempo real',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Individual countdown time tile with premium card styling.
class _TimeTile extends StatelessWidget {
  final String value;
  final String label;
  final Color primary;
  final bool isDark;
  final bool isSeconds;

  const _TimeTile({
    required this.value,
    required this.label,
    required this.primary,
    required this.isDark,
    this.isSeconds = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSeconds
                ? primary.withValues(alpha: 0.2)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.05)),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.syne(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: isSeconds ? primary : primary,
                height: 1.0,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.4),
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
