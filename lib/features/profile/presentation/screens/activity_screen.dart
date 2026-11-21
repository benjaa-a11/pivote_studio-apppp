import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/core/services/app_activity_service.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:pivote/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:pivote/features/profile/presentation/screens/diagnostics_screen.dart';
import 'package:pivote/features/profile/presentation/screens/history_screen.dart';
import 'package:pivote/features/profile/presentation/widgets/profile_design_system.dart';
import 'package:pivote/shared/widgets/common/pivote_surfaces.dart';

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
      title: 'Campeón del Mundo',
      subtitle: 'Más de 8 horas · Nivel Leyenda',
      minMinutes: 480,
      maxMinutes: 999999,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.accent(context);
    final danger = AppTheme.danger(context);
    final favCount = context.watch<FavoritesProvider>().favoriteIds.length;
    final activityService = context.watch<AppActivityService>();
    final totalMinutes = activityService.totalActiveSeconds / 60.0;

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

    return ProfileSubsectionScaffold(
      title: 'Actividad y rango',
      subtitle: 'Estadísticas y evolución en tiempo real',
      children: [
        // 1. Hero de tiempo activo estilo MatchesHero
        AppAnimations.staggeredSlideIn(
          index: 0,
          child: PivoteDiffusedCard(
            borderRadius: AppRadius.hero,
            glowColor: accent,
            glowAlignment: const Alignment(0.0, -0.85),
            glowOpacity: 1.4,
            highlighted: true,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bolt_rounded, color: accent, size: 17),
                    const SizedBox(width: 6),
                    Text(
                      'TIEMPO DE USO TOTAL',
                      style: AppFont.mono(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: accent,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  activityService.getFormattedActiveTime(),
                  style: AppFont.mono(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary(context),
                    letterSpacing: -1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.accentDim(context),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.30),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        'Sincronizando en vivo',
                        style: AppFont.primary(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // 2. Rango actual
        AppAnimations.staggeredSlideIn(
          index: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ProfileSectionTitle('Nivel de experiencia'),
              PivoteDiffusedCard(
                borderRadius: AppRadius.lg,
                glowOpacity: 0.85,
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: AppTheme.accentDim(context),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.30),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            activityService.getArgentineRankEmoji(),
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'RANGO ACTUAL',
                                style: AppFont.mono(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: accent,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                activityService.getArgentineRank(),
                                style: AppFont.primary(
                                  fontSize: 17.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary(context),
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
                        activityService.getArgentineRankDescription(),
                        style: AppFont.primary(
                          fontSize: 12.8,
                          color: AppTheme.textSecondary(context),
                          fontWeight: FontWeight.w500,
                          height: 1.42,
                        ),
                      ),
                    ),
                    if (totalMinutes < 480.0) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Siguiente: $nextRankEmoji $nextRank',
                            style: AppFont.primary(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: accent,
                            ),
                          ),
                          Text(
                            'Faltan $remainingMinutes min',
                            style: AppFont.mono(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textTertiary(context),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 7,
                          backgroundColor: AppTheme.surface3(context),
                          valueColor: AlwaysStoppedAnimation<Color>(accent),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        // 3. Estadísticas de consumo (estrictamente 3 colores)
        AppAnimations.staggeredSlideIn(
          index: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ProfileSectionTitle('Consumo'),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.58,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  _StatGridCard(
                    title: 'Sesiones',
                    value: '${activityService.sessionCount}',
                    subtitle: 'Ingresos',
                    icon: Icons.login_rounded,
                    tintColor: accent,
                  ),
                  _StatGridCard(
                    title: 'Canales vistos',
                    value: '${activityService.channelsWatched}',
                    subtitle: 'Ver historial',
                    icon: Icons.tv_rounded,
                    tintColor: accent,
                    onTap: () => Navigator.push(
                      context,
                      AppAnimations.createRoute(const HistoryScreen()),
                    ),
                  ),
                  _StatGridCard(
                    title: 'Radios',
                    value: '${activityService.radiosListened}',
                    subtitle: 'Escuchadas',
                    icon: Icons.radio_rounded,
                    tintColor: accent,
                  ),
                  _StatGridCard(
                    title: 'Favoritos',
                    value: '$favCount',
                    subtitle: 'Ver guardados',
                    icon: Icons.favorite_rounded,
                    tintColor: danger,
                    onTap: () => Navigator.push(
                      context,
                      AppAnimations.createRoute(const FavoritesScreen()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 4. Camino de rangos
        AppAnimations.staggeredSlideIn(
          index: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ProfileSectionTitle('Camino de rangos'),
              ProfileGroupCard(
                children: [
                  for (final tier in _tiers)
                    _buildTierRow(context, tier, totalMinutes),
                ],
              ),
            ],
          ),
        ),

        // 5. Enlace rápido a diagnóstico
        AppAnimations.staggeredSlideIn(
          index: 4,
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: ProfileGroupCard(
              children: [
                ProfileGroupRow(
                  leading: const ProfileSettingIconBox(
                    icon: Icons.speed_rounded,
                    highlight: true,
                  ),
                  title: 'Diagnóstico de streaming',
                  subtitle: 'Medí velocidad, ping y estabilidad de tu red',
                  showChevron: true,
                  onTap: () => Navigator.push(
                    context,
                    AppAnimations.createRoute(const DiagnosticsScreen()),
                  ),
                ),
              ],
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Center(
            child: Text(
              'Miembro de Pivote desde el ${activityService.getFormattedStartDate()}',
              style: AppFont.primary(
                fontSize: 11.5,
                color: AppTheme.textTertiary(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTierRow(
    BuildContext context,
    _RankTier tier,
    double totalMinutes,
  ) {
    final accent = AppTheme.accent(context);
    final isUnlocked = totalMinutes >= tier.minMinutes;
    final isCurrent =
        totalMinutes >= tier.minMinutes && totalMinutes < tier.maxMinutes;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isCurrent || isUnlocked
                  ? AppTheme.accentDim(context)
                  : AppTheme.surface2(context),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: isCurrent
                    ? accent.withValues(alpha: 0.42)
                    : AppTheme.border(context),
              ),
            ),
            alignment: Alignment.center,
            child: Opacity(
              opacity: isUnlocked ? 1.0 : 0.45,
              child: Text(tier.emoji, style: const TextStyle(fontSize: 19)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tier.title,
                  style: AppFont.primary(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isUnlocked
                        ? AppTheme.textPrimary(context)
                        : AppTheme.textTertiary(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tier.subtitle,
                  style: AppFont.primary(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textTertiary(context),
                  ),
                ),
              ],
            ),
          ),
          if (isCurrent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.accentDim(context),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: accent.withValues(alpha: 0.35)),
              ),
              child: Text(
                'ACTUAL',
                style: AppFont.mono(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
              ),
            )
          else if (isUnlocked)
            Icon(Icons.check_circle_rounded, size: 18, color: accent)
          else
            Icon(
              Icons.lock_outline_rounded,
              size: 17,
              color: AppTheme.textTertiary(context),
            ),
        ],
      ),
    );
  }
}

class _StatGridCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color tintColor;
  final VoidCallback? onTap;

  const _StatGridCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.tintColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PivoteDiffusedCard(
      borderRadius: AppRadius.card,
      glowColor: tintColor,
      glowAlignment: const Alignment(-0.85, -0.75),
      glowOpacity: 0.85,
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: tintColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: tintColor, size: 15),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFont.primary(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary(context),
                  ),
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
                style: AppFont.mono(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary(context),
                ),
              ),
              Text(
                subtitle,
                style: AppFont.primary(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: onTap != null
                      ? tintColor
                      : AppTheme.textTertiary(context),
                ),
              ),
            ],
          ),
        ],
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
