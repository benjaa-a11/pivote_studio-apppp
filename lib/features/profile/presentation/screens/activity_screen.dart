import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pivote/core/services/app_activity_service.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/shared/widgets/common/pivote_app_bar.dart';
import 'package:pivote/features/profile/presentation/screens/diagnostics_screen.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark ? AppTheme.darkAccent : theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const PivoteAppBar(
        title: 'Mi Actividad',
        subtitle: 'Estadísticas, nivel de usuario y tiempo en vivo',
      ),
      body: Consumer<AppActivityService>(
        builder: (context, activityService, child) {
          final totalMinutes = activityService.totalActiveSeconds / 60.0;

          // Rank progression calculation
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
                physics: const ClampingScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top active usage time card
                    AppAnimations.smoothFadeInScale(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 26, horizontal: 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(26),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [
                                    primaryColor.withValues(alpha: 0.16),
                                    theme.colorScheme.surface,
                                  ]
                                : [
                                    primaryColor.withValues(alpha: 0.12),
                                    Colors.white,
                                  ],
                          ),
                          border: Border.all(
                            color: primaryColor.withValues(alpha: 0.22),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: isDark ? 0.08 : 0.04),
                              blurRadius: 20,
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
                                  color: primaryColor,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'TIEMPO DE USO TOTAL',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w900,
                                    color: primaryColor,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              activityService.getFormattedActiveTime(),
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 44,
                                fontWeight: FontWeight.w900,
                                color: theme.colorScheme.onSurface,
                                letterSpacing: -1.0,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(
                                  color: const Color(0xFF10B981)
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 7),
                                  Text(
                                    'Sincronizando en vivo',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF10B981),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),

                    // Rango Section Title
                    Text(
                      'Mi Rango de Usuario',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Rango Card
                    AppAnimations.smoothFadeIn(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.06),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: primaryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Center(
                                    child: Text(
                                      activityService.getArgentineRankEmoji(),
                                      style: const TextStyle(fontSize: 32),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: primaryColor
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'NIVEL DE EXPERIENCIA',
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.w900,
                                            color: primaryColor,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        activityService.getArgentineRank(),
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w900,
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
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.65),
                                height: 1.4,
                              ),
                            ),

                            // Progress Bar to next Rank
                            if (totalMinutes < 480.0) ...[
                              const SizedBox(height: 16),
                              Divider(
                                height: 1,
                                color: theme.dividerColor
                                    .withValues(alpha: 0.08),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Siguiente nivel:',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: theme.hintColor,
                                    ),
                                  ),
                                  Text(
                                    '$nextRankEmoji $nextRank',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(100),
                                child: SizedBox(
                                  height: 8,
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : Colors.black.withValues(alpha: 0.06),
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(primaryColor),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    'Faltan $remainingMinutes min para subir',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: theme.hintColor,
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
                      'Estadísticas de Consumo',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Stats Grid
                    LayoutBuilder(
                      builder: (context, gridConstraints) {
                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          childAspectRatio: 1.5,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          children: [
                            _buildStatGridCard(
                              context,
                              title: 'Sesiones Totales',
                              value: '${activityService.sessionCount}',
                              icon: Icons.login_rounded,
                              color: const Color(0xFF74ACDF),
                              isDark: isDark,
                            ),
                            _buildStatGridCard(
                              context,
                              title: 'Canales Vistos',
                              value: '${activityService.channelsWatched}',
                              icon: Icons.tv_rounded,
                              color: const Color(0xFF52C41A),
                              isDark: isDark,
                            ),
                            _buildStatGridCard(
                              context,
                              title: 'Radios Escuchadas',
                              value: '${activityService.radiosListened}',
                              icon: Icons.radio_outlined,
                              color: const Color(0xFFFAAD14),
                              isDark: isDark,
                            ),
                            _buildStatGridCard(
                              context,
                              title: 'Fútbol Consultado',
                              value: '${activityService.matchesViewed}',
                              icon: Icons.sports_soccer_rounded,
                              color: const Color(0xFFF5222D),
                              isDark: isDark,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Diagnostics Banner
                    AppAnimations.smoothFadeIn(
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: primaryColor.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.speed_rounded,
                                color: primaryColor,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Comprobar Streaming',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Medí velocidad, ping y estabilidad de red.',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 11,
                                      color: theme.hintColor,
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
                                backgroundColor: primaryColor,
                                foregroundColor:
                                    isDark ? Colors.black : Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'Probar',
                                style: GoogleFonts.spaceGrotesk(
                                  fontWeight: FontWeight.w800,
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
                          color: theme.hintColor,
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
    required bool isDark,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
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
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: theme.hintColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
