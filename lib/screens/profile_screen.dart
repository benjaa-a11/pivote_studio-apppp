// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/channel_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import '../services/cache_manager_service.dart';
import '../services/viewing_history_service.dart';
import '../services/auth_service.dart';
import '../config/app_animations.dart';
import '../widgets/app_notifications.dart';
import '../widgets/profile/section_header.dart';
import 'profile/storage_manager_screen.dart';
import 'profile/history_screen.dart';
import 'profile/support_screen.dart';
import 'profile/privacy_security_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/common/custom_dialogs.dart';
import 'profile/edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final String _appVersion = '1.6.0';
  String _cacheSize = 'Calculando...';
  int _historyCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCacheInfo();
  }

  Future<void> _loadCacheInfo() async {
    final size = await CacheManagerService.getFormattedCacheSize();
    final count = await ViewingHistoryService.getHistoryCount();
    if (mounted) {
      setState(() {
        _cacheSize = size;
        _historyCount = count;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
            _buildModernHeader(context),
            const SizedBox(height: 24),
            _buildStats(context),
            const SizedBox(height: 12),

            // UI Sections
            _buildSection(
              context,
              title: 'Apariencia',
              icon: Icons.palette_outlined,
              children: [_buildAppearanceSection(context)],
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
              title: 'Acerca de',
              icon: Icons.info_outline,
              children: [_buildAboutAppSection(context)],
            ),

            const SizedBox(height: 24),
            _buildLogoutButton(context),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeader(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    final imagePath = userProvider.profileImagePath;

    return Container(
      height: 380,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withValues(alpha: 0.8)
                ]
              : [theme.colorScheme.primary, theme.colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(50)),
      ),
      child: Stack(
        children: [
          // Decorative Blobs
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: (isDark
                        ? theme.colorScheme.tertiary
                        : theme.colorScheme.secondary)
                    .withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: (isDark
                        ? theme.colorScheme.secondary
                        : theme.colorScheme.tertiary)
                    .withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Header Content
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // Profile Image with Edit Button
                Center(
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 65,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          backgroundImage: imagePath != null
                              ? FileImage(File(imagePath))
                              : null,
                          child: imagePath == null
                              ? const Icon(Icons.person,
                                  size: 70, color: Colors.white)
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            userProvider.updateProfileImage();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? theme.colorScheme.surface
                                  : Colors.black,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // User Details
                AppAnimations.smoothFadeIn(
                  child: Column(
                    children: [
                      Text(
                        user != null
                            ? '${user.name} ${user.lastName}'
                            : 'Cargando...',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? '',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const EditProfileScreen()));
                          },
                          borderRadius: BorderRadius.circular(100),
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.edit_rounded,
                                    color: Colors.white, size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  'Editar Perfil',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
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
        ],
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
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 20,
                color: theme.colorScheme.primary.withValues(alpha: 0.7)),
            const SizedBox(height: 12),
            Text(value,
                style: GoogleFonts.montserrat(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                )),
            Text(label,
                style: GoogleFonts.montserrat(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
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
        activeColor: Theme.of(context).colorScheme.primary,
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
        _buildOptionTile(
          context,
          icon: Icons.history,
          title: 'Historial',
          subtitle: '$_historyCount canales vistos',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HistoryScreen()),
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
          color: isDark
              ? theme.colorScheme.error.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? theme.colorScheme.error.withValues(alpha: 0.5)
                : theme.colorScheme.error.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
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
        tileColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side:
                BorderSide(color: theme.dividerColor.withValues(alpha: 0.05))),
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(title,
            style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: subtitle != null
            ? Text(subtitle,
                style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6)))
            : null,
        trailing: trailing ?? const Icon(Icons.chevron_right, size: 20),
      ),
    );
  }

  // --- Dialogs (Simplified for brevity but keeping original logic) ---

  void _showLogoutDialog(BuildContext context) async {
    final confirmed = await CustomDialogs.showConfirmDialog(
      context,
      title: '¿Cerrar Sesión?',
      message: '¿Estás seguro de que deseas salir de tu cuenta?',
      confirmLabel: 'SALIR',
      cancelLabel: 'CANCELAR',
      isDestructive: true,
      dialogContext: DialogContext.warning,
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

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Acerca de Pivote Studio',
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 32),

            // App Branding Section with Animation
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1)),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/logo.png',
                    width: 70,
                    errorBuilder: (context, _, __) => Icon(
                      Icons.auto_awesome_rounded,
                      size: 50,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Pivote Studio',
              style: GoogleFonts.montserrat(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Versión $_appVersion',
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Native-style Information List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildAboutTile(
                    context,
                    icon: Icons.code_rounded,
                    title: 'Desarrollado por',
                    subtitle: 'Pivote Tech Team',
                  ),
                  _buildAboutTile(
                    context,
                    icon: Icons.language_rounded,
                    title: 'Sitio Web Oficial',
                    subtitle: 'www.pivote.app',
                  ),
                  _buildAboutTile(
                    context,
                    icon: Icons.policy_rounded,
                    title: 'Política de Privacidad',
                    subtitle: 'Revisa cómo cuidamos tus datos',
                  ),
                  _buildAboutTile(
                    context,
                    icon: Icons.description_rounded,
                    title: 'Términos de Servicio',
                    subtitle: 'Reglas de uso de la plataforma',
                  ),
                  const SizedBox(height: 24),

                  // Botón de Verificar Actualizaciones
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _checkUpdates(context),
                      icon: const Icon(Icons.system_update_rounded, size: 20),
                      label: Text(
                        'Buscar Actualizaciones',
                        style:
                            GoogleFonts.montserrat(fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.surface,
                        foregroundColor: theme.colorScheme.primary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                          color: theme.dividerColor.withValues(alpha: 0.1),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  Center(
                    child: Text(
                      '© 2026 Pivote Studio. Todos los derechos reservados.\nHecho con ❤️ en Argentina.',
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.4),
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkUpdates(BuildContext context) async {
    Navigator.pop(context); // Close the modal

    // Show loading notification
    AppNotifications.showInfo(context, 'Buscando actualizaciones...');

    // Simulate network request
    await Future.delayed(const Duration(seconds: 2));

    if (context.mounted) {
      AppNotifications.showSuccess(
          context, '¡Tu app está actualizada a la última versión!');
    }
  }

  Widget _buildAboutTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary, size: 22),
        title: Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
        ),
        onTap: () {
          // Future: Open URLs
        },
      ),
    );
  }
}
