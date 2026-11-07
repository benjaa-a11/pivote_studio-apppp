import 'dart:convert';

class EventCamera {
  final int id;
  final String nombre;
  final String url;
  final String tipo;

  EventCamera({
    required this.id,
    required this.nombre,
    required this.url,
    required this.tipo,
  });

  factory EventCamera.fromJson(Map<String, dynamic> json) {
    return EventCamera(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      url: json['url'] ?? '',
      tipo: json['tipo'] ?? 'exclusiva',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'url': url,
      'tipo': tipo,
    };
  }
}

class Channel {
  final String id;
  final String name;
  final String category;
  final List<String> logoUrl; // [0] dark mode, [1] light mode
  final List<StreamSource> streamUrl;
  final String description;

  /// Optional external guide identifier (numeric channel code or name)
  final String? guid;
  final bool isHidden;
  final int order;
  bool isFavorite;
  final String? type; // 'dash' or 'hls' to override detection o 'evento'
  final String? quality;
  final String? evento; // Nombre del evento ("Gran Hermano 2026")
  final List<EventCamera>? camaras; // Arreglo de cámaras

  Channel({
    required this.id,
    required this.name,
    required this.category,
    required this.logoUrl,
    required this.streamUrl,
    required this.description,
    this.guid,
    this.isHidden = false,
    this.order = 999,
    this.isFavorite = false,
    this.type,
    this.quality,
    this.evento,
    this.camaras,
  });

  factory Channel.fromJson(Map<String, dynamic> json) {
    List<String> logoUrls = [];
    if (json['logoUrl'] is List) {
      logoUrls = List<String>.from(json['logoUrl']);
    } else if (json['logoUrl'] is String) {
      logoUrls = [json['logoUrl']];
    } else if (json['icono'] is String &&
        (json['icono'] as String).isNotEmpty) {
      logoUrls = [json['icono']];
    } else if (json['logo'] is String && (json['logo'] as String).isNotEmpty) {
      logoUrls = [json['logo']];
    }

    // Root headers if present (normalized key casing)
    final Map<String, String>? rootHeaders =
        StreamSource.extractNormalizedHeaders(json);

    // Parse streamUrl - supports old String format, Map format, and external CLEARKEY format
    List<StreamSource> streams = [];
    if (json['streamUrl'] is List) {
      for (var item in json['streamUrl']) {
        if (item is String) {
          // Old format: simple string URL (may contain |Referer=... pipe syntax)
          final (cleanUrl, pipeHeaders) = StreamSource.splitPipeHeaders(item);
          final merged = <String, String>{
            if (rootHeaders != null) ...rootHeaders,
            ...pipeHeaders,
          };
          streams.add(StreamSource(
            url: cleanUrl,
            headers: StreamSource.resolveSmartHeaders(
              cleanUrl,
              merged.isEmpty ? null : merged,
            ),
          ));
        } else if (item is Map) {
          // New format: map with url, k1, k2, clearkeys, headers
          final s = StreamSource.fromJson(Map<String, dynamic>.from(item));
          final mergedHeaders = <String, String>{
            if (rootHeaders != null) ...rootHeaders,
            if (s.headers != null) ...s.headers!,
          };
          streams.add(StreamSource(
            url: s.url,
            k1: s.k1,
            k2: s.k2,
            label: s.label,
            clearkeys: s.clearkeys,
            headers: StreamSource.resolveSmartHeaders(
              s.url,
              mergedHeaders.isEmpty ? null : mergedHeaders,
            ),
            drmLicenseUri: s.drmLicenseUri,
          ));
        }
      }
    } else if (json['streamUrl'] is String) {
      final (cleanUrl, pipeHeaders) =
          StreamSource.splitPipeHeaders(json['streamUrl'].toString());
      final merged = <String, String>{
        if (rootHeaders != null) ...rootHeaders,
        ...pipeHeaders,
      };
      streams = [
        StreamSource(
          url: cleanUrl,
          headers: StreamSource.resolveSmartHeaders(
            cleanUrl,
            merged.isEmpty ? null : merged,
          ),
        )
      ];
    }

    // Support external CLEARKEY format (e.g. ESPN / Flow format where URL and DRM are at root)
    final rootStreamUrl = json['original_url'] ?? json['url'];
    final drmLicenseUri = json['drm_license_uri']?.toString();
    if (streams.isEmpty &&
        rootStreamUrl != null &&
        rootStreamUrl.toString().isNotEmpty) {
      Map<String, String>? clearkeys;
      if (drmLicenseUri != null && drmLicenseUri.isNotEmpty) {
        clearkeys = StreamSource.parseDrmLicenseUri(drmLicenseUri);
      }
      final urlStr = rootStreamUrl.toString();
      streams.add(StreamSource(
        url: urlStr,
        clearkeys: clearkeys,
        headers: StreamSource.resolveSmartHeaders(urlStr, rootHeaders),
        drmLicenseUri: drmLicenseUri,
      ));
    }

    // Parse camaras
    List<EventCamera>? eventCameras;
    if (json['camaras'] != null && json['camaras'] is List) {
      eventCameras = (json['camaras'] as List)
          .map((c) => EventCamera.fromJson(Map<String, dynamic>.from(c)))
          .toList();
    }

    final rawName = json['name']?.toString() ?? '';
    final rawId = json['id']?.toString();
    final fallbackId = rawName.isNotEmpty
        ? rawName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_')
        : '';
    final id = (rawId != null && rawId.isNotEmpty) ? rawId : fallbackId;

    final rawType = json['type']?.toString();
    final type = (rawType != null && rawType.toUpperCase() == 'CLEARKEY')
        ? 'dash'
        : rawType;

    return Channel(
      id: id,
      name: rawName,
      category: json['category'] ?? '',
      logoUrl: logoUrls,
      streamUrl: streams,
      description: json['description'] ?? '',
      guid: json['guid'],
      isHidden: json['isHidden'] ?? false,
      order: json['order'] ?? 999,
      isFavorite: json['isFavorite'] ?? false,
      type: type,
      quality: json['quality'],
      evento: json['evento'],
      camaras: eventCameras,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'logoUrl': logoUrl,
      'streamUrl': streamUrl.map((s) => s.toJson()).toList(),
      'description': description,
      if (guid != null) 'guid': guid,
      'isHidden': isHidden,
      'order': order,
      'isFavorite': isFavorite,
      if (type != null) 'type': type,
      if (quality != null) 'quality': quality,
      if (evento != null) 'evento': evento,
      if (camaras != null) 'camaras': camaras!.map((c) => c.toJson()).toList(),
    };
  }

  StreamType getStreamType(String url) {
    // Priority 1: Use explicit type field if available
    if (type != null) {
      final t = type!.toLowerCase();
      if (t == 'dash' || t == 'mpd' || t == 'clearkey') {
        return StreamType.dash;
      }
      if (t == 'hls') return StreamType.m3u8;
    }

    // Priority 2: Check if the current stream has DRM keys (always DASH/MPD)
    final currentStream = streamUrl.isNotEmpty
        ? streamUrl.firstWhere(
            (s) => s.url == url,
            orElse: () => streamUrl.first,
          )
        : null;
    if (currentStream != null && currentStream.hasDrm) {
      return StreamType.dash;
    }

    // Priority 3: Detect from URL extension
    if (url.contains('.mpd')) {
      return StreamType.dash;
    } else if (url.contains('.m3u8') || url.contains('m3u')) {
      return StreamType.m3u8;
    } else if (url.contains('.mp4') || url.contains('.mkv')) {
      return StreamType.mp4;
    } else if (url.contains('iframe') ||
        url.contains('embed') ||
        url.contains('pivo-pro.vercel.app') ||
        url.contains('pivopro.vercel.app') ||
        url.contains('vercel.app')) {
      return StreamType.iframe;
    }
    // Default to m3u8 for live streams
    return StreamType.m3u8;
  }

  Channel copyWith({
    String? id,
    String? name,
    String? category,
    List<String>? logoUrl,
    List<StreamSource>? streamUrl,
    String? description,
    String? guid,
    bool? isHidden,
    int? order,
    bool? isFavorite,
    String? type,
    String? quality,
    String? evento,
    List<EventCamera>? camaras,
  }) {
    return Channel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      logoUrl: logoUrl ?? this.logoUrl,
      streamUrl: streamUrl ?? this.streamUrl,
      description: description ?? this.description,
      guid: guid ?? this.guid,
      isHidden: isHidden ?? this.isHidden,
      order: order ?? this.order,
      isFavorite: isFavorite ?? this.isFavorite,
      type: type ?? this.type,
      quality: quality ?? this.quality,
      evento: evento ?? this.evento,
      camaras: camaras ?? this.camaras,
    );
  }

  String getLogoUrl(bool isDarkMode) {
    if (logoUrl.isEmpty) return '';
    if (logoUrl.length == 1) return logoUrl[0];
    return isDarkMode ? logoUrl[0] : logoUrl[1];
  }
}

/// Represents a stream source with URL, optional DRM keys, and optional HTTP headers
class StreamSource {
  final String url;
  final String? k1; // Legacy: Key ID for single-key DRM
  final String? k2; // Legacy: Key for single-key DRM
  final String? label; // Optional label like "Servidor 1", "HD", etc.
  final Map<String, String>?
      clearkeys; // Multi-key ClearKey DRM: {keyId: key, ...}
  final Map<String, String>?
      headers; // Custom HTTP headers (Origin, Referer, User-Agent, etc.)
  final String? drmLicenseUri; // Raw DRM license URI (kid:...,k:... or JSON)

  StreamSource({
    required this.url,
    this.k1,
    this.k2,
    this.label,
    this.clearkeys,
    this.headers,
    this.drmLicenseUri,
  });

  factory StreamSource.fromJson(Map<String, dynamic> json) {
    final url = json['url'] ?? json['original_url'] ?? '';
    final drmLicenseUri = json['drm_license_uri']?.toString();

    // Parse clearkeys map from Firestore or from drm_license_uri if present
    Map<String, String>? parsedClearkeys;
    if (json['clearkeys'] != null && json['clearkeys'] is Map) {
      parsedClearkeys = Map<String, String>.from(
        (json['clearkeys'] as Map).map(
          (key, value) => MapEntry(key.toString(), value.toString()),
        ),
      );
    } else if (drmLicenseUri != null && drmLicenseUri.isNotEmpty) {
      parsedClearkeys = parseDrmLicenseUri(drmLicenseUri);
    }

    // Parse custom HTTP headers (normalized + pipe syntax + smart URL presets)
    final (cleanUrl, pipeHeaders) = splitPipeHeaders(url.toString());
    final extractedHeaders = extractNormalizedHeaders(json);
    final mergedRaw = <String, String>{
      if (extractedHeaders != null) ...extractedHeaders,
      ...pipeHeaders,
    };
    final parsedHeaders = resolveSmartHeaders(
      cleanUrl,
      mergedRaw.isEmpty ? null : mergedRaw,
    );

    return StreamSource(
      url: cleanUrl,
      k1: json['k1']?.toString(),
      k2: json['k2']?.toString(),
      label: json['label']?.toString() ?? json['name']?.toString(),
      clearkeys: parsedClearkeys,
      headers: parsedHeaders,
      drmLicenseUri: drmLicenseUri,
    );
  }

  /// Splits M3U/IPTV pipe-annotated URLs like:
  /// `https://host/live/canal.m3u8|Referer=https://host/&User-Agent=Mozilla/5.0`
  static (String, Map<String, String>) splitPipeHeaders(String rawUrl) {
    final trimmed = rawUrl.trim();
    final pipeIdx = trimmed.indexOf('|');
    if (pipeIdx <= 0 || pipeIdx >= trimmed.length - 1) {
      return (trimmed, const {});
    }
    final cleanUrl = trimmed.substring(0, pipeIdx).trim();
    final headerPart = trimmed.substring(pipeIdx + 1).trim();
    final parsed = <String, String>{};
    for (final pair in headerPart.split('&')) {
      final eqIdx = pair.indexOf('=');
      if (eqIdx <= 0) continue;
      final rawKey = pair.substring(0, eqIdx).trim();
      final rawVal = pair.substring(eqIdx + 1).trim();
      if (rawKey.isNotEmpty && rawVal.isNotEmpty) {
        String decoded = rawVal;
        try {
          decoded = Uri.decodeQueryComponent(rawVal);
        } catch (_) {}
        parsed[normalizeHeaderKey(rawKey)] = decoded;
      }
    }
    return (cleanUrl, parsed);
  }

  /// Normalizes canonical HTTP header names (`user-agent` -> `User-Agent`,
  /// `referer` -> `Referer`, `origin` -> `Origin`) so custom JSON headers
  /// never collide or duplicate in ExoPlayer.
  static String normalizeHeaderKey(String rawKey) {
    final trimmed = rawKey.trim();
    switch (trimmed.toLowerCase()) {
      case 'user-agent':
      case 'user_agent':
      case 'useragent':
        return 'User-Agent';
      case 'referer':
      case 'referrer':
        return 'Referer';
      case 'origin':
        return 'Origin';
      case 'cookie':
        return 'Cookie';
      case 'authorization':
        return 'Authorization';
      default:
        return trimmed;
    }
  }

  /// Extracts and normalizes HTTP headers from a JSON map (supports both nested
  /// `headers` map and flat `user-agent`/`referer`/`origin` keys).
  static Map<String, String>? extractNormalizedHeaders(
      Map<String, dynamic> json) {
    final result = <String, String>{};

    void putHeader(String key, dynamic val) {
      if (val == null) return;
      final str = val.toString().trim();
      if (str.isEmpty) return;
      result[normalizeHeaderKey(key)] = str;
    }

    if (json['headers'] is Map) {
      (json['headers'] as Map).forEach((k, v) {
        if (k != null) putHeader(k.toString(), v);
      });
    }

    // Also support flat header keys if provided directly on the object
    for (final entry in json.entries) {
      final lower = entry.key.toLowerCase();
      if (lower == 'user-agent' ||
          lower == 'user_agent' ||
          lower == 'useragent' ||
          lower == 'referer' ||
          lower == 'referrer' ||
          lower == 'origin') {
        final normKey = normalizeHeaderKey(entry.key);
        if (!result.containsKey(normKey)) {
          putHeader(normKey, entry.value);
        }
      }
    }

    return result.isEmpty ? null : result;
  }

  /// Injects smart preset headers based on stream URL patterns when not already
  /// explicitly specified by the channel JSON.
  static Map<String, String>? resolveSmartHeaders(
    String rawUrl,
    Map<String, String>? existing,
  ) {
    final merged = <String, String>{};
    if (existing != null) {
      existing.forEach((k, v) {
        final norm = normalizeHeaderKey(k);
        if (v.trim().isNotEmpty) {
          merged[norm] = v.trim();
        }
      });
    }

    final lower = rawUrl.trim().toLowerCase();
    if (lower.isEmpty) return merged.isEmpty ? null : merged;

    void putIfAbsent(String key, String value) {
      if (!merged.containsKey(key) || merged[key]!.isEmpty) {
        merged[key] = value;
      }
    }

    // 1. nvideo.net
    if (lower.contains('nvideo.net') || lower.contains('nvideo')) {
      putIfAbsent(
        'User-Agent',
        'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      );
      putIfAbsent('Referer', 'https://nvideo.net/');
      putIfAbsent('Origin', 'https://nvideo.net');
    }
    // 2. Flow Paraguay (cvattv.com.ar direct edge links & .com.py)
    // Ej: https://edge-mix01-ros.cvattv.com.ar/live/c7eds/GEN__CAM1/SA_Live_dash_enc/GEN__CAM1.mpd
    else if (lower.contains('cvattv.com.ar') ||
        lower.contains('flow.com.py') ||
        lower.contains('cvattv.com.py') ||
        lower.contains('.com.py')) {
      putIfAbsent(
        'User-Agent',
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36',
      );
      putIfAbsent('Origin', 'https://portal.app.flow.com.py');
      putIfAbsent('Referer', 'https://portal.app.flow.com.py/');
    }
    // 3. Prime Video / AivAndroidPlayer MPD
    // Ej: http://otte.live.fly.ww.aiv-cdn.net/iad-nitro/live/clients/dash-sd/enc/.../cenc-sd.mpd
    else if (lower.contains('aiv-cdn.net') ||
        lower.contains('iad-nitro') ||
        lower.contains('cenc-sd.mpd') ||
        lower.contains('primevideo.com') ||
        lower.contains('aiv-delivery.net') ||
        lower.contains('pv-cdn.net') ||
        lower.contains('d25xi40x97liuc') ||
        lower.contains('atv-ps')) {
      putIfAbsent('Referer', 'https://www.primevideo.com/');
      putIfAbsent(
        'User-Agent',
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AivAndroidPlayer/1.0 (AndroidDevice) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36',
      );
    }
    // 4. Flow Argentina (cdn-token.app.flow.com.ar / cdn-flow-balancer.app.flow.com.ar / flow.com.ar)
    // Ej: https://cdn-token.app.flow.com.ar/cdntoken/v2/generator?path=https://cdn-flow-balancer.app.flow.com.ar/...
    else if (lower.contains('cdn-token.app.flow.com.ar') ||
        lower.contains('cdn-flow-balancer.app.flow.com.ar') ||
        lower.contains('app.flow.com.ar') ||
        lower.contains('flow.com.ar') ||
        lower.contains('cablevisionflow') ||
        lower.contains('telecom.com.ar')) {
      putIfAbsent('Origin', 'https://portal.app.flow.com.ar');
      putIfAbsent('Referer', 'https://portal.app.flow.com.ar/');
      putIfAbsent(
        'User-Agent',
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36',
      );
    }

    return merged.isEmpty ? null : merged;
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'url': url};
    if (k1 != null) map['k1'] = k1;
    if (k2 != null) map['k2'] = k2;
    if (label != null) map['label'] = label;
    if (clearkeys != null && clearkeys!.isNotEmpty) {
      map['clearkeys'] = clearkeys;
    }
    if (headers != null && headers!.isNotEmpty) {
      map['headers'] = headers;
    }
    if (drmLicenseUri != null && drmLicenseUri!.isNotEmpty) {
      map['drm_license_uri'] = drmLicenseUri;
    }
    return map;
  }

  /// Returns the effective raw drm_license_uri string
  String? get effectiveDrmLicenseUri {
    final isRemoteHttpUrl = drmLicenseUri != null &&
        (drmLicenseUri!.startsWith('http://') ||
            drmLicenseUri!.startsWith('https://'));

    if (clearkeys != null && clearkeys!.isNotEmpty) {
      return clearkeys!.entries
          .map((e) => 'kid:${e.key},k:${e.value}')
          .join(',');
    }
    if (drmLicenseUri != null && drmLicenseUri!.isNotEmpty && !isRemoteHttpUrl) {
      return drmLicenseUri;
    }
    if (k1 != null && k2 != null && k1!.isNotEmpty && k2!.isNotEmpty) {
      return 'kid:$k1,k:$k2';
    }
    return null;
  }

  /// Parses drm_license_uri (e.g. "kid:0Hn_o3V-gzVhH8SL5rpH_w,k:BQWdHLIbZwilXpwm-zji8w" or JSON)
  /// and converts keys from base64url to hex.
  static Map<String, String> parseDrmLicenseUri(String uri) {
    final result = <String, String>{};
    final trimmed = uri.trim();

    // Check for JSON format first
    if (trimmed.startsWith('{')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map) {
          if (decoded['keys'] is List) {
            for (var k in decoded['keys']) {
              if (k is Map && k['kid'] != null && k['k'] != null) {
                result[normalizeKeyToHex(k['kid'].toString())] =
                    normalizeKeyToHex(k['k'].toString());
              }
            }
          } else if (decoded['kid'] != null && decoded['k'] != null) {
            result[normalizeKeyToHex(decoded['kid'].toString())] =
                normalizeKeyToHex(decoded['k'].toString());
          }
        }
        if (result.isNotEmpty) return result;
      } catch (_) {}
    }

    // Pattern 1: kid:VALUE,k:VALUE (comma, space, or semicolon separated)
    final pairRegex = RegExp(
      r'kid:([a-zA-Z0-9_\-=]+)[\s,;]+k:([a-zA-Z0-9_\-=]+)',
      caseSensitive: false,
    );
    for (final match in pairRegex.allMatches(trimmed)) {
      final kid = match.group(1);
      final k = match.group(2);
      if (kid != null && k != null) {
        result[normalizeKeyToHex(kid)] = normalizeKeyToHex(k);
      }
    }

    // Pattern 2 (inverse): k:VALUE,kid:VALUE
    if (result.isEmpty) {
      final inverseRegex = RegExp(
        r'k:([a-zA-Z0-9_\-=]+)[\s,;]+kid:([a-zA-Z0-9_\-=]+)',
        caseSensitive: false,
      );
      for (final match in inverseRegex.allMatches(trimmed)) {
        final k = match.group(1);
        final kid = match.group(2);
        if (kid != null && k != null) {
          result[normalizeKeyToHex(kid)] = normalizeKeyToHex(k);
        }
      }
    }

    return result;
  }

  /// Normalizes a key or key ID to a 32-character hexadecimal string.
  /// If already 32-char hex, returns lowercased hex.
  /// If base64/base64url, decodes and converts to hex string.
  static String normalizeKeyToHex(String keyOrKid) {
    final clean = keyOrKid.trim();
    final hexCandidate = clean.replaceAll('-', '').replaceAll(' ', '');
    // If it's already a 32-character hex string
    if (hexCandidate.length == 32 &&
        RegExp(r'^[0-9a-fA-F]{32}$').hasMatch(hexCandidate)) {
      return hexCandidate.toLowerCase();
    }
    // Try base64 / base64url decoding
    try {
      var b64 = clean.replaceAll('-', '+').replaceAll('_', '/');
      while (b64.length % 4 != 0) {
        b64 += '=';
      }
      final bytes = base64.decode(b64);
      return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    } catch (_) {
      return clean;
    }
  }

  /// Returns true if this stream has DRM keys (multi-key or legacy single-key)
  bool get hasDrm =>
      (clearkeys != null && clearkeys!.isNotEmpty) ||
      (k1 != null && k2 != null && k1!.isNotEmpty && k2!.isNotEmpty);

  /// Returns true if this stream uses multi-key ClearKey DRM
  bool get hasMultiClearKeys => clearkeys != null && clearkeys!.isNotEmpty;

  /// Returns the effective ClearKey map (multi-key or legacy single-key as map)
  Map<String, String>? get effectiveClearkeys {
    if (clearkeys != null && clearkeys!.isNotEmpty) return clearkeys;
    if (k1 != null && k2 != null && k1!.isNotEmpty && k2!.isNotEmpty) {
      return {k1!: k2!};
    }
    return null;
  }

  /// Returns true if this is a DASH stream (detected by URL or DRM keys)
  bool get isDash => url.contains('.mpd') || hasDrm;

  /// Returns true if this is an HLS stream
  bool get isHls {
    final lower = url.toLowerCase();
    return lower.contains('.m3u8') ||
        lower.contains('.m3u') ||
        lower.contains('chunklist') ||
        lower.contains('/hls/') ||
        lower.contains('output=m3u8') ||
        lower.contains('output=hls') ||
        lower.contains('format=m3u8');
  }
}

enum StreamType {
  m3u8, // HLS
  mp4, // MP4 video
  dash, // DASH (MPD)
  iframe, // Embed/iframe
}
