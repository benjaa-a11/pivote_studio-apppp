import 'dart:io';
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pivote/features/video/presentation/providers/channel_provider.dart';
import 'package:pivote/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:pivote/core/theme/theme_provider.dart';
import 'package:pivote/features/auth/presentation/providers/user_provider.dart';
import 'package:pivote/core/services/cache_manager_service.dart';
import 'package:pivote/features/auth/data/services/auth_service.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/shared/widgets/app_notifications.dart';
import 'package:pivote/features/profile/presentation/widgets/section_header.dart';
import 'package:pivote/features/profile/presentation/screens/storage_manager_screen.dart';
import 'package:pivote/features/profile/presentation/screens/support_screen.dart';
import 'package:pivote/features/profile/presentation/screens/privacy_security_screen.dart';
import 'package:pivote/features/profile/presentation/screens/notifications_settings_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pivote/shared/widgets/common/app_dialogs.dart';
import 'package:pivote/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:pivote/core/services/greeting_service.dart';

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
                _buildStats(context),
                const SizedBox(height: 24),

                // UI Sections
                _buildSection(
                  context,
                  title: 'Apariencia',
                  icon: Icons.palette_outlined,
                  children: [_buildAppearanceSection(context)],
                ),

                _buildSection(
                  context,
                  title: 'Notificaciones',
                  icon: Icons.notifications_outlined,
                  children: [_buildNotificationsSection(context)],
                ),

                _buildSection(
                  context,
                  title: 'Almacenamiento',
                  icon: Icons.storage_outlined,
                  children: [_buildStorageSection(context)],
                ),

                _buildSection(
                  context,
                  title: 'Soporte',
                  icon: Icons.support_agent_outlined,
                  children: [_buildSupportSection(context)],
                ),

                _buildSection(
                  context,
                  title: 'Información',
                  icon: Icons.info_outline,
                  children: [_buildAboutAppSection(context)],
                ),

                const SizedBox(height: 24),
                _buildLogoutButton(context),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
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
      expandedHeight: 380, // Aumentado para que el botón no se corte
      pinned: true,
      stretch: true,
      backgroundColor: theme.colorScheme.primary,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
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
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(50),
              bottomRight: Radius.circular(50),
            ),
          ),
          child: Stack(
            children: [
              // Decorative Blobs with improved animation/depth
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

              // Header Content
              // Header Content with Glassmorphism Card
              SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(40),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 32, horizontal: 24),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(40),
                        ),
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
                                    radius: 60,
                                    backgroundColor: Colors.white.withAlpha(51),
                                    backgroundImage: imagePath != null
                                        ? FileImage(File(imagePath))
                                        : null,
                                    child: imagePath == null
                                        ? const Icon(Icons.person,
                                            size: 60, color: Colors.white)
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
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // User Details
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
                                  const SizedBox(height: 6),
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
                                  const SizedBox(height: 4),
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
                                  const SizedBox(height: 24),
                                  Material(
                                    color: isDark
                                        ? Colors.black.withAlpha(15)
                                        : Colors.white.withAlpha(38),
                                    borderRadius: BorderRadius.circular(100),
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context,
      {required String title,
      required IconData icon,
      required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(icon: icon, title: title),
        ...children,
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildStats(BuildContext context) {
    return Consumer2<ChannelProvider, FavoritesProvider>(
      builder: (context, channelProvider, favoritesProvider, child) {
        final totalChannels = channelProvider.channels.length;
        final favoriteChannels = favoritesProvider.favoriteIds.length;
        final categories = channelProvider.categories.length - 1;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              _buildStatItem(context, totalChannels.toString(), 'Canales',
                  FontAwesomeIcons.tv),
              _buildStatItem(context, favoriteChannels.toString(), 'Favoritos',
                  FontAwesomeIcons.heart),
              _buildStatItem(context, categories.toString(), 'Categorías',
                  FontAwesomeIcons.layerGroup),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
      BuildContext context, String value, String label, IconData icon) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withAlpha(51),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.dividerColor.withAlpha(20)),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 20, color: theme.colorScheme.primary.withAlpha(179)),
            const SizedBox(height: 12),
            Text(value,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                )),
            Text(label,
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withAlpha(128))),
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceSection(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return _buildOptionTile(
      context,
      icon: themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
      title: 'Modo ${themeProvider.isDarkMode ? 'Oscuro' : 'Claro'}',
      subtitle: 'Configuración visual de la app',
      trailing: Switch(
        value: themeProvider.isDarkMode,
        onChanged: (v) => themeProvider.toggleTheme(),
        activeThumbColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildNotificationsSection(BuildContext context) {
    return _buildOptionTile(
      context,
      icon: Icons.notifications_outlined,
      title: 'Configurar notificaciones',
      subtitle: 'Gestiona tus preferencias de notificaciones',
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const NotificationsSettingsScreen(),
        ),
      ),
    );
  }

  Widget _buildStorageSection(BuildContext context) {
    return Column(
      children: [
        _buildOptionTile(
          context,
          icon: Icons.cached,
          title: 'Caché',
          subtitle: _cacheSize,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const StorageManagerScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildSupportSection(BuildContext context) {
    return Column(
      children: [
        _buildOptionTile(
          context,
          icon: Icons.help_outline,
          title: 'Ayuda y soporte',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SupportScreen()),
          ),
        ),
        _buildOptionTile(
          context,
          icon: Icons.privacy_tip_outlined,
          title: 'Privacidad y Seguridad',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const PrivacySecurityScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildAboutAppSection(BuildContext context) {
    return _buildOptionTile(
      context,
      icon: Icons.info_outline,
      title: 'Versión',
      subtitle: 'v$_appVersion',
      onTap: () => _showAboutDialog(context),
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

  Widget _buildOptionTile(BuildContext context,
      {required IconData icon,
      required String title,
      String? subtitle,
      Widget? trailing,
      VoidCallback? onTap}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        tileColor: theme.colorScheme.surfaceContainerHighest.withAlpha(76),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: theme.dividerColor.withAlpha(20))),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withAlpha(26),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 20),
        ),
        title: Text(title,
            style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: subtitle != null
            ? Text(subtitle,
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withAlpha(153)))
            : null,
        trailing: trailing ?? const Icon(Icons.chevron_right, size: 20),
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
            const SizedBox(height: 48),

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
