import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/services/notification_service.dart';
import 'package:pivote/shared/widgets/app_notifications.dart';
import 'package:pivote/shared/widgets/common/app_dialogs.dart';
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

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    final enabled = await NotificationService.areNotificationsEnabled();
    if (!mounted) return;
    setState(() {
      _enabled = enabled;
      _loading = false;
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
        subtitle: 'Controlá cómo querés recibir avisos y alertas',
      ),
      body: _loading && !_enabled
          ? const Center(child: PivoteLoader(size: 40))
          : ListView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              children: [
                // Top Master Status Banner
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _enabled
                          ? [
                              primaryColor.withValues(
                                  alpha: isDark ? .18 : .14),
                              theme.colorScheme.surface,
                            ]
                          : [
                              theme.colorScheme.surface,
                              theme.colorScheme.surface,
                            ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color:
                          primaryColor.withValues(alpha: _enabled ? .25 : .08),
                    ),
                    boxShadow: _enabled
                        ? [
                            BoxShadow(
                              color: primaryColor.withValues(
                                  alpha: isDark ? 0.08 : 0.04),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : [],
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
                            Text(
                              _enabled ? 'Alertas Activas' : 'Alertas Pausadas',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _enabled
                                  ? 'Recibirás avisos de transmisiones en vivo y partidos.'
                                  : 'No recibirás avisos en tu dispositivo.',
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

                const SizedBox(height: 28),
                Text(
                  'Categorías de alertas',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                _info(
                  context,
                  Icons.sports_soccer_rounded,
                  'Fútbol y Partidos en Vivo',
                  'Avisos cuando comiencen partidos destacados y clásicos.',
                  const Color(0xFF10B981),
                  isDark,
                ),
                _info(
                  context,
                  Icons.live_tv_rounded,
                  'Nuevos Canales y Eventos',
                  'Señales agregadas y transmisiones exclusivas de fin de semana.',
                  const Color(0xFF5B8CFF),
                  isDark,
                ),
                _info(
                  context,
                  Icons.radio_rounded,
                  'Radios y Programas',
                  'Emisiones destacadas de tus emisoras favoritas.',
                  const Color(0xFFF59E0B),
                  isDark,
                ),
                _info(
                  context,
                  Icons.auto_awesome_rounded,
                  'Mejoras y Actualizaciones',
                  'Nuevas funciones, optimizaciones y avisos de la app.',
                  const Color(0xFF8C6CFF),
                  isDark,
                ),

                const SizedBox(height: 20),
                if (_enabled)
                  Material(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      onTap: _sendTest,
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 15),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: primaryColor.withValues(alpha: .15),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: .1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.send_rounded,
                                  size: 18, color: primaryColor),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Enviar notificación de prueba',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                ),
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

  Widget _info(BuildContext context, IconData icon, String title, String body,
      Color color, bool isDark) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
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
          ],
        ),
      ),
    );
  }
}
