import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/features/home/data/models/app_notification.dart';
import 'package:pivote/features/home/presentation/providers/notifications_provider.dart';
import 'package:pivote/features/profile/presentation/widgets/profile_design_system.dart';
import 'package:pivote/features/soccer/presentation/providers/soccer_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final soccerData = context.read<SoccerProvider>().soccerData;
      context.read<NotificationsProvider>().refresh(soccerData: soccerData);
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = ProfilePalette.of(context);
    final notificationsProvider = context.watch<NotificationsProvider>();
    final dynamicItems = notificationsProvider.items;

    return ProfileSubsectionScaffold(
      title: 'Notificaciones',
      trailing: dynamicItems.any((e) => !e.isRead)
          ? Material(
              color: AppColors.accentBg,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  notificationsProvider.markAllAsRead();
                },
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: palette.accent, width: 1),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Marcar leídas',
                    style: AppFont.primary(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accentTint,
                    ),
                  ),
                ),
              ),
            )
          : null,
      children: [
        const SizedBox(height: 6),
        ProfileGroupCard(
          padding: const EdgeInsets.all(18),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: palette.iconBox,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(
                    Icons.rocket_launch_rounded,
                    size: 22,
                    color: AppColors.info,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.positive.withValues(alpha: 0.16),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Text(
                              'COMUNICADO OFICIAL',
                              style: AppFont.primary(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: AppTheme.success(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Estamos trabajando para mejorar esta app',
                        style: AppFont.primary(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.25,
                          color: palette.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Nuestro equipo está optimizando cada sección, mejorando la velocidad de carga y preparando nuevas funciones para vos.',
                        style: AppFont.primary(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.45,
                          color: palette.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        const ProfileSectionTitle('Novedades y mejoras en camino'),
        ProfileGroupCard(
          children: [
            _AnnouncementTile(
              palette: palette,
              icon: Icons.live_tv_rounded,
              iconColor: AppColors.positive,
              badgeText: 'PRIORIDAD #1',
              title: 'Los canales serán arreglados al 100%',
              body:
                  'Estamos revisando y actualizando todas las señales en vivo y enlaces M3U8 para brindarte reproducción inmediata y estabilidad total.',
              timeLabel: 'En progreso',
              showBottomDivider: true,
            ),
            _AnnouncementTile(
              palette: palette,
              icon: Icons.sports_soccer_rounded,
              iconColor: AppColors.warning,
              badgeText: 'DEPORTES',
              title:
                  'El fútbol será algo muy importante en esta app y podrás verlo todo',
              body:
                  'Sumaremos cobertura completa de partidos en vivo, agendas diarias actualizadas y múltiples opciones de señal para cada encuentro.',
              timeLabel: 'Destacado',
              showBottomDivider: true,
            ),
            _AnnouncementTile(
              palette: palette,
              icon: Icons.auto_awesome_rounded,
              iconColor: AppColors.violet,
              badgeText: 'ACTUALIZACIÓN',
              title: 'Pronto se desarrollarán muchas mejoras',
              body:
                  'Nuevo diseño unificado, reproductor más rápido, mejoras en radios y herramientas de diagnóstico avanzadas.',
              timeLabel: 'Muy pronto',
              showBottomDivider: false,
            ),
          ],
        ),
        if (dynamicItems.isNotEmpty) ...[
          const ProfileSectionTitle('Avisos recientes'),
          ProfileGroupCard(
            children: [
              for (int i = 0; i < dynamicItems.length; i++)
                _DynamicNotificationRow(
                  item: dynamicItems[i],
                  palette: palette,
                  showBottomDivider: i < dynamicItems.length - 1,
                  onTap: () {
                    notificationsProvider.markAsRead(dynamicItems[i].id);
                  },
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _AnnouncementTile extends StatelessWidget {
  final ProfilePalette palette;
  final IconData icon;
  final Color iconColor;
  final String badgeText;
  final String title;
  final String body;
  final String timeLabel;
  final bool showBottomDivider;

  const _AnnouncementTile({
    required this.palette,
    required this.icon,
    required this.iconColor,
    required this.badgeText,
    required this.title,
    required this.body,
    required this.timeLabel,
    required this.showBottomDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: showBottomDivider
            ? Border(
                bottom: BorderSide(color: palette.border, width: 1),
              )
            : null,
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: palette.iconBox,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      badgeText,
                      style: AppFont.primary(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: iconColor,
                      ),
                    ),
                    Text(
                      timeLabel,
                      style: AppFont.primary(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: palette.muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: AppFont.primary(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: palette.text,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  body,
                  style: AppFont.primary(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.42,
                    color: palette.muted,
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

class _DynamicNotificationRow extends StatelessWidget {
  final AppNotification item;
  final ProfilePalette palette;
  final bool showBottomDivider;
  final VoidCallback onTap;

  const _DynamicNotificationRow({
    required this.item,
    required this.palette,
    required this.showBottomDivider,
    required this.onTap,
  });

  IconData _iconForType(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.match:
      case AppNotificationType.goal:
        return Icons.sports_soccer_rounded;
      case AppNotificationType.news:
        return Icons.newspaper_rounded;
      case AppNotificationType.system:
        return Icons.notifications_active_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: palette.cardPressed,
        child: Container(
          decoration: BoxDecoration(
            border: showBottomDivider
                ? Border(
                    bottom: BorderSide(color: palette.border, width: 1),
                  )
                : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: palette.iconBox,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  _iconForType(item.type),
                  size: 19,
                  color: palette.text,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: AppFont.primary(
                              fontSize: 14.5,
                              fontWeight: item.isRead
                                  ? FontWeight.w600
                                  : FontWeight.w700,
                              color: palette.text,
                            ),
                          ),
                        ),
                        if (!item.isRead)
                          Container(
                            width: 9,
                            height: 9,
                            margin: const EdgeInsets.only(left: 8),
                            decoration: BoxDecoration(
                              color: AppColors.live,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: palette.card,
                                width: 1.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.body,
                      style: AppFont.primary(
                        fontSize: 12.8,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                        color: palette.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
