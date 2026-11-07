import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/features/profile/presentation/screens/diagnostics_screen.dart';
import 'package:pivote/features/profile/presentation/screens/storage_manager_screen.dart';
import 'package:pivote/shared/widgets/common/apple_pressable.dart';
import 'package:pivote/shared/widgets/common/pivote_app_bar.dart';

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
        subtitle: 'Asistencia rápida, autodiagnóstico y preguntas frecuentes',
      ),
      body: ListView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          AppAnimations.staggeredSlideIn(
            index: 0,
            child: _buildHero(context, isDark, primaryColor),
          ),
          const SizedBox(height: 24),

          // Connected Quick Troubleshooting Tools
          AppAnimations.staggeredSlideIn(
            index: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle(theme, 'SOLUCIÓN RÁPIDA DE PROBLEMAS'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _toolCard(
                        context,
                        isDark: isDark,
                        icon: Icons.speed_rounded,
                        title: 'Test de Red',
                        subtitle: 'Medir ping y Mbps',
                        color: const Color(0xFF38BDF8),
                        onTap: () => Navigator.push(
                          context,
                          AppAnimations.createRoute(const DiagnosticsScreen()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _toolCard(
                        context,
                        isDark: isDark,
                        icon: Icons.cleaning_services_rounded,
                        title: 'Limpiar Caché',
                        subtitle: 'Reparar carga lenta',
                        color: const Color(0xFFE58B46),
                        onTap: () => Navigator.push(
                          context,
                          AppAnimations.createRoute(
                              const StorageManagerScreen()),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),

          // FAQs
          AppAnimations.staggeredSlideIn(
            index: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle(theme, 'PREGUNTAS FRECUENTES'),
                const SizedBox(height: 10),
                _faq(
                  context,
                  Icons.favorite_outline_rounded,
                  '¿Cómo guardo un canal o radio en favoritos?',
                  'Dentro del reproductor de cualquier canal o radio, o desde tu historial, toca el icono de corazón para agregarlo o quitarlo de tu colección sincronizada.',
                  isDark,
                ),
                _faq(
                  context,
                  Icons.wifi_tethering_error_rounded,
                  '¿Por qué una transmisión se detiene o tiene buffering?',
                  'Puede deberse a fluctuaciones en tu red Wi-Fi o datos móviles. Ejecutá el "Test de Red" arriba para verificar tu velocidad y limpiá la caché temporal si el reproductor demora en iniciar.',
                  isDark,
                ),
                _faq(
                  context,
                  Icons.data_saver_off_rounded,
                  '¿La aplicación consume muchos datos móviles?',
                  'El streaming de video en vivo en alta definición consume entre 1 GB y 2.5 GB por hora. Te recomendamos usar Wi-Fi para partidos completos o películas.',
                  isDark,
                ),
                _faq(
                  context,
                  Icons.dark_mode_outlined,
                  '¿Cómo cambio entre modo oscuro y claro?',
                  'Podés cambiarlo con un solo toque desde el botón superior derecho en tu Perfil, o entrando a Perfil > Apariencia y Pantalla.',
                  isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Community & Socials
          AppAnimations.staggeredSlideIn(
            index: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle(theme, 'COMUNIDAD Y CANALES OFICIALES'),
                const SizedBox(height: 10),
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
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: .06),
                    borderRadius: BorderRadius.circular(18),
                    border:
                        Border.all(color: primaryColor.withValues(alpha: .15)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: primaryColor, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Para reportes técnicos de señales, escribinos a soporte@pivote.com indicando el nombre del canal.',
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
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(ThemeData theme, String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.7,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
        ),
      ),
    );
  }

  Widget _toolCard(
    BuildContext context, {
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return ApplePressable(
      scaleDownFactor: 0.96,
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131722) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF1E2533) : AppTheme.lightBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: theme.hintColor,
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

  Widget _buildHero(BuildContext context, bool isDark, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF18221D), const Color(0xFF131722)]
              : [
                  primaryColor.withValues(alpha: 0.95),
                  primaryColor.withValues(alpha: 0.75),
                ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: primaryColor.withValues(alpha: isDark ? 0.28 : 0.15),
        ),
        boxShadow: AppShadows.appleDepth(context, elevation: 0.9),
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
                      ? primaryColor.withValues(alpha: 0.16)
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
                      ? primaryColor.withValues(alpha: 0.14)
                      : Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'SOPORTE ACTIVO',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: isDark ? primaryColor : Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '¿En qué podemos ayudarte hoy?',
            style: GoogleFonts.spaceGrotesk(
              color: isDark ? Colors.white : Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Usá las herramientas rápidas o comunicate directamente con nuestro equipo técnico.',
            style: GoogleFonts.spaceGrotesk(
              color: isDark
                  ? Theme.of(context).hintColor
                  : Colors.white.withValues(alpha: 0.88),
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
                  'Telegram Directo',
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
    return ApplePressable(
      scaleDownFactor: 0.96,
      borderRadius: BorderRadius.circular(16),
      onTap: () => _open(url),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? primaryColor.withValues(alpha: 0.14)
              : Colors.white.withValues(alpha: .20),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? primaryColor.withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon is IconData)
              Icon(icon,
                  color: isDark ? primaryColor : Colors.white, size: 17)
            else
              FaIcon(icon as FaIconData,
                  color: isDark ? primaryColor : Colors.white, size: 17),
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
    );
  }

  Widget _faq(
    BuildContext context,
    IconData icon,
    String question,
    String answer,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final primaryColor =
        isDark ? AppTheme.darkAccent : theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131722) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? const Color(0xFF1E2533) : AppTheme.lightBorder,
          ),
        ),
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            leading: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 17, color: primaryColor),
            ),
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            iconColor: primaryColor,
            collapsedIconColor: theme.hintColor,
            title: Text(
              question,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
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
    return ApplePressable(
      scaleDownFactor: 0.95,
      borderRadius: BorderRadius.circular(18),
      onTap: () => _open(url),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131722) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? const Color(0xFF1E2533) : AppTheme.lightBorder,
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
    );
  }

  Future<void> _open(String value) async {
    final uri = Uri.parse(value);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
