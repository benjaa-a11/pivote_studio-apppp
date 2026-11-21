import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pivote/core/services/firebase_service.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/shared/widgets/app_notifications.dart';
import 'package:pivote/shared/widgets/common/pivote_surfaces.dart';

class FirebaseRequiredScreen extends StatelessWidget {
  const FirebaseRequiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final error = FirebaseService.initializationError;
    final danger = AppTheme.danger(context);

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: PivoteAmbientBackdrop(
        accentColor: danger,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: PivoteDiffusedCard(
                  borderRadius: AppRadius.hero,
                  glowColor: danger,
                  glowAlignment: const Alignment(0.0, -0.9),
                  glowOpacity: 1.3,
                  highlighted: true,
                  borderColor: danger.withValues(alpha: 0.32),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: AppTheme.dangerDim(context),
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(
                            color: danger.withValues(alpha: 0.34),
                          ),
                        ),
                        child: Icon(
                          Icons.cloud_off_rounded,
                          color: danger,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Configuración incompleta',
                        textAlign: TextAlign.center,
                        style: AppFont.primary(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: AppTheme.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'La app no pudo inicializar Firebase. Sin esta conexión, el inicio de sesión y los canales no pueden funcionar.',
                        textAlign: TextAlign.center,
                        style: AppFont.primary(
                          fontSize: 13.5,
                          height: 1.45,
                          color: AppTheme.textSecondary(context),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (error != null && error.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.surface2(context),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: AppTheme.border(context)),
                          ),
                          child: Text(
                            error,
                            style: AppFont.mono(
                              fontSize: 11.5,
                              height: 1.4,
                              color: AppTheme.textSecondary(context),
                            ),
                          ),
                        ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                await Clipboard.setData(
                                  ClipboardData(
                                    text: error ??
                                        'Firebase initialization error (no details)',
                                  ),
                                );
                                if (context.mounted) {
                                  AppNotifications.showSuccess(
                                    context,
                                    'Diagnóstico copiado',
                                  );
                                }
                              },
                              child: const Text('Copiar log'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: () => SystemNavigator.pop(),
                              child: const Text('Cerrar'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Solución (dev): ejecutá flutterfire configure y volvé a compilar.',
                        textAlign: TextAlign.center,
                        style: AppFont.primary(
                          fontSize: 11.5,
                          color: AppTheme.textTertiary(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
