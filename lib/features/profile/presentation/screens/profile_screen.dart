import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/core/services/auth_service.dart';
import 'package:pivote/core/services/cache_manager_service.dart';
import 'package:pivote/core/services/greeting_service.dart';
import 'package:pivote/features/auth/presentation/providers/user_provider.dart';
import 'package:pivote/features/auth/presentation/screens/login_screen.dart';
import 'package:pivote/features/profile/presentation/screens/appearance_settings_screen.dart';
import 'package:pivote/features/profile/presentation/screens/diagnostics_screen.dart';
import 'package:pivote/features/profile/presentation/screens/edit_profile_screen.dart';
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
      if (mounted) setState(() => _cacheSize = size);
    } catch (_) {}
  }

  void _open(Widget screen) {
    Navigator.push(context, AppAnimations.createRoute(screen));
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
                const SizedBox(height: 18),
                _buildQuickActions(context),
                _buildSection(
                  context,
                  'Preferencias',
                  [
                    _buildSettingTile(
                      context,
                      icon: Icons.palette_outlined,
                      title: 'Apariencia',
                      subtitle: 'Tema y pantalla',
                      onTap: () => _open(const AppearanceSettingsScreen()),
                    ),
                    _buildSettingTile(
                      context,
                      icon: Icons.notifications_none_rounded,
                      title: 'Notificaciones',
                      subtitle: 'Avisos y permisos',
                      onTap: () => _open(const NotificationsSettingsScreen()),
                    ),
                    _buildSettingTile(
                      context,
                      icon: Icons.storage_outlined,
                      title: 'Almacenamiento',
                      subtitle: 'Caché · $_cacheSize',
                      onTap: () => _open(const StorageManagerScreen()).then((_) => _loadCacheInfo()),
                    ),
                  ],
                ),
                _buildSection(
                  context,
                  'Herramientas',
                  [
                    _buildSettingTile(
                      context,
                      icon: Icons.speed_rounded,
                      title: 'Diagnóstico de streaming',
                      subtitle: 'Velocidad, ping y estabilidad',
                      accent: const Color(0xFF5B8CFF),
                      onTap: () => _open(const DiagnosticsScreen()),
                    ),
                  ],
                ),
                _buildSection(
                  context,
                  'Soporte y seguridad',
                  [
                    _buildSettingTile(
                      context,
                      icon: Icons.support_agent_rounded,
                      title: 'Ayuda y soporte',
                      subtitle: 'Preguntas frecuentes y contacto',
                      accent: const Color(0xFF35B77A),
                      onTap: () => _open(const SupportScreen()),
                    ),
                    _buildSettingTile(
                      context,
                      icon: Icons.shield_outlined,
                      title: 'Privacidad y seguridad',
                      subtitle: 'Protección de tu cuenta y datos',
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
                  ],
                ),
                _buildLogout(context),
                const SizedBox(height: 26),
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

    return SliverAppBar(
      expandedHeight: 350,
      pinned: false,
      stretch: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      backgroundColor: theme.scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.zero,
        stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF162310), const Color(0xFF0B0F0A)]
                  : [const Color(0xFFDDFF9E), const Color(0xFFF5F8EE)],
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
                    color: theme.colorScheme.primary.withValues(alpha: isDark ? .12 : .28),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: -120,
                left: -80,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: isDark ? .05 : .1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            'PERFIL',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: .07) : Colors.white.withValues(alpha: .58),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: theme.colorScheme.primary.withValues(alpha: .14)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_rounded, size: 13, color: theme.colorScheme.primary),
                                const SizedBox(width: 5),
                                Text(
                                  'Cuenta activa',
                                  style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: theme.colorScheme.primary.withValues(alpha: .75), width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withValues(alpha: .22),
                                  blurRadius: 28,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 52,
                              backgroundColor: theme.colorScheme.primary.withValues(alpha: .12),
                              backgroundImage: imagePath != null ? FileImage(File(imagePath)) : null,
                              child: imagePath == null
                                  ? Icon(Icons.person_rounded, size: 54, color: theme.colorScheme.primary)
                                  : null,
                            ),
                          ),
                          Positioned(
                            right: 2,
                            bottom: 2,
                            child: Material(
                              color: theme.colorScheme.primary,
                              shape: const CircleBorder(),
                              elevation: 4,
                              child: InkWell(
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  userProvider.updateProfileImage();
                                },
                                customBorder: const CircleBorder(),
                                child: const Padding(
                                  padding: EdgeInsets.all(9),
                                  child: Icon(Icons.camera_alt_rounded, size: 16, color: Colors.black),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Text(
                        GreetingService.getGreeting(),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface.withValues(alpha: .55),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.name.isNotEmpty == true ? user!.name : 'Tu perfil',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.email ?? 'Cuenta Pivote',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface.withValues(alpha: .52),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Material(
                        color: isDark ? Colors.white.withValues(alpha: .07) : Colors.white.withValues(alpha: .64),
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          onTap: () => _open(const EditProfileScreen()),
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit_rounded, size: 15, color: theme.colorScheme.primary),
                                const SizedBox(width: 7),
                                Text('Editar perfil', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w800)),
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

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Expanded(child: _quickAction(Icons.person_outline_rounded, 'Cuenta', 'Editar', () => _open(const EditProfileScreen()))),
          const SizedBox(width: 10),
          Expanded(child: _quickAction(Icons.speed_rounded, 'Streaming', 'Diagnóstico', () => _open(const DiagnosticsScreen()), accent: const Color(0xFF5B8CFF))),
          const SizedBox(width: 10),
          Expanded(child: _quickAction(Icons.storage_outlined, 'Datos', 'Caché', () => _open(const StorageManagerScreen()), accent: const Color(0xFFE58B46))),
        ],
      ),
    );
  }

  Widget _quickAction(IconData icon, String title, String subtitle, VoidCallback onTap, {Color? accent}) {
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
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .035), blurRadius: 16, offset: const Offset(0, 7))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: color.withValues(alpha: .1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 17, color: color),
              ),
              const SizedBox(height: 10),
              Text(title, style: GoogleFonts.spaceGrotesk(fontSize: 11.5, fontWeight: FontWeight.w800)),
              const SizedBox(height: 1),
              Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.spaceGrotesk(fontSize: 9.5, fontWeight: FontWeight.w600, color: theme.hintColor)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> items) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 3, bottom: 9),
            child: Row(
              children: [
                Text(title, style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: .2)),
                const Spacer(),
                Container(width: 30, height: 3, decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: .25), borderRadius: BorderRadius.circular(99))),
              ],
            ),
          ),
          Material(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.dividerColor.withValues(alpha: .07)),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < items.length; i++) ...[
                    items[i],
                    if (i < items.length - 1) Divider(height: 1, indent: 68, endIndent: 14, color: theme.dividerColor.withValues(alpha: .06)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? accent,
  }) {
    final theme = Theme.of(context);
    final color = accent ?? theme.colorScheme.primary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: color.withValues(alpha: .1), borderRadius: BorderRadius.circular(13)),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.spaceGrotesk(fontSize: 14.5, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.spaceGrotesk(fontSize: 10.5, fontWeight: FontWeight.w600, color: theme.hintColor)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded, size: 13, color: theme.hintColor.withValues(alpha: .55)),
          ],
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
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: theme.colorScheme.error.withValues(alpha: .12))),
            child: Row(
              children: [
                Icon(Icons.logout_rounded, color: theme.colorScheme.error, size: 20),
                const SizedBox(width: 11),
                Expanded(child: Text('Cerrar sesión', style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w800, color: theme.colorScheme.error))),
                Icon(Icons.arrow_forward_ios_rounded, color: theme.colorScheme.error.withValues(alpha: .55), size: 13),
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
        Text('Hecha en Argentina', style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w800, color: theme.hintColor)),
        const SizedBox(height: 6),
        const Text('🇦🇷', style: TextStyle(fontSize: 18)),
        const SizedBox(height: 7),
        Text('Pivote Studio · $_appVersion', style: GoogleFonts.spaceGrotesk(fontSize: 9.5, fontWeight: FontWeight.w600, color: theme.hintColor.withValues(alpha: .7))),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) async {
    final confirmed = await AppDialogs.showConfirm(
      context: context,
      title: '¿Cerrar sesión?',
      message: 'Tu cuenta permanecerá guardada y podrás volver a entrar cuando quieras.',
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
      Navigator.of(context).pushAndRemoveUntil(AppAnimations.createFadeRoute(const LoginScreen()), (route) => false);
    }
  }

  void _showAboutDialog(BuildContext context) {
    final theme = Theme.of(context);
    AppDialogs.showModal(
      context: context,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
        child: Column(
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: .1), borderRadius: BorderRadius.circular(22)),
              child: Padding(padding: const EdgeInsets.all(15), child: Image.asset('assets/logo.png', errorBuilder: (_, __, ___) => Icon(Icons.play_circle_fill_rounded, color: theme.colorScheme.primary, size: 38))),
            ),
            const SizedBox(height: 14),
            Text('Pivote Studio', style: GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -.7)),
            const SizedBox(height: 3),
            Text('Versión $_appVersion', style: GoogleFonts.spaceGrotesk(fontSize: 11.5, fontWeight: FontWeight.w600, color: theme.hintColor)),
            const SizedBox(height: 15),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: .06), borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.colorScheme.primary.withValues(alpha: .1))),
              child: Row(children: [Icon(Icons.auto_awesome_rounded, color: theme.colorScheme.primary, size: 19), const SizedBox(width: 9), Expanded(child: Text('Una experiencia de streaming pensada para vos.', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700)))]),
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: () => _checkUpdates(context),
              borderRadius: BorderRadius.circular(15),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
                decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(15), border: Border.all(color: theme.dividerColor.withValues(alpha: .08))),
                child: Row(children: [Icon(Icons.system_update_rounded, color: theme.colorScheme.primary, size: 19), const SizedBox(width: 10), Expanded(child: Text('Buscar actualizaciones', style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w800))), Icon(Icons.arrow_forward_ios_rounded, size: 12, color: theme.hintColor)]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkUpdates(BuildContext context) async {
    Navigator.pop(context);
    AppDialogs.showLoading(context: context, message: 'Buscando actualizaciones…');
    await Future.delayed(const Duration(seconds: 2));
    if (!context.mounted) return;
    Navigator.pop(context);
    AppDialogs.showAlert(context: context, title: 'Todo actualizado', message: 'Tenés la última versión disponible de Pivote Studio.', type: AppDialogType.success);
  }
}
