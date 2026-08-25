import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/core/services/cache_manager_service.dart';
import 'package:pivote/core/services/greeting_service.dart';
import 'package:pivote/core/services/app_activity_service.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/features/auth/data/services/auth_service.dart';
import 'package:pivote/features/auth/presentation/providers/user_provider.dart';
import 'package:pivote/features/auth/presentation/screens/login_screen.dart';
import 'package:pivote/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:pivote/features/profile/presentation/screens/activity_screen.dart';
import 'package:pivote/features/profile/presentation/screens/appearance_settings_screen.dart';
import 'package:pivote/features/profile/presentation/screens/diagnostics_screen.dart';
import 'package:pivote/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:pivote/features/profile/presentation/screens/history_screen.dart';
import 'package:pivote/features/profile/presentation/screens/notifications_settings_screen.dart';
import 'package:pivote/features/profile/presentation/screens/privacy_security_screen.dart';
import 'package:pivote/features/profile/presentation/screens/storage_manager_screen.dart';
import 'package:pivote/features/profile/presentation/screens/support_screen.dart';
import 'package:pivote/shared/widgets/app_notifications.dart';
import 'package:pivote/shared/widgets/common/app_dialogs.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _appVersion = '3.0.0';
  String _cacheSize = 'Calculando…';

  @override
  void initState() {
    super.initState();
    _loadCacheInfo();
  }

  Future<void> _loadCacheInfo() async {
    try {
      final size = await CacheManagerService.getFormattedCacheSize();
      if (mounted) {
        setState(() => _cacheSize = size);
      }
    } catch (_) {}
  }

  Future<void> _open(Widget screen) {
    return Navigator.push(context, AppAnimations.createRoute(screen));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          _buildHero(context, isDark),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 16),
                _buildStatsOverview(context, isDark),
                const SizedBox(height: 14),
                _buildQuickActions(context),
                _buildSection(context, 'Preferencias', [
                  _buildSettingTile(
                    context,
                    icon: Icons.palette_outlined,
                    title: 'Apariencia',
                    subtitle: 'Modo oscuro y pantalla activa',
                    accent: theme.colorScheme.primary,
                    onTap: () => _open(const AppearanceSettingsScreen()),
                  ),
                  _buildSettingTile(
                    context,
                    icon: Icons.notifications_none_rounded,
                    title: 'Notificaciones',
                    subtitle: 'Alertas de eventos y partidos',
                    accent: const Color(0xFF5B8CFF),
                    onTap: () => _open(const NotificationsSettingsScreen()),
                  ),
                  _buildSettingTile(
                    context,
                    icon: Icons.storage_outlined,
                    title: 'Almacenamiento',
                    subtitle: 'Caché · $_cacheSize',
                    accent: const Color(0xFFE58B46),
                    onTap: () {
                      _open(const StorageManagerScreen())
                          .then((_) => _loadCacheInfo());
                    },
                  ),
                ]),
                _buildSection(context, 'Actividad y Contenido', [
                  _buildSettingTile(
                    context,
                    icon: Icons.emoji_events_outlined,
                    title: 'Mi Actividad',
                    subtitle: 'Insignias, tiempo y nivel de usuario',
                    accent: const Color(0xFFF59E0B),
                    onTap: () => _open(const ActivityScreen()),
                  ),
                  _buildSettingTile(
                    context,
                    icon: Icons.history_rounded,
                    title: 'Historial de reproducción',
                    subtitle: 'Canales y contenido reciente',
                    accent: const Color(0xFF10B981),
                    onTap: () => _open(const HistoryScreen()),
                  ),
                  _buildSettingTile(
                    context,
                    icon: Icons.speed_rounded,
                    title: 'Diagnóstico de streaming',
                    subtitle: 'Velocidad, ping, DNS y estabilidad',
                    accent: const Color(0xFF5B8CFF),
                    onTap: () => _open(const DiagnosticsScreen()),
                  ),
                ]),
                _buildSection(context, 'Soporte y seguridad', [
                  _buildSettingTile(
                    context,
                    icon: Icons.support_agent_rounded,
                    title: 'Ayuda y soporte',
                    subtitle: 'Preguntas frecuentes y canales directos',
                    accent: const Color(0xFF35B77A),
                    onTap: () => _open(const SupportScreen()),
                  ),
                  _buildSettingTile(
                    context,
                    icon: Icons.shield_outlined,
                    title: 'Privacidad y seguridad',
                    subtitle: 'Protección de cuenta y datos locales',
                    accent: const Color(0xFF7C69F4),
                    onTap: () => _open(const PrivacySecurityScreen()),
                  ),
                  _buildSettingTile(
                    context,
                    icon: Icons.info_outline_rounded,
                    title: 'Acerca de Pivote',
                    subtitle: 'Versión $_appVersion',
                    accent: const Color(0xFF74ACDF),
                    onTap: () => _showAboutDialog(context),
                  ),
                ]),
                _buildLogout(context),
                const SizedBox(height: 28),
                _buildFooter(context),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;
    final imagePath = userProvider.profileImagePath;
    final primaryColor = isDark ? AppTheme.darkAccent : theme.colorScheme.primary;

    return SliverAppBar(
      expandedHeight: 360,
      pinned: false,
      stretch: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      backgroundColor: theme.scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.zero,
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF131B16), const Color(0xFF080C0A)]
                  : [const Color(0xFFE2F9C2), const Color(0xFFF7FAF2)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -80,
                right: -60,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: isDark ? .12 : .28),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: -100,
                left: -80,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: isDark ? .06 : .12),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: isDark ? 0.15 : 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: primaryColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              'MI CUENTA',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                                color: primaryColor,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: .07)
                                  : Colors.white.withValues(alpha: .65),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.06),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_rounded,
                                    size: 13,
                                    color: primaryColor),
                                const SizedBox(width: 5),
                                Text(
                                  'Pivote Pro Activo',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: primaryColor.withValues(alpha: .75),
                                  width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withValues(alpha: 0.2),
                                  blurRadius: 18,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 52,
                              backgroundColor:
                                  primaryColor.withValues(alpha: .12),
                              backgroundImage: imagePath != null
                                  ? FileImage(File(imagePath))
                                  : null,
                              child: imagePath == null
                                  ? Icon(Icons.person_rounded,
                                      size: 54,
                                      color: primaryColor)
                                  : null,
                            ),
                          ),
                          Positioned(
                            right: 2,
                            bottom: 2,
                            child: Material(
                              color: primaryColor,
                              shape: const CircleBorder(),
                              elevation: 3,
                              child: InkWell(
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  userProvider.updateProfileImage();
                                },
                                customBorder: const CircleBorder(),
                                child: Padding(
                                  padding: const EdgeInsets.all(9),
                                  child: Icon(Icons.camera_alt_rounded,
                                      size: 16,
                                      color: isDark ? Colors.black : Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        GreetingService.getGreeting(),
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: .55)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.name.isNotEmpty == true
                            ? user!.name
                            : 'Usuario Pivote',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.8),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.email ?? 'Sesión activa',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: .52)),
                      ),
                      const SizedBox(height: 14),
                      Material(
                        color: isDark
                            ? Colors.white.withValues(alpha: .08)
                            : Colors.white.withValues(alpha: .75),
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          onTap: () => _open(const EditProfileScreen()),
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 9),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit_rounded,
                                    size: 15,
                                    color: primaryColor),
                                const SizedBox(width: 7),
                                Text(
                                  'Editar perfil',
                                  style: GoogleFonts.spaceGrotesk(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Stats Overview Card ───
  Widget _buildStatsOverview(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final activityService = context.watch<AppActivityService>();
    final favProvider = context.watch<FavoritesProvider>();
    final totalMinutes = (activityService.totalActiveSeconds / 60).round();
    final favCount = favProvider.favoriteIds.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _statItem(
              context,
              label: 'Tiempo activo',
              value: totalMinutes >= 60
                  ? '${(totalMinutes / 60).toStringAsFixed(1)} h'
                  : '$totalMinutes m',
              icon: Icons.timer_outlined,
              accent: isDark ? AppTheme.darkAccent : theme.colorScheme.primary,
            ),
            Container(
              width: 1,
              height: 36,
              color: theme.dividerColor.withValues(alpha: 0.08),
            ),
            _statItem(
              context,
              label: 'Favoritos',
              value: '$favCount',
              icon: Icons.favorite_rounded,
              accent: const Color(0xFFEF4444),
            ),
            Container(
              width: 1,
              height: 36,
              color: theme.dividerColor.withValues(alpha: 0.08),
            ),
            _statItem(
              context,
              label: 'Estado App',
              value: 'Óptimo',
              icon: Icons.check_circle_rounded,
              accent: const Color(0xFF10B981),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color accent,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: accent),
            const SizedBox(width: 5),
            Text(
              value,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).hintColor,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Expanded(
            child: _quickAction(
              Icons.person_outline_rounded,
              'Cuenta',
              'Editar datos',
              () => _open(const EditProfileScreen()),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _quickAction(
              Icons.speed_rounded,
              'Streaming',
              'Diagnóstico',
              () => _open(const DiagnosticsScreen()),
              accent: const Color(0xFF5B8CFF),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _quickAction(
              Icons.storage_outlined,
              'Almacén',
              'Caché',
              () => _open(const StorageManagerScreen()),
              accent: const Color(0xFFE58B46),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickAction(
      IconData icon, String title, String subtitle, VoidCallback onTap,
      {Color? accent}) {
    final theme = Theme.of(context);
    final color = accent ?? theme.colorScheme.primary;
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 13, 12, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: .12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 17, color: color),
              ),
              const SizedBox(height: 10),
              Text(title,
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 12, fontWeight: FontWeight.w800)),
              const SizedBox(height: 1),
              Text(subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: theme.hintColor)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> items) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 3, bottom: 9),
            child: Row(
              children: [
                Text(title,
                    style: GoogleFonts.spaceGrotesk(
                        fontSize: 13.5, fontWeight: FontWeight.w900)),
                const Spacer(),
                Container(
                    width: 24,
                    height: 3,
                    decoration: BoxDecoration(
                        color: theme.colorScheme.primary
                            .withValues(alpha: .3),
                        borderRadius: BorderRadius.circular(99))),
              ],
            ),
          ),
          Material(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: theme.dividerColor.withValues(alpha: .07))),
              child: Column(
                children: [
                  for (int i = 0; i < items.length; i++) ...[
                    items[i],
                    if (i < items.length - 1)
                      Divider(
                          height: 1,
                          indent: 68,
                          endIndent: 14,
                          color: theme.dividerColor.withValues(alpha: .06)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap,
      Color? accent}) {
    final theme = Theme.of(context);
    final color = accent ?? theme.colorScheme.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(13)),
                  child: Icon(icon, size: 20, color: color)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 14.5, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.hintColor)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 13, color: theme.hintColor.withValues(alpha: .55)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogout(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 0),
      child: Material(
        color: theme.colorScheme.error.withValues(alpha: .065),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => _showLogoutDialog(context),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: theme.colorScheme.error.withValues(alpha: .12))),
            child: Row(
              children: [
                Icon(Icons.logout_rounded,
                    color: theme.colorScheme.error, size: 20),
                const SizedBox(width: 11),
                Expanded(
                    child: Text('Cerrar sesión',
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.error))),
                Icon(Icons.arrow_forward_ios_rounded,
                    color: theme.colorScheme.error.withValues(alpha: .55),
                    size: 13),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text('Hecha con pasión en Argentina',
            style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: theme.hintColor)),
        const SizedBox(height: 6),
        const Text('🇦🇷', style: TextStyle(fontSize: 18)),
        const SizedBox(height: 7),
        Text('Pivote Studio · $_appVersion',
            style: GoogleFonts.spaceGrotesk(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: theme.hintColor.withValues(alpha: .7))),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) async {
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
      Provider.of<UserProvider>(context, listen: false).clearUser();
      AppNotifications.showInfo(context, 'Sesión cerrada correctamente');
      Navigator.of(context).pushAndRemoveUntil(
          AppAnimations.createFadeRoute(const LoginScreen()), (route) => false);
    }
  }

  void _showAboutDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 6, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: .12),
                      shape: BoxShape.circle),
                  child: Icon(Icons.play_circle_fill_rounded,
                      color: isDark ? AppTheme.darkAccent : theme.colorScheme.primary, size: 36)),
              const SizedBox(height: 12),
              Text('Pivote Studio',
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 3),
              Text('Versión $_appVersion • Edición Premium',
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: theme.hintColor)),
              const SizedBox(height: 20),
              Material(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () => _checkUpdates(context),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Icon(Icons.system_update_rounded,
                            color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text('Verificar actualizaciones',
                                style: GoogleFonts.spaceGrotesk(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800))),
                        Icon(Icons.arrow_forward_ios_rounded,
                            size: 13, color: theme.hintColor),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _checkUpdates(BuildContext context) async {
    Navigator.pop(context);
    AppDialogs.showLoading(
        context: context, message: 'Buscando actualizaciones…');
    await Future.delayed(const Duration(seconds: 2));
    if (!context.mounted) return;
    Navigator.pop(context);
    AppDialogs.showAlert(
        context: context,
        title: 'Todo actualizado',
        message: 'Tenés la última versión de Pivote Studio instalada.',
        type: AppDialogType.success);
  }
}
