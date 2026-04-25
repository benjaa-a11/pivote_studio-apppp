import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pivote/core/animations/app_animations.dart';

class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Privacidad y Seguridad',
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
              color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Decorative background glow
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSecurityHeader(context),
                  const SizedBox(height: 48),
                  _buildSectionTitle(theme, 'Tu privacidad'),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    context,
                    title: 'Protección de Identidad',
                    subtitle: 'Cifrado de grado bancario',
                    icon: Icons.fingerprint_rounded,
                    content:
                        'Tus credenciales nunca se almacenan en texto plano. Utilizamos protocolos OAuth 2.0 y hashing avanzado para asegurar tu acceso.',
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    context,
                    title: 'Transparencia de Datos',
                    subtitle: 'Nada que ocultar',
                    icon: Icons.analytics_outlined,
                    content:
                        'Pivote Studio no rastrea tu actividad fuera de la aplicación. Tus datos de uso son anónimos y se utilizan solo para mejorar la estabilidad del streaming.',
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    context,
                    title: 'Nube Privada',
                    subtitle: 'Sincronización segura',
                    icon: Icons.cloud_done_outlined,
                    content:
                        'Tus favoritos e historial se sincronizan mediante túneles SSL/TLS ultra seguros hacia tu base de datos privada en Firebase.',
                  ),
                  const SizedBox(height: 48),
                  _buildSectionTitle(theme, 'Acciones de Seguridad'),
                  const SizedBox(height: 16),
                  _buildActionItem(
                    context,
                    title: 'Ver historial de accesos',
                    icon: Icons.history_toggle_off_rounded,
                    onTap: () {},
                  ),
                  _buildActionItem(
                    context,
                    title: 'Gestión de Sesiones',
                    subtitle: 'Cerrar en otros dispositivos',
                    icon: Icons.devices_other_rounded,
                    onTap: () {},
                  ),
                  _buildActionItem(
                    context,
                    title: 'Solicitar mis datos',
                    icon: Icons.download_done_rounded,
                    onTap: () {},
                  ),
                  const SizedBox(height: 40),
                  Center(
                    child: Text(
                      'Última actualización: Marzo 2026',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.spaceGrotesk(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildSecurityHeader(BuildContext context) {
    final theme = Theme.of(context);
    return AppAnimations.smoothFadeIn(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                FontAwesomeIcons.shieldHalved,
                color: Colors.white,
                size: 50,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Estás Protegido',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                'SEGURIDAD NIVEL ELITE',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required String content,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.shade50.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primary.withValues(alpha: 0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.spaceGrotesk(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          subtitle.toUpperCase(),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                content,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  height: 1.6,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context, {
    required String title,
    String? subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        tileColor:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
        ),
        leading:
            Icon(icon, color: color ?? theme.colorScheme.primary, size: 26),
        title: Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.bold,
            color: color ?? theme.colorScheme.onSurface,
            fontSize: 15,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              )
            : null,
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
