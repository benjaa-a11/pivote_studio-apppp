class Channel {
  final String id;
  final String name;
  final String category;
  final List<String> logoUrl; // [0] dark mode, [1] light mode
  final List<StreamSource> streamUrl; // Changed to support both String and Map
  final String description;
  final bool isHidden;
  final int order;
  bool isFavorite;
  final String? type; // Optional: 'dash' or 'hls' to override detection
  final String? quality; // Optional: quality indicator
  
  // DRM keys at channel level (for backwards compatibility)
  final String? k1;
  final String? k2;

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
    this.k1,
    this.k2,
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
      k1: json['k1'],
      k2: json['k2'],
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
      if (k1 != null) 'k1': k1,
      if (k2 != null) 'k2': k2,
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
        url.contains('pivopro.vercel.app') ||
        (!url.contains('.m3u8') &&
            !url.contains('.mp4') &&
            !url.contains('.mpd'))) {
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
    String? k1,
    String? k2,
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
      k1: k1 ?? this.k1,
      k2: k2 ?? this.k2,
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
  final String? k1; // Key ID for DRM
  final String? k2; // Key for DRM
  final String? label; // Optional label like "Servidor 1", "HD", etc.

  StreamSource({
    required this.url,
    this.k1,
    this.k2,
    this.label,
  });

  factory StreamSource.fromJson(Map<String, dynamic> json) {
    return StreamSource(
      url: json['url'] ?? '',
      k1: json['k1'],
      k2: json['k2'],
      label: json['label'],
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'url': url};
    if (k1 != null) map['k1'] = k1;
    if (k2 != null) map['k2'] = k2;
    if (label != null) map['label'] = label;
    return map;
  }

  bool get hasDrm => k1 != null && k2 != null;

  bool get isDash => url.contains('.mpd');
  
  bool get isHls => url.contains('.m3u8') || url.contains('m3u');
}

enum StreamType {
  m3u8,
  mp4,
  dash,
  iframe,
}