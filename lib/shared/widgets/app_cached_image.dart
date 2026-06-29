import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:pivote/core/services/image_cache_helper.dart';

/// Widget unificado para cargar imágenes de red en toda la app.
///
/// Características:
/// - Siempre usa [ImageCacheHelper.logoCacheManager] con User-Agent correcto (evita 403)
/// - Shimmer placeholder suave durante la carga
/// - Fade-in animado al aparecer la imagen
/// - Error widget configurable
/// - `memCacheWidth/Height` correctamente dimensionados según el uso real
/// - `ValueKey` basado en la URL para evitar flickering al navegar
class AppCachedImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? errorWidget;
  final Widget? placeholder;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final int? maxWidthDiskCache;
  final int? maxHeightDiskCache;
  final Duration fadeInDuration;
  final bool useLogoManager;
  final BorderRadius? borderRadius;

  const AppCachedImage({
    required this.imageUrl,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
    this.errorWidget,
    this.placeholder,
    this.memCacheWidth,
    this.memCacheHeight,
    this.maxWidthDiskCache,
    this.maxHeightDiskCache,
    this.fadeInDuration = const Duration(milliseconds: 250),
    this.useLogoManager = true,
    this.borderRadius,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (imageUrl.isEmpty || !imageUrl.startsWith('http')) {
      return _buildErrorWidget(context, isDark);
    }

    Widget image = CachedNetworkImage(
      // Usar ValueKey basado en URL para evitar flickering en listas
      key: ValueKey<String>(imageUrl),
      cacheManager: useLogoManager
          ? ImageCacheHelper.logoCacheManager
          : ImageCacheHelper.customCacheManager,
      imageUrl: imageUrl,
      fit: fit,
      width: width,
      height: height,
      fadeInDuration: fadeInDuration,
      fadeOutDuration: const Duration(milliseconds: 100),
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      maxWidthDiskCache: maxWidthDiskCache ?? memCacheWidth,
      maxHeightDiskCache: maxHeightDiskCache ?? memCacheHeight,
      placeholder: (context, url) => placeholder ?? _buildShimmer(context, isDark),
      errorWidget: (context, url, error) => _buildErrorWidget(context, isDark),
    );

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return image;
  }

  Widget _buildShimmer(BuildContext context, bool isDark) {
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE8E8E8),
      highlightColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
      period: const Duration(milliseconds: 1200),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE8E8E8),
          borderRadius: borderRadius,
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, bool isDark) {
    if (errorWidget != null) return errorWidget!;
    return Center(
      child: Icon(
        Icons.broken_image_outlined,
        size: 24,
        color: isDark ? Colors.white24 : Colors.black26,
      ),
    );
  }
}

/// Variante pre-configurada para logos de canales de TV (cuadrados, ~100px UI)
class ChannelLogoImage extends StatelessWidget {
  final String imageUrl;
  final double size;

  const ChannelLogoImage({
    required this.imageUrl,
    this.size = 80,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppCachedImage(
      imageUrl: imageUrl,
      fit: BoxFit.contain,
      width: size,
      height: size,
      memCacheWidth: 200,
      memCacheHeight: 200,
      useLogoManager: true,
      errorWidget: Icon(
        Icons.tv_rounded,
        size: size * 0.5,
        color: isDark ? Colors.white24 : Colors.black26,
      ),
    );
  }
}

/// Variante pre-configurada para escudos de equipos de fútbol
class TeamShieldImage extends StatelessWidget {
  final String imageUrl;
  final double size;
  final Widget? fallbackIcon;

  const TeamShieldImage({
    required this.imageUrl,
    this.size = 48,
    this.fallbackIcon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppCachedImage(
      imageUrl: imageUrl,
      fit: BoxFit.contain,
      width: size,
      height: size,
      memCacheWidth: 150,
      memCacheHeight: 150,
      useLogoManager: true,
      errorWidget: fallbackIcon ?? Icon(
        Icons.shield_outlined,
        size: size * 0.5,
        color: isDark ? Colors.white30 : Colors.black26,
      ),
    );
  }
}

/// Variante pre-configurada para logos de emisoras de radio
class RadioLogoImage extends StatelessWidget {
  final String imageUrl;
  final double size;
  final BorderRadius? borderRadius;

  const RadioLogoImage({
    required this.imageUrl,
    this.size = 56,
    this.borderRadius,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppCachedImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      width: size,
      height: size,
      memCacheWidth: 200,
      memCacheHeight: 200,
      useLogoManager: true,
      borderRadius: borderRadius,
      errorWidget: Icon(
        Icons.radio_rounded,
        size: size * 0.45,
        color: isDark ? Colors.white24 : Colors.black26,
      ),
    );
  }
}

/// Variante pre-configurada para posters de películas
class MoviePosterImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;

  const MoviePosterImage({
    required this.imageUrl,
    this.width,
    this.height,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppCachedImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      width: width,
      height: height,
      memCacheWidth: 400,
      memCacheHeight: 600,
      useLogoManager: false, // Usa customCacheManager para imágenes grandes
      fadeInDuration: const Duration(milliseconds: 300),
      errorWidget: Center(
        child: Icon(
          Icons.movie_rounded,
          size: 36,
          color: isDark ? Colors.white24 : Colors.black26,
        ),
      ),
    );
  }
}
