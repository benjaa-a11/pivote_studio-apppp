import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pivote/core/services/cache_manager_service.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/shared/widgets/common/app_dialogs.dart';

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
    String title = '¿Limpiar cache?';
    String message = 'Esta acción liberará espacio en tu dispositivo.';

    if (type == 'all') {
      title = '¿Limpiar todo?';
      message =
          'Se eliminarán todos los datos almacenados en cache, incluyendo imágenes y preferencias temporales.';
    } else if (type == 'images') {
      title = '¿Limpiar imágenes?';
      message = 'Se eliminarán las miniaturas y portadas descargadas.';
    } else if (type == 'app') {
      title = '¿Limpiar datos?';
      message = 'Se restablecerán los datos temporales de la aplicación.';
    }

    final confirmed = await AppDialogs.showConfirm(
      context: context,
      title: title,
      message: message,
      confirmLabel: 'Limpiar Todo',
      cancelLabel: 'Cancelar',
      isDestructive: true,
      type: AppDialogType.error,
    );

    if (confirmed != true) return;

    setState(() => _isCleaning = true);

    // Simulate some work for better UX
    await Future.delayed(const Duration(milliseconds: 800));

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
            'Limpieza completada correctamente',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Almacenamiento',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStorageOverview(context),
                  const SizedBox(height: 32),
                  Text(
                    'Detalle del espacio',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildStorageItem(
                    context,
                    title: 'Imágenes y Miniaturas',
                    size: _stats['formattedImageSize'] ?? '0 B',
                    icon: Icons.image_outlined,
                    color: const Color(0xFFE7714D),
                    onClear: () => _handleClearCache('images'),
                  ),
                  _buildStorageItem(
                    context,
                    title: 'Datos de Aplicación',
                    size: _stats['formattedAppCacheSize'] ?? '0 B',
                    icon: Icons.data_usage_outlined,
                    color: const Color(0xFF5BB389),
                    onClear: () => _handleClearCache('app'),
                  ),
                  _buildStorageItem(
                    context,
                    title: 'Preferencias y Configuración',
                    size: _stats['formattedPrefsSize'] ?? '0 B',
                    icon: Icons.settings_suggest_outlined,
                    color: const Color(0xFFD4B455),
                    showClear: false,
                  ),
                  const SizedBox(height: 40),
                  _buildClearAllButton(context),
                ],
              ),
            ),
    );
  }

  Widget _buildStorageOverview(BuildContext context) {
    final totalSize = _stats['formattedTotalSize'] ?? '0 B';

    return AppAnimations.smoothFadeIn(
      child: Container(
        padding: const EdgeInsets.all(32),
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE7714D), Color(0xFFE57C5D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE7714D).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            const Icon(FontAwesomeIcons.database,
                color: Colors.white, size: 40),
            const SizedBox(height: 16),
            Text(
              'Espacio Ocupado',
              style: GoogleFonts.montserrat(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                );
              },
              child: Text(
                totalSize,
                key: ValueKey(totalSize),
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Última limpieza: ${_formatDate(_stats['lastClearTime'])}',
              style: GoogleFonts.montserrat(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
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
    required String size,
    required IconData icon,
    required Color color,
    VoidCallback? onClear,
    bool showClear = true,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      size,
                      key: ValueKey(size),
                      style: GoogleFonts.montserrat(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (showClear)
              IconButton(
                onPressed: _isCleaning ? null : onClear,
                icon: const Icon(Icons.delete_sweep_outlined,
                    color: Colors.redAccent),
                tooltip: 'Limpiar',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildClearAllButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isCleaning ? null : () => _handleClearCache('all'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
          elevation: 8,
        ),
        child: _isCleaning
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : Text(
                'Limpiar Todo por Completo',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Nunca';
    if (date is DateTime) {
      return '${date.day}/${date.month}/${date.year}';
    }
    return 'Hace poco';
  }
}
