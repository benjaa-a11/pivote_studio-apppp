import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pivote/features/home/presentation/screens/search_screen.dart';
import 'package:pivote/features/home/presentation/screens/notifications_screen.dart';
import 'package:pivote/features/soccer/presentation/providers/soccer_provider.dart';
import 'package:pivote/features/soccer/data/models/soccer_models.dart';
import 'package:pivote/features/soccer/presentation/widgets/matches_hero.dart';
import 'package:pivote/shared/widgets/common/user_avatar.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/core/animations/app_animations.dart';

/// Header premium 2026 unificado para HomeScreen.
/// Presenta:
/// - Izquierda: Avatar de usuario dinámico (foto de perfil si existe o iniciales ej: "BF" si no).
/// - Centro: Marca/Logo elegante "PIVOTE STUDIO".
/// - Derecha: Botón de búsqueda (Lupa) y Botón de notificaciones (Campana).
/// - Todo contenido en una tarjeta flotante de esquinas suavizadas (28px).
class UnifiedHomeHeader extends StatelessWidget {
  const UnifiedHomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.isDark;

    return Consumer<SoccerProvider>(
      builder: (context, soccerProvider, child) {
        final isLoading = soccerProvider.isLoading;
        final soccerData = soccerProvider.soccerData;

        List<SoccerMatch> featuredMatches = [];
        if (!isLoading && soccerData != null) {
          featuredMatches = soccerData.matches.where((match) {
            if (match.shouldRemoveFromHero || match.isAutoFinished) return false;
            final isFeatured = match.isLive ||
                match.isScheduled ||
                (match.isFinished && !match.shouldRemoveFromHero);
            if (!isFeatured) return false;
            return match.tvChannels.any((c) => c.id != null);
          }).toList();
        }

        final hasMatches = isLoading || featuredMatches.isNotEmpty;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : Colors.grey).withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Fila superior: Avatar izquierda | Marca Centro | Lupa + Notificaciones derecha
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Row(
                  children: [
                    // Izquierda: Foto de Perfil / Iniciales
                    const UserAvatar(
                      size: 44,
                      showBorder: true,
                    ),

                    // Centro: Branding Titulo "PIVOTE STUDIO"
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.6),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'PIVOTE STUDIO',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: theme.colorScheme.onSurface,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Derecha: Lupa (Search) + Campana (Notificaciones)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Search Button
                        _buildHeaderIconButton(
                          context: context,
                          theme: theme,
                          isDark: isDark,
                          icon: Icons.search_rounded,
                          heroTag: 'search_icon',
                          onTap: () {
                            Navigator.push(
                              context,
                              AppAnimations.createFadeRoute(const SearchScreen()),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        // Notifications Button
                        _buildHeaderIconButton(
                          context: context,
                          theme: theme,
                          isDark: isDark,
                          icon: Icons.notifications_none_rounded,
                          heroTag: 'notification_icon',
                          onTap: () {
                            Navigator.push(
                              context,
                              AppAnimations.createFadeRoute(
                                  const NotificationsScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Carrusel de partidos o banner de bienvenida
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                child: hasMatches
                    ? const MatchesHero()
                    : _buildWelcomingBanner(context, theme, isDark),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderIconButton({
    required BuildContext context,
    required ThemeData theme,
    required bool isDark,
    required IconData icon,
    required String heroTag,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDark
                ? AppTheme.darkBg2
                : theme.colorScheme.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : theme.colorScheme.primary.withValues(alpha: 0.18),
              width: 1.2,
            ),
          ),
          alignment: Alignment.center,
          child: Hero(
            tag: heroTag,
            child: Icon(
              icon,
              size: 20,
              color: isDark ? AppTheme.darkAccent : theme.colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomingBanner(
      BuildContext context, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: AppGradients.accentGlass(context, isDark: isDark),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? theme.colorScheme.primary.withValues(alpha: 0.15)
              : theme.colorScheme.primary.withValues(alpha: 0.12),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.live_tv_rounded,
              color: theme.colorScheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Transmisión en Vivo 24/7',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.primary,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Disfruta los mejores canales en vivo, eventos deportivos y emisoras de radio.',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
