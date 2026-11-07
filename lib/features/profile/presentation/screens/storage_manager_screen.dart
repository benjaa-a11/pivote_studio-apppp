import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/core/services/cache_manager_service.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/features/profile/presentation/screens/history_screen.dart';
import 'package:pivote/shared/widgets/app_notifications.dart';
import 'package:pivote/shared/widgets/common/app_dialogs.dart';
import 'package:pivote/shared/widgets/common/apple_pressable.dart';
import 'package:pivote/shared/widgets/common/pivote_app_bar.dart';
import 'package:pivote/shared/widgets/common/pivote_loader.dart';

class StorageManagerScreen extends StatefulWidget {
  const StorageManagerScreen({super.key});

  @override
  State<StorageManagerScreen> createState() => _StorageManagerScreenState();
}

class _StorageManagerScreenState extends State<StorageManagerScreen> {
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  bool _isCleaning = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    final stats = await CacheManagerService.getCacheStatistics();
    if (mounted) {
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleClearCache(String type) async {
    String title = '¿Limpiar caché?';
    String message = 'Esta acción liberará espacio en tu dispositivo.';

    if (type == 'all') {
      title = '¿Liberar todo el espacio?';
      message =
          'Se borrarán todos los datos temporales e imágenes descargadas.';
    } else if (type == 'images') {
      title = '¿Borrar imágenes en caché?';
      message = 'Se eliminarán las miniaturas y logos guardados temporalmente.';
    } else if (type == 'app') {
      title = '¿Limpiar datos de la app?';
      message = 'Se restablecerán los buffers y temporales de reproducción.';
    }

    final confirmed = await AppDialogs.showConfirm(
      context: context,
      title: title,
      message: message,
      confirmLabel: 'Liberar espacio',
      cancelLabel: 'Cancelar',
      isDestructive: true,
      type: AppDialogType.error,
    );

    if (confirmed != true) return;

    await HapticFeedback.mediumImpact();
    setState(() => _isCleaning = true);

    await Future.delayed(const Duration(milliseconds: 550));

    if (type == 'all') {
      await CacheManagerService.clearAllCache();
    } else if (type == 'images') {
      await CacheManagerService.clearImageCache();
    } else if (type == 'app') {
      await CacheManagerService.clearAppCache();
    }

    await _loadStats();
    if (mounted) {
      setState(() => _isCleaning = false);
      AppNotifications.showSuccess(context, 'Espacio liberado correctamente');
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
        title: 'Almacenamiento y Caché',
        subtitle: 'Administrá la memoria temporal y optimizá el rendimiento',
      ),
      body: _isLoading
          ? const Center(child: PivoteLoader(size: 40))
          : SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppAnimations.staggeredSlideIn(
                    index: 0,
                    child: _buildStorageOverview(context, isDark, primaryColor),
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
                            'DESGLOSE DE MEMORIA',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.7,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.55),
                            ),
                          ),
                        ),
                        _buildStorageItem(
                          context,
                          title: 'Imágenes y Logos',
                          subtitle:
                              'Miniaturas de canales, escudos, radios y pósters',
                          size: _stats['formattedImageSize'] ?? '0 B',
                          icon: Icons.image_outlined,
                          color: const Color(0xFFE58B46),
                          onClear: () => _handleClearCache('images'),
                        ),
                        _buildStorageItem(
                          context,
                          title: 'Búfer de Streaming y Datos',
                          subtitle:
                              'Fragmentos temporales de video y audio en vivo',
                          size: _stats['formattedAppCacheSize'] ?? '0 B',
                          icon: Icons.data_usage_outlined,
                          color: const Color(0xFF10B981),
                          onClear: () => _handleClearCache('app'),
                        ),
                        _buildStorageItem(
                          context,
                          title: 'Preferencias y Ajustes',
                          subtitle:
                              'Configuración local, tema y sesión guardada',
                          size: _stats['formattedPrefsSize'] ?? '0 B',
                          icon: Icons.tune_rounded,
                          color: const Color(0xFF5B8CFF),
                          showClear: false,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppAnimations.staggeredSlideIn(
                    index: 2,
                    child: _buildConnectedHistoryCard(context, isDark),
                  ),
                  const SizedBox(height: 24),
                  AppAnimations.staggeredSlideIn(
                    index: 3,
                    child: _buildClearAllButton(context, isDark, primaryColor),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStorageOverview(
      BuildContext context, bool isDark, Color primaryColor) {
    final theme = Theme.of(context);
    final totalSize = _stats['formattedTotalSize'] ?? '0 B';
    final imgBytes = (_stats['imageCacheSize'] as int?) ?? 0;
    final appBytes = (_stats['appCacheSize'] as int?) ?? 0;
    final prefBytes = (_stats['preferencesSize'] as int?) ?? 0;
    final sumBytes = (imgBytes + appBytes + prefBytes).clamp(1, 1 << 30);

    final imgFlex = ((imgBytes / sumBytes) * 100).round().clamp(8, 84);
    final appFlex = ((appBytes / sumBytes) * 100).round().clamp(8, 84);
    final prefFlex = ((prefBytes / sumBytes) * 100).round().clamp(6, 40);

    return Container(
      padding: const EdgeInsets.all(22),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF18221D), const Color(0xFF11161C)]
              : [
                  primaryColor.withValues(alpha: 0.14),
                  Colors.white,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: primaryColor.withValues(alpha: isDark ? 0.25 : 0.2),
        ),
        boxShadow: AppShadows.appleDepth(context, elevation: 0.9),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.storage_rounded,
                    color: primaryColor, size: 25),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ESPACIO TEMPORAL EN USO',
                      style: GoogleFonts.spaceGrotesk(
                        color: primaryColor,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      child: Text(
                        totalSize,
                        key: ValueKey(totalSize),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Visual Segmented Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  Expanded(
                    flex: imgFlex,
                    child: Container(color: const Color(0xFFE58B46)),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: appFlex,
                    child: Container(color: const Color(0xFF10B981)),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: prefFlex,
                    child: Container(color: const Color(0xFF5B8CFF)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Legend & Last Clean Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _legendDot(theme, const Color(0xFFE58B46), 'Imágenes'),
              _legendDot(theme, const Color(0xFF10B981), 'Búfer'),
              _legendDot(theme, const Color(0xFF5B8CFF), 'Ajustes'),
              Text(
                'Limpiezas: ${_stats['totalClears'] ?? 0}',
                style: GoogleFonts.spaceGrotesk(
                  color: theme.hintColor,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.schedule_rounded,
                    size: 13, color: theme.hintColor),
                const SizedBox(width: 6),
                Text(
                  'Última limpieza: ${_formatDate(_stats['lastClearTime'])}',
                  style: GoogleFonts.spaceGrotesk(
                    color: theme.hintColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(ThemeData theme, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: theme.hintColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStorageItem(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String size,
    required IconData icon,
    required Color color,
    VoidCallback? onClear,
    bool showClear = true,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131722) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF1E2533) : AppTheme.lightBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 21),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.spaceGrotesk(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          size,
                          style: GoogleFonts.spaceGrotesk(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(
                      color: theme.hintColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (showClear) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: _isCleaning ? null : onClear,
                icon: Icon(Icons.delete_sweep_rounded,
                    color: theme.colorScheme.error, size: 21),
                tooltip: 'Liberar este espacio',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConnectedHistoryCard(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    return ApplePressable(
      scaleDownFactor: 0.98,
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Navigator.push(
          context,
          AppAnimations.createRoute(const HistoryScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131722) : Colors.white,
          borderRadius: BorderRadius.circular(20),
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
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.history_rounded,
                color: Color(0xFF10B981),
                size: 20,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gestionar Historial de Reproducción',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'Ver o limpiar los canales vistos recientemente',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildClearAllButton(
      BuildContext context, bool isDark, Color primaryColor) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isCleaning ? null : () => _handleClearCache('all'),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: isDark ? Colors.black : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 0,
        ),
        child: _isCleaning
            ? SizedBox(
                height: 22,
                width: 22,
                child: PivoteLoader(
                  color: isDark ? Colors.black : Colors.white,
                  strokeWidth: 2.5,
                  size: 22,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cleaning_services_rounded,
                      size: 20, color: isDark ? Colors.black : Colors.white),
                  const SizedBox(width: 10),
                  Text(
                    'Limpiar todo el almacenamiento',
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w900,
                      fontSize: 14.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Sin limpiezas recientes';
    if (date is DateTime) {
      final d = date.day.toString().padLeft(2, '0');
      final m = date.month.toString().padLeft(2, '0');
      return '$d/$m/${date.year}';
    }
    return 'Recientemente';
  }
}
