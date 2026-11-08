import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/core/services/notification_service.dart';
import 'package:pivote/core/theme/app_typography.dart';
import 'package:pivote/features/profile/presentation/widgets/profile_design_system.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends State<NotificationsSettingsScreen> {
  bool _newVideos = true;
  bool _liveNow = true;
  bool _continueWatching = false;
  bool _newsAndReleases = true;
  String _quietHours = '23:00 – 07:00';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _newVideos = prefs.getBool('notif_new_videos') ?? true;
      _liveNow = prefs.getBool('notif_live_now') ?? true;
      _continueWatching = prefs.getBool('notif_continue_watching') ?? false;
      _newsAndReleases = prefs.getBool('notif_news_releases') ?? true;
      _quietHours = prefs.getString('notif_quiet_hours') ?? '23:00 – 07:00';
    });
  }

  Future<void> _updatePref(String key, bool value) async {
    await HapticFeedback.selectionClick();
    if (value) {
      final enabled = await NotificationService.areNotificationsEnabled();
      if (!enabled) {
        await NotificationService.requestPermission();
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    if (!mounted) return;
    setState(() {
      if (key == 'notif_new_videos') _newVideos = value;
      if (key == 'notif_live_now') _liveNow = value;
      if (key == 'notif_continue_watching') _continueWatching = value;
      if (key == 'notif_news_releases') _newsAndReleases = value;
    });
  }

  Future<void> _pickQuietHours() async {
    final palette = ProfilePalette.of(context);
    final options = [
      '23:00 – 07:00',
      '22:00 – 07:00',
      '00:00 – 08:00',
      'Desactivado',
    ];

    final chosen = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: palette.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  child: Text(
                    'Horario silencioso',
                    style: AppFont.primary(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: palette.text,
                    ),
                  ),
                ),
                ProfileGroupCard(
                  children: [
                    for (final opt in options)
                      ProfileGroupRow(
                        title: opt,
                        valueText: _quietHours == opt ? 'Activo' : null,
                        onTap: () => Navigator.pop(ctx, opt),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (chosen != null && mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('notif_quiet_hours', chosen);
      if (mounted) {
        setState(() => _quietHours = chosen);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProfileSubsectionScaffold(
      title: 'Notificaciones',
      children: [
        AppAnimations.staggeredSlideIn(
          index: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ProfileSectionTitle('Canales', first: true),
              ProfileGroupCard(
                children: [
                  ProfileGroupRow(
                    title: 'Nuevos videos',
                    subtitle: 'De los canales que seguís',
                    onTap: () => _updatePref('notif_new_videos', !_newVideos),
                    trailing: ProfileSwitch(
                      value: _newVideos,
                      onChanged: (v) => _updatePref('notif_new_videos', v),
                    ),
                  ),
                  ProfileGroupRow(
                    title: 'En vivo ahora',
                    subtitle: 'Cuando un canal inicia una transmisión',
                    onTap: () => _updatePref('notif_live_now', !_liveNow),
                    trailing: ProfileSwitch(
                      value: _liveNow,
                      onChanged: (v) => _updatePref('notif_live_now', v),
                    ),
                  ),
                  ProfileGroupRow(
                    title: 'Seguir viendo',
                    subtitle: 'Recordatorio de lo que dejaste a medias',
                    onTap: () => _updatePref(
                        'notif_continue_watching', !_continueWatching),
                    trailing: ProfileSwitch(
                      value: _continueWatching,
                      onChanged: (v) =>
                          _updatePref('notif_continue_watching', v),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        AppAnimations.staggeredSlideIn(
          index: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ProfileSectionTitle('Pivote'),
              ProfileGroupCard(
                children: [
                  ProfileGroupRow(
                    title: 'Novedades y estrenos',
                    onTap: () =>
                        _updatePref('notif_news_releases', !_newsAndReleases),
                    trailing: ProfileSwitch(
                      value: _newsAndReleases,
                      onChanged: (v) => _updatePref('notif_news_releases', v),
                    ),
                  ),
                  const ProfileGroupRow(
                    title: 'Avisos de seguridad',
                    subtitle: 'Siempre activos por tu protección',
                    trailing: ProfileSwitch(
                      value: true,
                      enabled: false,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        AppAnimations.staggeredSlideIn(
          index: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ProfileSectionTitle('No molestar'),
              ProfileGroupCard(
                children: [
                  ProfileGroupRow(
                    title: 'Horario silencioso',
                    valueText: _quietHours,
                    showChevron: true,
                    onTap: _pickQuietHours,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
