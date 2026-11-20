// ════════════════════════════════════════════════════════════════════════════
// Pivote Stream Resolver — Modelos
// ════════════════════════════════════════════════════════════════════════════
//
// Archivo Dart puro (sin Flutter) para poder testearlo y ejecutarlo desde
// herramientas de línea de comandos (`dart run tool/stream_resolver_probe.dart`).

/// Candidato a URL de reproducción encontrado dentro de una página.
class StreamCandidate {
  final String url;
  final int score;
  final String strategy;

  /// Nombre de la clave / variable JS de donde salió (ej. `playbackURL`, `src`).
  final String? key;

  const StreamCandidate({
    required this.url,
    required this.score,
    required this.strategy,
    this.key,
  });

  StreamCandidate withScore(int newScore) => StreamCandidate(
        url: url,
        score: newScore,
        strategy: strategy,
        key: key,
      );

  @override
  String toString() => '[$score] $strategy${key != null ? '($key)' : ''} → $url';
}

/// Resultado final de la resolución de una URL de canal.
class ResolveResult {
  /// URL reproducible final (M3U8 / MPD / TS) o la original si ya era directa.
  final String url;

  /// Referer recomendado para el reproductor.
  final String? referer;

  /// Cabeceras HTTP recomendadas para el reproductor (User-Agent coherente con
  /// el que se usó para resolver, Referer/Origin de la página, etc.).
  final Map<String, String> headers;

  /// Estrategia que encontró la URL (diagnóstico).
  final String strategy;

  /// Momento (hora local del dispositivo, ya corregida por desfase del
  /// servidor) en el que el token de la URL expira. `null` = desconocido.
  final DateTime? expiresAt;

  /// URL de la página original (PHP/web) de la que se extrajo el stream.
  /// Solo se completa cuando hubo resolución real: permite re-resolver.
  final String? sourcePageUrl;

  /// Si el manifiesto fue verificado con una petición real (#EXTM3U / MPD).
  final bool verified;

  final DateTime resolvedAt;

  ResolveResult({
    required this.url,
    this.referer,
    this.headers = const {},
    required this.strategy,
    this.expiresAt,
    this.sourcePageUrl,
    this.verified = false,
    DateTime? resolvedAt,
  }) : resolvedAt = resolvedAt ?? DateTime.now();

  /// `true` si la URL salió de una página (no era directa ni passthrough).
  bool get wasResolved =>
      strategy != 'passthrough' &&
      strategy != 'direct' &&
      strategy != 'fallback' &&
      strategy != 'empty';

  /// Una fuente es "renovable" cuando proviene de una página que puede
  /// volver a consultarse para obtener un token nuevo.
  bool get isRefreshable =>
      wasResolved && sourcePageUrl != null && sourcePageUrl!.isNotEmpty;

  Duration? get timeToExpiry => expiresAt?.difference(DateTime.now());

  ResolveResult copyWith({
    String? url,
    String? referer,
    Map<String, String>? headers,
    String? strategy,
    DateTime? expiresAt,
    String? sourcePageUrl,
    bool? verified,
  }) {
    return ResolveResult(
      url: url ?? this.url,
      referer: referer ?? this.referer,
      headers: headers ?? this.headers,
      strategy: strategy ?? this.strategy,
      expiresAt: expiresAt ?? this.expiresAt,
      sourcePageUrl: sourcePageUrl ?? this.sourcePageUrl,
      verified: verified ?? this.verified,
      resolvedAt: resolvedAt,
    );
  }

  @override
  String toString() =>
      'ResolveResult(strategy=$strategy, verified=$verified, expiresAt=$expiresAt, url=$url)';
}
