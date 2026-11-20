// ════════════════════════════════════════════════════════════════════════════
// Exportaciones de Stream Resolver y compatibilidad con StreamUrlResolver
// ════════════════════════════════════════════════════════════════════════════

export 'package:pivote/features/video/data/services/stream_resolver/js_deobfuscator.dart';
export 'package:pivote/features/video/data/services/stream_resolver/resolver_models.dart';
export 'package:pivote/features/video/data/services/stream_resolver/stream_candidate_extractor.dart';
export 'package:pivote/features/video/data/services/stream_resolver/stream_http_client.dart';
export 'package:pivote/features/video/data/services/stream_resolver/stream_resolver_engine.dart';
export 'package:pivote/features/video/data/services/stream_resolver/stream_token_inspector.dart';

import 'package:pivote/features/video/data/services/stream_resolver/resolver_models.dart';
import 'package:pivote/features/video/data/services/stream_resolver/stream_resolver_engine.dart';

/// Fachada de compatibilidad para código que utilizaba la clase previa [StreamUrlResolver].
class StreamUrlResolver {
  StreamUrlResolver._();

  /// Resuelve [url] delegando en el motor avanzado [StreamResolverEngine].
  static Future<ResolveResult> resolve(
    String url, {
    Map<String, String>? headers,
    bool forceRefresh = false,
  }) {
    return StreamResolverEngine.resolve(
      url,
      customHeaders: headers,
      forceRefresh: forceRefresh,
    );
  }

  /// Invalida una URL del caché (útil si devolvió 403 / token expirado).
  static void invalidate(String url) {
    StreamResolverEngine.invalidate(url);
  }

  /// Limpia todo el caché y temporizadores de renovación.
  static void clearCache() {
    StreamResolverEngine.clearCache();
  }

  /// Escucha eventos de renovación silenciosa de token.
  static void onStreamRenewed(String pageUrl, void Function(ResolveResult) listener) {
    StreamResolverEngine.onStreamRenewed(pageUrl, listener);
  }

  /// Remueve listener de renovación.
  static void removeRenewalListener(String pageUrl, void Function(ResolveResult) listener) {
    StreamResolverEngine.removeRenewalListener(pageUrl, listener);
  }
}
