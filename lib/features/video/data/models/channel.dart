class Channel {
  final String id;
  final String name;
  final String category;
  final List<String> logoUrl; // [0] dark mode, [1] light mode
  final List<StreamSource> streamUrl;
  final String description;
  final bool isHidden;
  final int order;
  bool isFavorite;
  final String? type; // 'dash' or 'hls' to override detection
  final String? quality;

  Channel({
    required this.id,
    required this.name,
    required this.category,
    required this.logoUrl,
    required this.streamUrl,
    required this.description,
    this.isHidden = false,
    this.order = 999,
    this.isFavorite = false,
    this.type,
    this.quality,
  });

  factory Channel.fromJson(Map<String, dynamic> json) {
    List<String> logoUrls = [];
    if (json['logoUrl'] is List) {
      logoUrls = List<String>.from(json['logoUrl']);
    } else if (json['logoUrl'] is String) {
      logoUrls = [json['logoUrl']];
    }

    // Parse streamUrl - supports both old String format and new Map format
    List<StreamSource> streams = [];
    if (json['streamUrl'] is List) {
      for (var item in json['streamUrl']) {
        if (item is String) {
          // Old format: simple string URL
          streams.add(StreamSource(url: item));
        } else if (item is Map<String, dynamic>) {
          // New format: map with url, k1, k2
          streams.add(StreamSource.fromJson(item));
        }
      }
    } else if (json['streamUrl'] is String) {
      streams = [StreamSource(url: json['streamUrl'])];
    }

    return Channel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      logoUrl: logoUrls,
      streamUrl: streams,
      description: json['description'] ?? '',
      isHidden: json['isHidden'] ?? false,
      order: json['order'] ?? 999,
      isFavorite: json['isFavorite'] ?? false,
      type: json['type'],
      quality: json['quality'],
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
      'isHidden': isHidden,
      'order': order,
      'isFavorite': isFavorite,
      if (type != null) 'type': type,
      if (quality != null) 'quality': quality,
    };
  }

  StreamType getStreamType(String url) {
    // Priority 1: Use explicit type field if available
    if (type != null) {
      if (type!.toLowerCase() == 'dash') return StreamType.dash;
      if (type!.toLowerCase() == 'hls') return StreamType.m3u8;
    }

    // Priority 2: Detect from URL extension
    if (url.contains('.mpd')) {
      return StreamType.dash;
    } else if (url.contains('.m3u8') || url.contains('m3u')) {
      return StreamType.m3u8;
    } else if (url.contains('.mp4') || url.contains('.mkv')) {
      return StreamType.mp4;
    } else if (url.contains('iframe') ||
        url.contains('embed') ||
        url.contains('pivopro.vercel.app')) {
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
    bool? isHidden,
    int? order,
    bool? isFavorite,
    String? type,
    String? quality,
  }) {
    return Channel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      logoUrl: logoUrl ?? this.logoUrl,
      streamUrl: streamUrl ?? this.streamUrl,
      description: description ?? this.description,
      isHidden: isHidden ?? this.isHidden,
      order: order ?? this.order,
      isFavorite: isFavorite ?? this.isFavorite,
      type: type ?? this.type,
      quality: quality ?? this.quality,
    );
  }

  String getLogoUrl(bool isDarkMode) {
    if (logoUrl.isEmpty) return '';
    if (logoUrl.length == 1) return logoUrl[0];
    return isDarkMode ? logoUrl[0] : logoUrl[1];
  }
}

/// Represents a stream source with URL and optional DRM keys
class StreamSource {
  final String url;
  final String? k1; // Key ID for DRM (hex format)
  final String? k2; // Key for DRM (hex format)
  final String? label; // Optional label like "Servidor 1", "HD", etc.
  final Map<String, String>?
      headers; // Custom HTTP headers (Referer, Origin, etc.)

  StreamSource({
    required this.url,
    this.k1,
    this.k2,
    this.label,
    this.headers,
  });

  factory StreamSource.fromJson(Map<String, dynamic> json) {
    Map<String, String>? parsedHeaders;
    if (json['headers'] != null && json['headers'] is Map) {
      parsedHeaders = Map<String, String>.from(json['headers']);
    }

    return StreamSource(
      url: json['url'] ?? '',
      k1: json['k1'],
      k2: json['k2'],
      label: json['label'],
      headers: parsedHeaders,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'url': url};
    if (k1 != null) map['k1'] = k1;
    if (k2 != null) map['k2'] = k2;
    if (label != null) map['label'] = label;
    if (headers != null) map['headers'] = headers;
    return map;
  }

  /// Returns true if this stream has DRM keys
  bool get hasDrm =>
      k1 != null && k2 != null && k1!.isNotEmpty && k2!.isNotEmpty;

  /// Returns true if DRM keys are valid (hexadecimal format)
  bool get hasValidDrm {
    if (!hasDrm) return false;
    final hexPattern = RegExp(r'^[0-9a-fA-F]+$');
    return hexPattern.hasMatch(k1!) && hexPattern.hasMatch(k2!);
  }

  /// Builds ClearKey configuration string for media_kit
  /// Format: "keyId:key"
  String? get clearKeyConfig {
    if (!hasValidDrm) return null;
    return '$k1:$k2';
  }

  /// Returns true if this is a DASH stream
  bool get isDash => url.contains('.mpd');

  /// Returns true if this is an HLS stream
  bool get isHls => url.contains('.m3u8') || url.contains('m3u');
}

enum StreamType {
  m3u8, // HLS
  mp4, // MP4 video
  dash, // DASH (MPD)
  iframe, // Embed/iframe
}
