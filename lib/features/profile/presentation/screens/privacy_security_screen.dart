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
      appBar: AppBar(
        title: Text(
          'Privacidad y Seguridad',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSecurityHeader(context),
            const SizedBox(height: 40),
            _buildInfoSection(
              context,
              title: 'Protección de Datos',
              icon: Icons.lock_outline,
              content:
                  'Utilizamos tecnología de cifrado de extremo a extremo para asegurar que tus datos personales estén protegidos en todo momento durante la transmisión a nuestros servidores de Firebase.',
            ),
            const SizedBox(height: 24),
            _buildInfoSection(
              context,
              title: 'Uso de la Información',
              icon: Icons.visibility_off_outlined,
              content:
                  'Tu historial de visualización y canales favoritos se guardan localmente y en tu nube privada de Pivote. Nunca compartimos tu información con terceros con fines publicitarios.',
            ),
            const SizedBox(height: 24),
            _buildInfoSection(
              context,
              title: 'Control Total',
              icon: Icons.tune,
              content:
                  'Tienes el control completo sobre tus datos. Puedes borrar tu historial de búsqueda, historial de canales o incluso solicitar la eliminación de tu cuenta desde la configuración.',
            ),
            const SizedBox(height: 40),
            _buildActionItem(
              context,
              title: 'Cambiar Contraseña',
              icon: Icons.password_outlined,
              onTap: () {},
            ),
            _buildActionItem(
              context,
              title: 'Verificar Identidad',
              subtitle: 'Añadir verificación en dos pasos',
              icon: Icons.verified_user_outlined,
              onTap: () {},
            ),
            _buildActionItem(
              context,
              title: 'Cerrar todas las sesiones',
              icon: Icons.phonelink_erase_outlined,
              color: Colors.red,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityHeader(BuildContext context) {
    return AppAnimations.smoothFadeIn(
      child: Container(
        padding: const EdgeInsets.all(32),
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFD4B455), Color(0xFFC4A445)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD4B455).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            const Icon(FontAwesomeIcons.shieldHalved,
                color: Colors.white, size: 56),
            const SizedBox(height: 20),
            Text(
              'Estás Protegido',
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tu seguridad es nuestra máxima prioridad.',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String content,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                content,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  height: 1.5,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        tileColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.05)),
        ),
        leading: Icon(icon, color: color ?? theme.colorScheme.primary),
        title: Text(
          title,
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        subtitle: subtitle != null
            ? Text(subtitle, style: GoogleFonts.montserrat(fontSize: 12))
            : null,
        trailing: const Icon(Icons.chevron_right, size: 20),
      ),
    );
  }
}
