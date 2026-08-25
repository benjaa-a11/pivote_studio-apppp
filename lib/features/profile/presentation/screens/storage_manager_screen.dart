import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/services/cache_manager_service.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/shared/widgets/common/app_dialogs.dart';
import 'package:pivote/shared/widgets/common/pivote_loader.dart';
import 'package:pivote/shared/widgets/common/pivote_app_bar.dart';

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
      message = 'Se borrarán todos los datos temporales e imágenes descargadas.';
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

    HapticFeedback.mediumImpact();
    setState(() => _isCleaning = true);

    await Future.delayed(const Duration(milliseconds: 700));

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Espacio liberado correctamente',
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark ? AppTheme.darkAccent : theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const PivoteAppBar(
        title: 'Almacenamiento',
        subtitle: 'Administrá el espacio de memoria y caché',
      ),
      body: _isLoading
          ? const Center(child: PivoteLoader(size: 40))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStorageOverview(context, isDark, primaryColor),
                  const SizedBox(height: 28),
                  Text(
                    'Detalle del almacenamiento',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildStorageItem(
                    context,
                    title: 'Imágenes y Logos',
                    subtitle: 'Miniaturas de canales, radios y pósters',
                    size: _stats['formattedImageSize'] ?? '0 B',
                    icon: Icons.image_outlined,
                    color: const Color(0xFFE58B46),
                    onClear: () => _handleClearCache('images'),
                  ),
                  _buildStorageItem(
                    context,
                    title: 'Búfer de Streaming y Datos',
                    subtitle: 'Fragmentos temporales de video y audio',
                    size: _stats['formattedAppCacheSize'] ?? '0 B',
                    icon: Icons.data_usage_outlined,
                    color: const Color(0xFF5BB389),
                    onClear: () => _handleClearCache('app'),
                  ),
                  _buildStorageItem(
                    context,
                    title: 'Preferencias de Usuario',
                    subtitle: 'Ajustes, favoritos y configuración local',
                    size: _stats['formattedPrefsSize'] ?? '0 B',
                    icon: Icons.tune_rounded,
                    color: const Color(0xFF5B8CFF),
                    showClear: false,
                  ),
                  const SizedBox(height: 28),
                  _buildClearAllButton(context, isDark, primaryColor),
                ],
              ),
            ),
    );
  }

  Widget _buildStorageOverview(
      BuildContext context, bool isDark, Color primaryColor) {
    final totalSize = _stats['formattedTotalSize'] ?? '0 B';

    return AppAnimations.smoothFadeIn(
      child: Container(
        padding: const EdgeInsets.all(26),
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    const Color(0xFF1E2822),
                    const Color(0xFF0F1512),
                  ]
                : [
                    primaryColor.withValues(alpha: 0.15),
                    primaryColor.withValues(alpha: 0.05),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: primaryColor.withValues(alpha: isDark ? 0.25 : 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: isDark ? 0.1 : 0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(Icons.storage_rounded,
                  color: primaryColor, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              'Espacio Total en Caché',
              style: GoogleFonts.spaceGrotesk(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Text(
                totalSize,
                key: ValueKey(totalSize),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                  color: primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surface
                    .withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                ),
              ),
              child: Text(
                'Última limpieza: ${_formatDate(_stats['lastClearTime'])}',
                style: GoogleFonts.spaceGrotesk(
                  color: Theme.of(context).hintColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
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
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(
                      color: theme.hintColor,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    size,
                    style: GoogleFonts.spaceGrotesk(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            if (showClear)
              IconButton(
                onPressed: _isCleaning ? null : onClear,
                icon: Icon(Icons.delete_sweep_rounded,
                    color: theme.colorScheme.error, size: 22),
                tooltip: 'Liberar este espacio',
              ),
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
                      size: 20,
                      color: isDark ? Colors.black : Colors.white),
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
    if (date == null) return 'Nunca';
    if (date is DateTime) {
      return '${date.day}/${date.month}/${date.year}';
    }
    return 'Recientemente';
  }
}
