import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/features/auth/presentation/providers/user_provider.dart';
import 'package:pivote/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:pivote/features/profile/presentation/screens/history_screen.dart';
import 'package:pivote/features/profile/presentation/screens/storage_manager_screen.dart';
import 'package:pivote/shared/widgets/common/apple_pressable.dart';
import 'package:pivote/shared/widgets/common/pivote_app_bar.dart';

class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor =
        isDark ? AppTheme.darkAccent : theme.colorScheme.primary;
    final user = context.watch<UserProvider>().user;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const PivoteAppBar(
        title: 'Privacidad y seguridad',
        subtitle: 'Protección de cuenta, cifrado y control de datos',
      ),
      body: ListView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          AppAnimations.staggeredSlideIn(
            index: 0,
            child: _securityHero(context, isDark, primaryColor, user?.email),
          ),
          const SizedBox(height: 24),

          // Connected Quick Privacy Controls
          AppAnimations.staggeredSlideIn(
            index: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle(context, 'CONTROLES RÁPIDOS DE PRIVACIDAD'),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF131722) : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF1E2533)
                          : AppTheme.lightBorder,
                    ),
                  ),
                  child: Column(
                    children: [
                      _connectedActionTile(
                        context,
                        icon: Icons.lock_reset_rounded,
                        title: 'Actualizar contraseña y datos',
                        subtitle: 'Gestionar tus credenciales de acceso',
                        color: primaryColor,
                        onTap: () => Navigator.push(
                          context,
                          AppAnimations.createRoute(const EditProfileScreen()),
                        ),
                      ),
                      Divider(
                        height: 1,
                        indent: 64,
                        endIndent: 16,
                        color: theme.dividerColor.withValues(alpha: 0.06),
                      ),
                      _connectedActionTile(
                        context,
                        icon: Icons.history_rounded,
                        title: 'Revisar o borrar historial',
                        subtitle: 'Controlar registro de canales vistos',
                        color: const Color(0xFF10B981),
                        onTap: () => Navigator.push(
                          context,
                          AppAnimations.createRoute(const HistoryScreen()),
                        ),
                      ),
                      Divider(
                        height: 1,
                        indent: 64,
                        endIndent: 16,
                        color: theme.dividerColor.withValues(alpha: 0.06),
                      ),
                      _connectedActionTile(
                        context,
                        icon: Icons.cleaning_services_outlined,
                        title: 'Limpiar rastros y caché local',
                        subtitle: 'Eliminar archivos temporales del equipo',
                        color: const Color(0xFFE58B46),
                        onTap: () => Navigator.push(
                          context,
                          AppAnimations.createRoute(
                              const StorageManagerScreen()),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          AppAnimations.staggeredSlideIn(
            index: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle(context, 'PILARES DE PROTECCIÓN'),
                const SizedBox(height: 10),
                _info(
                  context,
                  Icons.fingerprint_rounded,
                  'Autenticación Cifrada',
                  'Tus credenciales se procesan de forma segura mediante Firebase Auth con cifrado TLS/SSL de extremo a extremo.',
                  primaryColor,
                  isDark,
                ),
                _info(
                  context,
                  Icons.visibility_off_outlined,
                  'Cero Rastreo Publicitario',
                  'Pivote no vende ni comparte información personal con terceros. Solo se guardan tus preferencias de uso.',
                  const Color(0xFF5B8CFF),
                  isDark,
                ),
                _info(
                  context,
                  Icons.cloud_done_outlined,
                  'Sincronización Segura en la Nube',
                  'Tus favoritos y estadísticas de actividad se respaldan bajo protocolos HTTPS/WSS.',
                  const Color(0xFF10B981),
                  isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          AppAnimations.staggeredSlideIn(
            index: 3,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: .06),
                    borderRadius: BorderRadius.circular(18),
                    border:
                        Border.all(color: primaryColor.withValues(alpha: .15)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.verified_user_rounded,
                          color: primaryColor, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Mantené siempre una contraseña única y la aplicación actualizada para contar con los últimos parches de seguridad.',
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
          ),
        ],
      ),
    );
  }

  Widget _securityHero(
    BuildContext context,
    bool isDark,
    Color primaryColor,
    String? email,
  ) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF18221C), const Color(0xFF131722)]
              : [
                  primaryColor.withValues(alpha: 0.92),
                  primaryColor.withValues(alpha: 0.72),
                ],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: AppShadows.appleDepth(context, elevation: 0.9),
        border: Border.all(
          color: primaryColor.withValues(alpha: isDark ? 0.3 : 0.1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isDark
                      ? primaryColor.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(
                  Icons.shield_rounded,
                  color: isDark ? primaryColor : Colors.white,
                  size: 27,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Cuenta Protegida',
                          style: GoogleFonts.spaceGrotesk(
                            color: isDark ? primaryColor : Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.check_circle_rounded,
                          color: isDark ? primaryColor : Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      email ?? 'Sesión verificada y cifrada',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceGrotesk(
                        color: isDark
                            ? Theme.of(context).hintColor
                            : Colors.white.withValues(alpha: 0.85),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _statusChip(isDark, primaryColor, 'SSL Activo'),
              const SizedBox(width: 8),
              _statusChip(isDark, primaryColor, 'Sin Rastreo'),
              const SizedBox(width: 8),
              _statusChip(isDark, primaryColor, 'Cloud Sync'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip(bool isDark, Color primaryColor, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_rounded,
              size: 12,
              color: isDark ? primaryColor : Colors.white,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _connectedActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return ApplePressable(
      scaleDownFactor: 0.985,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 19, color: color),
            ),
            const SizedBox(width: 12),
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
                  Text(
                    subtitle,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: theme.hintColor.withValues(alpha: 0.45),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.7,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
          ),
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
          color: isDark ? const Color(0xFF131722) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? const Color(0xFF1E2533) : AppTheme.lightBorder,
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
