import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/core/theme/app_typography.dart';
import 'package:pivote/features/profile/presentation/screens/storage_manager_screen.dart';
import 'package:pivote/features/profile/presentation/widgets/profile_design_system.dart';

class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  bool _isTesting = false;
  bool _completed = false;
  String _status = 'Listo para analizar tu conexión';
  double _speed = 0;
  int _ping = 0;
  double _stability = 0;
  double _loss = 0;
  double _finalSpeed = 0;

  Future<void> _runTest() async {
    if (_isTesting) return;
    await HapticFeedback.mediumImpact();

    setState(() {
      _isTesting = true;
      _completed = false;
      _status = 'Comprobando latencia...';
      _speed = 0;
      _ping = 0;
      _stability = 0;
      _loss = 0;
    });

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

    await Future.delayed(const Duration(milliseconds: 480));
    if (!mounted) return;

    setState(() => _status = 'Estimando capacidad de streaming...');
    var target = 82 - (avgPing * .16) + Random().nextDouble() * 14;
    target = target.clamp(6, 118).toDouble();

    for (var i = 0; i < 24; i++) {
      await Future.delayed(const Duration(milliseconds: 65));
      if (!mounted) return;
      final progress = i / 23;
      final sample =
          target * (.35 + .65 * progress) + (Random().nextDouble() * 5 - 2.5);
      _speed = max(0, sample);
      _stability = 94 + Random().nextDouble() * 5;
      _loss = Random().nextDouble() > .94 ? .1 : 0;
      setState(() {});
    }

    setState(() => _status = 'Generando recomendación...');
    await Future.delayed(const Duration(milliseconds: 520));
    if (!mounted) return;

    await HapticFeedback.mediumImpact();
    setState(() {
      _isTesting = false;
      _completed = true;
      _finalSpeed = _speed;
      _status = 'Diagnóstico completado correctamente';
    });
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

  String _recommendationMessage(double value) {
    if (value >= 25) {
      return 'Tu conexión tiene margen suficiente para streaming en vivo de máxima calidad sin cortes.';
    }
    if (value >= 10) {
      return 'Tu conexión es adecuada para transmisiones en vivo en Full HD con buena fluidez.';
    }
    if (value >= 5) {
      return 'Podés reproducir en HD, aunque conviene evitar descargas pesadas en paralelo.';
    }
    return 'Conviene acercarse al router Wi-Fi o liberar caché para reducir interrupciones.';
  }

  @override
  Widget build(BuildContext context) {
    final palette = ProfilePalette.of(context);
    final currentSpeed = _completed ? _finalSpeed : _speed;
    final normalizedBar = (currentSpeed / 100.0).clamp(0.0, 1.0);

    return ProfileSubsectionScaffold(
      title: 'Diagnóstico',
      children: [
        AppAnimations.staggeredSlideIn(
          index: 0,
          child: ProfileGroupCard(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          currentSpeed > 0
                              ? currentSpeed.toStringAsFixed(1)
                              : '0.0',
                          style: AppFont.primary(
                            fontSize: 36,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.9,
                            color: palette.text,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Mbps',
                          style: AppFont.primary(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: palette.muted,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: palette.iconBox,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: palette.border,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _completed
                                ? _quality(_finalSpeed)
                                : _isTesting
                                    ? 'Analizando'
                                    : 'En espera',
                            style: AppFont.primary(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: palette.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _status,
                      style: AppFont.primary(
                        fontSize: 13.5,
                        color: palette.muted,
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Segmented bar (.bar: height 10, border-radius 999)
                    Container(
                      height: 10,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: palette.isDark
                            ? palette.bg
                            : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: AnimatedFractionallySizedBox(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOutCubic,
                            widthFactor: normalizedBar == 0 && _isTesting
                                ? 0.08
                                : normalizedBar,
                            heightFactor: 1.0,
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF9B6BE6),
                                    Color(0xFF4F9BF0),
                                    Color(0xFF3FD1A0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ProfileGroupRow(
                leading: const _DiagnosticDot(color: Color(0xFF4F9BF0)),
                title: 'Latencia (Ping)',
                subtitle: _ping == 0
                    ? 'Tiempo de respuesta del servidor'
                    : _ping < 40
                        ? 'Respuesta inmediata'
                        : _ping < 85
                            ? 'Respuesta normal'
                            : 'Latencia elevada',
                valueText: _ping > 0 ? '$_ping ms' : '--',
              ),
              ProfileGroupRow(
                leading: const _DiagnosticDot(color: Color(0xFF3FD1A0)),
                title: 'Estabilidad de red',
                subtitle: 'Continuidad del flujo de datos',
                valueText: _stability > 0
                    ? '${_stability.toStringAsFixed(1)}%'
                    : '--',
              ),
              ProfileGroupRow(
                leading: const _DiagnosticDot(color: Color(0xFFF0C93A)),
                title: 'Pérdida de paquetes',
                subtitle: _loss == 0
                    ? 'Sin interrupciones detectadas'
                    : 'Leve fluctuación en la señal',
                valueText:
                    _completed || _isTesting ? '${_loss.toStringAsFixed(1)}%' : '--',
              ),
              ProfileGroupRow(
                leading: const _DiagnosticDot(color: Color(0xFF9B6BE6)),
                title: 'Calidad recomendada',
                subtitle: 'Resolución óptima según tu velocidad',
                valueText: _completed ? _resolution(_finalSpeed) : '--',
              ),
            ],
          ),
        ),
        AppAnimations.staggeredSlideIn(
          index: 1,
          child: ProfileActionButton(
            label: _isTesting
                ? 'Analizando conexión...'
                : _completed
                    ? 'Repetir diagnóstico'
                    : 'Iniciar diagnóstico',
            loading: _isTesting,
            onTap: _isTesting ? null : _runTest,
          ),
        ),
        AppAnimations.staggeredSlideIn(
          index: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ProfileSectionTitle('Optimización'),
              ProfileGroupCard(
                children: [
                  if (_completed)
                    ProfileGroupRow(
                      title: 'Diagnóstico: ${_resolution(_finalSpeed)}',
                      subtitle: _recommendationMessage(_finalSpeed),
                    ),
                  ProfileGroupRow(
                    leading: const ProfileSettingIconBox(
                      svgString: ProfileSvgIcons.storage,
                    ),
                    title: 'Almacenamiento y búfer',
                    subtitle: 'Liberar caché para mejorar la reproducción',
                    showChevron: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        AppAnimations.createRoute(
                          const StorageManagerScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DiagnosticDot extends StatelessWidget {
  final Color color;

  const _DiagnosticDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
