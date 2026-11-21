import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/core/services/cache_manager_service.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/features/profile/presentation/widgets/profile_design_system.dart';
import 'package:pivote/shared/widgets/app_notifications.dart';
import 'package:pivote/shared/widgets/common/app_dialogs.dart';
import 'package:pivote/shared/widgets/common/pivote_surfaces.dart';

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
    if (mounted) setState(() => _wifiOnly = val);
  }

  Future<void> _pickDownloadQuality() async {
    final options = [
      ('Alta', 'Máxima nitidez disponible'),
      ('Media', 'Balance entre calidad y datos'),
      ('Baja', 'Ahorro máximo de espacio'),
    ];

    final chosen = await AppDialogs.showModal<String>(
      context: context,
      child: Builder(
        builder: (ctx) => SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PivoteSheetHeader(
                  title: 'Calidad de descarga',
                  subtitle: 'Elegí la calidad predeterminada',
                  icon: Icons.high_quality_rounded,
                ),
                const SizedBox(height: 16),
                ProfileGroupCard(
                  children: [
                    for (final (label, desc) in options)
                      ProfileGroupRow(
                        title: label,
                        subtitle: desc,
                        trailing: _downloadQuality == label
                            ? Icon(
                                Icons.check_circle_rounded,
                                size: 20,
                                color: AppTheme.accent(ctx),
                              )
                            : null,
                        onTap: () => Navigator.pop(ctx, label),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (chosen != null && mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('storage_download_quality', chosen);
      if (mounted) setState(() => _downloadQuality = chosen);
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
    await Future.delayed(const Duration(milliseconds: 350));

    await CacheManagerService.clearAllCache(clearHistory: false);
    await _loadData();

    if (mounted) {
      setState(() => _isCleaning = false);
      AppNotifications.showSuccess(context, 'Caché limpiada correctamente');
    }
  }

  Widget _buildSegmentDot(Color color) {
    return Container(
      width: 11,
      height: 11,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.accent(context);
    final segColor1 = accent;
    final segColor2 = accent.withValues(alpha: 0.50);
    final segColor3 = AppTheme.textTertiary(context);

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

    final double seg1 = totalBytes == 0
        ? 0.025
        : ((imgBytes / (64 * 1024 * 1024)).clamp(0.05, 0.28));
    final double seg2 = totalBytes == 0
        ? 0.015
        : ((appBytes / (64 * 1024 * 1024)).clamp(0.035, 0.22));
    final double seg3 = totalBytes == 0
        ? 0.01
        : ((prefBytes / (64 * 1024 * 1024)).clamp(0.02, 0.12));

    return ProfileSubsectionScaffold(
      title: 'Almacenamiento',
      subtitle: 'Caché local y descargas',
      children: [
        AppAnimations.staggeredSlideIn(
          index: 0,
          child: ProfileGroupCard(
            highlighted: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          totalFormatted,
                          style: AppFont.mono(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.7,
                            color: AppTheme.textPrimary(context),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'en caché local',
                          style: AppFont.primary(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textTertiary(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: Container(
                        height: 11,
                        width: double.infinity,
                        color: AppTheme.surface3(context),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final maxW = constraints.maxWidth;
                            return Row(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: maxW * seg1,
                                  height: 11,
                                  color: segColor1,
                                ),
                                const SizedBox(width: 2),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: maxW * seg2,
                                  height: 11,
                                  color: segColor2,
                                ),
                                const SizedBox(width: 2),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: maxW * seg3,
                                  height: 11,
                                  color: segColor3,
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
                leading: _buildSegmentDot(segColor1),
                title: 'Imágenes y logos',
                valueText: imageFormatted,
              ),
              ProfileGroupRow(
                leading: _buildSegmentDot(segColor2),
                title: 'Caché de aplicación',
                valueText: appCacheFormatted,
              ),
              ProfileGroupRow(
                leading: _buildSegmentDot(segColor3),
                title: 'Preferencias y datos',
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
                    subtitle: 'Evitá consumir datos móviles',
                    onTap: () => _toggleWifiOnly(!_wifiOnly),
                    trailing: ProfileSwitch(
                      value: _wifiOnly,
                      onChanged: _toggleWifiOnly,
                    ),
                  ),
                  ProfileGroupRow(
                    title: 'Calidad predeterminada',
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
