import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pivote/core/services/notification_service.dart';
import 'package:pivote/shared/widgets/app_notifications.dart';
import 'package:pivote/shared/widgets/common/app_dialogs.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pivote/shared/widgets/common/pivote_loader.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends State<NotificationsSettingsScreen> {
  bool _notificationsEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkNotificationStatus();
  }

  Future<void> _checkNotificationStatus() async {
    final enabled = await NotificationService.areNotificationsEnabled();
    if (mounted) {
      setState(() {
        _notificationsEnabled = enabled;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() => _isLoading = true);

    try {
      if (value) {
        // Enable notifications
        final granted = await NotificationService.requestPermission();
        if (granted) {
          if (mounted) {
            AppNotifications.showSuccess(
              context,
              'Notificaciones activadas correctamente',
            );
          }
          setState(() => _notificationsEnabled = true);
        } else {
          if (mounted) {
            _showPermissionDialog();
          }
          setState(() => _notificationsEnabled = false);
        }
      } else {
        // Disable notifications
        await NotificationService.disableNotifications();
        if (mounted) {
          AppNotifications.showInfo(
            context,
            'Notificaciones desactivadas',
          );
        }
        setState(() => _notificationsEnabled = false);
      }
    } catch (e) {
      if (mounted) {
        AppNotifications.showError(
          context,
          'Error al cambiar configuración de notificaciones',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showPermissionDialog() {
    AppDialogs.showConfirm(
      context: context,
      title: 'Permiso requerido',
      message:
          'Para recibir notificaciones, necesitas habilitar los permisos en la configuración de tu dispositivo.',
      confirmLabel: 'Configuración',
      cancelLabel: 'Cancelar',
      type: AppDialogType.warning,
    ).then((confirmed) {
      if (confirmed == true) {
        openAppSettings();
      }
    });
  }

  Future<void> _sendTestNotification() async {
    if (!_notificationsEnabled) {
      AppNotifications.showWarning(
        context,
        'Primero activa las notificaciones',
      );
      return;
    }

    try {
      await NotificationService.sendTestNotification();
      if (mounted) {
        AppNotifications.showSuccess(
          context,
          'Notificación de prueba enviada',
        );
      }
    } catch (e) {
      if (mounted) {
        AppNotifications.showError(
          context,
          'Error al enviar notificación de prueba',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Notificaciones',
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: PivoteLoader(size: 40))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Icon
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withAlpha(26),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _notificationsEnabled
                            ? Icons.notifications_active
                            : Icons.notifications_off,
                        size: 50,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Main Toggle
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.dividerColor.withAlpha(13),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.notifications_active_outlined,
                          color: theme.colorScheme.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Notificaciones Push',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _notificationsEnabled
                                    ? 'Recibirás notificaciones'
                                    : 'No recibirás notificaciones',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurface
                                      .withAlpha(128),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _notificationsEnabled,
                          onChanged: _toggleNotifications,
                          activeThumbColor: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Information Section
                  Text(
                    '¿Qué notificaciones recibirás?',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildInfoCard(
                    context,
                    icon: Icons.live_tv,
                    title: 'Nuevos canales',
                    description:
                        'Te avisaremos cuando se agreguen nuevos canales',
                  ),
                  const SizedBox(height: 12),

                  _buildInfoCard(
                    context,
                    icon: Icons.sports_soccer,
                    title: 'Partidos en vivo',
                    description:
                        'Notificaciones sobre partidos importantes y resultados',
                  ),
                  const SizedBox(height: 12),

                  _buildInfoCard(
                    context,
                    icon: Icons.update,
                    title: 'Actualizaciones',
                    description: 'Información sobre nuevas funciones y mejoras',
                  ),
                  const SizedBox(height: 32),

                  // Test Notification Button
                  if (_notificationsEnabled)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _sendTestNotification,
                        icon: const Icon(Icons.send),
                        label: Text(
                          'Enviar notificación de prueba',
                          style: GoogleFonts.spaceGrotesk(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withAlpha(13),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha(26),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.primary,
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
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withAlpha(128),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
