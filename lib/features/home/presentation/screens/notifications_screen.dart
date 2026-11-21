import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/features/home/data/models/app_notification.dart';
import 'package:pivote/features/home/presentation/providers/notifications_provider.dart';
import 'package:pivote/features/soccer/presentation/providers/soccer_provider.dart';
import 'package:pivote/shared/widgets/common/apple_pressable.dart';
import 'package:pivote/shared/widgets/common/pivote_surfaces.dart';

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
    final notificationsProvider = context.watch<NotificationsProvider>();
    final dynamicItems = notificationsProvider.items;
    final hasUnread = dynamicItems.any((e) => !e.isRead);
    final hPad = AppResponsive.screenHorizontalPadding(context);
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final accent = AppTheme.accent(context);

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: PivoteAmbientBackdrop(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                hPad.horizontal / 2,
                topPad + 6,
                hPad.horizontal / 2,
                bottomPad + 32,
              ),
              children: [
                PivoteSubHeader(
                  title: 'Notificaciones',
                  trailing: hasUnread
                      ? PivoteIconButton(
                          icon: Icons.done_all_rounded,
                          active: true,
                          tooltip: 'Marcar todas como leídas',
                          onTap: () {
                            HapticFeedback.lightImpact();
                            notificationsProvider.markAllAsRead();
                          },
                        )
                      : null,
                ),

                // Hero comunicado con difuminación MatchesHero
                PivoteDiffusedCard(
                  borderRadius: AppRadius.hero,
                  glowColor: accent,
                  glowAlignment: const Alignment(-0.85, -0.7),
                  glowOpacity: 1.35,
                  highlighted: true,
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.accentDim(context),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.32),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          size: 22,
                          color: accent,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.accentDim(context),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.pill),
                              ),
                              child: Text(
                                'COMUNICADO OFICIAL',
                                style: AppFont.mono(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: accent,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Experiencia renovada en Pivote',
                              style: AppFont.primary(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.25,
                                color: AppTheme.textPrimary(context),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Optimizamos cada sección con un diseño limpio, coherente y rápido en modo claro y oscuro.',
                              style: AppFont.primary(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                height: 1.45,
                                color: AppTheme.textSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),
                const PivoteSectionHeader(title: 'Novedades y mejoras'),
                const SizedBox(height: 12),

                const PivoteDiffusedCard(
                  borderRadius: AppRadius.lg,
                  glowOpacity: 0.65,
                  child: Column(
                    children: [
                      _AnnouncementTile(
                        icon: Icons.live_tv_rounded,
                        badgeText: 'SEÑALES',
                        title: 'Canales en vivo optimizados',
                        body:
                            'Actualizamos señales en vivo y enlaces de transmisión para una reproducción más estable.',
                        timeLabel: 'Activo',
                        showBottomDivider: true,
                      ),
                      _AnnouncementTile(
                        icon: Icons.sports_soccer_rounded,
                        badgeText: 'DEPORTES',
                        title: 'Cobertura completa de fútbol en vivo',
                        body:
                            'Agendas diarias actualizadas, marcadores al instante y acceso directo a los canales.',
                        timeLabel: 'Destacado',
                        showBottomDivider: true,
                      ),
                      _AnnouncementTile(
                        icon: Icons.tune_rounded,
                        badgeText: 'DISEÑO',
                        title: 'Interfaz unificada de nueva generación',
                        body:
                            'Paleta unificada, cargas con skeleton shimmer, toasts flotantes y controles modernos.',
                        timeLabel: 'Nuevo',
                        showBottomDivider: false,
                      ),
                    ],
                  ),
                ),

                if (dynamicItems.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  PivoteSectionHeader(
                    title: 'Avisos recientes',
                    badgeText: '${dynamicItems.length}',
                    isLive: hasUnread,
                  ),
                  const SizedBox(height: 12),
                  PivoteDiffusedCard(
                    borderRadius: AppRadius.lg,
                    glowOpacity: 0.55,
                    child: Column(
                      children: [
                        for (int i = 0; i < dynamicItems.length; i++)
                          _DynamicNotificationRow(
                            item: dynamicItems[i],
                            showBottomDivider: i < dynamicItems.length - 1,
                            onTap: () => notificationsProvider
                                .markAsRead(dynamicItems[i].id),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnnouncementTile extends StatelessWidget {
  final IconData icon;
  final String badgeText;
  final String title;
  final String body;
  final String timeLabel;
  final bool showBottomDivider;

  const _AnnouncementTile({
    required this.icon,
    required this.badgeText,
    required this.title,
    required this.body,
    required this.timeLabel,
    required this.showBottomDivider,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.accent(context);
    return Container(
      decoration: BoxDecoration(
        border: showBottomDivider
            ? Border(
                bottom: BorderSide(color: AppTheme.border(context), width: 1),
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
              color: AppTheme.accentDim(context),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: accent.withValues(alpha: 0.25)),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 19, color: accent),
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
                      style: AppFont.mono(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.45,
                        color: accent,
                      ),
                    ),
                    Text(
                      timeLabel,
                      style: AppFont.primary(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textTertiary(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: AppFont.primary(
                    fontSize: 14.8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: AppTheme.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: AppFont.primary(
                    fontSize: 12.8,
                    fontWeight: FontWeight.w500,
                    height: 1.42,
                    color: AppTheme.textSecondary(context),
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
  final bool showBottomDivider;
  final VoidCallback onTap;

  const _DynamicNotificationRow({
    required this.item,
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
    final danger = AppTheme.danger(context);

    return ApplePressable(
      scaleDownFactor: 0.985,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: showBottomDivider
              ? Border(
                  bottom: BorderSide(color: AppTheme.border(context), width: 1),
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
                color: AppTheme.surface2(context),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppTheme.border(context)),
              ),
              alignment: Alignment.center,
              child: Icon(
                _iconForType(item.type),
                size: 19,
                color: item.isRead
                    ? AppTheme.textTertiary(context)
                    : AppTheme.accent(context),
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
                            fontSize: 14.2,
                            fontWeight:
                                item.isRead ? FontWeight.w600 : FontWeight.w800,
                            color: AppTheme.textPrimary(context),
                          ),
                        ),
                      ),
                      if (!item.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 8),
                          decoration: BoxDecoration(
                            color: danger,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.body,
                    style: AppFont.primary(
                      fontSize: 12.6,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                      color: AppTheme.textSecondary(context),
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
}
