import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:pivote/features/video/data/models/channel.dart';

import 'resolver_models.dart';
import 'stream_candidate_extractor.dart';
import 'stream_http_client.dart';
import 'stream_token_inspector.dart';

// ════════════════════════════════════════════════════════════════════════════
// StreamResolverEngine — Motor de resolución, caché inteligente, verificación
// y rotación continua de tokens sin cortes para URLs Web/PHP a M3U8.
// ════════════════════════════════════════════════════════════════════════════

class StreamResolverEngine {
  StreamResolverEngine._();

  static const Duration defaultCacheTtl = Duration(minutes: 8);
  static const Duration minCacheTtl = Duration(minutes: 2);
  static const int maxCacheEntries = 24;

  // ── Caché en memoria ──────────────────────────────────────────────────────
  static final _cache = <String, ResolveResult>{};

  // Mutex para peticiones concurrentes de la misma URL
  static final _inFlight = <String, Completer<ResolveResult>>{};

  // ── Suscripciones activas para renovación silenciosa ──────────────────────
  static final _activeRenewals = <String, Timer>{};
  static final _renewalListeners = <String, List<void Function(ResolveResult)>>{};

  /// Limpia la caché y detiene temporizadores.
  static void clearCache() {
    _cache.clear();
    for (final timer in _activeRenewals.values) {
      timer.cancel();
    }
    _activeRenewals.clear();
    _renewalListeners.clear();
  }

  /// Invalida una URL específica para obligar a re-resolver inmediatamente (ej. tras un 401/403).
  static void invalidate(String url) {
    final clean = url.trim();
    _cache.remove(clean);
    _activeRenewals[clean]?.cancel();
    _activeRenewals.remove(clean);
  }

  /// Suscribe un callback para cuando la URL de stream sea renovada silenciosamente en segundo plano.
  static void onStreamRenewed(String pageUrl, void Function(ResolveResult) listener) {
    final clean = pageUrl.trim();
    _renewalListeners.putIfAbsent(clean, () => []).add(listener);
  }

  /// Desuscribe un callback.
  static void removeRenewalListener(String pageUrl, void Function(ResolveResult) listener) {
    final clean = pageUrl.trim();
    _renewalListeners[clean]?.remove(listener);
    if (_renewalListeners[clean]?.isEmpty == true) {
      _renewalListeners.remove(clean);
    }
  }

  // ── Resolución Principal ──────────────────────────────────────────────────

  /// Resuelve [rawUrl] a una URL de reproducción directa (.m3u8, .mpd, .ts).
  ///
  /// Si ya es directa o DRM, retorna inmediatamente passthrough.
  /// Si está en caché válida y no ha expirado su token, retorna la versión en caché.
  /// Si está vencida o es nueva, ejecuta el pipeline multietapa de scraping,
  /// desofuscación, candidatos ponderados y verificación.
  static Future<ResolveResult> resolve(
    String rawUrl, {
    Map<String, String>? customHeaders,
    bool forceRefresh = false,
  }) async {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) {
      return ResolveResult(url: trimmed, strategy: 'empty');
    }

    final lower = trimmed.toLowerCase();
    final initialSmart = StreamSource.resolveSmartHeaders(trimmed, customHeaders) ?? const {};

    // 1. Fast-path: ya es un stream directo (m3u8, mpd, chunklist, etc.)
    if (_isDirectStream(lower)) {
      return ResolveResult(
        url: trimmed,
        referer: initialSmart['Referer'],
        headers: initialSmart,
        strategy: 'direct',
      );
    }

    // 2. WebView / iframes de terceros conocidos que no deben desarmarse
    if (_isWebViewExempt(lower)) {
      return ResolveResult(
        url: trimmed,
        referer: initialSmart['Referer'],
        headers: initialSmart,
        strategy: 'passthrough',
      );
    }

    // 3. Comprobar caché en memoria
    if (!forceRefresh) {
      final cached = _cache[trimmed];
      if (cached != null) {
        final now = DateTime.now();
        // Comprobar si el token aún es válido (con margen de seguridad de 30 segundos)
        final isStillValid = cached.expiresAt == null
            ? now.difference(cached.resolvedAt) < defaultCacheTtl
            : cached.expiresAt!.isAfter(now.add(const Duration(seconds: 30)));

        if (isStillValid) {
          debugPrint('💾 StreamResolverEngine: Cache HIT para $trimmed → ${cached.url.substring(0, min(80, cached.url.length))}');
          return cached;
        } else {
          debugPrint('⏱️ StreamResolverEngine: Token o caché expirada para $trimmed, renovando...');
          _cache.remove(trimmed);
        }
      }
    }

    // 4. Si ya hay una resolución en vuelo para esta URL, esperar su resultado
    if (_inFlight.containsKey(trimmed)) {
      return _inFlight[trimmed]!.future;
    }

    final completer = Completer<ResolveResult>();
    _inFlight[trimmed] = completer;

    try {
      final result = await _executeResolutionPipeline(trimmed, initialSmart);
      if (result.wasResolved && result.url.isNotEmpty) {
        _cache[trimmed] = result;
        _scheduleProactiveRenewal(trimmed, result);
      }
      completer.complete(result);
      return result;
    } catch (e, st) {
      debugPrint('❌ StreamResolverEngine pipeline error: $e\n$st');
      final fallback = ResolveResult(
        url: trimmed,
        referer: initialSmart['Referer'],
        headers: initialSmart,
        strategy: 'fallback',
      );
      completer.complete(fallback);
      return fallback;
    } finally {
      _inFlight.remove(trimmed);
    }
  }

  // ── Pipeline Interno ──────────────────────────────────────────────────────

  static Future<ResolveResult> _executeResolutionPipeline(
    String pageUrl,
    Map<String, String> initialHeaders,
  ) async {
    // Nivel 1: Descargar la página principal con perfil móvil Chrome (evita 403 de Cloudflare/Nginx)
    var response = await StreamHttpClient.fetchPage(
      pageUrl,
      customHeaders: initialHeaders,
      preferMobileUa: true,
    );

    // Si falló con móvil o 403, intentar con desktop Chrome
    if (response == null || response.statusCode == 403 || response.body.isEmpty) {
      debugPrint('⚠️ StreamResolverEngine: Reintentando con User-Agent Desktop...');
      response = await StreamHttpClient.fetchPage(
        pageUrl,
        customHeaders: initialHeaders,
        preferMobileUa: false,
      );
    }

    if (response == null || response.body.isEmpty) {
      // Si la URL redirigió directamente a un .m3u8 en los headers Location
      if (response != null && response.finalUri.toString().toLowerCase().contains('.m3u8')) {
        final finalStreamUrl = response.finalUri.toString();
        return _buildSuccessResult(
          finalStreamUrl,
          pageUrl,
          response.finalUri,
          'redirect-chain',
          response.date,
        );
      }
      debugPrint('❌ StreamResolverEngine: No se pudo obtener respuesta válida de $pageUrl');
      return ResolveResult(url: pageUrl, strategy: 'fallback');
    }

    // Si el cuerpo devuelto YA es un manifiesto HLS directo
    if (response.body.trimLeft().startsWith('#EXTM3U')) {
      return ResolveResult(
        url: response.finalUri.toString(),
        strategy: 'direct-body',
        referer: pageUrl,
      );
    }

    // Nivel 2: Extraer candidatos de la página actual
    var candidates = StreamCandidateExtractor.extract(response.body, response.finalUri);
    debugPrint('🔎 StreamResolverEngine: ${candidates.length} candidatos encontrados en la página principal');

    // Nivel 3: Si no hay candidatos directos, buscar iframes o redirecciones JS embebidas
    if (candidates.isEmpty) {
      final frames = StreamCandidateExtractor.findEmbeddedFrames(response.body, response.finalUri);
      for (final frameUri in frames.take(3)) {
        debugPrint('🪟 StreamResolverEngine: Explorando iframe embebido: $frameUri');
        final frameResp = await StreamHttpClient.fetchPage(
          frameUri.toString(),
          customHeaders: {
            ...initialHeaders,
            'Referer': response.finalUri.toString(),
          },
        );
        if (frameResp != null && frameResp.body.isNotEmpty) {
          final frameCandidates = StreamCandidateExtractor.extract(frameResp.body, frameResp.finalUri);
          if (frameCandidates.isNotEmpty) {
            candidates = frameCandidates;
            break;
          }
        }
      }
    }

    if (candidates.isEmpty) {
      debugPrint('⚠️ StreamResolverEngine: Sin candidatos de stream en $pageUrl');
      return ResolveResult(url: pageUrl, strategy: 'fallback');
    }

    // Nivel 4: Evaluar candidatos en orden de puntuación y verificar el mejor
    for (final candidate in candidates) {
      debugPrint('🎯 Evaluando candidato (${candidate.score} pts): ${candidate.url}');

      // Si el candidato ya tiene token y formato .m3u8 muy claro, verificarlo
      final verification = await StreamHttpClient.verifyStreamCandidate(
        candidate.url,
        headers: {
          'Referer': response.finalUri.toString(),
          'Origin': '${response.finalUri.scheme}://${response.finalUri.host}',
        },
      );

      final playableUrl = verification?.finalUrl ?? candidate.url;
      final serverDate = verification?.serverDate ?? response.date;

      if (verification?.isValidManifest == true || candidate.score >= 50) {
        debugPrint('✅ StreamResolverEngine: STREAM RESUELTO con éxito: $playableUrl');
        return _buildSuccessResult(
          playableUrl,
          pageUrl,
          response.finalUri,
          candidate.strategy,
          serverDate,
          verified: verification?.isValidManifest ?? false,
        );
      }
    }

    // Fallback al candidato con mayor puntuación
    final best = candidates.first;
    debugPrint('⚠️ StreamResolverEngine: Usando mejor candidato sin verificación estricta: ${best.url}');
    return _buildSuccessResult(
      best.url,
      pageUrl,
      response.finalUri,
      best.strategy,
      response.date,
    );
  }

  static ResolveResult _buildSuccessResult(
    String streamUrl,
    String sourcePageUrl,
    Uri pageUri,
    String strategy,
    DateTime? serverDate, {
    bool verified = false,
  }) {
    // Detectar expiración del token en la URL resuelta
    final expiresAt = StreamTokenInspector.detectExpiry(streamUrl, serverNow: serverDate);

    // Resolver cabeceras óptimas para ExoPlayer (Referer y User-Agent)
    final referer = '${pageUri.scheme}://${pageUri.host}/';
    final smartHeaders = StreamSource.resolveSmartHeaders(streamUrl, {
      'Referer': referer,
      'Origin': '${pageUri.scheme}://${pageUri.host}',
      'User-Agent': StreamHttpClient.mobileChromeUa,
    }) ?? {
      'Referer': referer,
      'User-Agent': StreamHttpClient.mobileChromeUa,
    };

    return ResolveResult(
      url: streamUrl,
      referer: referer,
      headers: smartHeaders,
      strategy: strategy,
      expiresAt: expiresAt,
      sourcePageUrl: sourcePageUrl,
      verified: verified,
    );
  }

  // ── Renovación Proactiva de Tokens (Sin Cortes) ───────────────────────────

  static void _scheduleProactiveRenewal(String pageUrl, ResolveResult currentResult) {
    _activeRenewals[pageUrl]?.cancel();

    Duration refreshDelay;
    final now = DateTime.now();

    if (currentResult.expiresAt != null) {
      final ttl = currentResult.expiresAt!.difference(now);
      // Renovar 60 segundos antes de que expire el token, o al 80% del tiempo de vida
      if (ttl > const Duration(minutes: 2)) {
        refreshDelay = ttl - const Duration(seconds: 60);
      } else if (ttl > const Duration(seconds: 45)) {
        refreshDelay = ttl - const Duration(seconds: 20);
      } else {
        refreshDelay = minCacheTtl;
      }
    } else {
      // Si no tiene fecha explícita, renovar periódicamente según el TTL de caché
      refreshDelay = defaultCacheTtl - const Duration(seconds: 45);
    }

    if (refreshDelay < const Duration(seconds: 30)) {
      refreshDelay = const Duration(seconds: 30);
    }

    debugPrint('⏰ StreamResolverEngine: Programada renovación silenciosa de token para $pageUrl en ${refreshDelay.inSeconds}s (expira en ${currentResult.expiresAt})');

    _activeRenewals[pageUrl] = Timer(refreshDelay, () async {
      debugPrint('🔄 StreamResolverEngine: Ejecutando renovación proactiva en segundo plano para: $pageUrl');
      try {
        final newResult = await resolve(pageUrl, forceRefresh: true);
        if (newResult.wasResolved && newResult.url.isNotEmpty) {
          debugPrint('✨ StreamResolverEngine: Token renovado con éxito en background para: $pageUrl');
          // Notificar a los reproductores activos que estén escuchando
          final listeners = _renewalListeners[pageUrl];
          if (listeners != null && listeners.isNotEmpty) {
            for (final listener in List.of(listeners)) {
              try {
                listener(newResult);
              } catch (e) {
                debugPrint('Error invocando listener de renovación: $e');
              }
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ StreamResolverEngine: Error en renovación silenciosa: $e');
      }
    });
  }

  // ── Filtros y Auxiliares ──────────────────────────────────────────────────

  static bool _isDirectStream(String uLower) {
    return uLower.contains('.m3u8') ||
        uLower.contains('.mpd') ||
        uLower.contains('output=m3u8') ||
        uLower.contains('format=m3u8') ||
        uLower.contains('chunklist');
  }

  static bool _isWebViewExempt(String uLower) {
    return uLower.contains('iframe') ||
        uLower.contains('embed') ||
        uLower.contains('pivo-pro') ||
        uLower.contains('pivopro') ||
        uLower.contains('vercel.app') ||
        (uLower.contains('.html') && !uLower.endsWith('.php'));
  }
}
