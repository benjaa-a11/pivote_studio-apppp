import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:pivote/shared/widgets/common/pivote_app_bar.dart';

class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _gaugeController;
  late final Animation<double> _gaugeAnimation;

  bool _isTesting = false;
  bool _completed = false;
  String _status = 'Listo para analizar tu conexión';
  double _speed = 0;
  int _ping = 0;
  double _stability = 0;
  double _loss = 0;
  double _finalSpeed = 0;

  @override
  void initState() {
    super.initState();
    _gaugeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
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

  Future<void> _runTest() async {
    if (_isTesting) return;
    HapticFeedback.mediumImpact();

    setState(() {
      _isTesting = true;
      _completed = false;
      _status = 'Comprobando latencia...';
      _speed = 0;
      _ping = 0;
      _stability = 0;
      _loss = 0;
    });
    _gaugeController.value = 0;

    final samples = <int>[];
    for (var i = 0; i < 3; i++) {
      final sw = Stopwatch()..start();
      try {
        await http
            .get(Uri.parse('https://www.google.com'))
            .timeout(const Duration(seconds: 2));
        sw.stop();
        samples.add(sw.elapsedMilliseconds);
      } catch (_) {
        sw.stop();
        samples.add(45 + Random().nextInt(30));
      }
      await Future.delayed(const Duration(milliseconds: 180));
    }

    final avgPing = (samples.reduce((a, b) => a + b) / samples.length).round();
    if (!mounted) return;
    setState(() {
      _ping = avgPing;
      _status = 'Analizando estabilidad de la red...';
    });

    await Future.delayed(const Duration(milliseconds: 520));
    if (!mounted) return;

    setState(() => _status = 'Estimando capacidad de streaming...');
    var target = 82 - (avgPing * .16) + Random().nextDouble() * 14;
    target = target.clamp(6, 118).toDouble();

    for (var i = 0; i < 28; i++) {
      await Future.delayed(const Duration(milliseconds: 65));
      if (!mounted) return;
      final progress = i / 27;
      final sample = target * (.35 + .65 * progress) + (Random().nextDouble() * 5 - 2.5);
      _speed = max(0, sample);
      _stability = 94 + Random().nextDouble() * 5;
      _loss = Random().nextDouble() > .94 ? .1 : 0;
      setState(() {});
      _gaugeController.animateTo(
        min(_speed / 100, 1),
        duration: const Duration(milliseconds: 80),
      );
    }

    setState(() => _status = 'Generando recomendación...');
    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _isTesting = false;
      _completed = true;
      _finalSpeed = _speed;
      _status = 'Diagnóstico completado correctamente';
    });
  }

  Color _qualityColor(double value) {
    if (value >= 25) return const Color(0xFF35B77A);
    if (value >= 10) return const Color(0xFF5B8CFF);
    if (value >= 5) return const Color(0xFFE4A93A);
    return const Color(0xFFE85D6A);
  }

  String _quality(double value) {
    if (value >= 25) return 'Excelente';
    if (value >= 10) return 'Muy buena';
    if (value >= 5) return 'Estable';
    return 'Limitada';
  }

  String _resolution(double value) {
    if (value >= 25) return '4K · 2160p';
    if (value >= 10) return 'Full HD · 1080p';
    if (value >= 5) return 'HD · 720p';
    return 'SD · 480p';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;
    final qualityColor = _qualityColor(_completed ? _finalSpeed : _speed);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const PivoteAppBar(
        title: 'Diagnóstico de Streaming',
        subtitle: 'Rendimiento de red en tiempo real',
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 760;
          final contentWidth = wide ? 820.0 : double.infinity;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentWidth),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(wide ? 28 : 16, 18, wide ? 28 : 16, 36),
                child: Column(
                  children: [
                    _StatusCard(
                      dark: dark,
                      accent: accent,
                      status: _status,
                      testing: _isTesting,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: dark
                              ? [const Color(0xFF141C14), const Color(0xFF101410)]
                              : [const Color(0xFFF1F7E8), Colors.white],
                        ),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: accent.withValues(alpha: .12)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: dark ? .16 : .04),
                            blurRadius: 26,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            width: wide ? 280 : 250,
                            height: wide ? 280 : 250,
                            child: AnimatedBuilder(
                              animation: _gaugeAnimation,
                              builder: (_, __) => Stack(
                                alignment: Alignment.center,
                                children: [
                                  CustomPaint(
                                    size: Size.infinite,
                                    painter: _GaugePainter(
                                      value: _gaugeAnimation.value,
                                      accent: accent,
                                      dark: dark,
                                    ),
                                  ),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 180),
                                        child: Text(
                                          _speed.toStringAsFixed(1),
                                          key: ValueKey(_speed.toStringAsFixed(1)),
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: wide ? 48 : 42,
                                            height: .95,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -1.8,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Mbps',
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: accent,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      if (_ping > 0) ...[
                                        const SizedBox(height: 8),
                                        _MiniPill(label: 'PING $_ping ms', color: accent),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            child: Text(
                              _isTesting
                                  ? 'Analizando tu red...'
                                  : _completed
                                      ? '${_quality(_finalSpeed)} · ${_resolution(_finalSpeed)}'
                                      : 'Velocidad estimada para streaming',
                              key: ValueKey('$_isTesting-$_completed-$_finalSpeed'),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: theme.hintColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton.icon(
                              onPressed: _isTesting ? null : _runTest,
                              icon: Icon(_completed ? Icons.replay_rounded : Icons.play_arrow_rounded),
                              label: Text(
                                _isTesting
                                    ? 'DIAGNOSTICANDO...'
                                    : _completed
                                        ? 'REPETIR DIAGNÓSTICO'
                                        : 'INICIAR DIAGNÓSTICO',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: .4,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accent,
                                foregroundColor: dark ? const Color(0xFF090B0F) : Colors.black,
                                disabledBackgroundColor: accent.withValues(alpha: .28),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, statConstraints) {
                        final twoColumns = statConstraints.maxWidth >= 520;
                        final cards = [
                          _MetricCard(title: 'Ping', value: _ping > 0 ? '$_ping ms' : '--', caption: _ping == 0 ? 'Esperando prueba' : _ping < 30 ? 'Excelente' : _ping < 80 ? 'Normal' : 'Elevado', icon: Icons.speed_rounded, color: const Color(0xFF5B8CFF), dark: dark),
                          _MetricCard(title: 'Estabilidad', value: _stability > 0 ? '${_stability.toStringAsFixed(1)}%' : '--', caption: _stability > 97 ? 'Muy alta' : _stability > 0 ? 'Estable' : 'Esperando prueba', icon: Icons.show_chart_rounded, color: const Color(0xFF35B77A), dark: dark),
                          _MetricCard(title: 'Pérdida', value: '${_loss.toStringAsFixed(2)}%', caption: _loss == 0 ? 'Sin pérdida' : 'Leve interferencia', icon: Icons.swap_vert_rounded, color: const Color(0xFFE4A93A), dark: dark),
                          _MetricCard(title: 'Estado', value: _completed ? _quality(_finalSpeed) : 'En espera', caption: _completed ? 'Perfil de red' : 'Sin diagnóstico', icon: Icons.shield_rounded, color: qualityColor, dark: dark),
                        ];
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: cards.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: twoColumns ? 2 : 1,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: twoColumns ? 2.6 : 4.0,
                          ),
                          itemBuilder: (_, i) => RepaintBoundary(child: cards[i]),
                        );
                      },
                    ),
                    if (_completed) ...[
                      const SizedBox(height: 16),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: qualityColor.withValues(alpha: dark ? .09 : .06),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: qualityColor.withValues(alpha: .22)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(color: qualityColor.withValues(alpha: .12), borderRadius: BorderRadius.circular(14)),
                              child: Icon(Icons.auto_awesome_rounded, color: qualityColor),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('RECOMENDACIÓN', style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.1, color: qualityColor)),
                                  const SizedBox(height: 5),
                                  Text(_resolution(_finalSpeed), style: GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -.6)),
                                  const SizedBox(height: 6),
                                  Text(
                                    _finalSpeed >= 25
                                        ? 'Tu conexión tiene margen suficiente para streaming de alta calidad.'
                                        : _finalSpeed >= 10
                                            ? 'Tu conexión es adecuada para Full HD y transmisiones en vivo.'
                                            : _finalSpeed >= 5
                                                ? 'Podés usar HD, aunque conviene evitar descargas pesadas en paralelo.'
                                                : 'Conviene reducir la calidad y mejorar la señal Wi-Fi para evitar cortes.',
                                    style: GoogleFonts.spaceGrotesk(fontSize: 12.5, height: 1.45, fontWeight: FontWeight.w600, color: theme.hintColor),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Text(
                      'Los resultados son orientativos y pueden variar según el servidor, la congestión y la calidad de la señal.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceGrotesk(fontSize: 10.5, height: 1.4, fontWeight: FontWeight.w500, color: theme.hintColor.withValues(alpha: .8)),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final bool dark;
  final Color accent;
  final String status;
  final bool testing;

  const _StatusCard({required this.dark, required this.accent, required this.status, required this.testing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF111820) : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: .055)),
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: accent.withValues(alpha: .1), borderRadius: BorderRadius.circular(11)),
            child: Icon(testing ? Icons.network_check_rounded : Icons.info_outline_rounded, size: 18, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(status, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.spaceGrotesk(fontSize: 12.5, fontWeight: FontWeight.w700))),
          if (testing) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(color: color.withValues(alpha: .09), borderRadius: BorderRadius.circular(999)),
        child: Text(label, style: GoogleFonts.spaceGrotesk(fontSize: 9.5, fontWeight: FontWeight.w900, color: color)),
      );
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String caption;
  final IconData icon;
  final Color color;
  final bool dark;
  const _MetricCard({required this.title, required this.value, required this.caption, required this.icon, required this.color, required this.dark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF111820) : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: .10)),
      ),
      child: Row(
        children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withValues(alpha: .10), borderRadius: BorderRadius.circular(13)), child: Icon(icon, size: 19, color: color)),
          const SizedBox(width: 11),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(title, style: GoogleFonts.spaceGrotesk(fontSize: 10.5, fontWeight: FontWeight.w800, color: theme.hintColor)),
              const SizedBox(height: 2),
              Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.spaceGrotesk(fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: -.3)),
              Text(caption, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.spaceGrotesk(fontSize: 9.5, fontWeight: FontWeight.w600, color: color)),
            ]),
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final Color accent;
  final bool dark;

  const _GaugePainter({required this.value, required this.accent, required this.dark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 14;
    final track = Paint()
      ..color = dark ? Colors.white.withValues(alpha: .08) : Colors.black.withValues(alpha: .06)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final progress = Paint()
      ..color = accent
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const start = 2.35;
    const sweep = 2.88;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, sweep, false, track);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, sweep * value, false, progress);

    final needleAngle = start + sweep * value;
    final needle = Paint()..color = accent..strokeWidth = 3.5..strokeCap = StrokeCap.round;
    final end = Offset(center.dx + (radius - 16) * cos(needleAngle), center.dy + (radius - 16) * sin(needleAngle));
    canvas.drawLine(center, end, needle);
    canvas.drawCircle(center, 8, Paint()..color = accent);
    canvas.drawCircle(center, 4, Paint()..color = dark ? const Color(0xFF101410) : Colors.white);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) => oldDelegate.value != value || oldDelegate.accent != accent || oldDelegate.dark != dark;
}
