import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pivote/core/theme/theme_provider.dart';
import 'package:pivote/core/services/wakelock_service.dart';
import 'package:pivote/shared/widgets/common/pivote_app_bar.dart';

class AppearanceSettingsScreen extends StatelessWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final wakelock = context.watch<WakelockService>();
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const PivoteAppBar(
        title: 'Apariencia',
        subtitle: 'Personalizá cómo se ve y funciona Pivote',
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF171B19), const Color(0xFF0E1110)]
                    : [const Color(0xFFF4F7EE), Colors.white],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.colorScheme.primary.withValues(alpha: .11)),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.palette_rounded, color: theme.colorScheme.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tu estilo', style: GoogleFonts.spaceGrotesk(fontSize: 19, fontWeight: FontWeight.w900, letterSpacing: -.4)),
                      const SizedBox(height: 3),
                      Text('Ajustes rápidos para una experiencia más cómoda.', style: GoogleFonts.spaceGrotesk(fontSize: 11.5, fontWeight: FontWeight.w600, color: theme.hintColor, height: 1.35)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _sectionTitle(context, 'Tema'),
          const SizedBox(height: 9),
          _settingCard(
            context,
            icon: themeProvider.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            title: 'Modo oscuro',
            subtitle: themeProvider.isDarkMode ? 'Activo · más cómodo de noche' : 'Desactivado · modo claro activo',
            accent: theme.colorScheme.primary,
            trailing: Switch.adaptive(
              value: themeProvider.isDarkMode,
              onChanged: (_) => themeProvider.toggleTheme(),
            ),
          ),
          const SizedBox(height: 18),
          _sectionTitle(context, 'Reproducción'),
          const SizedBox(height: 9),
          _settingCard(
            context,
            icon: wakelock.keepScreenOn ? Icons.visibility_rounded : Icons.visibility_off_rounded,
            title: 'Pantalla siempre encendida',
            subtitle: wakelock.keepScreenOn ? 'La pantalla permanece activa durante el contenido' : 'La pantalla se apaga normalmente',
            accent: wakelock.keepScreenOn ? const Color(0xFFFFA726) : theme.colorScheme.primary,
            trailing: Switch.adaptive(
              value: wakelock.keepScreenOn,
              onChanged: wakelock.setKeepScreenOn,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.dividerColor.withValues(alpha: .07)),
            ),
            child: Row(
              children: [
                Icon(Icons.tune_rounded, color: theme.hintColor, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text('Los cambios se aplican inmediatamente y se guardan en tu dispositivo.', style: GoogleFonts.spaceGrotesk(fontSize: 10.5, fontWeight: FontWeight.w600, color: theme.hintColor, height: 1.4))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Text(title, style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface));
  }

  Widget _settingCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accent,
    required Widget trailing,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: .1)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .025), blurRadius: 14, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: accent.withValues(alpha: .1), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: accent, size: 21)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: GoogleFonts.spaceGrotesk(fontSize: 14.5, fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.spaceGrotesk(fontSize: 10.5, fontWeight: FontWeight.w600, color: theme.hintColor, height: 1.35))])),
          trailing,
        ],
      ),
    );
  }
}
