import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/shared/widgets/common/pivote_app_bar.dart';
import 'package:pivote/features/home/data/models/app_notification.dart';
import 'package:pivote/features/home/presentation/providers/notifications_provider.dart';
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
      context.read<NotificationsProvider>().refresh(
            soccerData: context.read<SoccerProvider>().soccerData,
          );
    });
  }

  Future<void> _refresh() async {
    await context.read<NotificationsProvider>().refresh(
          soccerData: context.read<SoccerProvider>().soccerData,
        );
  }

  Future<void> _open(AppNotification item) async {
    await context.read<NotificationsProvider>().markAsRead(item.id);
    final url = item.deepLink;
    if (url != null) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PivoteAppBar(
        title: 'Notificaciones',
        actions: [
          Consumer<NotificationsProvider>(
            builder: (_, provider, __) {
              if (provider.unreadCount == 0) return const SizedBox.shrink();
              return IconButton(
                tooltip: 'Marcar todo como leído',
                onPressed: provider.markAllAsRead,
                icon: Icon(
                  Icons.done_all_rounded,
                  color: theme.colorScheme.primary,
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.items.isEmpty) {
            return const _LoadingView();
          }
          if (provider.items.isEmpty) {
            return _EmptyView(onRefresh: _refresh);
          }

          return RefreshIndicator.adaptive(
            onRefresh: _refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _Header(
                    isDark: isDark,
                    unread: provider.unreadCount,
                  ),
                ),
                if (provider.error != null)
                  SliverToBoxAdapter(
                    child: _ErrorBanner(
                      message: provider.error!,
                      onRetry: _refresh,
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                  sliver: SliverList.builder(
                    itemCount: provider.items.length,
                    itemBuilder: (_, index) {
                      final item = provider.items[index];
                      return _NotificationCard(
                        item: item,
                        onTap: () => _open(item),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool isDark;
  final int unread;

  const _Header({required this.isDark, required this.unread});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Centro de novedades',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.7,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  unread == 0 ? 'Estás al día.' : '$unread novedades sin leer',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppTheme.darkText3 : AppTheme.lightText3,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt_rounded, size: 15, color: theme.colorScheme.primary),
                const SizedBox(width: 4),
                Text(
                  'EN VIVO',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
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

class _NotificationCard extends StatelessWidget {
  final AppNotification item;
  final VoidCallback onTap;

  const _NotificationCard({required this.item, required this.onTap});

  IconData get icon => switch (item.type) {
        AppNotificationType.news => Icons.article_rounded,
        AppNotificationType.match => Icons.sports_soccer_rounded,
        AppNotificationType.goal => Icons.flash_on_rounded,
        AppNotificationType.system => Icons.notifications_active_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unread = !item.isRead;
    final time = DateFormat('dd MMM · HH:mm', 'es').format(item.publishedAt.toLocal());

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: unread
            ? theme.colorScheme.primary.withValues(alpha: .055)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: unread
                    ? theme.colorScheme.primary.withValues(alpha: .16)
                    : theme.dividerColor.withValues(alpha: .08),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: item.imageUrl != null
                      ? Image.network(
                          item.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            icon,
                            color: theme.colorScheme.primary,
                          ),
                        )
                      : Icon(icon, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.source.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: .6,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          Text(
                            time,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 10,
                              color: theme.hintColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 15,
                          height: 1.2,
                          fontWeight: unread ? FontWeight.w800 : FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          height: 1.35,
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (unread) ...[
                  const SizedBox(width: 7),
                  Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
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

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 7,
      itemBuilder: (_, __) => Container(
        height: 100,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _EmptyView({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RefreshIndicator.adaptive(
      onRefresh: onRefresh,
      child: ListView(
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * .22),
          Icon(
            Icons.notifications_off_rounded,
            size: 64,
            color: theme.colorScheme.primary.withValues(alpha: .55),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'Todo tranquilo por acá',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 42),
              child: Text(
                'Cuando haya noticias o actividad futbolera importante, aparecerá acá.',
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  color: theme.hintColor,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        color: Theme.of(context).colorScheme.error.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          dense: true,
          leading: const Icon(Icons.cloud_off_rounded),
          title: Text(message),
          trailing: TextButton(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ),
      ),
    );
  }
}
