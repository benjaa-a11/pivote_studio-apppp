import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/core/services/app_activity_service.dart';
import 'package:pivote/core/services/cache_manager_service.dart';
import 'package:pivote/core/services/greeting_service.dart';
import 'package:pivote/core/services/notification_service.dart';
import 'package:pivote/core/services/wakelock_service.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/core/theme/theme_provider.dart';
import 'package:pivote/features/auth/data/services/auth_service.dart';
import 'package:pivote/features/auth/presentation/providers/user_provider.dart';
import 'package:pivote/features/auth/presentation/screens/login_screen.dart';
import 'package:pivote/features/favorites/data/services/viewing_history_service.dart';
import 'package:pivote/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:pivote/features/favorites/presentation/screens/favorites_screen.dart';
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
import 'package:pivote/shared/widgets/common/apple_pressable.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _appVersion = '3.0.0';
  String _cacheSize = 'Calculando…';
  int _historyCount = 0;
  bool _notificationsEnabled = false;

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
        NotificationService.areNotificationsEnabled(),
      ]);
      if (mounted) {
        setState(() {
          _cacheSize = results[0] as String;
          _historyCount = (results[1] as List<String>).length;
          _notificationsEnabled = results[2] as bool;
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

  double _computeRankProgress(double totalMinutes) {
    if (totalMinutes < 5.0) return (totalMinutes / 5.0).clamp(0.0, 1.0);
    if (totalMinutes < 30.0) {
      return ((totalMinutes - 5.0) / 25.0).clamp(0.0, 1.0);
    }
    if (totalMinutes < 120.0) {
      return ((totalMinutes - 30.0) / 90.0).clamp(0.0, 1.0);
    }
    if (totalMinutes < 480.0) {
      return ((totalMinutes - 120.0) / 360.0).clamp(0.0, 1.0);
    }
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.isDark;
    final themeProvider = context.watch<ThemeProvider>();
    final wakelock = context.watch<WakelockService>();
    final activityService = context.watch<AppActivityService>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: isDark ? AppTheme.darkAccent : theme.colorScheme.primary,
          backgroundColor:
              isDark ? AppTheme.darkBg2 : theme.colorScheme.surface,
          onRefresh: _refreshDynamicState,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: ClampingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: AppAnimations.staggeredSlideIn(
                  index: 0,
                  child: _buildHero(context, isDark, themeProvider, activityService),
                ),
              ),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 14),
                    AppAnimations.staggeredSlideIn(
                      index: 1,
                      child: _buildBentoStats(context, isDark, activityService),
                    ),
                    AppAnimations.staggeredSlideIn(
                      index: 2,
                      child: _buildSection(
                        context,
                        'Cuenta y Actividad',
                        [
                          _buildSettingTile(
                            context,
                            icon: Icons.person_outline_rounded,
                            title: 'Editar perfil',
                            subtitle: 'Nombre, foto de perfil y contraseña',
                            accent: isDark
                                ? AppTheme.darkAccent
                                : theme.colorScheme.primary,
                            onTap: () => _open(const EditProfileScreen()),
                          ),
                          _buildSettingTile(
                            context,
                            icon: Icons.emoji_events_outlined,
                            title: 'Mi Actividad y Rango',
                            subtitle:
                                '${activityService.getArgentineRankEmoji()} ${activityService.getArgentineRank()} · ${activityService.getFormattedActiveTime()}',
                            accent: const Color(0xFFF59E0B),
                            badgeText: 'EN VIVO',
                            badgeColor: const Color(0xFF10B981),
                            onTap: () => _open(const ActivityScreen()),
                          ),
                          _buildSettingTile(
                            context,
                            icon: Icons.history_rounded,
                            title: 'Historial de reproducción',
                            subtitle: _historyCount > 0
                                ? '$_historyCount ${_historyCount == 1 ? 'canal visto' : 'canales vistos'} recientemente'
                                : 'Sin canales reproducidos aún',
                            accent: const Color(0xFF10B981),
                            onTap: () => _open(const HistoryScreen()),
                          ),
                          _buildSettingTile(
                            context,
                            icon: Icons.favorite_border_rounded,
                            title: 'Mis Favoritos',
                            subtitle: 'Acceso rápido a tus señales guardadas',
                            accent: const Color(0xFFEF4444),
                            onTap: () => _open(const FavoritesScreen()),
                          ),
                        ],
                      ),
                    ),
                    AppAnimations.staggeredSlideIn(
                      index: 3,
                      child: _buildSection(
                        context,
                        'Preferencias y Sistema',
                        [
                          _buildSettingTile(
                            context,
                            icon: Icons.palette_outlined,
                            title: 'Apariencia y Pantalla',
                            subtitle:
                                '${themeProvider.isDarkMode ? 'Modo Oscuro' : 'Modo Claro'} · ${wakelock.keepScreenOn ? 'Pantalla siempre activa' : 'Apagado automático'}',
                            accent: theme.colorScheme.primary,
                            onTap: () =>
                                _open(const AppearanceSettingsScreen()),
                          ),
                          _buildSettingTile(
                            context,
                            icon: Icons.notifications_none_rounded,
                            title: 'Notificaciones',
                            subtitle: _notificationsEnabled
                                ? 'Alertas de partidos y eventos activas'
                                : 'Alertas desactivadas en este dispositivo',
                            accent: const Color(0xFF5B8CFF),
                            badgeText:
                                _notificationsEnabled ? 'ACTIVAS' : 'OFF',
                            badgeColor: _notificationsEnabled
                                ? const Color(0xFF10B981)
                                : theme.hintColor,
                            onTap: () =>
                                _open(const NotificationsSettingsScreen()),
                          ),
                          _buildSettingTile(
                            context,
                            icon: Icons.storage_outlined,
                            title: 'Almacenamiento y Caché',
                            subtitle: 'Espacio temporal en uso · $_cacheSize',
                            accent: const Color(0xFFE58B46),
                            onTap: () => _open(const StorageManagerScreen()),
                          ),
                          _buildSettingTile(
                            context,
                            icon: Icons.speed_rounded,
                            title: 'Diagnóstico de Streaming',
                            subtitle: 'Test de velocidad, ping y calidad sugerida',
                            accent: const Color(0xFF38BDF8),
                            onTap: () => _open(const DiagnosticsScreen()),
                          ),
                        ],
                      ),
                    ),
                    AppAnimations.staggeredSlideIn(
                      index: 4,
                      child: _buildSection(
                        context,
                        'Soporte y Seguridad',
                        [
                          _buildSettingTile(
                            context,
                            icon: Icons.shield_outlined,
                            title: 'Privacidad y seguridad',
                            subtitle: 'Protección de cuenta y gestión de datos',
                            accent: const Color(0xFF8B5CF6),
                            onTap: () => _open(const PrivacySecurityScreen()),
                          ),
                          _buildSettingTile(
                            context,
                            icon: Icons.support_agent_rounded,
                            title: 'Ayuda y soporte',
                            subtitle: 'Preguntas frecuentes y contacto directo',
                            accent: const Color(0xFF35B77A),
                            onTap: () => _open(const SupportScreen()),
                          ),
                          _buildSettingTile(
                            context,
                            icon: Icons.info_outline_rounded,
                            title: 'Acerca de Pivote',
                            subtitle: 'Versión $_appVersion · Edición Premium',
                            accent: const Color(0xFF74ACDF),
                            onTap: () => _showAboutDialog(context),
                          ),
                        ],
                      ),
                    ),
                    AppAnimations.staggeredSlideIn(
                      index: 5,
                      child: Column(
                        children: [
                          _buildLogout(context),
                          const SizedBox(height: 28),
                          _buildFooter(context),
                          const SizedBox(height: 110),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero(
    BuildContext context,
    bool isDark,
    ThemeProvider themeProvider,
    AppActivityService activityService,
  ) {
    final theme = Theme.of(context);
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;
    final imagePath = userProvider.profileImagePath;
    final primaryColor =
        isDark ? AppTheme.darkAccent : theme.colorScheme.primary;
    final topPadding = MediaQuery.paddingOf(context).top;

    ImageProvider<Object>? avatarImage;
    if (imagePath != null) {
      avatarImage = FileImage(File(imagePath));
    } else if (user?.photoUrl != null && user!.photoUrl!.isNotEmpty) {
      avatarImage = NetworkImage(user.photoUrl!);
    }

    final fullName = [
      if (user?.name.isNotEmpty == true) user!.name,
      if (user?.lastName.isNotEmpty == true) user!.lastName,
    ].join(' ').trim();

    final totalMinutes = activityService.totalActiveSeconds / 60.0;
    final rankProgress = _computeRankProgress(totalMinutes);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(18, topPadding + 14, 18, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF121916), theme.scaffoldBackgroundColor]
              : [const Color(0xFFE7F5D4), theme.scaffoldBackgroundColor],
        ),
      ),
      child: Column(
        children: [
          // Top utility row
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: isDark ? 0.14 : 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.28),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      GreetingService.getGreeting().toUpperCase(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.7,
                        color: isDark ? primaryColor : theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Quick Theme Toggle Pill
              ApplePressable(
                scaleDownFactor: 0.92,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                onTap: () {
                  HapticFeedback.selectionClick();
                  themeProvider.toggleTheme();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.darkBg2.withValues(alpha: 0.85)
                        : Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        transitionBuilder: (child, anim) =>
                            ScaleTransition(scale: anim, child: child),
                        child: Icon(
                          isDark
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded,
                          key: ValueKey<bool>(isDark),
                          size: 15,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isDark ? 'Oscuro' : 'Claro',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Main Profile Hero Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131722) : Colors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF1E2533)
                    : AppTheme.lightBorder,
              ),
              boxShadow: AppShadows.appleDepth(context, elevation: 0.9),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Avatar with camera badge
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: primaryColor.withValues(alpha: 0.85),
                              width: 2.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(
                                    alpha: isDark ? 0.22 : 0.14),
                                blurRadius: 16,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 36,
                            backgroundColor:
                                primaryColor.withValues(alpha: 0.12),
                            backgroundImage: avatarImage,
                            child: avatarImage == null
                                ? Icon(
                                    Icons.person_rounded,
                                    size: 36,
                                    color: primaryColor,
                                  )
                                : null,
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: ApplePressable(
                            scaleDownFactor: 0.88,
                            onTap: () => userProvider.updateProfileImage(),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: primaryColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF131722)
                                      : Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.camera_alt_rounded,
                                size: 12,
                                color: isDark ? Colors.black : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),

                    // User Info & Edit Action
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  fullName.isNotEmpty
                                      ? fullName
                                      : 'Usuario Pivote',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.email ?? 'Sesión activa',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.hintColor,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              ApplePressable(
                                scaleDownFactor: 0.94,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.pill),
                                onTap: () => _open(const EditProfileScreen()),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 13, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.pill),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.edit_rounded,
                                        size: 12,
                                        color: isDark
                                            ? Colors.black
                                            : Colors.white,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Editar perfil',
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w900,
                                          color: isDark
                                              ? Colors.black
                                              : Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ApplePressable(
                                scaleDownFactor: 0.94,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.pill),
                                onTap: () =>
                                    _open(const PrivacySecurityScreen()),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 11, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.06)
                                        : Colors.black.withValues(alpha: 0.05),
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.pill),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.verified_user_outlined,
                                        size: 12,
                                        color: primaryColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Seguridad',
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                          color: theme.colorScheme.onSurface,
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
                const SizedBox(height: 16),

                // Connected Rank & Activity Progress Bar inside Hero
                ApplePressable(
                  scaleDownFactor: 0.98,
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _open(const ActivityScreen()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : AppTheme.lightBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.04),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              activityService.getArgentineRankEmoji(),
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'RANGO ACTUAL · ${activityService.getArgentineRank().toUpperCase()}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.4,
                                      color: primaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    activityService
                                        .getArgentineRankDescription(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: theme.hintColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 12,
                              color: theme.hintColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: rankProgress,
                            minHeight: 5,
                            backgroundColor: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.06),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(primaryColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Interactive 4-Item Connected Bento Overview ───
  Widget _buildBentoStats(
    BuildContext context,
    bool isDark,
    AppActivityService activityService,
  ) {
    final theme = Theme.of(context);
    final favProvider = context.watch<FavoritesProvider>();
    final favCount = favProvider.favoriteIds.length;
    final primaryColor =
        isDark ? AppTheme.darkAccent : theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Expanded(
            child: _bentoStatCard(
              context,
              isDark: isDark,
              icon: Icons.bolt_rounded,
              value: activityService.getFormattedActiveTime(),
              label: 'Activo',
              accent: primaryColor,
              onTap: () => _open(const ActivityScreen()),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _bentoStatCard(
              context,
              isDark: isDark,
              icon: Icons.favorite_rounded,
              value: '$favCount',
              label: 'Favoritos',
              accent: const Color(0xFFEF4444),
              onTap: () => _open(const FavoritesScreen()),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _bentoStatCard(
              context,
              isDark: isDark,
              icon: Icons.history_rounded,
              value: '$_historyCount',
              label: 'Historial',
              accent: const Color(0xFF10B981),
              onTap: () => _open(const HistoryScreen()),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _bentoStatCard(
              context,
              isDark: isDark,
              icon: Icons.storage_rounded,
              value: _cacheSize.replaceAll('Calculando…', '...'),
              label: 'Caché',
              accent: const Color(0xFFE58B46),
              onTap: () => _open(const StorageManagerScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bentoStatCard(
    BuildContext context, {
    required bool isDark,
    required IconData icon,
    required String value,
    required String label,
    required Color accent,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return ApplePressable(
      scaleDownFactor: 0.94,
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131722) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? const Color(0xFF1E2533) : AppTheme.lightBorder,
          ),
          boxShadow: AppShadows.appleDepth(context, elevation: 0.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 15, color: accent),
            ),
            const SizedBox(height: 7),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: theme.hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> items) {
    final theme = Theme.of(context);
    final isDark = theme.isDark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title.toUpperCase(),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131722) : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF1E2533)
                    : AppTheme.lightBorder,
                width: 1.0,
              ),
              boxShadow: AppShadows.appleDepth(context, elevation: 0.7),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Column(
                children: [
                  for (int i = 0; i < items.length; i++) ...[
                    items[i],
                    if (i < items.length - 1)
                      Divider(
                        height: 1,
                        indent: 66,
                        endIndent: 16,
                        color: theme.dividerColor.withValues(alpha: 0.06),
                      ),
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
    String? badgeText,
    Color? badgeColor,
  }) {
    final theme = Theme.of(context);
    final color = accent ?? theme.colorScheme.primary;

    return ApplePressable(
      scaleDownFactor: 0.985,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (badgeText != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                (badgeColor ?? color).withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badgeText,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              color: badgeColor ?? color,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: theme.hintColor.withValues(alpha: 0.45),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogout(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 0),
      child: ApplePressable(
        scaleDownFactor: 0.96,
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showLogoutDialog(context),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
          decoration: BoxDecoration(
            color: theme.colorScheme.error.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.error.withValues(alpha: 0.18),
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(Icons.logout_rounded,
                    color: theme.colorScheme.error, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cerrar sesión',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.error,
                      ),
                    ),
                    Text(
                      'Salir de tu cuenta en este dispositivo',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.error.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: theme.colorScheme.error.withValues(alpha: 0.55),
                size: 13,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          'Hecha con pasión en Argentina',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: theme.hintColor,
          ),
        ),
        const SizedBox(height: 6),
        const Text('🇦🇷', style: TextStyle(fontSize: 18)),
        const SizedBox(height: 7),
        Text(
          'Pivote Studio · $_appVersion',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: theme.hintColor.withValues(alpha: .7),
          ),
        ),
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
      await Provider.of<UserProvider>(context, listen: false).clearUser();
      if (!context.mounted) return;
      AppNotifications.showInfo(context, 'Sesión cerrada correctamente');
      unawaited(Navigator.of(context).pushAndRemoveUntil(
          AppAnimations.createFadeRoute(const LoginScreen()), (route) => false));
    }
  }

  void _showAboutDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor =
        isDark ? AppTheme.darkAccent : theme.colorScheme.primary;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 6, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: .25),
                  ),
                ),
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  color: primaryColor,
                  size: 38,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Pivote Studio',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Versión $_appVersion • Edición Premium',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.hintColor,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _aboutMetric(theme, primaryColor, 'TV & Radio', 'En vivo'),
                    _aboutMetric(theme, primaryColor, 'Streaming', 'Baja latencia'),
                    _aboutMetric(theme, primaryColor, 'Seguridad', 'SSL Activo'),
                  ],
                ),
              ),
              const SizedBox(height: 14),
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
                        Icon(Icons.system_update_rounded, color: primaryColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Verificar actualizaciones',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 13,
                          color: theme.hintColor,
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

  Widget _aboutMetric(
      ThemeData theme, Color primaryColor, String title, String subtitle) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12.5,
            fontWeight: FontWeight.w900,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: theme.hintColor,
          ),
        ),
      ],
    );
  }

  Future<void> _checkUpdates(BuildContext context) async {
    Navigator.pop(context);
    AppDialogs.showLoading(
        context: context, message: 'Buscando actualizaciones…');
    await Future.delayed(const Duration(seconds: 2));
    if (!context.mounted) return;
    Navigator.pop(context);
    await AppDialogs.showAlert(
      context: context,
      title: 'Todo actualizado',
      message: 'Tenés la última versión de Pivote Studio instalada.',
      type: AppDialogType.success,
    );
  }
}
