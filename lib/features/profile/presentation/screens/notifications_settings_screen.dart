import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pivote/core/services/notification_service.dart';
import 'package:pivote/shared/widgets/app_notifications.dart';
import 'package:pivote/shared/widgets/common/app_dialogs.dart';
import 'package:pivote/shared/widgets/common/pivote_app_bar.dart';
import 'package:pivote/shared/widgets/common/pivote_loader.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
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
    setState(() { _enabled = enabled; _loading = false; });
  }

  Future<void> _toggle(bool value) async {
    setState(() => _loading = true);
    try {
      if (value) {
        final granted = await NotificationService.requestPermission();
        if (!granted) {
          if (mounted) _showPermissionDialog();
          return;
        }
        _enabled = true;
        if (mounted) AppNotifications.showSuccess(context, 'Notificaciones activadas');
      } else {
        await NotificationService.disableNotifications();
        _enabled = false;
        if (mounted) AppNotifications.showInfo(context, 'Notificaciones desactivadas');
      }
    } catch (_) {
      if (mounted) AppNotifications.showError(context, 'No pudimos actualizar la configuración');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showPermissionDialog() {
    AppDialogs.showConfirm(
      context: context,
      title: 'Permiso requerido',
      message: 'Habilitá las notificaciones en la configuración del dispositivo para recibir avisos.',
      confirmLabel: 'Configuración',
      cancelLabel: 'Ahora no',
      type: AppDialogType.warning,
    ).then((ok) { if (ok == true) openAppSettings(); });
  }

  Future<void> _sendTest() async {
    if (!_enabled) {
      AppNotifications.showWarning(context, 'Activá las notificaciones primero');
      return;
    }
    try {
      await NotificationService.sendTestNotification();
      if (mounted) AppNotifications.showSuccess(context, 'Notificación de prueba enviada');
    } catch (_) {
      if (mounted) AppNotifications.showError(context, 'No pudimos enviar la prueba');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const PivoteAppBar(title: 'Notificaciones', subtitle: 'Controlá cómo querés recibir avisos'),
      body: _loading && !_enabled
          ? const Center(child: PivoteLoader(size: 40))
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _enabled
                          ? [accent.withValues(alpha: isDark ? .16 : .12), theme.colorScheme.surface]
                          : [theme.colorScheme.surface, theme.colorScheme.surface],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: accent.withValues(alpha: _enabled ? .16 : .08)),
                  ),
                  child: Row(
                    children: [
                      Container(width: 54, height: 54, decoration: BoxDecoration(color: accent.withValues(alpha: .1), borderRadius: BorderRadius.circular(17)), child: Icon(_enabled ? Icons.notifications_active_rounded : Icons.notifications_none_rounded, color: accent, size: 26)),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_enabled ? 'Todo listo' : 'Notificaciones pausadas', style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w900)), const SizedBox(height: 3), Text(_enabled ? 'Pivote puede avisarte de novedades importantes.' : 'Podés volver a activarlas cuando quieras.', style: GoogleFonts.spaceGrotesk(fontSize: 11.5, fontWeight: FontWeight.w600, color: theme.hintColor, height: 1.35))])),
                      Switch.adaptive(value: _enabled, onChanged: _loading ? null : _toggle),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('Qué vas a recibir', style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                _info(context, Icons.live_tv_rounded, 'Nuevos canales', 'Avisos cuando se agreguen canales o señales.', const Color(0xFF5B8CFF)),
                _info(context, Icons.sports_soccer_rounded, 'Fútbol en vivo', 'Partidos importantes, resultados y novedades.', const Color(0xFF35B77A)),
                _info(context, Icons.auto_awesome_rounded, 'Actualizaciones', 'Nuevas funciones, mejoras y cambios importantes.', const Color(0xFF8C6CFF)),
                const SizedBox(height: 18),
                if (_enabled)
                  Material(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      onTap: _sendTest,
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: accent.withValues(alpha: .11))),
                        child: Row(children: [Container(width: 36, height: 36, decoration: BoxDecoration(color: accent.withValues(alpha: .1), borderRadius: BorderRadius.circular(11)), child: Icon(Icons.send_rounded, size: 17, color: accent)), const SizedBox(width: 11), Expanded(child: Text('Enviar notificación de prueba', style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w800)),), Icon(Icons.arrow_forward_ios_rounded, size: 12, color: theme.hintColor)]),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _info(BuildContext context, IconData icon, String title, String body, Color color) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(17), border: Border.all(color: color.withValues(alpha: .1))),
        child: Row(children: [Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withValues(alpha: .1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 19)), const SizedBox(width: 11), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w800)), const SizedBox(height: 2), Text(body, style: GoogleFonts.spaceGrotesk(fontSize: 10.5, fontWeight: FontWeight.w600, color: theme.hintColor, height: 1.35))]))]),
      ),
    );
  }
}
