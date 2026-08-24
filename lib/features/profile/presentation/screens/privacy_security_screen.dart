import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/shared/widgets/common/pivote_app_bar.dart';

class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const PivoteAppBar(title: 'Privacidad y seguridad', subtitle: 'Protección de cuenta, datos y sesiones'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 34),
        children: [
          AppAnimations.smoothFadeIn(child: _securityHero(context)),
          const SizedBox(height: 22),
          _sectionTitle(context, 'Protección de tu cuenta'),
          const SizedBox(height: 9),
          _info(context, Icons.fingerprint_rounded, 'Protección de identidad', 'Tus credenciales se procesan mediante los mecanismos de autenticación de Firebase y no se muestran en texto plano.', accent),
          _info(context, Icons.visibility_outlined, 'Transparencia', 'Pivote limita el uso de datos a lo necesario para autenticación, preferencias y funcionamiento de la app.', const Color(0xFF5B8CFF)),
          _info(context, Icons.cloud_done_outlined, 'Sincronización segura', 'Favoritos y preferencias se sincronizan mediante conexiones cifradas con la infraestructura de Firebase.', const Color(0xFF35B77A)),
          const SizedBox(height: 20),
          _sectionTitle(context, 'Acciones'),
          const SizedBox(height: 9),
          _action(context, Icons.history_toggle_off_rounded, 'Historial de accesos', 'Próximamente podrás revisar accesos recientes.'),
          _action(context, Icons.devices_other_rounded, 'Gestión de sesiones', 'Próximamente podrás administrar otros dispositivos.'),
          _action(context, Icons.download_rounded, 'Solicitar mis datos', 'Prepará una solicitud para exportar la información asociada a tu cuenta.'),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(color: accent.withValues(alpha: .06), borderRadius: BorderRadius.circular(16), border: Border.all(color: accent.withValues(alpha: .1))),
            child: Row(children: [Icon(Icons.verified_user_rounded, color: accent, size: 18), const SizedBox(width: 9), Expanded(child: Text('Revisá siempre que tu cuenta esté protegida con una contraseña única y no la compartas.', style: GoogleFonts.spaceGrotesk(fontSize: 10.5, fontWeight: FontWeight.w600, color: theme.hintColor, height: 1.4)))]),
          ),
          const SizedBox(height: 12),
          Center(child: Text('Última revisión visual: agosto 2026', style: GoogleFonts.spaceGrotesk(fontSize: 9.5, fontWeight: FontWeight.w600, color: theme.hintColor))),
        ],
      ),
    );
  }

  Widget _securityHero(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [accent.withValues(alpha: .95), accent.withValues(alpha: .62)]),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: accent.withValues(alpha: .18), blurRadius: 26, offset: const Offset(0, 11))],
      ),
      child: Row(children: [Container(width: 54, height: 54, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .15), borderRadius: BorderRadius.circular(17)), child: const Icon(Icons.shield_rounded, color: Colors.white, size: 28)), const SizedBox(width: 13), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Tu cuenta está protegida', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)), const SizedBox(height: 3), Text('Seguridad activa · autenticación y datos sincronizados de forma protegida.', style: GoogleFonts.spaceGrotesk(color: Colors.white.withValues(alpha: .82), fontSize: 10.8, fontWeight: FontWeight.w600, height: 1.35))])), const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22)]),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) => Text(title, style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w900));

  Widget _info(BuildContext context, IconData icon, String title, String body, Color color) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: color.withValues(alpha: .1))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 42, height: 42, decoration: BoxDecoration(color: color.withValues(alpha: .1), borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: color, size: 20)), const SizedBox(width: 11), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(body, style: GoogleFonts.spaceGrotesk(fontSize: 10.5, fontWeight: FontWeight.w600, color: theme.hintColor, height: 1.45))]))]),
      ),
    );
  }

  Widget _action(BuildContext context, IconData icon, String title, String subtitle) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(17),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(17), border: Border.all(color: theme.dividerColor.withValues(alpha: .07))),
            child: Row(children: [Container(width: 40, height: 40, decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: .08), borderRadius: BorderRadius.circular(12)), child: Icon(icon, size: 19, color: theme.colorScheme.primary)), const SizedBox(width: 11), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: GoogleFonts.spaceGrotesk(fontSize: 12.5, fontWeight: FontWeight.w800)), const SizedBox(height: 2), Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w600, color: theme.hintColor, height: 1.35))])), Icon(Icons.arrow_forward_ios_rounded, size: 11, color: theme.hintColor)]),
          ),
        ),
      ),
    );
  }
}
