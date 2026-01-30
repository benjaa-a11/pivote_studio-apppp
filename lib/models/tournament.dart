class Tournament {
  final String id;
  final String name;
  final List<String> logoUrl; // Array with 2 URLs: [0] for dark mode, [1] for light mode

  Tournament({
    required this.id,
    required this.name,
    required this.logoUrl,
  });

  factory Tournament.fromJson(Map<String, dynamic> json) {
    List<String> logoUrls = [];
    if (json['logoUrl'] is List) {
      logoUrls = List<String>.from(json['logoUrl']);
    } else if (json['logoUrl'] is String) {
      logoUrls = [json['logoUrl']];
    }

    return Tournament(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      logoUrl: logoUrls,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'logoUrl': logoUrl,
    };
  }

  // Get logo URL based on theme mode
  String getLogoUrl(bool isDarkMode) {
    if (logoUrl.isEmpty) return '';
    if (logoUrl.length == 1) return logoUrl[0];
    // Return dark mode logo (index 0) or light mode logo (index 1)
    return isDarkMode ? logoUrl[0] : logoUrl[1];
  }
}