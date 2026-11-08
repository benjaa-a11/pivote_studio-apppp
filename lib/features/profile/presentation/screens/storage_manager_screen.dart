import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/core/services/cache_manager_service.dart';
import 'package:pivote/core/theme/app_typography.dart';
import 'package:pivote/features/profile/presentation/widgets/profile_design_system.dart';
import 'package:pivote/shared/widgets/app_notifications.dart';
import 'package:pivote/shared/widgets/common/app_dialogs.dart';

class StorageManagerScreen extends StatefulWidget {
  const StorageManagerScreen({super.key});

  @override
  State<StorageManagerScreen> createState() => _StorageManagerScreenState();
}

class _StorageManagerScreenState extends State<StorageManagerScreen> {
  Map<String, dynamic> _stats = {};
  bool _isCleaning = false;
  bool _wifiOnly = true;
  String _downloadQuality = 'Alta';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      CacheManagerService.getCacheStatistics(),
      SharedPreferences.getInstance(),
    ]);
    if (!mounted) return;
    final stats = results[0] as Map<String, dynamic>;
    final prefs = results[1] as SharedPreferences;
    setState(() {
      _stats = stats;
      _wifiOnly = prefs.getBool('storage_wifi_only') ?? true;
      _downloadQuality = prefs.getString('storage_download_quality') ?? 'Alta';
    });
  }

  Future<void> _toggleWifiOnly(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('storage_wifi_only', val);
    if (mounted) {
      setState(() => _wifiOnly = val);
    }
  }

  Future<void> _pickDownloadQuality() async {
    final palette = ProfilePalette.of(context);
    final options = ['Alta', 'Media', 'Baja'];

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
                    'Calidad de descarga',
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
                        valueText:
                            _downloadQuality == opt ? 'Seleccionada' : null,
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
      await prefs.setString('storage_download_quality', chosen);
      if (mounted) {
        setState(() => _downloadQuality = chosen);
      }
    }
  }

  Future<void> _handleClearCache() async {
    final confirmed = await AppDialogs.showConfirm(
      context: context,
      title: '¿Limpiar caché?',
      message:
          'Se liberará el espacio temporal de imágenes y búfer de reproducción.',
      confirmLabel: 'Limpiar caché',
      cancelLabel: 'Cancelar',
      isDestructive: true,
      type: AppDialogType.warning,
    );

    if (confirmed != true || !mounted) return;

    await HapticFeedback.mediumImpact();
    setState(() => _isCleaning = true);
    await Future.delayed(const Duration(milliseconds: 400));

    await CacheManagerService.clearAllCache(clearHistory: false);
    await _loadData();

    if (mounted) {
      setState(() => _isCleaning = false);
      AppNotifications.showSuccess(context, 'Caché limpiada correctamente');
    }
  }

  Widget _buildDot(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = ProfilePalette.of(context);

    final totalFormatted =
        (_stats['formattedTotalSize'] as String?) ?? '0 B';
    final imageFormatted =
        (_stats['formattedImageSize'] as String?) ?? '0 B';
    final appCacheFormatted =
        (_stats['formattedAppCacheSize'] as String?) ?? '0 B';
    final prefsFormatted =
        (_stats['formattedPrefsSize'] as String?) ?? '0 B';

    final imgBytes = (_stats['imageCacheSize'] as int?) ?? 0;
    final appBytes = (_stats['appCacheSize'] as int?) ?? 0;
    final prefBytes = (_stats['preferencesSize'] as int?) ?? 0;
    final totalBytes = imgBytes + appBytes + prefBytes;

    // Proportional widths relative to 8 GB (or visual minimum so segments are visible)
    final double seg1 = totalBytes == 0
        ? 0.02
        : ((imgBytes / (64 * 1024 * 1024)).clamp(0.04, 0.25));
    final double seg2 = totalBytes == 0
        ? 0.01
        : ((appBytes / (64 * 1024 * 1024)).clamp(0.03, 0.20));
    final double seg3 = totalBytes == 0
        ? 0.01
        : ((prefBytes / (64 * 1024 * 1024)).clamp(0.015, 0.10));

    return ProfileSubsectionScaffold(
      title: 'Almacenamiento',
      children: [
        AppAnimations.staggeredSlideIn(
          index: 0,
          child: ProfileGroupCard(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          totalFormatted,
                          style: AppFont.primary(
                            fontSize: 32,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.64,
                            color: palette.text,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'de 8 GB usados',
                          style: AppFont.primary(
                            fontSize: 15,
                            color: palette.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        height: 14,
                        width: double.infinity,
                        color: palette.switchOff,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final maxW = constraints.maxWidth;
                            return Row(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: maxW * seg1,
                                  height: 14,
                                  color: const Color(0xFF4F9BF0),
                                ),
                                const SizedBox(width: 2),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: maxW * seg2,
                                  height: 14,
                                  color: const Color(0xFF3FD1A0),
                                ),
                                const SizedBox(width: 2),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: maxW * seg3,
                                  height: 14,
                                  color: const Color(0xFFF0C93A),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ProfileGroupRow(
                leading: _buildDot(const Color(0xFF4F9BF0)),
                title: 'Descargas',
                valueText: imageFormatted,
              ),
              ProfileGroupRow(
                leading: _buildDot(const Color(0xFF3FD1A0)),
                title: 'Caché',
                valueText: appCacheFormatted,
              ),
              ProfileGroupRow(
                leading: _buildDot(const Color(0xFFF0C93A)),
                title: 'Otros',
                valueText: prefsFormatted,
              ),
            ],
          ),
        ),
        AppAnimations.staggeredSlideIn(
          index: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ProfileSectionTitle('Descargas'),
              ProfileGroupCard(
                children: [
                  ProfileGroupRow(
                    title: 'Solo con Wi-Fi',
                    subtitle: 'Evitá gastar datos móviles',
                    onTap: () => _toggleWifiOnly(!_wifiOnly),
                    trailing: ProfileSwitch(
                      value: _wifiOnly,
                      onChanged: _toggleWifiOnly,
                    ),
                  ),
                  ProfileGroupRow(
                    title: 'Calidad de descarga',
                    valueText: _downloadQuality,
                    showChevron: true,
                    onTap: _pickDownloadQuality,
                  ),
                ],
              ),
            ],
          ),
        ),
        AppAnimations.staggeredSlideIn(
          index: 2,
          child: ProfileActionButton(
            label: 'Limpiar caché · $totalFormatted',
            variant: ProfileButtonVariant.soft,
            loading: _isCleaning,
            onTap: _handleClearCache,
          ),
        ),
      ],
    );
  }
}
