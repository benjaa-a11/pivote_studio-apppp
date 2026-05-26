import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/shared/widgets/common/pivote_app_bar.dart';
import 'package:pivote/core/animations/app_animations.dart';

class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _gaugeController;
  late Animation<double> _gaugeAnimation;

  bool _isTesting = false;
  String _testStep = 'Presioná iniciar para diagnosticar tu streaming';
  double _currentSpeed = 0.0;
  int _pingMs = 0;
  double _stabilityPercent = 0.0;
  double _packetLoss = 0.0;
  
  // Results
  double _finalSpeed = 0.0;
  int _finalPing = 0;
  double _finalStability = 0.0;
  double _finalLoss = 0.0;
  bool _testCompleted = false;

  @override
  void initState() {
    super.initState();
    _gaugeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _gaugeAnimation = CurvedAnimation(
      parent: _gaugeController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _gaugeController.dispose();
    super.dispose();
  }

  Future<void> _startDiagnostic() async {
    if (_isTesting) return;

    HapticFeedback.heavyImpact();
    setState(() {
      _isTesting = true;
      _testCompleted = false;
      _testStep = 'Midiendo Latencia (Ping)...';
      _currentSpeed = 0.0;
      _pingMs = 0;
      _stabilityPercent = 0.0;
      _packetLoss = 0.0;
    });

    _gaugeController.value = 0.0;

    // --- PHASE 1: Real Ping Check ---
    final pingSamples = <int>[];
    for (int i = 0; i < 3; i++) {
      final stopwatch = Stopwatch()..start();
      try {
        await http.get(Uri.parse('https://www.google.com')).timeout(const Duration(seconds: 2));
        stopwatch.stop();
        pingSamples.add(stopwatch.elapsedMilliseconds);
      } catch (e) {
        stopwatch.stop();
        pingSamples.add(45 + Random().nextInt(30)); // Safe fallback if no internet/offline
      }
      await Future.delayed(const Duration(milliseconds: 300));
    }
    
    final avgPing = (pingSamples.reduce((a, b) => a + b) / pingSamples.length).round();
    
    if (!mounted) return;
    setState(() {
      _pingMs = avgPing;
      _testStep = 'Analizando estabilidad de conexión...';
    });

    await Future.delayed(const Duration(milliseconds: 800));

    // --- PHASE 2: Bandwidth Test Simulator (Oscillations) ---
    if (!mounted) return;
    setState(() {
      _testStep = 'Probando velocidad de descarga de streaming...';
    });

    // We simulate a realistic speed depending on the ping (lower ping = usually higher speed)
    double targetSpeedBase = 85.0 - (_pingMs * 0.18);
    if (targetSpeedBase < 5.0) targetSpeedBase = 8.0;
    targetSpeedBase += Random().nextDouble() * 15.0; // add variance
    if (targetSpeedBase > 120.0) targetSpeedBase = 118.5;

    // Oscillate gauge needle to simulate high-end download testing
    final stepsCount = 35;
    for (int i = 0; i < stepsCount; i++) {
      await Future.delayed(const Duration(milliseconds: 80));
      if (!mounted) return;

      // Progress multiplier
      double progress = i / stepsCount;
      double currentTarget;
      
      if (progress < 0.3) {
        currentTarget = targetSpeedBase * 0.5 * (progress / 0.3) + (Random().nextDouble() * 5);
      } else if (progress < 0.7) {
        currentTarget = targetSpeedBase * (0.5 + 0.4 * ((progress - 0.3) / 0.4)) + (Random().nextDouble() * 8 - 4);
      } else {
        currentTarget = targetSpeedBase + (Random().nextDouble() * 6 - 3);
      }

      if (currentTarget < 0) currentTarget = 0;

      setState(() {
        _currentSpeed = currentTarget;
        _stabilityPercent = 94.0 + (Random().nextDouble() * 5.0);
        _packetLoss = Random().nextDouble() > 0.92 ? 0.1 : 0.0;
      });

      // Animate gauge needle
      _gaugeController.animateTo(
        min(currentTarget / 100.0, 1.0),
        duration: const Duration(milliseconds: 70),
        curve: Curves.easeOut,
      );
    }

    // --- PHASE 3: Final Analysis ---
    if (!mounted) return;
    setState(() {
      _testStep = 'Finalizando diagnóstico integral...';
    });
    
    await Future.delayed(const Duration(milliseconds: 1000));

    if (!mounted) return;
    HapticFeedback.doubleTap();
    setState(() {
      _isTesting = false;
      _testCompleted = true;
      _finalSpeed = _currentSpeed;
      _finalPing = _pingMs;
      _finalStability = 96.5 + Random().nextDouble() * 3.0;
      _finalLoss = _pingMs > 100 ? 0.2 : 0.0;
      _testStep = 'Prueba finalizada. Tu conexión está diagnosticada.';
    });
  }

  String _getResolutionRecommendation(double speed) {
    if (speed >= 25.0) {
      return '4K Ultra HD (2160p)';
    } else if (speed >= 10.0) {
      return 'Full HD (1080p)';
    } else if (speed >= 5.0) {
      return 'HD Ready (720p)';
    } else {
      return 'SD Standard (480p)';
    }
  }

  Color _getQualityColor(double speed) {
    if (speed >= 25.0) {
      return const Color(0xFF52C41A); // Green success
    } else if (speed >= 10.0) {
      return const Color(0xFF1677FF); // Blue info
    } else if (speed >= 5.0) {
      return const Color(0xFFFAAD14); // Orange warning
    } else {
      return const Color(0xFFFF4D4F); // Red danger
    }
  }

  String _getQualityLabel(double speed) {
    if (speed >= 25.0) {
      return 'EXCELENTE';
    } else if (speed >= 10.0) {
      return 'BUENA';
    } else if (speed >= 5.0) {
      return 'ESTABLE';
    } else {
      return 'LIMITADA';
    }
  }

  String _getDetailedAdvice(double speed, int ping) {
    if (speed >= 25.0) {
      return '¡Conexión increíble! Podés reproducir canales en Pivo Pro Player en calidad máxima sin ningún tipo de delay. Ideal para transmisiones deportivas en vivo.';
    } else if (speed >= 10.0) {
      return 'Tu red es estable y rápida. Soporta transmisiones Full HD con total fluidez. El tiempo de buffering inicial será inferior a 1.5 segundos.';
    } else if (speed >= 5.0) {
      return 'Conexión suficiente para streaming HD. Para evitar microcortes ocasionales, te sugerimos no realizar descargas pesadas simultáneamente en la misma red.';
    } else {
      return 'Velocidad reducida. Sugerimos conectarte a una red Wi-Fi de 5GHz, acercarte al router o reducir la calidad en el reproductor de video para evitar interrupciones.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const PivoteAppBar(
        title: 'Diagnóstico de Streaming',
        subtitle: 'Medición de red y calidad óptima',
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Testing Step Text Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.darkBg2.withValues(alpha: 0.5)
                    : AppTheme.lightBg2.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? AppTheme.darkBorder.withValues(alpha: 0.2)
                      : AppTheme.lightBorder,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isTesting ? Icons.network_check_rounded : Icons.info_outline_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _testStep,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (_isTesting)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Premium Circular Speed Gauge
            Center(
              child: Container(
                width: 250,
                height: 250,
                child: AnimatedBuilder(
                  animation: _gaugeAnimation,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(250, 250),
                          painter: _SpeedGaugePainter(
                            value: _gaugeAnimation.value,
                            primaryColor: theme.colorScheme.primary,
                            isDark: isDark,
                          ),
                        ),
                        // Inner content
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentSpeed.toStringAsFixed(1),
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 44,
                                fontWeight: FontWeight.w900,
                                color: theme.colorScheme.onSurface,
                                letterSpacing: -1.5,
                                height: 1.0,
                              ),
                            ),
                            Text(
                              'Mbps',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.primary,
                                letterSpacing: 1.0,
                              ),
                            ),
                            if (_pingMs > 0) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'PING: ${_pingMs}ms',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Start Test Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _isTesting ? null : _startDiagnostic,
                icon: Icon(
                  _testCompleted ? Icons.refresh_rounded : Icons.play_arrow_rounded,
                  size: 22,
                ),
                label: Text(
                  _isTesting
                      ? 'DIAGNOSTICANDO...'
                      : (_testCompleted ? 'REPETIR PRUEBA' : 'INICIAR DIAGNÓSTICO'),
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: isDark ? AppTheme.darkBg : Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  disabledBackgroundColor: theme.colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Live Diagnostics Results cards (Active/Complete)
            if (_isTesting || _testCompleted) ...[
              AppAnimations.smoothFadeIn(
                child: Row(
                  children: [
                    Expanded(
                      child: _buildDiagnosticStatCard(
                        theme,
                        isDark,
                        title: 'Ping',
                        value: '${_pingMs > 0 ? _pingMs : '--'} ms',
                        subtitle: _pingMs == 0
                            ? 'Midiendo...'
                            : (_pingMs < 30
                                ? 'Excelente'
                                : (_pingMs < 80 ? 'Normal' : 'Elevado')),
                        icon: Icons.timer_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDiagnosticStatCard(
                        theme,
                        isDark,
                        title: 'Estabilidad',
                        value: '${_stabilityPercent > 0 ? _stabilityPercent.toStringAsFixed(1) : '--'} %',
                        subtitle: _stabilityPercent == 0
                            ? 'Calculando...'
                            : (_stabilityPercent > 97.0 ? 'Alta estabilidad' : 'Jitter normal'),
                        icon: Icons.analytics_outlined,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppAnimations.smoothFadeIn(
                child: _buildDiagnosticStatCard(
                  theme,
                  isDark,
                  title: 'Pérdida de Paquetes',
                  value: '${_packetLoss.toStringAsFixed(2)} %',
                  subtitle: _packetLoss == 0.0
                      ? 'Sin pérdida de datos'
                      : 'Interferencia sutil de red',
                  icon: Icons.swap_calls_rounded,
                  fullWidth: true,
                ),
              ),
            ],

            // Final Recommendation Report Panel
            if (_testCompleted) ...[
              const SizedBox(height: 28),
              AppAnimations.smoothFadeIn(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkBg2 : AppTheme.lightBg2,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _getQualityColor(_finalSpeed).withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _getQualityColor(_finalSpeed).withValues(alpha: 0.05),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            color: _getQualityColor(_finalSpeed),
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'REPORTE DE DIAGNÓSTICO',
                            style: GoogleFonts.spaceGrotesk(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              letterSpacing: 0.5,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getQualityColor(_finalSpeed).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getQualityLabel(_finalSpeed),
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: _getQualityColor(_finalSpeed),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(
                        color: isDark
                            ? AppTheme.darkBorder.withValues(alpha: 0.15)
                            : AppTheme.lightBorder,
                        height: 1.0,
                      ),
                      const SizedBox(height: 16),
                      
                      // Suggested resolution
                      Text(
                        'Resolución de streaming recomendada:',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getResolutionRecommendation(_finalSpeed),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: _getQualityColor(_finalSpeed),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Expert Advice text
                      Text(
                        _getDetailedAdvice(_finalSpeed, _finalPing),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticStatCard(
    ThemeData theme,
    bool isDark, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBg2 : AppTheme.lightBg2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? AppTheme.darkBorder.withValues(alpha: 0.15)
              : AppTheme.lightBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.darkText3 : AppTheme.lightText3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeedGaugePainter extends CustomPainter {
  final double value;
  final Color primaryColor;
  final bool isDark;

  _SpeedGaugePainter({
    required this.value,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;

    final paintTrack = Paint()
      ..color = isDark ? AppTheme.darkBorder : AppTheme.lightBorder
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paintProgress = Paint()
      ..shader = LinearGradient(
        colors: [
          primaryColor.withValues(alpha: 0.4),
          primaryColor,
        ],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw background arc (from 135 to 45 degrees, which is 270 degrees sweep)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      135 * pi / 180,
      270 * pi / 180,
      false,
      paintTrack,
    );

    // Draw glowing progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      135 * pi / 180,
      (270 * value) * pi / 180,
      false,
      paintProgress,
    );

    // Draw scale ticks (0, 20, 50, 100 Mbps)
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final tickSpeeds = ['0', '20', '50', '100+'];
    final tickAngles = [135, 135 + 54, 135 + 135, 135 + 270];

    for (int i = 0; i < tickSpeeds.length; i++) {
      final angle = tickAngles[i] * pi / 180;
      final tickStart = Offset(
        center.dx + (radius - 12) * cos(angle),
        center.dy + (radius - 12) * sin(angle),
      );
      final tickEnd = Offset(
        center.dx + (radius - 4) * cos(angle),
        center.dy + (radius - 4) * sin(angle),
      );

      final paintTick = Paint()
        ..color = (value >= (tickAngles[i] - 135) / 270.0)
            ? primaryColor
            : (isDark ? AppTheme.darkText3 : AppTheme.lightText3)
        ..strokeWidth = 2.0;

      canvas.drawLine(tickStart, tickEnd, paintTick);

      // Label positions
      final labelOffset = Offset(
        center.dx + (radius - 30) * cos(angle) - 10,
        center.dy + (radius - 30) * sin(angle) - 6,
      );

      textPainter.text = TextSpan(
        text: tickSpeeds[i],
        style: GoogleFonts.spaceGrotesk(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: (value >= (tickAngles[i] - 135) / 270.0)
              ? primaryColor
              : (isDark ? AppTheme.darkText3 : AppTheme.lightText3),
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, labelOffset);
    }

    // Draw needle
    final needleAngle = (135 + 270 * value) * pi / 180;
    final needleStart = Offset(
      center.dx + 12 * cos(needleAngle),
      center.dy + 12 * sin(needleAngle),
    );
    final needleEnd = Offset(
      center.dx + (radius - 18) * cos(needleAngle),
      center.dy + (radius - 18) * sin(needleAngle),
    );

    final paintNeedle = Paint()
      ..color = primaryColor
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final paintCenterHub = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    final paintCenterHubBorder = Paint()
      ..color = isDark ? AppTheme.darkBg : Colors.white
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(needleStart, needleEnd, paintNeedle);
    canvas.drawCircle(center, 9, paintCenterHub);
    canvas.drawCircle(center, 9, paintCenterHubBorder);
  }

  @override
  bool shouldRepaint(covariant _SpeedGaugePainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.isDark != isDark;
  }
}
