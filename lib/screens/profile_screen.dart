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
import '../widgets/profile/section_header.dart';
import 'profile/storage_manager_screen.dart';
import 'profile/history_screen.dart';
import 'profile/support_screen.dart';
import 'profile/privacy_security_screen.dart';
import 'package:google_fonts/google_fonts.dart';

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
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    final imagePath = userProvider.profileImagePath;

    return Container(
      height: 380,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE7714D), Color(0xFFE57C5D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(50)),
      ),
      child: Stack(
        children: [
          // Decorative Blobs (Same as Auth)
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: const Color(0xFFD4B455).withValues(alpha: 0.6),
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
                color: const Color(0xFF5BB389).withValues(alpha: 0.5),
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
                            decoration: const BoxDecoration(
                              color: Colors.black,
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
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? '',
                        style: GoogleFonts.montserrat(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
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
                        child: Text(
                          'Pivote VIP',
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: OutlinedButton(
        onPressed: () => _showLogoutDialog(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          minimumSize: const Size(double.infinity, 56),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        ),
        child: Text('Cerrar Sesión',
            style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold, fontSize: 16)),
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

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas salir de tu cuenta?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              await AuthService.logout();
              if (context.mounted) {
                Provider.of<UserProvider>(context, listen: false).clearUser();
                Navigator.pop(context);
              }
            },
            child: const Text('Salir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Pivote Studio',
      applicationVersion: _appVersion,
      applicationIcon: Image.asset('assets/logo.png', height: 40),
      children: [
        Text(
          'Pivote Studio es la plataforma definitiva para el streaming de televisión en vivo. '
          'Disfruta de tus canales favoritos con la mejor calidad y una interfaz moderna y profesional.',
          style: GoogleFonts.montserrat(),
        )
      ],
    );
  }
}
