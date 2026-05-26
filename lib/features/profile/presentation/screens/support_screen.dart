import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/shared/widgets/common/pivote_app_bar.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const PivoteAppBar(
        title: 'Ayuda y Soporte',
        subtitle: 'Resolvé tus dudas y contactanos',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildContactCard(context),
            const SizedBox(height: 40),
            Text(
              'Preguntas Frecuentes',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildFAQItem(
              context,
              '¿Cómo agrego canales a favoritos?',
              'Puedes presionar el icono de corazón en la esquina superior derecha de cualquier canal mientras lo ves para añadirlo a tu sección de favoritos.',
            ),
            _buildFAQItem(
              context,
              '¿La aplicación consume muchos datos?',
              'El streaming de TV en vivo consume datos significativos. Recomendamos usar una conexión Wi-Fi para una mejor experiencia y evitar cargos extras.',
            ),
            _buildFAQItem(
              context,
              '¿Por qué algunos canales no cargan?',
              'Esto puede deberse a tu conexión a internet o a que la señal del canal está experimentando problemas técnicos momentáneos. Intenta recargar o probar otro canal.',
            ),
            _buildFAQItem(
              context,
              '¿Cómo cambio el tema de la app?',
              'En la sección de Perfil, bajo el apartado de Apariencia, tienes un interruptor para alternar entre el Modo Claro y el Modo Oscuro.',
            ),
            const SizedBox(height: 48),
            _buildSocialLinks(context),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(BuildContext context) {
    return AppAnimations.smoothFadeIn(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF5BB389), Color(0xFF4AA078)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5BB389).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            const Icon(Icons.support_agent, color: Colors.white, size: 48),
            const SizedBox(height: 16),
            Text(
              '¿Necesitas ayuda?',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Nuestro equipo está disponible para ayudarte con cualquier problema o duda.',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildContactButton(
                    context,
                    label: 'Email',
                    icon: Icons.email_outlined,
                    onTap: () => _launchURL('mailto:soporte@pivote.com'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildContactButton(
                    context,
                    label: 'Telegram',
                    icon: FontAwesomeIcons.telegram,
                    onTap: () => _launchURL('https://t.me/pivote_support'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactButton(
    BuildContext context, {
    required String label,
    required dynamic icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withAlpha(51),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor.withAlpha(26)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon is IconData
                ? Icon(icon, color: Colors.white, size: 18)
                : FaIcon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withAlpha(51),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
        ),
        child: ExpansionTile(
          title: Text(
            question,
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          shape: const RoundedRectangleBorder(side: BorderSide.none),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          expandedAlignment: Alignment.topLeft,
          children: [
            Text(
              answer,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialLinks(BuildContext context) {
    return Column(
      children: [
        Center(
          child: Text(
            'Síguenos',
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _socialIcon(FontAwesomeIcons.instagram),
            const SizedBox(width: 24),
            _socialIcon(FontAwesomeIcons.xTwitter),
            const SizedBox(width: 24),
            _socialIcon(FontAwesomeIcons.facebook),
          ],
        ),
      ],
    );
  }

  Widget _socialIcon(dynamic icon) {
    return icon is IconData
        ? Icon(icon, color: Colors.grey.withValues(alpha: 0.6), size: 28)
        : FaIcon(icon, color: Colors.grey.withValues(alpha: 0.6), size: 28);
  }

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
