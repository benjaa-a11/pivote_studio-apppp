import 'dart:convert';

// ════════════════════════════════════════════════════════════════════════════
// JsDeobfuscator — Desarmado estático (sin ejecutar JS) de las técnicas de
// ofuscación usadas por los reproductores PHP/Clappr/JWPlayer de TV en vivo.
// ════════════════════════════════════════════════════════════════════════════
//
// Técnicas soportadas:
//   1. Arrays de pares [índice, base64] + atob + offset numérico (cualquier
//      nombre de variable, múltiples bloques por página, offset por bloque):
//        var playbackURL="",ds=[[80,"bUI4Mzg2OTltRQ=="],...];
//        ds.sort((a,b)=>a[0]-b[0]);
//        var k=WSmaw()+twvTI();
//        ds.forEach(e=>{ playbackURL+=String.fromCharCode(parseInt(atob(v).replace(/\D/g,''))-k) });
//        function WSmaw(){return 78118;} function twvTI(){return 760483;}
//   2. Dean Edwards P.A.C.K.E.R.  eval(function(p,a,c,k,e,d){...})
//   3. atob("aHR0cHM6Ly...") y base64 sueltos que decodifican a http(s)
//   4. Strings invertidos  "8u3m.xedni/..".split("").reverse().join("")
//   5. Arrays unidos       ["htt","ps:/","/host"].join("")
//   6. Concatenación       "https://" + "host" + "/live.m3u8"
//   7. Escapes JS          \/  \u002F  \x2F

/// Fragmento de texto obtenido al desofuscar.
class DecodedFragment {
  final String text;
  final String technique;

  /// Variable JS destino (ej. `playbackURL`) cuando se conoce.
  final String? varName;

  const DecodedFragment(this.text, this.technique, {this.varName});

  @override
  String toString() => '$technique${varName != null ? '($varName)' : ''}: $text';
}

class JsDeobfuscator {
  JsDeobfuscator._();

  /// Ejecuta todas las técnicas y devuelve los fragmentos decodificados.
  static List<DecodedFragment> decodeAll(String source) {
    final out = <DecodedFragment>[];

    void safe(void Function() fn) {
      try {
        fn();
      } catch (_) {}
    }

    safe(() => out.addAll(decodeCharCodeArrays(source)));
    safe(() {
      for (final unpacked in unpackAll(source)) {
        out.add(DecodedFragment(unpacked, 'packer'));
        // Lo desempaquetado puede contener a su vez arrays ofuscados.
        out.addAll(decodeCharCodeArrays(unpacked));
      }
    });
    safe(() => out.addAll(decodeBase64Strings(source)));
    safe(() => out.addAll(decodeReversedStrings(source)));
    safe(() => out.addAll(decodeJoinedArrays(source)));
    safe(() => out.addAll(decodeConcatenations(source)));
    return out;
  }

  // ── Escapes JS ────────────────────────────────────────────────────────────

  static final _reUnicodeEscape = RegExp(r'\\u([0-9a-fA-F]{4})');
  static final _reHexEscape = RegExp(r'\\x([0-9a-fA-F]{2})');

  static String unescapeJs(String s) {
    var out = s.replaceAll(r'\/', '/');
    out = out.replaceAllMapped(
      _reUnicodeEscape,
      (m) => String.fromCharCode(int.parse(m.group(1)!, radix: 16)),
    );
    out = out.replaceAllMapped(
      _reHexEscape,
      (m) => String.fromCharCode(int.parse(m.group(1)!, radix: 16)),
    );
    return out.replaceAll('&amp;', '&');
  }

  // ── 1. Arrays de char-codes ofuscados ─────────────────────────────────────

  static final _reForEach = RegExp(r'([A-Za-z_$][\w$]*)\s*\.\s*forEach\s*\(');
  static final _reAppendTarget =
      RegExp(r'([A-Za-z_$][\w$.]*)\s*\+=\s*String\.fromCharCode\s*\(');
  static final _rePair = RegExp(
    r'''\[\s*(-?\d+)\s*,\s*(?:"([^"]*)"|'([^']*)'|(-?\d+))\s*\]''',
  );
  static final _reFlatItem = RegExp(r'''"([^"]*)"|'([^']*)'|(-?\d+)''');

  /// Decodifica todos los bloques `ARR.forEach(... X += String.fromCharCode(...) ...)`.
  static List<DecodedFragment> decodeCharCodeArrays(String body) {
    final results = <DecodedFragment>[];

    for (final loop in _reForEach.allMatches(body)) {
      final arrayVar = loop.group(1)!;
      final openParen = loop.end - 1;
      final closeParen = _matchBracket(body, openParen, '(', ')');
      if (closeParen < 0) continue;
      final loopBody = body.substring(openParen, closeParen + 1);

      if (!loopBody.contains('fromCharCode')) continue;

      final targetMatch = _reAppendTarget.firstMatch(loopBody);
      final targetVar = targetMatch?.group(1);

      // Expresión dentro de String.fromCharCode( ... )
      final fccIdx = loopBody.indexOf('fromCharCode');
      final fccOpen = loopBody.indexOf('(', fccIdx);
      final fccClose = _matchBracket(loopBody, fccOpen, '(', ')');
      if (fccOpen < 0 || fccClose < 0) continue;
      final inner = loopBody.substring(fccOpen + 1, fccClose).trim();

      final usesAtob = inner.contains('atob');
      final offsetMatch =
          RegExp(r'([-+])\s*([A-Za-z_$][\w$]*|\d+)\s*$').firstMatch(inner);

      int offset = 0;
      int sign = -1;
      if (offsetMatch != null) {
        sign = offsetMatch.group(1) == '-' ? -1 : 1;
        final token = offsetMatch.group(2)!;
        final parsed = int.tryParse(token);
        if (parsed != null) {
          offset = parsed;
        } else {
          final v = _resolveIdentifierValue(body, token, beforeIndex: loop.start);
          if (v == null) continue; // Sin offset fiable → no inventar basura
          offset = v;
        }
      }

      // Localizar el literal del array (la última asignación antes del forEach)
      final arrayLiteral = _findArrayLiteral(body, arrayVar, loop.start);
      if (arrayLiteral == null) continue;

      final entries = <MapEntry<int, Object>>[];
      final pairs = _rePair.allMatches(arrayLiteral).toList();
      if (pairs.isNotEmpty) {
        for (final p in pairs) {
          final idx = int.parse(p.group(1)!);
          final str = p.group(2) ?? p.group(3);
          if (str != null) {
            entries.add(MapEntry(idx, str));
          } else {
            entries.add(MapEntry(idx, int.parse(p.group(4)!)));
          }
        }
      } else {
        var i = 0;
        final innerArr = arrayLiteral.substring(1, arrayLiteral.length - 1);
        for (final m in _reFlatItem.allMatches(innerArr)) {
          final str = m.group(1) ?? m.group(2);
          entries.add(MapEntry(i++, str ?? int.parse(m.group(3)!)));
        }
      }
      if (entries.isEmpty) continue;

      // ¿Se ordena el array? (a[0]-b[0] ascendente | b[0]-a[0] descendente)
      final sortRe = RegExp(
        '(?<![\\w\$.])${RegExp.escape(arrayVar)}\\s*\\.\\s*sort\\s*\\(([^;]*)',
      );
      RegExpMatch? sortMatch;
      for (final m in sortRe.allMatches(body.substring(0, loop.start))) {
        sortMatch = m;
      }
      if (sortMatch != null) {
        final cmp = sortMatch.group(1) ?? '';
        final desc = RegExp(r'b\s*\[\s*0\s*\]\s*-\s*a\s*\[\s*0\s*\]').hasMatch(cmp);
        entries.sort((a, b) => desc ? b.key - a.key : a.key - b.key);
      }

      final sb = StringBuffer();
      var bad = 0;
      for (final e in entries) {
        int? n;
        final v = e.value;
        if (v is int) {
          n = v;
        } else if (v is String) {
          var raw = v;
          if (usesAtob) {
            try {
              raw = utf8.decode(base64.decode(_padBase64(v)), allowMalformed: true);
            } catch (_) {
              raw = v;
            }
          }
          final digits = raw.replaceAll(RegExp(r'\D'), '');
          n = digits.isEmpty ? null : int.tryParse(digits);
        }
        if (n == null) {
          bad++;
          continue;
        }
        final code = n + sign * offset;
        if (code > 0 && code < 0x110000) {
          sb.writeCharCode(code);
        } else {
          bad++;
        }
      }

      final decoded = sb.toString();
      if (decoded.isEmpty || bad > entries.length ~/ 4) continue;
      results.add(DecodedFragment(decoded, 'charcode-array', varName: targetVar));
    }
    return results;
  }

  /// Busca `arrayVar = [ ... ]` (o `arrayVar=[...]` dentro de un `var a=..,b=[..]`)
  /// más cercano ANTES de [beforeIndex] y devuelve el literal con corchetes.
  static String? _findArrayLiteral(String body, String arrayVar, int beforeIndex) {
    final re = RegExp('(?<![\\w\$.])${RegExp.escape(arrayVar)}\\s*=\\s*\\[');
    RegExpMatch? best;
    for (final m in re.allMatches(body)) {
      if (m.start >= beforeIndex) break;
      // Saltar declaraciones vacías tipo  ds=[],  y quedarse con la que tiene datos
      final open = m.end - 1;
      final close = _matchBracket(body, open, '[', ']');
      if (close < 0) continue;
      if (close - open > 2) best = m;
    }
    if (best == null) return null;
    final open = best.end - 1;
    final close = _matchBracket(body, open, '[', ']');
    if (close < 0) return null;
    return body.substring(open, close + 1);
  }

  /// Resuelve el valor numérico de un identificador (ej. `k`) evaluando la
  /// asignación más cercana antes de [beforeIndex]: `k = A() + B() - 3`.
  static int? _resolveIdentifierValue(String body, String name, {required int beforeIndex}) {
    final assignRe = RegExp(
      '(?<![\\w\$.])${RegExp.escape(name)}\\s*=(?!=)\\s*([^;,\\n]+)',
    );
    RegExpMatch? last;
    for (final m in assignRe.allMatches(body)) {
      if (m.start >= beforeIndex) break;
      last = m;
    }
    // Si no hay asignación previa (hoisting), aceptar la primera posterior
    last ??= assignRe.firstMatch(body);
    if (last == null) return null;
    return _evalNumericExpr(body, last.group(1)!.trim(), depth: 0);
  }

  /// Evalúa expresiones aditivas simples: números, `fn()`, identificadores,
  /// `parseInt("123")`, `Number("12")`, paréntesis triviales.
  static int? _evalNumericExpr(String body, String expr, {required int depth}) {
    if (depth > 4) return null;
    var e = expr.trim();
    while (e.startsWith('(') && _matchBracket(e, 0, '(', ')') == e.length - 1) {
      e = e.substring(1, e.length - 1).trim();
    }
    final termRe = RegExp(
      r'''([-+]?)\s*(parseInt\s*\(\s*["']?(-?\d+)["']?\s*\)|Number\s*\(\s*["']?(-?\d+)["']?\s*\)|(-?\d+)|([A-Za-z_$][\w$]*)\s*\(\s*\)|([A-Za-z_$][\w$]*))''',
    );
    var total = 0;
    var consumed = 0;
    for (final m in termRe.allMatches(e)) {
      final gap = e.substring(consumed, m.start).trim();
      if (gap.isNotEmpty) return null; // operador no soportado (*, /, etc.)
      consumed = m.end;
      final sign = m.group(1) == '-' ? -1 : 1;
      int? v;
      if (m.group(3) != null) {
        v = int.tryParse(m.group(3)!);
      } else if (m.group(4) != null) {
        v = int.tryParse(m.group(4)!);
      } else if (m.group(5) != null) {
        v = int.tryParse(m.group(5)!);
      } else if (m.group(6) != null) {
        v = _resolveFunctionReturn(body, m.group(6)!, depth: depth + 1);
      } else if (m.group(7) != null) {
        v = _resolveIdentifierValue(body, m.group(7)!, beforeIndex: body.length);
      }
      if (v == null) return null;
      total += sign * v;
    }
    if (e.substring(consumed).trim().isNotEmpty) return null;
    return total;
  }

  static int? _resolveFunctionReturn(String body, String fnName, {required int depth}) {
    final n = RegExp.escape(fnName);
    final patterns = [
      RegExp('function\\s+$n\\s*\\(\\s*\\)\\s*\\{\\s*return\\s+([^;}]+?)\\s*;?\\s*\\}'),
      RegExp('$n\\s*=\\s*function\\s*\\(\\s*\\)\\s*\\{\\s*return\\s+([^;}]+?)\\s*;?\\s*\\}'),
      RegExp('$n\\s*=\\s*\\(\\s*\\)\\s*=>\\s*\\{?\\s*(?:return\\s+)?([^;}\\n]+?)\\s*;?\\s*\\}?\\s*[;,\\n]'),
    ];
    for (final re in patterns) {
      final m = re.firstMatch(body);
      if (m != null) return _evalNumericExpr(body, m.group(1)!, depth: depth);
    }
    return null;
  }

  // ── 2. P.A.C.K.E.R. (Dean Edwards) ────────────────────────────────────────

  static final _rePacker = RegExp(
    r'''\}\s*\(\s*(['"])((?:\\.|(?!\1).)*)\1\s*,\s*(\d+|\[\])\s*,\s*(\d+)\s*,\s*(['"])((?:\\.|(?!\5).)*)\5\s*\.split\(\s*['"]\|['"]\s*\)''',
    dotAll: true,
  );

  static List<String> unpackAll(String source) {
    if (!source.contains('p,a,c,k,e,')) return const [];
    final out = <String>[];
    for (final m in _rePacker.allMatches(source)) {
      try {
        final payload = m.group(2)!.replaceAll(r"\'", "'").replaceAll(r'\"', '"').replaceAll(r'\\', r'\');
        final radixRaw = m.group(3)!;
        final radix = radixRaw == '[]' ? 62 : int.parse(radixRaw);
        final count = int.parse(m.group(4)!);
        final symtab = m.group(6)!.split('|');
        if (symtab.length != count && symtab.length < count) {
          // Tolerar diccionarios ligeramente desfasados
        }
        final unpacked = payload.replaceAllMapped(RegExp(r'\b\w+\b'), (w) {
          final word = w.group(0)!;
          final idx = _unbase(word, radix);
          if (idx == null || idx >= symtab.length) return word;
          final rep = symtab[idx];
          return rep.isEmpty ? word : rep;
        });
        out.add(unpacked);
      } catch (_) {}
    }
    return out;
  }

  static const _alphabet62 =
      '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';

  static int? _unbase(String word, int radix) {
    if (radix <= 36) return int.tryParse(word, radix: radix.clamp(2, 36));
    var result = 0;
    for (final ch in word.split('')) {
      final v = _alphabet62.indexOf(ch);
      if (v < 0 || v >= radix) return null;
      result = result * radix + v;
    }
    return result;
  }

  // ── 3. Base64 ─────────────────────────────────────────────────────────────

  static final _reAtob = RegExp(r'''atob\s*\(\s*["']([A-Za-z0-9+/=_-]{8,})["']\s*\)''');

  /// "aHR0c" = "http" en base64: cualquier string que empiece así es una URL.
  static final _reHttpB64 = RegExp(r'aHR0c[A-Za-z0-9+/_-]{12,}={0,2}');

  static List<DecodedFragment> decodeBase64Strings(String body) {
    final out = <DecodedFragment>[];
    final seen = <String>{};
    void tryDecode(String b64, String technique) {
      if (!seen.add(b64)) return;
      try {
        final normalized = _padBase64(b64.replaceAll('-', '+').replaceAll('_', '/'));
        final text = utf8.decode(base64.decode(normalized), allowMalformed: true);
        if (text.isEmpty || text.contains('\uFFFD')) return;
        out.add(DecodedFragment(text, technique));
        // Doble base64 (muy usado)
        final inner = text.trim();
        if (RegExp(r'^[A-Za-z0-9+/=]{16,}$').hasMatch(inner)) {
          tryDecode(inner, '$technique+b64');
        }
      } catch (_) {}
    }

    for (final m in _reAtob.allMatches(body)) {
      tryDecode(m.group(1)!, 'atob');
    }
    for (final m in _reHttpB64.allMatches(body)) {
      tryDecode(m.group(0)!, 'base64-url');
    }
    return out;
  }

  // ── 4. Strings invertidos ─────────────────────────────────────────────────

  static final _reReversed = RegExp(
    r'''(["'])([^"'\n]{10,})\1\s*\.split\(\s*(["'])\3\s*\)\s*\.reverse\(\s*\)\s*\.join\(\s*(["'])\4\s*\)''',
  );

  static List<DecodedFragment> decodeReversedStrings(String body) {
    return _reReversed
        .allMatches(body)
        .map((m) => DecodedFragment(m.group(2)!.split('').reversed.join(), 'reversed'))
        .toList();
  }

  // ── 5. Arrays unidos con join("") ─────────────────────────────────────────

  static final _reJoined = RegExp(
    r'''\[\s*((?:(?:"[^"\n]*"|'[^'\n]*')\s*,\s*)+(?:"[^"\n]*"|'[^'\n]*'))\s*\]\s*\.join\(\s*(["'])\2\s*\)''',
  );
  static final _reStrLit = RegExp(r'''"([^"\n]*)"|'([^'\n]*)' '''.trim());

  static List<DecodedFragment> decodeJoinedArrays(String body) {
    final out = <DecodedFragment>[];
    for (final m in _reJoined.allMatches(body)) {
      final parts = _reStrLit
          .allMatches(m.group(1)!)
          .map((p) => p.group(1) ?? p.group(2) ?? '')
          .join();
      out.add(DecodedFragment(unescapeJs(parts), 'array-join'));
    }
    return out;
  }

  // ── 6. Concatenación de literales ─────────────────────────────────────────

  static final _reConcat = RegExp(
    r'''(?:(?:"[^"\n]*"|'[^'\n]*')\s*\+\s*){1,40}(?:"[^"\n]*"|'[^'\n]*')''',
  );

  static List<DecodedFragment> decodeConcatenations(String body) {
    final out = <DecodedFragment>[];
    for (final m in _reConcat.allMatches(body)) {
      final joined = _reStrLit
          .allMatches(m.group(0)!)
          .map((p) => p.group(1) ?? p.group(2) ?? '')
          .join();
      final lower = joined.toLowerCase();
      if (lower.contains('m3u8') || lower.contains('.mpd') || lower.startsWith('http')) {
        out.add(DecodedFragment(unescapeJs(joined), 'concat'));
      }
    }
    return out;
  }

  // ── Utilidades ────────────────────────────────────────────────────────────

  static String _padBase64(String b64) {
    final clean = b64.trim();
    final mod = clean.length % 4;
    return mod == 0 ? clean : clean + '=' * (4 - mod);
  }

  /// Devuelve el índice del cierre que balancea el carácter de apertura en
  /// [openIndex], ignorando el contenido de strings y regex simples.
  static int _matchBracket(String s, int openIndex, String open, String close) {
    if (openIndex < 0 || openIndex >= s.length || s[openIndex] != open) return -1;
    var depth = 0;
    String? quote;
    for (var i = openIndex; i < s.length; i++) {
      final c = s[i];
      if (quote != null) {
        if (c == '\\') {
          i++;
          continue;
        }
        if (c == quote) quote = null;
        continue;
      }
      if (c == '"' || c == "'" || c == '`') {
        quote = c;
        continue;
      }
      if (c == open) {
        depth++;
      } else if (c == close) {
        depth--;
        if (depth == 0) return i;
      }
    }
    return -1;
  }
}
