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
    final accent = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const PivoteAppBar(title: 'Ayuda y soporte', subtitle: 'Resolvé dudas y encontrá ayuda rápida'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 36),
        children: [
          AppAnimations.smoothFadeIn(child: _hero(context)),
          const SizedBox(height: 24),
          Text('Preguntas frecuentes', style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          _faq(context, '¿Cómo agrego un canal a favoritos?', 'Abrí el canal y usá el botón de favorito en la pantalla del reproductor. Va a quedar disponible en tu sección de favoritos.'),
          _faq(context, '¿La app consume muchos datos?', 'El streaming en vivo puede consumir bastante tráfico. Para una experiencia más estable, recomendamos Wi‑Fi o una conexión móvil con buen ancho de banda.'),
          _faq(context, '¿Por qué algunos canales no cargan?', 'Puede tratarse de la conexión o de una señal temporalmente inestable. Probá actualizar el canal, revisar tu red o ejecutar el diagnóstico de streaming.'),
          _faq(context, '¿Cómo cambio el tema?', 'Desde Perfil > Apariencia podés alternar entre modo claro y oscuro. El cambio se aplica inmediatamente.'),
          const SizedBox(height: 22),
          Text('Comunidad', style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _social(context, FontAwesomeIcons.instagram, 'Instagram', const Color(0xFFE4405F), null)),
              const SizedBox(width: 9),
              Expanded(child: _social(context, FontAwesomeIcons.xTwitter, 'X', theme.colorScheme.onSurface, null)),
              const SizedBox(width: 9),
              Expanded(child: _social(context, FontAwesomeIcons.facebookF, 'Facebook', const Color(0xFF1877F2), null)),
            ],
          ),
          const SizedBox(height: 18),
          Row(children: [Icon(Icons.info_outline_rounded, color: accent, size: 16), const SizedBox(width: 7), Expanded(child: Text('Para soporte técnico, incluí el modelo de tu dispositivo y una descripción breve del problema.', style: GoogleFonts.spaceGrotesk(fontSize: 10.5, fontWeight: FontWeight.w600, color: theme.hintColor, height: 1.4)))]),
        ],
      ),
    );
  }

  Widget _hero(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [accent.withValues(alpha: .95), accent.withValues(alpha: .7)]),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: accent.withValues(alpha: .2), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.black.withValues(alpha: .09), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 25)), const Spacer(), Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .14), borderRadius: BorderRadius.circular(999)), child: Text('PIVOTE CARE', style: GoogleFonts.spaceGrotesk(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)))]),
        const SizedBox(height: 20),
        Text('Estamos para ayudarte', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900, letterSpacing: -.5)),
        const SizedBox(height: 5),
        Text('Encontrá respuestas o contactanos directamente desde acá.', style: GoogleFonts.spaceGrotesk(color: Colors.white.withValues(alpha: .84), fontSize: 11.5, fontWeight: FontWeight.w600, height: 1.4)),
        const SizedBox(height: 18),
        Row(children: [Expanded(child: _contact(context, Icons.email_outlined, 'Email', 'mailto:soporte@pivote.com')), const SizedBox(width: 9), Expanded(child: _contact(context, FontAwesomeIcons.telegram, 'Telegram', 'https://t.me/pivote_support'))]),
      ]),
    );
  }

  Widget _contact(BuildContext context, dynamic icon, String label, String url) {
    return Material(color: Colors.white.withValues(alpha: .13), borderRadius: BorderRadius.circular(15), child: InkWell(onTap: () => _open(url), borderRadius: BorderRadius.circular(15), child: Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [icon is IconData ? Icon(icon, color: Colors.white, size: 17) : FaIcon(icon, color: Colors.white, size: 17), const SizedBox(width: 7), Text(label, style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w800))])));
  }

  Widget _faq(BuildContext context, String question, String answer) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(17),
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 1),
            childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17), side: BorderSide.none),
            collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17), side: BorderSide(color: theme.dividerColor.withValues(alpha: .07))),
            iconColor: theme.colorScheme.primary,
            collapsedIconColor: theme.hintColor,
            title: Text(question, style: GoogleFonts.spaceGrotesk(fontSize: 12.5, fontWeight: FontWeight.w800)),
            children: [Text(answer, style: GoogleFonts.spaceGrotesk(fontSize: 11.5, fontWeight: FontWeight.w600, color: theme.hintColor, height: 1.45))],
          ),
        ),
      ),
    );
  }

  Widget _social(BuildContext context, IconData icon, String label, Color color, String? url) {
    final theme = Theme.of(context);
    return Material(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(16), child: InkWell(onTap: url == null ? null : () => _open(url), borderRadius: BorderRadius.circular(16), child: Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: .12))), child: Column(children: [Icon(icon, size: 17, color: color), const SizedBox(height: 6), Text(label, style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w800))])));
  }

  Future<void> _open(String value) async {
    final uri = Uri.parse(value);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}
