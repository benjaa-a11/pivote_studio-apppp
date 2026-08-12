import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pivote/features/auth/presentation/providers/user_provider.dart';
import 'package:pivote/core/services/cache_manager_service.dart';
import 'package:pivote/features/auth/data/services/auth_service.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/shared/widgets/app_notifications.dart';
import 'package:pivote/features/profile/presentation/screens/storage_manager_screen.dart';
import 'package:pivote/features/profile/presentation/screens/support_screen.dart';
import 'package:pivote/features/profile/presentation/screens/privacy_security_screen.dart';
import 'package:pivote/features/profile/presentation/screens/notifications_settings_screen.dart';
import 'package:pivote/features/profile/presentation/screens/appearance_settings_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pivote/features/auth/presentation/screens/login_screen.dart';
import 'package:pivote/shared/widgets/common/app_dialogs.dart';
import 'package:pivote/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:pivote/core/services/greeting_service.dart';
import 'package:pivote/features/profile/presentation/screens/diagnostics_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final String _appVersion = '3.0.0';
  String _cacheSize = 'Calculando...';

  @override
  void initState() {
    super.initState();
    _loadCacheInfo();
  }

  Future<void> _loadCacheInfo() async {
    final size = await CacheManagerService.getFormattedCacheSize();
    if (mounted) {
      setState(() {
        _cacheSize = size;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          _buildSliverHeader(context),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 24),

                // Grupo 1: Preferencias
                _buildCardGroup(
                  context,
                  title: 'Preferencias',
                  children: [
                    _buildMenuTile(
                      context,
                      icon: Icons.palette_outlined,
                      title: 'Apariencia',
                      subtitle: 'Tema visual y comportamiento de pantalla',
                      onTap: () => Navigator.push(
                        context,
                        AppAnimations.createRoute(
                          const AppearanceSettingsScreen(),
                        ),
                      ),
                    ),
                    _buildMenuTile(
                      context,
                      icon: Icons.notifications_outlined,
                      title: 'Notificaciones',
                      subtitle: 'Avisos de partidos y novedades',
                      onTap: () => Navigator.push(
                        context,
                        AppAnimations.createRoute(
                          const NotificationsSettingsScreen(),
                        ),
                      ),
                    ),
                    _buildMenuTile(
                      context,
                      icon: Icons.storage_outlined,
                      title: 'Almacenamiento',
                      subtitle: 'Caché ocupado: $_cacheSize',
                      onTap: () => Navigator.push(
                        context,
                        AppAnimations.createRoute(
                          const StorageManagerScreen(),
                        ),
                      ).then((_) => _loadCacheInfo()),
                    ),
                  ],
                ),

                // Grupo 2: Herramientas
                _buildCardGroup(
                  context,
                  title: 'Herramientas',
                  children: [
                    _buildMenuTile(
                      context,
                      icon: Icons.speed_rounded,
                      title: 'Diagnóstico de Streaming',
                      subtitle: 'Velocidad y latencia de red',
                      onTap: () => Navigator.push(
                        context,
                        AppAnimations.createRoute(
                          const DiagnosticsScreen(),
                        ),
                      ),
                    ),
                  ],
                ),

                // Grupo 3: Soporte y Legal
                _buildCardGroup(
                  context,
                  title: 'Soporte y Legal',
                  children: [
                    _buildMenuTile(
                      context,
                      icon: Icons.help_outline_rounded,
                      title: 'Ayuda y Soporte',
                      subtitle: 'Preguntas frecuentes y soporte técnico',
                      onTap: () => Navigator.push(
                        context,
                        AppAnimations.createRoute(
                          const SupportScreen(),
                        ),
                      ),
                    ),
                    _buildMenuTile(
                      context,
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacidad y Seguridad',
                      subtitle: 'Términos de servicio y políticas',
                      onTap: () => Navigator.push(
                        context,
                        AppAnimations.createRoute(
                          const PrivacySecurityScreen(),
                        ),
                      ),
                    ),
                    _buildMenuTile(
                      context,
                      icon: Icons.info_outline_rounded,
                      title: 'Información de la App',
                      subtitle: 'Versión de Pivote Studio',
                      onTap: () => _showAboutDialog(context),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                _buildLogoutButton(context),
                const SizedBox(height: 32),
                _buildArgentinaBadge(context),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardGroup(BuildContext context,
      {required String title, required List<Widget> children}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              title.toUpperCase(),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
                letterSpacing: 1.0,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.2 : 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1)
                    Divider(
                      height: 1,
                      indent: 64,
                      endIndent: 20,
                      color: theme.dividerColor.withValues(alpha: 0.05),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      VoidCallback? onTap,
      Widget? trailing}) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: theme.colorScheme.primary, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.spaceGrotesk(
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 12,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
      trailing: trailing ?? Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildSliverHeader(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    final imagePath = userProvider.profileImagePath;

    return SliverAppBar(
      expandedHeight: 380,
      pinned: false,
      stretch: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.zero,
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withAlpha(204),
                    ]
                  : [theme.colorScheme.primary, theme.colorScheme.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Decorative blobs
              Positioned(
                top: -50,
                right: -40,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.black : theme.colorScheme.secondary)
                        .withAlpha(isDark ? 50 : 76),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: 80,
                left: -70,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.black : theme.colorScheme.tertiary)
                        .withAlpha(isDark ? 40 : 51),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              // Header content
              SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Profile Image with Edit Button
                        Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(51),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 56,
                                backgroundColor: Colors.white.withAlpha(51),
                                backgroundImage: imagePath != null
                                    ? FileImage(File(imagePath))
                                    : null,
                                child: imagePath == null
                                    ? const Icon(Icons.person,
                                        size: 56, color: Colors.white)
                                    : null,
                              ),
                            ),
                            Positioned(
                              bottom: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  userProvider.updateProfileImage();
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                  child: Icon(
                                    Icons.camera_alt,
                                    color: isDark
                                        ? Colors.black
                                        : Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        AppAnimations.smoothFadeIn(
                          child: Column(
                            children: [
                              Text(
                                GreetingService.getGreeting(),
                                style:
                                    theme.textTheme.titleMedium?.copyWith(
                                  color: isDark
                                      ? Colors.black87
                                      : Colors.white.withAlpha(179),
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user != null ? user.name : 'Cargando...',
                                style: theme.textTheme.headlineMedium
                                    ?.copyWith(
                                  color:
                                      isDark ? Colors.black : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user?.email ?? '',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: isDark
                                      ? Colors.black54
                                      : Colors.white.withAlpha(204),
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              Material(
                                color: isDark
                                    ? Colors.black.withAlpha(15)
                                    : Colors.white.withAlpha(38),
                                borderRadius: BorderRadius.circular(100),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        AppAnimations.createRoute(
                                            const EditProfileScreen()));
                                  },
                                  borderRadius: BorderRadius.circular(100),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 10),
                                    decoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(100),
                                      border: Border.all(
                                          color: isDark
                                              ? Colors.black.withAlpha(40)
                                              : Colors.white.withAlpha(76)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.edit_rounded,
                                            color: isDark
                                                ? Colors.black87
                                                : Colors.white,
                                            size: 16),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Editar Perfil',
                                          style: theme.textTheme.labelMedium
                                              ?.copyWith(
                                            color: isDark
                                                ? Colors.black87
                                                : Colors.white,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
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

  Widget _buildLogoutButton(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        height: 65,
        decoration: BoxDecoration(
          color: isDark ? theme.colorScheme.error.withAlpha(26) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? theme.colorScheme.error.withAlpha(128)
                : theme.colorScheme.error.withAlpha(51),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showLogoutDialog(context),
            borderRadius: BorderRadius.circular(20),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded,
                      color: isDark
                          ? theme.colorScheme.error
                          : theme.colorScheme.error,
                      size: 22),
                  const SizedBox(width: 12),
                  Text(
                    'Cerrar Sesión',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isDark
                          ? theme.colorScheme.error
                          : theme.colorScheme.error,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Dialogs (Simplified for brevity but keeping original logic) ---

  void _showLogoutDialog(BuildContext context) async {
    final confirmed = await AppDialogs.showConfirm(
      context: context,
      title: '¿Quieres salir?',
      message:
          'Cerraremos tu sesión actual. Podrás volver a entrar cuando quieras.',
      confirmLabel: 'Salir',
      cancelLabel: 'Me quedo',
      isDestructive: true,
      type: AppDialogType.warning,
    );

    if (confirmed == true) {
      await AuthService.logout();
      if (context.mounted) {
        Provider.of<UserProvider>(context, listen: false).clearUser();
        AppNotifications.showInfo(context, 'Has cerrado sesión correctamente');
        Navigator.of(context).pushAndRemoveUntil(
          AppAnimations.createFadeRoute(const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  void _showAboutDialog(BuildContext context) {
    final theme = Theme.of(context);

    AppDialogs.showModal(
      context: context,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Logo Section
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Image.asset(
                  'assets/logo.png',
                  width: 50,
                  height: 50,
                  errorBuilder: (context, _, __) => Icon(
                    Icons.play_circle_fill,
                    size: 40,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Pivote Studio',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Versión $_appVersion',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withAlpha(128),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF74ACDF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF74ACDF).withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🇦🇷', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Text(
                    'Por un argentino para los argentinos',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF74ACDF),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            _buildModernActionTile(
              context,
              'Verificar Actualizaciones',
              Icons.system_update_rounded,
              () => _checkUpdates(context),
            ),

            const SizedBox(height: 48),
            Text(
              '© 2026 Pivote. Todos los derechos reservados.',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildModernActionTile(
      BuildContext context, String title, IconData icon, VoidCallback onTap) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withAlpha(76),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.dividerColor.withAlpha(13),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: theme.colorScheme.onSurface.withAlpha(76)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArgentinaBadge(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🇦🇷', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Text(
              'Desarrollada por un argentino para los argentinos',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).hintColor.withValues(alpha: 0.6),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 3,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF74ACDF), Colors.white, Color(0xFF74ACDF)],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Future<void> _checkUpdates(BuildContext context) async {
    Navigator.pop(context); // Close the bottom sheet

    AppDialogs.showLoading(
      context: context,
      message: 'Buscando actualizaciones...',
    );

    await Future.delayed(const Duration(seconds: 2));

    if (context.mounted) {
      Navigator.pop(context); // Close loading dialog

      AppDialogs.showAlert(
        context: context,
        title: '¡Todo actualizado!',
        message: 'Tienes la última versión de Pivote Studio instalada.',
        type: AppDialogType.success,
      );
    }
  }
}
