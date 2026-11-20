// ════════════════════════════════════════════════════════════════════════════
// StreamTokenInspector — Detección de expiración de tokens en URLs de stream
// ════════════════════════════════════════════════════════════════════════════
//
// Formatos reales observados:
//   Flussonic / Streamer:  ?token=<sha1>-<n>-<EXPIRA>-<EMITIDO>
//      https://x.fubo18.com/dsports/mono.m3u8?token=74b9..a8-f9-1795210405-1795192405
//   Wowza / Nimble:        ?wmsAuthSign=...&validminutes=  / ?e=<unix>
//   Akamai:                ?hdnts=st=<unix>~exp=<unix>~acl=...~hmac=...
//   CloudFront / genérico: ?Expires=<unix>&Signature=...
//
// Estrategia: 1) parámetros con nombre explícito de expiración; 2) cualquier
// timestamp unix (10 dígitos, o 13 en ms) que caiga en el futuro cercano.
// Todo se corrige por el desfase entre el reloj del servidor (header `Date`)
// y el del dispositivo, para no renovar tarde en teléfonos con hora errónea.

class StreamTokenInspector {
  StreamTokenInspector._();

  static const Duration _maxHorizon = Duration(days: 3);
  static const Duration _minHorizon = Duration(seconds: 20);

  static final _reNamedExpiry = RegExp(
    r'(?:^|[?&~;])(?:exp|expires|expiry|expire|e|validto|valid_until|deadline|ttl_until)=(\d{10}|\d{13})(?!\d)',
    caseSensitive: false,
  );
  static final _reAnyTimestamp = RegExp(r'(?<!\d)(\d{13}|\d{10})(?!\d)');

  /// Devuelve la hora de expiración expresada en el reloj del DISPOSITIVO.
  ///
  /// [serverNow] es la hora del servidor (header `Date` de la respuesta de la
  /// página) para compensar relojes desfasados.
  static DateTime? detectExpiry(String url, {DateTime? serverNow}) {
    String decoded;
    try {
      decoded = Uri.decodeFull(url);
    } catch (_) {
      decoded = url;
    }

    final deviceNow = DateTime.now();
    final reference = (serverNow ?? deviceNow).toUtc();
    final skew = serverNow != null ? serverNow.difference(deviceNow) : Duration.zero;

    DateTime? pick(Iterable<RegExpMatch> matches) {
      DateTime? best;
      for (final m in matches) {
        final t = _toDate(m.group(1)!);
        if (t == null) continue;
        final delta = t.difference(reference);
        if (delta < _minHorizon || delta > _maxHorizon) continue;
        if (best == null || t.isAfter(best)) best = t;
      }
      return best;
    }

    final expiryServerClock =
        pick(_reNamedExpiry.allMatches(decoded)) ?? pick(_reAnyTimestamp.allMatches(decoded));
    if (expiryServerClock == null) return null;

    // Convertir del reloj del servidor al reloj local del dispositivo.
    return expiryServerClock.subtract(skew).toLocal();
  }

  static DateTime? _toDate(String digits) {
    final n = int.tryParse(digits);
    if (n == null) return null;
    final ms = digits.length == 13 ? n : n * 1000;
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  }

  /// Parsea el header HTTP `Date` (RFC 1123). Devuelve `null` si no es válido.
  static DateTime? parseHttpDate(String? value) {
    if (value == null || value.isEmpty) return null;
    const months = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
      'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    };
    final m = RegExp(r'(\d{1,2})\s+([A-Za-z]{3})\s+(\d{4})\s+(\d{2}):(\d{2}):(\d{2})').firstMatch(value);
    if (m == null) return null;
    final month = months[m.group(2)!.toLowerCase()];
    if (month == null) return null;
    return DateTime.utc(
      int.parse(m.group(3)!),
      month,
      int.parse(m.group(1)!),
      int.parse(m.group(4)!),
      int.parse(m.group(5)!),
      int.parse(m.group(6)!),
    );
  }
}
