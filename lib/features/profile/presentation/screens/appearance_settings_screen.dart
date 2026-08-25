import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pivote/core/theme/app_theme.dart';
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
    final primaryColor = isDark ? AppTheme.darkAccent : theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const PivoteAppBar(
        title: 'Apariencia',
        subtitle: 'Personalizá cómo se ve y funciona Pivote',
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF161F1A), const Color(0xFF0E1310)]
                    : [const Color(0xFFE9F9D6), Colors.white],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: primaryColor.withValues(alpha: .18),
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: isDark ? 0.08 : 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.palette_rounded,
                      color: primaryColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tu estilo visual',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.4,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Elegí el tema que mejor se adapte a tus ojos y horario.',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: theme.hintColor,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),

          // Theme Preview Selector Cards
          _sectionTitle(context, 'Modo de tema'),
          const SizedBox(height: 12),
          Row(
            children: [
              // Dark Theme Option Card
              Expanded(
                child: _themeCard(
                  context,
                  title: 'Modo Oscuro',
                  subtitle: 'Ideal de noche',
                  icon: Icons.dark_mode_rounded,
                  isSelected: themeProvider.isDarkMode,
                  cardBg: const Color(0xFF141416),
                  accentColor: AppTheme.darkAccent,
                  onTap: () {
                    if (!themeProvider.isDarkMode) {
                      HapticFeedback.selectionClick();
                      themeProvider.toggleTheme();
                    }
                  },
                ),
              ),
              const SizedBox(width: 14),
              // Light Theme Option Card
              Expanded(
                child: _themeCard(
                  context,
                  title: 'Modo Claro',
                  subtitle: 'Limpio y brillante',
                  icon: Icons.light_mode_rounded,
                  isSelected: !themeProvider.isDarkMode,
                  cardBg: const Color(0xFFF4F6F8),
                  accentColor: const Color(0xFF52B788),
                  onTap: () {
                    if (themeProvider.isDarkMode) {
                      HapticFeedback.selectionClick();
                      themeProvider.toggleTheme();
                    }
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),
          _sectionTitle(context, 'Reproducción y Pantalla'),
          const SizedBox(height: 12),
          _settingCard(
            context,
            icon: wakelock.keepScreenOn
                ? Icons.visibility_rounded
                : Icons.visibility_off_rounded,
            title: 'Pantalla siempre activa',
            subtitle: wakelock.keepScreenOn
                ? 'La pantalla no se apagará mientras reproduces contenido'
                : 'La pantalla seguirá el tiempo de apagado del dispositivo',
            accent: wakelock.keepScreenOn
                ? const Color(0xFFFFA726)
                : primaryColor,
            trailing: Switch.adaptive(
              value: wakelock.keepScreenOn,
              activeThumbColor: primaryColor,
              activeTrackColor: primaryColor.withValues(alpha: 0.4),
              onChanged: (val) {
                HapticFeedback.selectionClick();
                wakelock.setKeepScreenOn(val);
              },
            ),
          ),

          const SizedBox(height: 24),
          Container(
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
              children: [
                Icon(Icons.tune_rounded, color: primaryColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Las preferencias se guardan localmente y se aplican en tiempo real en todas las secciones.',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
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

  Widget _sectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: GoogleFonts.spaceGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w900,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _themeCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required Color cardBg,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? accentColor
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06)),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: accentColor, size: 20),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle_rounded,
                        color: accentColor, size: 20),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? accentColor : theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: theme.hintColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent, size: 21),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.hintColor,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
