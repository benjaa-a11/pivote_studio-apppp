import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/core/services/app_activity_service.dart';
import 'package:pivote/core/services/cache_manager_service.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/core/theme/theme_provider.dart';
import 'package:pivote/features/auth/data/services/auth_service.dart';
import 'package:pivote/features/auth/presentation/providers/user_provider.dart';
import 'package:pivote/features/favorites/data/services/viewing_history_service.dart';
import 'package:pivote/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:pivote/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:pivote/features/radio/presentation/providers/radio_provider.dart';
import 'package:pivote/features/video/presentation/providers/channel_provider.dart';
import 'package:pivote/features/profile/presentation/screens/about_screen.dart';
import 'package:pivote/features/profile/presentation/screens/activity_screen.dart';
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
import 'package:pivote/shared/widgets/common/apple_pressable.dart';
import 'package:pivote/shared/widgets/common/pivote_surfaces.dart';

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
    if (hours > 0) return '${hours}h';
    final minutes = (totalSeconds ~/ 60).clamp(1, 59);
    return '${minutes}m';
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
      if (!context.mounted) return;
      final userProvider = context.read<UserProvider>();
      final channelProvider = context.read<ChannelProvider>();
      final radioProvider = context.read<RadioProvider>();
      final favProvider = context.read<FavoritesProvider>();
      final activityService = context.read<AppActivityService>();

      await AuthService.logout();
      channelProvider.clearOnLogout();
      radioProvider.clearOnLogout();
      favProvider.clearLocalFavorites();
      await ViewingHistoryService.clearLocalCache();
      await activityService.onUserLogout();
      await userProvider.clearUser();

      if (!context.mounted) return;
      AppNotifications.showInfo(context, 'Sesión cerrada correctamente');
      // Volvemos a la raíz (_AuthenticationWrapper), que mostrará LoginScreen
      // manteniendo el guardián de autenticación siempre activo.
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
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
    final email = user?.email ?? '';
    final initial = displayName[0].toUpperCase();

    final isVip = user?.isVip == true ||
        user?.userType.toLowerCase() == 'vip' ||
        user?.userType.toLowerCase() == 'admin';

    final topPadding = MediaQuery.paddingOf(context).top;
    final hPad = AppResponsive.horizontalPadding(context);
    final accent = AppTheme.accent(context);
    final danger = AppTheme.danger(context);

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
                hPad,
                topPadding + 14,
                hPad,
                114,
              ),
              children: [
                // ---------- Header principal unificado ----------
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Perfil',
                            style: AppFont.primary(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.7,
                              height: 1.05,
                              color: AppTheme.textPrimary(context),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Tu cuenta y preferencias',
                            style: AppFont.primary(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textTertiary(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    PivoteIconButton(
                      icon: Icons.edit_outlined,
                      tooltip: 'Editar perfil',
                      onTap: () => _open(const EditProfileScreen()),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // ---------- Hero Identity Card estilo MatchesHero ----------
                AppAnimations.staggeredSlideIn(
                  index: 0,
                  child: PivoteDiffusedCard(
                    borderRadius: AppRadius.hero,
                    glowColor: accent,
                    secondaryGlowColor: isVip ? accent : null,
                    glowAlignment: const Alignment(-0.85, -0.75),
                    secondaryGlowAlignment: const Alignment(0.9, 0.85),
                    glowOpacity: 1.35,
                    highlighted: isVip,
                    child: Column(
                      children: [
                        // Identidad superior
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                          child: Row(
                            children: [
                              ProfileAvatarWithRing(
                                size: 70,
                                avatarBytes: userProvider.avatarBytes,
                                imagePath: userProvider.profileImagePath,
                                photoUrl: user?.photoUrl,
                                fallbackInitial: initial,
                                onTap: () => _open(const EditProfileScreen()),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppFont.primary(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.45,
                                        color: AppTheme.textPrimary(context),
                                      ),
                                    ),
                                    if (email.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        email,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppFont.primary(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.textTertiary(context),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        ProfilePlanBadge(isVip: isVip),
                                        const SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: () {
                                            HapticFeedback.selectionClick();
                                            _open(const ActivityScreen());
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 9,
                                              vertical: 4.5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.surface2(context),
                                              borderRadius: BorderRadius.circular(
                                                AppRadius.pill,
                                              ),
                                              border: Border.all(
                                                color: AppTheme.border(context),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.bolt_rounded,
                                                  size: 13,
                                                  color: accent,
                                                ),
                                                const SizedBox(width: 3),
                                                Text(
                                                  'Mi rango',
                                                  style: AppFont.primary(
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppTheme.textSecondary(
                                                      context,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Divisor hairline 1px estilo MatchesHero
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: AppTheme.border(context),
                        ),

                        // Barra de métricas interactivas integrada
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 10,
                          ),
                          child: IntrinsicHeight(
                            child: Row(
                              children: [
                                Expanded(
                                  child: _HeroStatCell(
                                    value: _formatActiveHours(
                                      activityService.totalActiveSeconds,
                                    ),
                                    label: 'Actividad',
                                    highlight: true,
                                    onTap: () => _open(const ActivityScreen()),
                                  ),
                                ),
                                VerticalDivider(
                                  width: 1,
                                  thickness: 1,
                                  indent: 6,
                                  endIndent: 6,
                                  color: AppTheme.border(context),
                                ),
                                Expanded(
                                  child: _HeroStatCell(
                                    value: '${favProvider.favoriteIds.length}',
                                    label: 'Favoritos',
                                    onTap: () => _open(const FavoritesScreen()),
                                  ),
                                ),
                                VerticalDivider(
                                  width: 1,
                                  thickness: 1,
                                  indent: 6,
                                  endIndent: 6,
                                  color: AppTheme.border(context),
                                ),
                                Expanded(
                                  child: _HeroStatCell(
                                    value: '$_historyCount',
                                    label: 'Historial',
                                    onTap: () => _open(const HistoryScreen()),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ---------- Sección 1: Preferencias ----------
                AppAnimations.staggeredSlideIn(
                  index: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ProfileSectionTitle('Preferencias'),
                      ProfileGroupCard(
                        children: [
                          ProfileGroupRow(
                            leading: const ProfileSettingIconBox(
                              icon: Icons.palette_outlined,
                              highlight: true,
                            ),
                            title: 'Apariencia',
                            subtitle: 'Tema visual y escala de texto',
                            valueText: themeProvider.themeModeLabel,
                            showChevron: true,
                            onTap: () =>
                                _open(const AppearanceSettingsScreen()),
                          ),
                          ProfileGroupRow(
                            leading: const ProfileSettingIconBox(
                              icon: Icons.notifications_none_rounded,
                            ),
                            title: 'Notificaciones',
                            subtitle: 'Alertas en vivo y horario silencioso',
                            showChevron: true,
                            onTap: () =>
                                _open(const NotificationsSettingsScreen()),
                          ),
                          ProfileGroupRow(
                            leading: const ProfileSettingIconBox(
                              icon: Icons.bolt_rounded,
                            ),
                            title: 'Actividad y rango',
                            subtitle: activityService.getArgentineRank(),
                            showChevron: true,
                            onTap: () => _open(const ActivityScreen()),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ---------- Sección 2: Rendimiento ----------
                AppAnimations.staggeredSlideIn(
                  index: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ProfileSectionTitle('Sistema y streaming'),
                      ProfileGroupCard(
                        children: [
                          ProfileGroupRow(
                            leading: const ProfileSettingIconBox(
                              icon: Icons.storage_rounded,
                            ),
                            title: 'Almacenamiento',
                            subtitle: 'Caché local e imágenes',
                            valueText: _cacheSize,
                            showChevron: true,
                            onTap: () => _open(const StorageManagerScreen()),
                          ),
                          ProfileGroupRow(
                            leading: const ProfileSettingIconBox(
                              icon: Icons.speed_rounded,
                            ),
                            title: 'Diagnóstico de red',
                            subtitle: 'Velocidad, latencia y estabilidad',
                            showChevron: true,
                            onTap: () => _open(const DiagnosticsScreen()),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ---------- Sección 3: Cuenta ----------
                AppAnimations.staggeredSlideIn(
                  index: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ProfileSectionTitle('Cuenta'),
                      ProfileGroupCard(
                        children: [
                          ProfileGroupRow(
                            leading: const ProfileSettingIconBox(
                              icon: Icons.person_outline_rounded,
                            ),
                            title: 'Editar perfil',
                            subtitle: 'Nombre, correo y foto',
                            showChevron: true,
                            onTap: () => _open(const EditProfileScreen()),
                          ),
                          ProfileGroupRow(
                            leading: const ProfileSettingIconBox(
                              icon: Icons.shield_outlined,
                            ),
                            title: 'Privacidad y seguridad',
                            subtitle: 'Contraseña y dispositivos',
                            showChevron: true,
                            onTap: () => _open(const PrivacySecurityScreen()),
                          ),
                          ProfileGroupRow(
                            leading: const ProfileSettingIconBox(
                              icon: Icons.info_outline_rounded,
                            ),
                            title: 'Acerca de Pivote',
                            valueText: 'v1.0.0',
                            showChevron: true,
                            onTap: () => _open(const AboutScreen()),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ---------- Cerrar sesión ----------
                AppAnimations.staggeredSlideIn(
                  index: 4,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: ProfileActionButton(
                      label: 'Cerrar sesión',
                      variant: ProfileButtonVariant.danger,
                      leadingIcon: Icon(
                        Icons.logout_rounded,
                        size: 19,
                        color: danger,
                      ),
                      onTap: () => _showLogoutDialog(context),
                    ),
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

class _HeroStatCell extends StatelessWidget {
  final String value;
  final String label;
  final bool highlight;
  final VoidCallback? onTap;

  const _HeroStatCell({
    required this.value,
    required this.label,
    this.highlight = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ApplePressable(
      scaleDownFactor: 0.95,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFont.mono(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: highlight
                    ? AppTheme.accent(context)
                    : AppTheme.textPrimary(context),
              ),
            ),
            const SizedBox(height: 2.5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFont.primary(
                fontSize: 11.8,
                fontWeight: FontWeight.w600,
                color: AppTheme.textTertiary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
