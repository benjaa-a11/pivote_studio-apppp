import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/core/services/notification_service.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/shared/widgets/app_notifications.dart';
import 'package:pivote/shared/widgets/common/app_dialogs.dart';
import 'package:pivote/shared/widgets/common/apple_pressable.dart';
import 'package:pivote/shared/widgets/common/pivote_app_bar.dart';
import 'package:pivote/shared/widgets/common/pivote_loader.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends State<NotificationsSettingsScreen> {
  bool _enabled = false;
  bool _loading = true;

  bool _catSoccer = true;
  bool _catTv = true;
  bool _catRadio = true;
  bool _catUpdates = true;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    final enabled = await NotificationService.areNotificationsEnabled();
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _enabled = enabled;
      _catSoccer = prefs.getBool('notif_cat_soccer') ?? true;
      _catTv = prefs.getBool('notif_cat_tv') ?? true;
      _catRadio = prefs.getBool('notif_cat_radio') ?? true;
      _catUpdates = prefs.getBool('notif_cat_updates') ?? true;
      _loading = false;
    });
  }

  Future<void> _toggleCategory(String key, bool value) async {
    await HapticFeedback.selectionClick();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    if (!mounted) return;
    setState(() {
      if (key == 'notif_cat_soccer') _catSoccer = value;
      if (key == 'notif_cat_tv') _catTv = value;
      if (key == 'notif_cat_radio') _catRadio = value;
      if (key == 'notif_cat_updates') _catUpdates = value;
    });
  }

  Future<void> _toggle(bool value) async {
    await HapticFeedback.selectionClick();
    setState(() => _loading = true);
    try {
      if (value) {
        final granted = await NotificationService.requestPermission();
        if (!granted) {
          if (mounted) _showPermissionDialog();
          return;
        }
        _enabled = true;
        if (mounted) {
          AppNotifications.showSuccess(context, 'Notificaciones activadas');
        }
      } else {
        await NotificationService.disableNotifications();
        _enabled = false;
        if (mounted) {
          AppNotifications.showInfo(context, 'Notificaciones desactivadas');
        }
      }
    } catch (_) {
      if (mounted) {
        AppNotifications.showError(
            context, 'No pudimos actualizar la configuración');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showPermissionDialog() {
    AppDialogs.showConfirm(
      context: context,
      title: 'Permiso de notificaciones',
      message:
          'Para no perderte inicios de partidos y estrenos, habilita los permisos de notificación en el sistema.',
      confirmLabel: 'Abrir Configuración',
      cancelLabel: 'Ahora no',
      type: AppDialogType.warning,
    ).then((ok) {
      if (ok == true) openAppSettings();
    });
  }

  Future<void> _sendTest() async {
    if (!_enabled) {
      AppNotifications.showWarning(
          context, 'Activá las notificaciones primero');
      return;
    }
    await HapticFeedback.lightImpact();
    try {
      await NotificationService.sendTestNotification();
      if (mounted) {
        AppNotifications.showSuccess(
            context, 'Notificación de prueba enviada con éxito');
      }
    } catch (_) {
      if (mounted) {
        AppNotifications.showError(context, 'No pudimos enviar la prueba');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor =
        isDark ? AppTheme.darkAccent : theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const PivoteAppBar(
        title: 'Notificaciones',
        subtitle: 'Personalizá tus alertas de partidos y transmisiones',
      ),
      body: _loading && !_enabled
          ? const Center(child: PivoteLoader(size: 40))
          : ListView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              children: [
                // Top Master Status Banner
                AppAnimations.staggeredSlideIn(
                  index: 0,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _enabled
                            ? [
                                primaryColor.withValues(
                                    alpha: isDark ? .18 : .14),
                                isDark ? const Color(0xFF131722) : Colors.white,
                              ]
                            : [
                                isDark ? const Color(0xFF131722) : Colors.white,
                                isDark ? const Color(0xFF131722) : Colors.white,
                              ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _enabled
                            ? primaryColor.withValues(alpha: .3)
                            : (isDark
                                ? const Color(0xFF1E2533)
                                : AppTheme.lightBorder),
                      ),
                      boxShadow: AppShadows.appleDepth(context, elevation: 0.8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            _enabled
                                ? Icons.notifications_active_rounded
                                : Icons.notifications_off_rounded,
                            color: primaryColor,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    _enabled
                                        ? 'Alertas Activas'
                                        : 'Alertas Pausadas',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: (_enabled
                                              ? const Color(0xFF10B981)
                                              : theme.hintColor)
                                          .withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      _enabled ? 'ON' : 'OFF',
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        color: _enabled
                                            ? const Color(0xFF10B981)
                                            : theme.hintColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _enabled
                                    ? 'Recibirás avisos importantes en tiempo real.'
                                    : 'Activalas para enterarte cuando empiece un partido.',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: theme.hintColor,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: _enabled,
                          activeThumbColor: primaryColor,
                          activeTrackColor: primaryColor.withValues(alpha: 0.4),
                          onChanged: _loading ? null : _toggle,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 26),
                AppAnimations.staggeredSlideIn(
                  index: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 10),
                        child: Text(
                          'CATEGORÍAS DE ALERTAS',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.55),
                          ),
                        ),
                      ),
                      _categoryToggleCard(
                        context,
                        icon: Icons.sports_soccer_rounded,
                        title: 'Fútbol y Partidos en Vivo',
                        body:
                            'Avisos cuando comiencen partidos destacados y clásicos.',
                        color: const Color(0xFF10B981),
                        isDark: isDark,
                        value: _enabled && _catSoccer,
                        onChanged: _enabled
                            ? (v) => _toggleCategory('notif_cat_soccer', v)
                            : null,
                      ),
                      _categoryToggleCard(
                        context,
                        icon: Icons.live_tv_rounded,
                        title: 'Nuevos Canales y Eventos',
                        body:
                            'Señales agregadas y transmisiones especiales de fin de semana.',
                        color: const Color(0xFF5B8CFF),
                        isDark: isDark,
                        value: _enabled && _catTv,
                        onChanged: _enabled
                            ? (v) => _toggleCategory('notif_cat_tv', v)
                            : null,
                      ),
                      _categoryToggleCard(
                        context,
                        icon: Icons.radio_rounded,
                        title: 'Radios y Programas',
                        body: 'Emisiones destacadas de tus emisoras favoritas.',
                        color: const Color(0xFFF59E0B),
                        isDark: isDark,
                        value: _enabled && _catRadio,
                        onChanged: _enabled
                            ? (v) => _toggleCategory('notif_cat_radio', v)
                            : null,
                      ),
                      _categoryToggleCard(
                        context,
                        icon: Icons.auto_awesome_rounded,
                        title: 'Mejoras y Actualizaciones',
                        body:
                            'Nuevas funciones, optimizaciones y novedades de Pivote.',
                        color: const Color(0xFF8C6CFF),
                        isDark: isDark,
                        value: _enabled && _catUpdates,
                        onChanged: _enabled
                            ? (v) => _toggleCategory('notif_cat_updates', v)
                            : null,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                AppAnimations.staggeredSlideIn(
                  index: 2,
                  child: ApplePressable(
                    scaleDownFactor: 0.98,
                    borderRadius: BorderRadius.circular(18),
                    onTap: _sendTest,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 15),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF131722) : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: primaryColor.withValues(alpha: .20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.send_rounded,
                                size: 18, color: primaryColor),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Enviar notificación de prueba',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  'Verificá al instante cómo suenan y se ven tus alertas',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: theme.hintColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded,
                              size: 13, color: theme.hintColor),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _categoryToggleCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String body,
    required Color color,
    required bool isDark,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _enabled ? 1.0 : 0.55,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 13, 10, 13),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131722) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? const Color(0xFF1E2533) : AppTheme.lightBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      body,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: theme.hintColor,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: value,
                activeThumbColor: color,
                activeTrackColor: color.withValues(alpha: 0.35),
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
