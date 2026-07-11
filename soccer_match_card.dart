import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pivote/core/services/app_activity_service.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/shared/widgets/common/pivote_app_bar.dart';
import 'package:pivote/features/profile/presentation/screens/diagnostics_screen.dart';
import 'package:pivote/core/theme/app_theme.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const PivoteAppBar(
        title: 'Mi Actividad',
        subtitle: 'Estadísticas e insignias de reproducción',
      ),
      body: Consumer<AppActivityService>(
        builder: (context, activityService, child) {
          final totalMinutes = activityService.totalActiveSeconds / 60.0;
          
          // Rank calculation variables for progression
          double progress = 0.0;
          String nextRank = '';
          String nextRankEmoji = '';
          double nextRankTarget = 0.0;

          if (totalMinutes < 5.0) {
            nextRankTarget = 5.0;
            nextRank = 'Pasador de Facturas';
            nextRankEmoji = '🥐';
            progress = (totalMinutes / 5.0).clamp(0.0, 1.0);
          } else if (totalMinutes < 30.0) {
            nextRankTarget = 30.0;
            nextRank = 'Asador de Fin de Semana';
            nextRankEmoji = '🥩';
            progress = ((totalMinutes - 5.0) / 25.0).clamp(0.0, 1.0);
          } else if (totalMinutes < 120.0) {
            nextRankTarget = 120.0;
            nextRank = 'Convocado a la Scaloneta';
            nextRankEmoji = '🏆';
            progress = ((totalMinutes - 30.0) / 90.0).clamp(0.0, 1.0);
          } else if (totalMinutes < 480.0) {
            nextRankTarget = 480.0;
            nextRank = 'Campeón del Mundo';
            nextRankEmoji = '👑';
            progress = ((totalMinutes - 120.0) / 360.0).clamp(0.0, 1.0);
          } else {
            nextRankTarget = 480.0;
            nextRank = '¡Nivel Máximo!';
            nextRankEmoji = '⭐';
            progress = 1.0;
          }

          final remainingMinutes = (nextRankTarget - totalMinutes).ceil();

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top active usage time card with premium look
                    AppAnimations.smoothFadeInScale(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [
                                    theme.colorScheme.primary.withValues(alpha: 0.12),
                                    theme.colorScheme.primary.withValues(alpha: 0.04),
                                  ]
                                : [
                                    theme.colorScheme.primary.withValues(alpha: 0.08),
                                    theme.colorScheme.primary.withValues(alpha: 0.02),
                                  ],
                          ),
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(alpha: 0.15),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.03 : 0.01),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.bolt_rounded,
                                  color: theme.colorScheme.primary,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'TIEMPO DE USO TOTAL',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: theme.colorScheme.primary,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              activityService.getFormattedActiveTime(),
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 42,
                                fontWeight: FontWeight.w900,
                                color: theme.colorScheme.onSurface,
                                letterSpacing: -1.0,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Actualizando en vivo',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Rango Argento Section Title
                    Text(
                      'Mi Rango',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Rango Argento Card
                    AppAnimations.smoothFadeIn(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Text(
                                  activityService.getArgentineRankEmoji(),
                                  style: const TextStyle(fontSize: 44),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'CATEGORÍA ARGENTINA',
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 8,
                                            fontWeight: FontWeight.w800,
                                            color: theme.colorScheme.primary,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        activityService.getArgentineRank(),
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              activityService.getArgentineRankDescription(),
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                height: 1.4,
                              ),
                            ),

                            // Progress Bar to next Rank (Except for final rank)
                            if (totalMinutes < 480.0) ...[
                              const SizedBox(height: 20),
                              const Divider(height: 1),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Siguiente nivel:',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  Text(
                                    '$nextRankEmoji $nextRank',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Sleek progression bar with gradient track
                              ClipRRect(
                                borderRadius: BorderRadius.circular(100),
                                child: SizedBox(
                                  height: 8,
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                                    valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    'Faltan $remainingMinutes min',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Stats Title
                    Text(
                      'Estadísticas de Uso',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Stats Grid - Responsive grid layout
                    LayoutBuilder(
                      builder: (context, gridConstraints) {
                        final isSmallWidth = gridConstraints.maxWidth < 360;
                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          childAspectRatio: isSmallWidth ? 1.4 : 1.7,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          children: [
                            _buildStatGridCard(
                              context,
                              title: 'Ingresos Totales',
                              value: '${activityService.sessionCount}',
                              icon: Icons.login_rounded,
                              color: const Color(0xFF74ACDF),
                            ),
                            _buildStatGridCard(
                              context,
                              title: 'Canales Vistos',
                              value: '${activityService.channelsWatched}',
                              icon: Icons.tv_rounded,
                              color: const Color(0xFF52C41A),
                            ),
                            _buildStatGridCard(
                              context,
                              title: 'Radios Escuchadas',
                              value: '${activityService.radiosListened}',
                              icon: Icons.radio_outlined,
                              color: const Color(0xFFFAAD14),
                            ),
                            _buildStatGridCard(
                              context,
                              title: 'Fútbol Consultado',
                              value: '${activityService.matchesViewed}',
                              icon: Icons.sports_soccer_rounded,
                              color: const Color(0xFFF5222D),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 28),

                    // Consejo del Día Card
                    AppAnimations.smoothFadeIn(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [
                                    const Color(0xFF74ACDF).withValues(alpha: 0.15),
                                    Colors.transparent,
                                  ]
                                : [
                                    const Color(0xFF74ACDF).withValues(alpha: 0.08),
                                    Colors.transparent,
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFF74ACDF).withValues(alpha: 0.15),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('💡', style: TextStyle(fontSize: 18)),
                                const SizedBox(width: 8),
                                Text(
                                  'Tip de Campo',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF74ACDF),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Preparate un buen mate amargo, sintonizá tu canal favorito y alentá con la pasión de siempre. ¡Pivote Studio te acompaña en cada transmisión!',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Diagnostics Banner (Interactive Connection Diagnostic entry point)
                    AppAnimations.smoothFadeIn(
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [
                                    theme.colorScheme.primary.withValues(alpha: 0.12),
                                    Colors.transparent,
                                  ]
                                : [
                                    theme.colorScheme.primary.withValues(alpha: 0.06),
                                    Colors.transparent,
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.22 : 0.15),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.speed_rounded,
                                color: theme.colorScheme.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '¿Se corta el streaming?',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Realizá un diagnóstico de velocidad y latencia de red.',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 11,
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  AppAnimations.createRoute(
                                    const DiagnosticsScreen(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: isDark ? AppTheme.darkBg : Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'Probar',
                                style: GoogleFonts.spaceGrotesk(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Registry Footer
                    Center(
                      child: Text(
                        'Miembro de Pivote Studio desde el ${activityService.getFormattedStartDate()}',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatGridCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 14),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
