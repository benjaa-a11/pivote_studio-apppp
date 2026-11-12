import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/core/services/app_activity_service.dart';
import 'package:pivote/core/services/cache_manager_service.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/core/theme/app_typography.dart';
import 'package:pivote/core/theme/theme_provider.dart';
import 'package:pivote/features/auth/data/services/auth_service.dart';
import 'package:pivote/features/auth/presentation/providers/user_provider.dart';
import 'package:pivote/features/auth/presentation/screens/login_screen.dart';
import 'package:pivote/features/favorites/data/services/viewing_history_service.dart';
import 'package:pivote/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:pivote/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:pivote/features/profile/presentation/screens/about_screen.dart';
import 'package:pivote/features/profile/presentation/screens/appearance_settings_screen.dart';
import 'package:pivote/features/profile/presentation/screens/diagnostics_screen.dart';
import 'package:pivote/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:pivote/features/profile/presentation/screens/history_screen.dart';
import 'package:pivote/features/profile/presentation/screens/notifications_settings_screen.dart';
import 'package:pivote/features/profile/presentation/screens/privacy_security_screen.dart';
import 'package:pivote/features/profile/presentation/screens/storage_manager_screen.dart';
import 'package:pivote/features/profile/presentation/widgets/profile_design_system.dart';
import 'package:pivote/shared/widgets/app_notifications.dart';
import 'package:pivote/shared/widgets/common/app_dialogs.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _cacheSize = '0 B';
  int _historyCount = 0;

  @override
  void initState() {
    super.initState();
    _refreshDynamicState();
  }

  Future<void> _refreshDynamicState() async {
    try {
      final results = await Future.wait([
        CacheManagerService.getFormattedCacheSize(),
        ViewingHistoryService.getTopChannels(),
      ]);
      if (mounted) {
        setState(() {
          _cacheSize = results[0] as String;
          _historyCount = (results[1] as List<String>).length;
        });
      }
    } catch (_) {}
  }

  Future<void> _open(Widget screen) async {
    await Navigator.push(context, AppAnimations.createRoute(screen));
    if (mounted) {
      unawaited(_refreshDynamicState());
    }
  }

  String _formatActiveHours(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    if (hours > 0) {
      return '$hours h';
    }
    final minutes = (totalSeconds ~/ 60).clamp(1, 59);
    return '$minutes min';
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final confirmed = await AppDialogs.showConfirm(
      context: context,
      title: '¿Cerrar sesión?',
      message:
          'Tu cuenta permanecerá guardada y podrás volver a entrar cuando quieras.',
      confirmLabel: 'Salir',
      cancelLabel: 'Cancelar',
      isDestructive: true,
      type: AppDialogType.warning,
    );
    if (confirmed == true) {
      await AuthService.logout();
      if (!context.mounted) return;
      await Provider.of<UserProvider>(context, listen: false).clearUser();
      if (!context.mounted) return;
      AppNotifications.showInfo(context, 'Sesión cerrada correctamente');
      unawaited(
        Navigator.of(context).pushAndRemoveUntil(
          AppAnimations.createFadeRoute(const LoginScreen()),
          (route) => false,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = ProfilePalette.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final userProvider = context.watch<UserProvider>();
    final activityService = context.watch<AppActivityService>();
    final favProvider = context.watch<FavoritesProvider>();

    final user = userProvider.user;
    final fullName = [
      if (user?.name.isNotEmpty == true) user!.name,
      if (user?.lastName.isNotEmpty == true) user!.lastName,
    ].join(' ').trim();
    final displayName = fullName.isNotEmpty ? fullName : 'Usuario';
    final initial = displayName[0].toUpperCase();

    final isVip = user?.isVip == true ||
        user?.userType.toLowerCase() == 'vip' ||
        user?.userType.toLowerCase() == 'admin';

    final topPadding = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: palette.bg,
      body: RefreshIndicator(
        color: palette.accent,
        backgroundColor: palette.card,
        onRefresh: _refreshDynamicState,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: ClampingScrollPhysics(),
              ),
              padding: EdgeInsets.fromLTRB(
                AppResponsive.horizontalPadding(context),
                topPadding + 10,
                AppResponsive.horizontalPadding(context),
                112,
              ),
              children: [
                // ---------- Portada + Avatar con anillo ----------
                AppAnimations.staggeredSlideIn(
                  index: 0,
                  child: SizedBox(
                    height: 288, // 210 cover + 78 avatar half-overlap
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.topCenter,
                      children: [
                        const ProfileCoverBanner(),
                        Positioned(
                          top: 132, // 210 - 78
                          child: ProfileAvatarWithRing(
                            size: 156,
                            imagePath: userProvider.profileImagePath,
                            photoUrl: user?.photoUrl,
                            fallbackInitial: initial,
                            onTap: () => _open(const EditProfileScreen()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ---------- Usuario y plan ----------
                AppAnimations.staggeredSlideIn(
                  index: 1,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    child: Column(
                      children: [
                        Text(
                          displayName,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFont.primary(
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.52,
                            color: palette.text,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ProfilePlanBadge(isVip: isVip),
                      ],
                    ),
                  ),
                ),

                // ---------- Estadísticas ----------
                AppAnimations.staggeredSlideIn(
                  index: 2,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 22),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: palette.card,
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: palette.border, width: 1),
                        boxShadow: palette.cardShadow,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _ProfileStatItem(
                              value: _formatActiveHours(
                                activityService.totalActiveSeconds,
                              ),
                              label: 'Tiempo activo',
                            ),
                          ),
                          Expanded(
                            child: _ProfileStatItem(
                              value: '${favProvider.favoriteIds.length}',
                              label: 'Favoritos',
                              onTap: () => _open(const FavoritesScreen()),
                            ),
                          ),
                          Expanded(
                            child: _ProfileStatItem(
                              value: '$_historyCount',
                              label: 'Historial',
                              onTap: () => _open(const HistoryScreen()),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ---------- Lista de ajustes ----------
                AppAnimations.staggeredSlideIn(
                  index: 3,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: ProfileGroupCard(
                      children: [
                        ProfileGroupRow(
                          horizontalGap: 14,
                          leading: const ProfileSettingIconBox(
                            svgString: ProfileSvgIcons.appearance,
                          ),
                          title: 'Apariencia',
                          valueText: themeProvider.themeModeLabel,
                          showChevron: true,
                          onTap: () => _open(const AppearanceSettingsScreen()),
                        ),
                        ProfileGroupRow(
                          horizontalGap: 14,
                          leading: const ProfileSettingIconBox(
                            svgString: ProfileSvgIcons.notifications,
                          ),
                          title: 'Notificaciones',
                          showChevron: true,
                          onTap: () =>
                              _open(const NotificationsSettingsScreen()),
                        ),
                        ProfileGroupRow(
                          horizontalGap: 14,
                          leading: const ProfileSettingIconBox(
                            svgString: ProfileSvgIcons.storage,
                          ),
                          title: 'Almacenamiento',
                          valueText: _cacheSize,
                          showChevron: true,
                          onTap: () => _open(const StorageManagerScreen()),
                        ),
                        ProfileGroupRow(
                          horizontalGap: 14,
                          leading: const ProfileSettingIconBox(
                            svgString: ProfileSvgIcons.diagnostics,
                          ),
                          title: 'Diagnóstico de streaming',
                          showChevron: true,
                          onTap: () => _open(const DiagnosticsScreen()),
                        ),
                        ProfileGroupRow(
                          horizontalGap: 14,
                          leading: const ProfileSettingIconBox(
                            svgString: ProfileSvgIcons.editProfile,
                          ),
                          title: 'Editar perfil',
                          showChevron: true,
                          onTap: () => _open(const EditProfileScreen()),
                        ),
                        ProfileGroupRow(
                          horizontalGap: 14,
                          leading: const ProfileSettingIconBox(
                            svgString: ProfileSvgIcons.privacy,
                          ),
                          title: 'Privacidad y seguridad',
                          showChevron: true,
                          onTap: () => _open(const PrivacySecurityScreen()),
                        ),
                        ProfileGroupRow(
                          horizontalGap: 14,
                          leading: const ProfileSettingIconBox(
                            svgString: ProfileSvgIcons.about,
                          ),
                          title: 'Acerca de',
                          valueText: 'v1.0.0',
                          showChevron: true,
                          onTap: () => _open(const AboutScreen()),
                        ),
                      ],
                    ),
                  ),
                ),

                // ---------- Cerrar sesión ----------
                AppAnimations.staggeredSlideIn(
                  index: 4,
                  child: ProfileActionButton(
                    label: 'Cerrar sesión',
                    variant: ProfileButtonVariant.danger,
                    leadingIcon: ProfileSvgIcons.svg(
                      ProfileSvgIcons.logout,
                      size: 20,
                      color: palette.danger,
                    ),
                    onTap: () => _showLogoutDialog(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileStatItem extends StatefulWidget {
  final String value;
  final String label;
  final VoidCallback? onTap;

  const _ProfileStatItem({
    required this.value,
    required this.label,
    this.onTap,
  });

  @override
  State<_ProfileStatItem> createState() => _ProfileStatItemState();
}

class _ProfileStatItemState extends State<_ProfileStatItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final palette = ProfilePalette.of(context);
    final interactive = widget.onTap != null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: interactive ? (_) => setState(() => _pressed = true) : null,
      onTapUp: interactive ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: interactive ? () => setState(() => _pressed = false) : null,
      onTap: interactive
          ? () {
              HapticFeedback.selectionClick();
              widget.onTap!();
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        decoration: BoxDecoration(
          color: _pressed
              ? (palette.isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFont.primary(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: palette.text,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFont.primary(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: palette.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
