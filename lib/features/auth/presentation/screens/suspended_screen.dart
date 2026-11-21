import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/features/auth/presentation/providers/user_provider.dart';
import 'package:pivote/shared/widgets/app_notifications.dart';
import 'package:pivote/shared/widgets/common/apple_pressable.dart';
import 'package:pivote/shared/widgets/common/pivote_loader.dart';
import 'package:pivote/shared/widgets/common/pivote_surfaces.dart';

class SuspendedScreen extends StatefulWidget {
  const SuspendedScreen({super.key});

  @override
  State<SuspendedScreen> createState() => _SuspendedScreenState();
}

class _SuspendedScreenState extends State<SuspendedScreen> {
  bool _isChecking = false;

  Future<void> _checkStatus() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);

    try {
      final userProvider = context.read<UserProvider>();
      await userProvider.refreshUser();

      if (mounted) {
        final user = userProvider.user;
        if (user != null && !user.isSuspended) {
          AppNotifications.showSuccess(
            context,
            '¡Tu cuenta fue reactivada! Bienvenido de nuevo.',
          );
        } else {
          AppNotifications.showWarning(
            context,
            'Tu cuenta sigue suspendida. Contactá con soporte si creés que es un error.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppNotifications.showError(
          context,
          'No se pudo verificar el estado actual. Revisá tu conexión.',
        );
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final danger = AppTheme.danger(context);
    final accent = AppTheme.accent(context);
    final onAccent = AppTheme.onAccent(context);

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: PivoteAmbientBackdrop(
        accentColor: danger,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: AppAnimations.smoothFadeInScale(
                  child: PivoteDiffusedCard(
                    borderRadius: AppRadius.hero,
                    glowColor: danger,
                    glowAlignment: const Alignment(0.0, -0.9),
                    glowOpacity: 1.4,
                    highlighted: true,
                    borderColor: danger.withValues(alpha: 0.36),
                    padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppTheme.dangerDim(context),
                            borderRadius: BorderRadius.circular(AppRadius.hero),
                            border: Border.all(
                              color: danger.withValues(alpha: 0.40),
                              width: 1.3,
                            ),
                          ),
                          child: Icon(
                            Icons.gavel_rounded,
                            size: 38,
                            color: danger,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          'Cuenta suspendida',
                          textAlign: TextAlign.center,
                          style: AppFont.primary(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary(context),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Tu cuenta fue suspendida temporalmente por nuestras normas comunitarias.\n\nSi creés que es un error o ya fue reactivada, comprobá tu estado abajo.',
                          textAlign: TextAlign.center,
                          style: AppFont.primary(
                            fontSize: 13.8,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary(context),
                          ),
                        ),
                        const SizedBox(height: 26),
                        ApplePressable(
                          scaleDownFactor: 0.97,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          onTap: _isChecking ? null : _checkStatus,
                          child: Container(
                            width: double.infinity,
                            height: 50,
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              boxShadow: AppShadows.glow(accent, alpha: 0.25),
                            ),
                            alignment: Alignment.center,
                            child: _isChecking
                                ? PivoteLoader(
                                    color: onAccent,
                                    strokeWidth: 2.3,
                                    size: 20,
                                  )
                                : Text(
                                    'Verificar estado',
                                    style: AppFont.primary(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                      color: onAccent,
                                    ),
                                  ),
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
      ),
    );
  }
}
