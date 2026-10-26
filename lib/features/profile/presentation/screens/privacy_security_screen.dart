import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/shared/widgets/common/pivote_app_bar.dart';

class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor =
        isDark ? AppTheme.darkAccent : theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const PivoteAppBar(
        title: 'Privacidad y seguridad',
        subtitle: 'Protección de cuenta, datos y conexiones seguras',
      ),
      body: ListView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          AppAnimations.smoothFadeIn(
              child: _securityHero(context, isDark, primaryColor)),
          const SizedBox(height: 28),
          _sectionTitle(context, 'Protección de tu cuenta'),
          const SizedBox(height: 12),
          _info(
            context,
            Icons.fingerprint_rounded,
            'Protección de Identidad y Acceso',
            'Tus credenciales se procesan de forma segura mediante los servicios de Firebase Auth con cifrado SSL.',
            primaryColor,
            isDark,
          ),
          _info(
            context,
            Icons.visibility_outlined,
            'Transparencia de Datos',
            'Pivote no comparte información personal con terceros. Únicamente se guardan preferencias para mejorar tu experiencia.',
            const Color(0xFF5B8CFF),
            isDark,
          ),
          _info(
            context,
            Icons.cloud_done_outlined,
            'Sincronización Cifrada',
            'Tus favoritos e historial se transmiten únicamente a través de protocolos seguros HTTPS/WSS.',
            const Color(0xFF10B981),
            isDark,
          ),
          const SizedBox(height: 24),
          _sectionTitle(context, 'Recomendaciones de Seguridad'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: .06),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: primaryColor.withValues(alpha: .15)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.verified_user_rounded,
                    color: primaryColor, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Revisá siempre que tu cuenta utilice una contraseña única y mantené actualizada la aplicación para recibir parches de seguridad.',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.hintColor,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'Pivote Studio · Cifrado y Privacidad Activa',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: theme.hintColor.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _securityHero(BuildContext context, bool isDark, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF18221C),
                  const Color(0xFF0F1512),
                ]
              : [
                  primaryColor.withValues(alpha: 0.92),
                  primaryColor.withValues(alpha: 0.72),
                ],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: isDark ? 0.12 : 0.25),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: primaryColor.withValues(alpha: isDark ? 0.3 : 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: isDark
                  ? primaryColor.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.shield_rounded,
              color: isDark ? primaryColor : Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cuenta Protegida',
                  style: GoogleFonts.spaceGrotesk(
                    color: isDark ? primaryColor : Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Autenticación cifrada y datos sincronizados con altos estándares de privacidad.',
                  style: GoogleFonts.spaceGrotesk(
                    color: isDark
                        ? Theme.of(context).hintColor
                        : Colors.white.withValues(alpha: 0.85),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.check_circle_rounded,
            color: isDark ? primaryColor : Colors.white,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) => Text(
        title,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      );

  Widget _info(BuildContext context, IconData icon, String title, String body,
      Color color, bool isDark) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.hintColor,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
