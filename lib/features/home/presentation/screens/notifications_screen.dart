import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
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
  Future<void> _refresh() async {
    await context.read<NotificationsProvider>().refresh(
          soccerData: context.read<SoccerProvider>().soccerData,
        );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refresh();
    });
  }

  void _openNews(AppNotification item) {
    context.read<NotificationsProvider>().markAsRead(item.id);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NewsDetailSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;

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
                icon: Icon(Icons.done_all_rounded, color: theme.colorScheme.primary),
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
                  child: _TopSummary(unread: provider.unreadCount),
                ),
                if (provider.error != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: _ErrorBanner(
                        message: provider.error!,
                        onRetry: _refresh,
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, 24 + bottom),
                  sliver: SliverList.builder(
                    itemCount: provider.items.length,
                    itemBuilder: (_, index) {
                      final item = provider.items[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _NotificationCard(
                          item: item,
                          onTap: () => _openNews(item),
                        ),
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

class _TopSummary extends StatelessWidget {
  final int unread;

  const _TopSummary({required this.unread});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Últimas novedades',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  unread == 0
                      ? 'Todo leído'
                      : '$unread noticias pendientes',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: theme.hintColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt_rounded, size: 15, color: theme.colorScheme.primary),
                const SizedBox(width: 4),
                Text(
                  'ACTUALIZADO',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .5,
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

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: unread
                  ? theme.colorScheme.primary.withValues(alpha: 0.18)
                  : theme.dividerColor.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 112,
                height: 112,
                child: item.imageUrl == null || item.imageUrl!.isEmpty
                    ? DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              theme.colorScheme.primary.withValues(alpha: 0.18),
                              theme.colorScheme.primary.withValues(alpha: 0.04),
                            ],
                          ),
                        ),
                        child: Icon(icon, size: 34, color: theme.colorScheme.primary),
                      )
                    : Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => DecoratedBox(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.08),
                          ),
                          child: Icon(icon, size: 34, color: theme.colorScheme.primary),
                        ),
                      ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
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
                                letterSpacing: .65,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          Text(
                            time,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 9.5,
                              color: theme.hintColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 15,
                          height: 1.18,
                          fontWeight: unread ? FontWeight.w800 : FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        item.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11.5,
                          height: 1.35,
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (unread)
                Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.only(top: 15, right: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewsDetailSheet extends StatelessWidget {
  final AppNotification item;

  const _NewsDetailSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final date = DateFormat('EEEE d MMMM · HH:mm', 'es').format(item.publishedAt.toLocal());
    final hasImage = item.imageUrl != null && item.imageUrl!.isNotEmpty;

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(18, 10, 18, 22 + bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.hintColor.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (hasImage)
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              if (hasImage) const SizedBox(height: 18),
              Text(
                item.source.toUpperCase(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .7,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                item.title,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 23,
                  height: 1.14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                date,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  color: theme.hintColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                item.body,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 15,
                  height: 1.55,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.82),
                ),
              ),
            ],
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
    final theme = Theme.of(context);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
      itemCount: 7,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Container(
        height: 140,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(22),
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
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.20),
          Icon(
            Icons.newspaper_rounded,
            size: 68,
            color: theme.colorScheme.primary.withValues(alpha: 0.55),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'No hay novedades todavía',
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
                'Deslizá hacia abajo para actualizar las noticias de fútbol.',
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
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.error.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: ListTile(
        dense: true,
        leading: Icon(Icons.cloud_off_rounded, color: theme.colorScheme.error),
        title: Text(message),
        trailing: TextButton(
          onPressed: onRetry,
          child: const Text('Reintentar'),
        ),
      ),
    );
  }
}
