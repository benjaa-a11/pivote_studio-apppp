class Channel {
  final String id;
  final String name;
  final String category;
  final List<String>
      logoUrl; // Array with 2 URLs: [0] for dark mode, [1] for light mode
  final List<String> streamUrl;
  final String description;
  final String? quality; // Add quality property
  final bool isHidden;
  final int order; // Default display order (lower = higher priority)
  bool isFavorite;

  Channel({
    required this.id,
    required this.name,
    required this.category,
    required this.logoUrl,
    required this.streamUrl,
    required this.description,
    this.quality, // Add quality parameter
    this.isHidden = false,
    this.order = 999, // Default to end if not specified
    this.isFavorite = false,
  });

  factory Channel.fromJson(Map<String, dynamic> json) {
    List<String> logoUrls = [];
    if (json['logoUrl'] is List) {
      logoUrls = List<String>.from(json['logoUrl']);
    } else if (json['logoUrl'] is String) {
      logoUrls = [json['logoUrl']];
    }

    List<String> streams = [];
    if (json['streamUrl'] is List) {
      streams = List<String>.from(json['streamUrl']);
    } else if (json['streamUrl'] is String) {
      streams = [json['streamUrl']];
    }

    return Channel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      logoUrl: logoUrls,
      streamUrl: streams,
      description: json['description'] ?? '',
      quality: json['quality'], // Add quality field
      isHidden: json['isHidden'] ?? false,
      order: json['order'] ?? 999, // Add order field with default
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'logoUrl': logoUrl,
      'streamUrl': streamUrl,
      'description': description,
      'quality': quality, // Add quality field
      'isHidden': isHidden,
      'order': order, // Add order field
      'isFavorite': isFavorite,
    };
  }

  StreamType getStreamType(String url) {
    // Improved detection for different stream types
    if (url.contains('.m3u8') || url.contains('m3u')) {
      return StreamType.m3u8;
    } else if (url.contains('.mp4') || url.contains('.mkv')) {
      return StreamType.mp4;
    } else if (url.contains('iframe') ||
        url.contains('embed') ||
        url.contains('pivopro.vercel.app') ||
        (!url.contains('.m3u8') && !url.contains('.mp4'))) {
      // If it doesn't contain typical video extensions but has a URL, treat as iframe
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
    List<String>? streamUrl,
    String? description,
    String? quality, // Add quality parameter
    bool? isHidden,
    int? order, // Add order parameter
    bool? isFavorite,
  }) {
    return Channel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      logoUrl: logoUrl ?? this.logoUrl,
      streamUrl: streamUrl ?? this.streamUrl,
      description: description ?? this.description,
      quality: quality ?? this.quality, // Add quality parameter
      isHidden: isHidden ?? this.isHidden,
      order: order ?? this.order, // Add order parameter
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  // Get logo URL based on theme mode
  String getLogoUrl(bool isDarkMode) {
    if (logoUrl.isEmpty) return '';
    if (logoUrl.length == 1) return logoUrl[0];
    // Return dark mode logo (index 0) or light mode logo (index 1)
    return isDarkMode ? logoUrl[0] : logoUrl[1];
  }
}

enum StreamType {
  m3u8,
  mp4,
  iframe,
}
