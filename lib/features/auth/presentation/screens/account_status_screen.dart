import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/features/auth/data/models/user_model.dart';
import 'package:pivote/features/auth/presentation/providers/user_provider.dart';
import 'package:pivote/shared/widgets/common/apple_pressable.dart';
import 'package:pivote/shared/widgets/common/pivote_surfaces.dart';

/// Pantalla de bloqueo cuando una cuenta está pendiente de aprobación,
/// vencida o desactivada en tiempo real por el administrador.
/// La sesión en Firebase Auth ya fue cerrada antes de llegar acá.
class AccountStatusScreen extends StatelessWidget {
  final AccountBlockInfo info;

  const AccountStatusScreen({
    super.key,
    required this.info,
  });

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return '$d/$m/$y';
  }

  @override
  Widget build(BuildContext context) {
    final isPending = info.reason == AccountBlockReason.pending;
    final isExpired = info.reason == AccountBlockReason.expired;

    final accent = AppTheme.accent(context);
    final danger = AppTheme.danger(context);
    final onAccent = AppTheme.onAccent(context);
    final statusColor = isPending ? accent : danger;
    final statusDim =
        isPending ? AppTheme.accentDim(context) : AppTheme.dangerDim(context);

    final IconData icon;
    final String badgeText;
    final String title;
    final String body;

    if (isPending) {
      icon = Icons.hourglass_top_rounded;
      badgeText = 'PENDIENTE DE APROBACIÓN';
      title = 'Cuenta pendiente';
      body =
          'Tu cuenta fue registrada correctamente y está esperando la aprobación manual del administrador.\n\nApenas te habiliten el acceso podrás volver a iniciar sesión con tu correo y contraseña.';
    } else if (isExpired) {
      icon = Icons.event_busy_rounded;
      badgeText = 'PLAN VENCIDO';
      title = 'Acceso vencido';
      final dateStr = info.vence != null ? ' el ${_formatDate(info.vence!)}' : '';
      body =
          'Tu acceso venció$dateStr.\n\nContactá al administrador para renovar tu suscripción y volver a ingresar a Pivote.';
    } else if (info.reason == AccountBlockReason.deviceLimitReached) {
      icon = Icons.phonelink_lock_rounded;
      badgeText = 'LÍMITE DE DISPOSITIVOS';
      title = 'Dispositivo no autorizado';
      final maxD = info.maxDispositivos ?? 1;
      final usedD = info.linkedDevicesCount ?? maxD;
      body =
          'Esta cuenta ya tiene $usedD de $maxD dispositivo${maxD == 1 ? '' : 's'} autorizado${maxD == 1 ? '' : 's'}.\n\nPor seguridad no se permite iniciar sesión desde otro equipo. Si cambiaste de celular, pedile al administrador que resetee tu dispositivo.';
    } else if (info.reason == AccountBlockReason.deviceRevoked) {
      icon = Icons.devices_other_rounded;
      badgeText = 'DISPOSITIVO DESVINCULADO';
      title = 'Sesión finalizada';
      body =
          'El administrador reseteó o desvinculó este dispositivo de tu cuenta.\n\nPodés volver a iniciar sesión si tenés un cupo disponible.';
    } else if (info.reason == AccountBlockReason.revoked) {
      icon = Icons.lock_person_rounded;
      badgeText = 'ACCESO DESACTIVADO';
      title = 'Sesión cerrada';
      body =
          'Tu cuenta fue desactivada por el administrador y tu sesión se cerró automáticamente.\n\nSi creés que es un error o ya fue reactivada, volvé a iniciar sesión.';
    } else {
      icon = Icons.shield_outlined;
      badgeText = 'SIN ACCESO HABILITADO';
      title = 'Cuenta sin activar';
      body =
          'Esta cuenta todavía no cuenta con un perfil habilitado en Pivote.\n\nContactá al administrador para solicitar activación.';
    }

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: PivoteAmbientBackdrop(
        accentColor: statusColor,
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
                    glowColor: statusColor,
                    glowAlignment: const Alignment(0.0, -0.9),
                    glowOpacity: 1.4,
                    highlighted: true,
                    borderColor: statusColor.withValues(alpha: 0.36),
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 78,
                          height: 78,
                          decoration: BoxDecoration(
                            color: statusDim,
                            borderRadius: BorderRadius.circular(AppRadius.hero),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.40),
                              width: 1.3,
                            ),
                          ),
                          child: Icon(
                            icon,
                            size: 36,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 4.5,
                          ),
                          decoration: BoxDecoration(
                            color: statusDim,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            badgeText,
                            style: AppFont.mono(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.9,
                              color: statusColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: AppFont.primary(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary(context),
                            letterSpacing: -0.5,
                          ),
                        ),
                        if (info.email != null && info.email!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            info.email!,
                            textAlign: TextAlign.center,
                            style: AppFont.mono(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textTertiary(context),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Text(
                          body,
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
                          onTap: () {
                            HapticFeedback.lightImpact();
                            context.read<UserProvider>().returnToLogin();
                          },
                          child: Container(
                            width: double.infinity,
                            height: 50,
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              boxShadow: AppShadows.glow(accent, alpha: 0.25),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Volver a iniciar sesión',
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
