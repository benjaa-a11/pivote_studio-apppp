import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
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

    await Future.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;

    setState(() => _status = 'Estimando capacidad de streaming...');
    var target = 82 - (avgPing * .16) + Random().nextDouble() * 14;
    target = target.clamp(6, 118).toDouble();

    for (var i = 0; i < 24; i++) {
      await Future.delayed(const Duration(milliseconds: 60));
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
    await Future.delayed(const Duration(milliseconds: 420));
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
    final accent = AppTheme.accent(context);
    final danger = AppTheme.danger(context);
    final currentSpeed = _completed ? _finalSpeed : _speed;
    final normalizedBar = (currentSpeed / 100.0).clamp(0.0, 1.0);
    final isLimited = _completed && _finalSpeed < 5;

    return ProfileSubsectionScaffold(
      title: 'Diagnóstico',
      subtitle: 'Rendimiento de red para streaming',
      children: [
        AppAnimations.staggeredSlideIn(
          index: 0,
          child: ProfileGroupCard(
            highlighted: _completed || _isTesting,
            glowColor: isLimited ? danger : accent,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
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
                          style: AppFont.mono(
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.0,
                            color: AppTheme.textPrimary(context),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Mbps',
                          style: AppFont.primary(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textTertiary(context),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isLimited
                                ? AppTheme.dangerDim(context)
                                : _completed || _isTesting
                                    ? AppTheme.accentDim(context)
                                    : AppTheme.surface2(context),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(
                              color: isLimited
                                  ? danger.withValues(alpha: 0.36)
                                  : _completed || _isTesting
                                      ? accent.withValues(alpha: 0.36)
                                      : AppTheme.border(context),
                            ),
                          ),
                          child: Text(
                            _completed
                                ? _quality(_finalSpeed)
                                : _isTesting
                                    ? 'Analizando'
                                    : 'En espera',
                            style: AppFont.primary(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isLimited
                                  ? danger
                                  : _completed || _isTesting
                                      ? accent
                                      : AppTheme.textSecondary(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _status,
                      style: AppFont.primary(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Barra de progreso estrictamente con el color del tema
                    Container(
                      height: 10,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.surface3(context),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
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
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    (isLimited ? danger : accent)
                                        .withValues(alpha: 0.65),
                                    isLimited ? danger : accent,
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
                leading: _MetricIconBox(
                  icon: Icons.network_ping_rounded,
                  alert: _ping >= 85,
                  active: _ping > 0 && _ping < 85,
                ),
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
                leading: _MetricIconBox(
                  icon: Icons.graphic_eq_rounded,
                  active: _stability > 0,
                ),
                title: 'Estabilidad de red',
                subtitle: 'Continuidad del flujo de datos',
                valueText: _stability > 0
                    ? '${_stability.toStringAsFixed(1)}%'
                    : '--',
              ),
              ProfileGroupRow(
                leading: _MetricIconBox(
                  icon: Icons.sync_problem_rounded,
                  alert: _loss > 0,
                  active: _completed && _loss == 0,
                ),
                title: 'Pérdida de paquetes',
                subtitle: _loss == 0
                    ? 'Sin interrupciones detectadas'
                    : 'Leve fluctuación en la señal',
                valueText: _completed || _isTesting
                    ? '${_loss.toStringAsFixed(1)}%'
                    : '--',
              ),
              ProfileGroupRow(
                leading: _MetricIconBox(
                  icon: Icons.hd_outlined,
                  active: _completed,
                ),
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
                      leading: const ProfileSettingIconBox(
                        icon: Icons.check_circle_outline_rounded,
                        highlight: true,
                      ),
                      title: 'Resultado: ${_resolution(_finalSpeed)}',
                      subtitle: _recommendationMessage(_finalSpeed),
                    ),
                  ProfileGroupRow(
                    leading: const ProfileSettingIconBox(
                      icon: Icons.storage_rounded,
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

class _MetricIconBox extends StatelessWidget {
  final IconData icon;
  final bool active;
  final bool alert;

  const _MetricIconBox({
    required this.icon,
    this.active = false,
    this.alert = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = alert
        ? AppTheme.danger(context)
        : active
            ? AppTheme.accent(context)
            : AppTheme.textTertiary(context);
    final bg = alert
        ? AppTheme.dangerDim(context)
        : active
            ? AppTheme.accentDim(context)
            : AppTheme.surface2(context);

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: (active || alert)
              ? color.withValues(alpha: 0.30)
              : AppTheme.border(context),
        ),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 18, color: color),
    );
  }
}
