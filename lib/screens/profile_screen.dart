// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/channel_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/theme_provider.dart';
import '../services/cache_manager_service.dart';
import '../services/viewing_history_service.dart';
import '../services/firebase_service.dart';
import '../widgets/profile/section_header.dart';
import '../widgets/common/custom_dialogs.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final String _appVersion = '1.5.0';
  Map<String, dynamic> _profileData = {};
  String _cacheSize = 'Calculando...';
  int _historyCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _loadCacheInfo();
  }

  Future<void> _loadProfileData() async {
    final data = await FirebaseService.getProfileData();
    if (mounted) {
      setState(() {
        _profileData = data;
      });
    }
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
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            children: [
              // Header con título
              _buildHeader(context),

              const SizedBox(height: 8),

              // Estadísticas
              _buildStats(context),

              // Grupo: Apariencia
              const SectionHeader(
                icon: Icons.palette_outlined,
                title: 'Apariencia',
              ),
              _buildAppearanceSection(context),

              // Grupo: Almacenamiento
              const SectionHeader(
                icon: Icons.storage_outlined,
                title: 'Almacenamiento',
              ),
              _buildStorageSection(context),

              // Grupo: Acerca de la App
              const SectionHeader(
                icon: Icons.info_outline,
                title: 'Acerca de la App',
              ),
              _buildAboutAppSection(context),

              // Grupo: Soporte
              const SectionHeader(
                icon: Icons.support_agent_outlined,
                title: 'Soporte',
              ),
              _buildSupportSection(context),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: const CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: Colors.blueGrey),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mi Perfil',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Usuario Pivote',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStats(BuildContext context) {
    return Consumer2<ChannelProvider, FavoritesProvider>(
      builder: (context, channelProvider, favoritesProvider, child) {
        final totalChannels = channelProvider.channels.length;
        final favoriteChannels = favoritesProvider.favoriteIds.length;
        final categories =
            channelProvider.categories.length - 1; // Excluding "Todos"

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  FontAwesomeIcons.tv,
                  totalChannels.toString(),
                  'Canales',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  FontAwesomeIcons.solidHeart,
                  favoriteChannels.toString(),
                  'Favoritos',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  FontAwesomeIcons.layerGroup,
                  categories.toString(),
                  'Categorías',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
      BuildContext context, dynamic icon, String value, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: (Theme.of(context).dividerTheme.color ?? Colors.white)
              .withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          icon is IconData
              ? Icon(icon,
                  color: Theme.of(context).colorScheme.primary, size: 24)
              : FaIcon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 22,
                ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required dynamic icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (Theme.of(context).dividerTheme.color ?? Colors.white)
              .withValues(alpha: 0.1),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDestructive
                ? Colors.red.withValues(alpha: 0.1)
                : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: icon is IconData
              ? Icon(
                  icon,
                  color: isDestructive
                      ? Colors.red
                      : Theme.of(context).colorScheme.primary,
                  size: 20,
                )
              : FaIcon(
                  icon,
                  color: isDestructive
                      ? Colors.red
                      : Theme.of(context).colorScheme.primary,
                  size: 18,
                ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? Colors.red : null,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey[600] : Colors.grey[500],
                ),
              )
            : null,
        trailing: trailing ??
            FaIcon(
              FontAwesomeIcons.chevronRight,
              size: 14,
              color: isDark ? Colors.grey[600] : Colors.grey[500],
            ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ==================== NEW SECTION METHODS ====================

  Widget _buildAppearanceSection(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return _buildOptionTile(
          context,
          icon: themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
          title: 'Modo ${themeProvider.isDarkMode ? 'oscuro' : 'claro'}',
          subtitle: 'Cambiar apariencia de la app',
          trailing: Switch(
            value: themeProvider.isDarkMode,
            onChanged: (value) {
              HapticFeedback.lightImpact();
              themeProvider.toggleTheme();
            },
            activeColor: Theme.of(context).colorScheme.primary,
          ),
          onTap: null,
        );
      },
    );
  }

  Widget _buildStorageSection(BuildContext context) {
    return Column(
      children: [
        _buildOptionTile(
          context,
          icon: Icons.cached,
          title: 'Caché de la aplicación',
          subtitle: _cacheSize,
          onTap: () {
            HapticFeedback.lightImpact();
            _showCacheManagementDialog(context);
          },
        ),
        _buildOptionTile(
          context,
          icon: Icons.history,
          title: 'Historial de visualización',
          subtitle: '$_historyCount canales vistos',
          onTap: () {
            HapticFeedback.lightImpact();
            _showHistoryDialog(context);
          },
        ),
        _buildOptionTile(
          context,
          icon: Icons.delete_sweep,
          title: 'Borrar todos los datos',
          subtitle: 'Eliminar caché e historial',
          isDestructive: true,
          onTap: () {
            HapticFeedback.mediumImpact();
            _showClearAllDataDialog(context);
          },
        ),
      ],
    );
  }

  Widget _buildAboutAppSection(BuildContext context) {
    return Column(
      children: [
        _buildOptionTile(
          context,
          icon: Icons.security,
          title: 'Seguridad y Privacidad',
          subtitle: 'Protección avanzada de datos',
          onTap: () {
            HapticFeedback.lightImpact();
            _showSecurityDialog(context);
          },
        ),
        _buildOptionTile(
          context,
          icon: Icons.star_outline,
          title: 'Características',
          subtitle: 'Descubre qué hace especial a Pivote',
          onTap: () {
            HapticFeedback.lightImpact();
            _showFeaturesDialog(context);
          },
        ),
        _buildOptionTile(
          context,
          icon: Icons.info_outline,
          title: 'Versión',
          subtitle: 'v$_appVersion',
          onTap: () {
            HapticFeedback.lightImpact();
            _showAboutDialog(context);
          },
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
          subtitle: 'Obtener asistencia',
          onTap: () {
            HapticFeedback.lightImpact();
            _showHelpDialog(context);
          },
        ),
        _buildOptionTile(
          context,
          icon: Icons.privacy_tip_outlined,
          title: 'Política de privacidad',
          subtitle: 'Cómo protegemos tus datos',
          onTap: () {
            HapticFeedback.lightImpact();
            _showPrivacyDialog(context);
          },
        ),
      ],
    );
  }

  // ==================== DIALOG METHODS ====================

  // Modern Help Dialog
  void _showHelpDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    CustomDialogs.showModernModalBottomSheet(
      context,
      title: 'Ayuda y soporte',
      titleIcon: FontAwesomeIcons.circleQuestion,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Subtitle (if needed inside)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              'Estamos aquí para ayudarte',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
          ),
          // Content
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildHelpCard(
                  context,
                  icon: FontAwesomeIcons.envelope,
                  title: 'Email',
                  subtitle:
                      _profileData['support_email'] ?? 'soporte@pivote.com',
                  onTap: () {
                    final email = _profileData['support_email'];
                    if (email != null) {
                      _launchUrl('mailto:$email');
                    }
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: FaIcon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const FaIcon(FontAwesomeIcons.chevronRight, size: 14),
        onTap: onTap,
      ),
    );
  }

  // Modern Privacy Dialog
  void _showPrivacyDialog(BuildContext context) {
    CustomDialogs.showModernModalBottomSheet(
      context,
      title: 'Privacidad',
      titleIcon: FontAwesomeIcons.shieldHalved,
      child: Flexible(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            _buildPrivacySection(
              context,
              title: 'Información que recopilamos',
              content:
                  'Recopilamos información que nos proporcionas directamente, como tu nombre, dirección de correo electrónico y preferencias de contenido.',
            ),
            _buildPrivacySection(
              context,
              title: 'Cómo usamos tu información',
              content:
                  'Usamos tu información para personalizar tu experiencia, mejorar nuestros servicios y comunicarnos contigo.',
            ),
            _buildPrivacySection(
              context,
              title: 'Compartir información',
              content:
                  'No vendemos ni alquilamos tu información personal a terceros. Podemos compartir información con proveedores de servicios de confianza.',
            ),
            _buildPrivacySection(
              context,
              title: 'Seguridad',
              content:
                  'Implementamos medidas de seguridad para proteger tu información personal.',
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacySection(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(
                FontAwesomeIcons.circleCheck,
                color: Theme.of(context).colorScheme.primary,
                size: 16,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[700],
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // Modern About Dialog
  void _showAboutDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    CustomDialogs.showModernModalBottomSheet(
      context,
      title: 'Acerca de',
      titleIcon: Icons.info_outline,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const FaIcon(FontAwesomeIcons.solidCirclePlay,
                color: Colors.white, size: 40),
          ),
          const SizedBox(height: 16),
          Text(
            'Pivote Studio',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text('Versión $_appVersion',
              style: TextStyle(
                  color: isDark ? Colors.grey[500] : Colors.grey[600])),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Aplicación profesional para ver canales de TV en vivo con una experiencia moderna y optimizada.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.grey[300] : Colors.grey[700],
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const FaIcon(FontAwesomeIcons.globe, size: 20),
            title: const Text('Sitio web'),
            onTap: () {
              final url = _profileData['website_url'];
              if (url != null) _launchUrl(url);
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showSecurityDialog(BuildContext context) {
    CustomDialogs.showModernModalBottomSheet(
      context,
      title: 'Seguridad',
      titleIcon: Icons.security,
      iconColor: Colors.green,
      child: Flexible(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(24),
          children: [
            _buildSecurityFeature(
              context,
              Icons.lock_outline,
              'Cifrado de Extremo a Extremo',
              'Comunicaciones protegidas con cifrado avanzado',
            ),
            _buildSecurityFeature(
              context,
              Icons.shield_outlined,
              'Protección de Datos',
              'Tus datos personales nunca son compartidos',
            ),
            _buildSecurityFeature(
              context,
              Icons.visibility_off_outlined,
              'Sin Rastreo',
              'No rastreamos tu actividad ni navegación',
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityFeature(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Colors.green,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFeaturesDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.star,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Características',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      Text(
                        'Lo que hace especial a Pivote',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color:
                                  isDark ? Colors.grey[500] : Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: [
                  _buildFeatureItem(
                    context,
                    Icons.live_tv,
                    'Streaming en Vivo',
                    'Acceso a canales de TV, Radio y Partidos en vivo',
                  ),
                  _buildFeatureItem(
                    context,
                    Icons.favorite,
                    'Favoritos',
                    'Guarda tus canales preferidos para acceso rápido',
                  ),
                  _buildFeatureItem(
                    context,
                    Icons.dark_mode,
                    'Modo Oscuro',
                    'Interfaz adaptable para cualquier condición de luz',
                  ),
                  _buildFeatureItem(
                    context,
                    Icons.speed,
                    'Rendimiento Óptimo',
                    'Carga rápida y reproducción fluida',
                  ),
                  _buildFeatureItem(
                    context,
                    Icons.devices,
                    'Multi-Dispositivo',
                    'Funciona en todos tus dispositivos',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showClearAllDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 12),
            Text('Borrar Todos los Datos'),
          ],
        ),
        content: const Text(
          'Esto eliminará todo el caché, historial y configuraciones. Esta acción no se puede deshacer.\n\n¿Estás seguro?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);

              // Show loading
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Eliminando datos...')),
                );
              }

              // Clear all data
              await CacheManagerService.clearAllCache(
                clearImages: true,
                clearAppData: true,
                clearHistory: true,
              );

              // Reload cache info
              await _loadCacheInfo();

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 12),
                        Text('Datos eliminados correctamente'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Borrar Todo'),
          ),
        ],
      ),
    );
  }

  void _showHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Historial de Visualización'),
        content: Text('Has visto $_historyCount canales diferentes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await ViewingHistoryService.clearHistory();
              await _loadCacheInfo();

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Historial eliminado')),
                );
              }
            },
            child: const Text('Borrar Historial'),
          ),
        ],
      ),
    );
  }

  // Modern Cache Management Dialog
  void _showCacheManagementDialog(BuildContext context) async {
    // Show minimal loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final stats = await CacheManagerService.getCacheStatistics();

    if (!context.mounted) return;
    Navigator.pop(context);

    CustomDialogs.showModernModalBottomSheet(
      context,
      title: 'Gestión de Caché',
      titleIcon: FontAwesomeIcons.database,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Stats Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                children: [
                  _buildModernStatRow(
                    context,
                    'Total utilizado',
                    stats['formattedTotalSize'] ?? '0 B',
                    icon: FontAwesomeIcons.hardDrive,
                    isTotal: true,
                  ),
                  const Divider(height: 32),
                  _buildModernStatRow(
                    context,
                    'Imágenes',
                    stats['formattedImageSize'] ?? '0 B',
                    icon: FontAwesomeIcons.image,
                  ),
                  const SizedBox(height: 12),
                  _buildModernStatRow(
                    context,
                    'Datos de App',
                    stats['formattedAppCacheSize'] ?? '0 B',
                    icon: FontAwesomeIcons.boxOpen,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showClearCacheDialog(context);
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const FaIcon(FontAwesomeIcons.broom, size: 16),
                    label: const Text('Limpiar Caché'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    CustomDialogs.showConfirmDialog(
      context,
      title: 'Limpiar Caché',
      message:
          '¿Estás seguro de que deseas limpiar el caché de la aplicación? Esto liberará espacio pero las imágenes se volverán a descargar.',
      confirmLabel: 'Limpiar',
      icon: FontAwesomeIcons.broom,
      isDestructive: true,
    ).then((confirmed) {
      if (confirmed == true && context.mounted) {
        _performCacheClear(context,
            clearImages: true, clearAppCache: true, clearHistory: false);
      }
    });
  }

  Future<void> _performCacheClear(
    BuildContext context, {
    required bool clearImages,
    required bool clearAppCache,
    required bool clearHistory,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await CacheManagerService.clearAllCache(
        clearImages: clearImages,
        clearAppData: clearAppCache,
        clearHistory: clearHistory,
      );

      if (context.mounted) {
        Navigator.pop(context);
        _loadCacheInfo();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Caché limpiado correctamente')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al limpiar el caché')),
        );
      }
    }
  }

  Widget _buildModernStatRow(BuildContext context, String label, String value,
      {required IconData icon, bool isTotal = false}) {
    final theme = Theme.of(context);
    return Row(
      children: [
        FaIcon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Text(label,
            style: TextStyle(fontWeight: isTotal ? FontWeight.bold : null)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isTotal ? theme.colorScheme.primary : null,
          ),
        ),
      ],
    );
  }

  // Helper for launching URLs
  Future<void> _launchUrl(String urlString) async {
    try {
      final Uri url = Uri.parse(urlString);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No se pudo abrir: $urlString')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al abrir el enlace')),
        );
      }
    }
  }
}
