import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/core/services/app_activity_service.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:pivote/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:pivote/features/profile/presentation/screens/diagnostics_screen.dart';
import 'package:pivote/features/profile/presentation/screens/history_screen.dart';
import 'package:pivote/shared/widgets/common/apple_pressable.dart';
import 'package:pivote/shared/widgets/common/pivote_app_bar.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  static const List<_RankTier> _tiers = [
    _RankTier(
      emoji: '🧉',
      title: 'Cebador de Mate',
      subtitle: '0 a 5 min de transmisión activa',
      minMinutes: 0,
      maxMinutes: 5,
    ),
    _RankTier(
      emoji: '🥐',
      title: 'Pasador de Facturas',
      subtitle: '5 a 30 min disfrutando contenido',
      minMinutes: 5,
      maxMinutes: 30,
    ),
    _RankTier(
      emoji: '🥩',
      title: 'Asador de Fin de Semana',
      subtitle: '30 a 120 min frente a la pantalla',
      minMinutes: 30,
      maxMinutes: 120,
    ),
    _RankTier(
      emoji: '🏆',
      title: 'Convocado a la Scaloneta',
      subtitle: '2 a 8 horas de pasión en vivo',
      minMinutes: 120,
      maxMinutes: 480,
    ),
    _RankTier(
      emoji: '👑',
      title: 'Campeón del Mundo ⭐⭐⭐',
      subtitle: 'Más de 8 horas · Nivel Leyenda',
      minMinutes: 480,
      maxMinutes: 999999,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor =
        isDark ? AppTheme.darkAccent : theme.colorScheme.primary;
    final favCount = context.watch<FavoritesProvider>().favoriteIds.length;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const PivoteAppBar(
        title: 'Mi Actividad y Rango',
        subtitle: 'Estadísticas en tiempo real y evolución de usuario',
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
              constraints: const BoxConstraints(maxWidth: 620),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Top active usage time card
                    AppAnimations.staggeredSlideIn(
                      index: 0,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 24, horizontal: 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(26),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [
                                    const Color(0xFF18221D),
                                    const Color(0xFF131722),
                                  ]
                                : [
                                    primaryColor.withValues(alpha: 0.14),
                                    Colors.white,
                                  ],
                          ),
                          border: Border.all(
                            color: primaryColor.withValues(alpha: 0.25),
                          ),
                          boxShadow:
                              AppShadows.appleDepth(context, elevation: 0.9),
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
                                    letterSpacing: 1.8,
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
                                letterSpacing: -1.2,
                              ),
                            ),
                            const SizedBox(height: 10),
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
                                    'Sincronizando actividad en vivo',
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
                    const SizedBox(height: 24),

                    // 2. Current Rank Card
                    AppAnimations.staggeredSlideIn(
                      index: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle(theme, 'NIVEL DE EXPERIENCIA'),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF131722)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF1E2533)
                                    : AppTheme.lightBorder,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 58,
                                      height: 58,
                                      decoration: BoxDecoration(
                                        color: primaryColor.withValues(
                                            alpha: 0.12),
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: Center(
                                        child: Text(
                                          activityService
                                              .getArgentineRankEmoji(),
                                          style: const TextStyle(fontSize: 30),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: primaryColor.withValues(
                                                  alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(7),
                                            ),
                                            child: Text(
                                              'RANGO ACTUAL',
                                              style: GoogleFonts.spaceGrotesk(
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.w900,
                                                color: primaryColor,
                                                letterSpacing: 0.8,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            activityService.getArgentineRank(),
                                            style: GoogleFonts.spaceGrotesk(
                                              fontSize: 17.5,
                                              fontWeight: FontWeight.w900,
                                              color:
                                                  theme.colorScheme.onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    activityService
                                        .getArgentineRankDescription(),
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 12,
                                      color: theme.hintColor,
                                      fontWeight: FontWeight.w600,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                                if (totalMinutes < 480.0) ...[
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Siguiente: $nextRankEmoji $nextRank',
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                          color: primaryColor,
                                        ),
                                      ),
                                      Text(
                                        'Faltan $remainingMinutes min',
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: theme.hintColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(100),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 8,
                                      backgroundColor: isDark
                                          ? Colors.white.withValues(alpha: 0.08)
                                          : Colors.black.withValues(alpha: 0.06),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          primaryColor),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 3. Stats Grid (Connected to History & Favorites!)
                    AppAnimations.staggeredSlideIn(
                      index: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle(theme, 'ESTADÍSTICAS DE CONSUMO'),
                          const SizedBox(height: 10),
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            childAspectRatio: 1.55,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            children: [
                              _buildStatGridCard(
                                context,
                                title: 'Sesiones Totales',
                                value: '${activityService.sessionCount}',
                                subtitle: 'Ingresos a la app',
                                icon: Icons.login_rounded,
                                color: const Color(0xFF74ACDF),
                                isDark: isDark,
                              ),
                              _buildStatGridCard(
                                context,
                                title: 'Canales Vistos',
                                value: '${activityService.channelsWatched}',
                                subtitle: 'Ver historial →',
                                icon: Icons.tv_rounded,
                                color: const Color(0xFF10B981),
                                isDark: isDark,
                                onTap: () => Navigator.push(
                                  context,
                                  AppAnimations.createRoute(
                                      const HistoryScreen()),
                                ),
                              ),
                              _buildStatGridCard(
                                context,
                                title: 'Radios Escuchadas',
                                value: '${activityService.radiosListened}',
                                subtitle: 'Emisoras en vivo',
                                icon: Icons.radio_outlined,
                                color: const Color(0xFFFAAD14),
                                isDark: isDark,
                              ),
                              _buildStatGridCard(
                                context,
                                title: 'Mis Favoritos',
                                value: '$favCount',
                                subtitle: 'Ver guardados →',
                                icon: Icons.favorite_rounded,
                                color: const Color(0xFFEF4444),
                                isDark: isDark,
                                onTap: () => Navigator.push(
                                  context,
                                  AppAnimations.createRoute(
                                      const FavoritesScreen()),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 4. Complete Rank Roadmap ("Camino de Rangos")
                    AppAnimations.staggeredSlideIn(
                      index: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle(theme, 'CAMINO DE RANGOS'),
                          const SizedBox(height: 10),
                          Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF131722)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF1E2533)
                                    : AppTheme.lightBorder,
                              ),
                            ),
                            child: Column(
                              children: [
                                for (int i = 0; i < _tiers.length; i++) ...[
                                  _buildTierRow(
                                    theme,
                                    isDark,
                                    primaryColor,
                                    _tiers[i],
                                    totalMinutes,
                                  ),
                                  if (i < _tiers.length - 1)
                                    Divider(
                                      height: 1,
                                      indent: 62,
                                      endIndent: 16,
                                      color: theme.dividerColor
                                          .withValues(alpha: 0.06),
                                    ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // 5. Connected Diagnostics Banner
                    AppAnimations.staggeredSlideIn(
                      index: 4,
                      child: ApplePressable(
                        scaleDownFactor: 0.98,
                        borderRadius: BorderRadius.circular(22),
                        onTap: () {
                          Navigator.push(
                            context,
                            AppAnimations.createRoute(
                                const DiagnosticsScreen()),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color:
                                isDark ? const Color(0xFF131722) : Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: primaryColor.withValues(alpha: 0.22),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: Icon(
                                  Icons.speed_rounded,
                                  color: primaryColor,
                                  size: 21,
                                ),
                              ),
                              const SizedBox(width: 13),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Comprobar estado de Streaming',
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    Text(
                                      'Medí velocidad, ping y estabilidad de tu red.',
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: theme.hintColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios_rounded,
                                  size: 13, color: primaryColor),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

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
                  ],
                ),
              ),
            ),
          );
        },
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

  Widget _buildTierRow(
    ThemeData theme,
    bool isDark,
    Color primaryColor,
    _RankTier tier,
    double totalMinutes,
  ) {
    final isUnlocked = totalMinutes >= tier.minMinutes;
    final isCurrent =
        totalMinutes >= tier.minMinutes && totalMinutes < tier.maxMinutes;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isCurrent
                  ? primaryColor.withValues(alpha: 0.16)
                  : (isUnlocked
                      ? const Color(0xFF10B981).withValues(alpha: 0.12)
                      : theme.colorScheme.onSurface.withValues(alpha: 0.05)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                tier.emoji,
                style: TextStyle(
                  fontSize: 19,
                  color: isUnlocked ? null : Colors.grey,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tier.title,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: isUnlocked
                        ? theme.colorScheme.onSurface
                        : theme.hintColor,
                  ),
                ),
                Text(
                  tier.subtitle,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: theme.hintColor,
                  ),
                ),
              ],
            ),
          ),
          if (isCurrent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'ACTUAL',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: primaryColor,
                ),
              ),
            )
          else if (isUnlocked)
            const Icon(
              Icons.check_circle_rounded,
              size: 18,
              color: Color(0xFF10B981),
            )
          else
            Icon(
              Icons.lock_outline_rounded,
              size: 17,
              color: theme.hintColor.withValues(alpha: 0.45),
            ),
        ],
      ),
    );
  }

  Widget _buildStatGridCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);

    return ApplePressable(
      scaleDownFactor: 0.96,
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131722) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF1E2533) : AppTheme.lightBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, color: color, size: 15),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: theme.hintColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: onTap != null ? color : theme.hintColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RankTier {
  final String emoji;
  final String title;
  final String subtitle;
  final double minMinutes;
  final double maxMinutes;

  const _RankTier({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.minMinutes,
    required this.maxMinutes,
  });
}
