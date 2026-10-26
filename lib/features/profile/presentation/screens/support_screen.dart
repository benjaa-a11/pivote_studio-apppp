import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/shared/widgets/common/pivote_app_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor =
        isDark ? AppTheme.darkAccent : theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const PivoteAppBar(
        title: 'Ayuda y soporte',
        subtitle: 'Preguntas frecuentes y atención directa',
      ),
      body: ListView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          _buildHero(context, isDark, primaryColor),
          const SizedBox(height: 28),
          Text(
            'Preguntas frecuentes',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          _faq(
            context,
            '¿Cómo guardo un canal o radio en favoritos?',
            'Dentro de la pantalla de reproducción de cualquier canal o radio, toca el icono de corazón en la barra superior para agregarlo o quitarlo de tus favoritos.',
            isDark,
          ),
          _faq(
            context,
            '¿Por qué una transmisión en vivo se detiene o tiene buffering?',
            'Puede deberse a la velocidad o estabilidad de tu conexión a internet. Te sugerimos ejecutar el "Diagnóstico de Streaming" desde tu perfil para comprobar el ping y la velocidad de descarga.',
            isDark,
          ),
          _faq(
            context,
            '¿La aplicación consume muchos datos móviles?',
            'El streaming en video HD consume entre 1 GB y 2.5 GB por hora según la calidad. Recomendamos utilizar conexión Wi-Fi para transmisiones de larga duración.',
            isDark,
          ),
          _faq(
            context,
            '¿Cómo cambio entre modo oscuro y claro?',
            'Ve a Perfil > Preferencias > Apariencia y selecciona el tema visual que prefieras. El cambio se aplica al instante.',
            isDark,
          ),
          _faq(
            context,
            '¿Cómo libero espacio ocupado por la aplicación?',
            'En Perfil > Preferencias > Almacenamiento puedes presionar "Limpiar todo el almacenamiento" para vaciar imágenes y archivos temporales de forma segura.',
            isDark,
          ),
          const SizedBox(height: 24),
          Text(
            'Comunidad y redes',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _social(
                  context,
                  FontAwesomeIcons.instagram,
                  'Instagram',
                  const Color(0xFFE4405F),
                  'https://instagram.com',
                  isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _social(
                  context,
                  FontAwesomeIcons.xTwitter,
                  'X (Twitter)',
                  theme.colorScheme.onSurface,
                  'https://x.com',
                  isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _social(
                  context,
                  FontAwesomeIcons.telegram,
                  'Telegram',
                  const Color(0xFF0088CC),
                  'https://t.me/pivote_support',
                  isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: .06),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: primaryColor.withValues(alpha: .15)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: primaryColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Para reportes técnicos, puedes enviar un correo a soporte@pivote.com incluyendo el modelo de tu equipo y una captura de pantalla.',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: theme.hintColor,
                      height: 1.4,
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

  Widget _buildHero(BuildContext context, bool isDark, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF19251D),
                  const Color(0xFF0F1512),
                ]
              : [
                  primaryColor.withValues(alpha: 0.95),
                  primaryColor.withValues(alpha: 0.72),
                ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: primaryColor.withValues(alpha: isDark ? 0.3 : 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: isDark ? 0.1 : 0.2),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark
                      ? primaryColor.withValues(alpha: 0.18)
                      : Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.support_agent_rounded,
                  color: isDark ? primaryColor : Colors.white,
                  size: 26,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark
                      ? primaryColor.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'ATENCIÓN DIRECTA',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: isDark ? primaryColor : Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            '¿En qué podemos ayudarte?',
            style: GoogleFonts.spaceGrotesk(
              color: isDark ? primaryColor : Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Encontrá respuestas inmediatas o comunicate con el equipo de soporte.',
            style: GoogleFonts.spaceGrotesk(
              color: isDark
                  ? Theme.of(context).hintColor
                  : Colors.white.withValues(alpha: 0.85),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _contact(
                  context,
                  Icons.email_outlined,
                  'Enviar Email',
                  'mailto:soporte@pivote.com',
                  isDark,
                  primaryColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _contact(
                  context,
                  FontAwesomeIcons.telegram,
                  'Telegram',
                  'https://t.me/pivote_support',
                  isDark,
                  primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _contact(
    BuildContext context,
    dynamic icon,
    String label,
    String url,
    bool isDark,
    Color primaryColor,
  ) {
    return Material(
      color: isDark
          ? primaryColor.withValues(alpha: 0.12)
          : Colors.white.withValues(alpha: .18),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _open(url),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon is IconData)
                Icon(icon,
                    color: isDark ? primaryColor : Colors.white, size: 18)
              else
                FaIcon(icon as FaIconData,
                    color: isDark ? primaryColor : Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  color: isDark ? primaryColor : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _faq(
      BuildContext context, String question, String answer, bool isDark) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ),
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ),
            iconColor: theme.colorScheme.primary,
            collapsedIconColor: theme.hintColor,
            title: Text(
              question,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
            children: [
              Text(
                answer,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.hintColor,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _social(BuildContext context, FaIconData icon, String label,
      Color color, String url, bool isDark) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => _open(url),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          child: Column(
            children: [
              FaIcon(icon, size: 20, color: color),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _open(String value) async {
    final uri = Uri.parse(value);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
