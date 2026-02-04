class Radio {
  final String id;
  final String name;
  final String frequency; // This will be mapped to "emisora" from Firestore
  final String logoUrl;
  final List<String> streamUrl;
  final String? category;
  bool isFavorite;

  Radio({
    required this.id,
    required this.name,
    required this.frequency,
    required this.logoUrl,
    required this.streamUrl,
    this.category,
    this.isFavorite = false,
  });

  factory Radio.fromJson(Map<String, dynamic> json) {
    List<String> streams = [];
    if (json['streamUrl'] is List) {
      streams = List<String>.from(json['streamUrl']);
    } else if (json['streamUrl'] is String) {
      streams = [json['streamUrl']];
    }

    return Radio(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      frequency:
          json['emisora'] ?? '', // Map "emisora" from Firestore to "frequency"
      logoUrl: json['logoUrl'] ?? '',
      streamUrl: streams,
      category: json['category'],
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'emisora': frequency, // Map "frequency" to "emisora" for Firestore
      'logoUrl': logoUrl,
      'streamUrl': streamUrl,
      'category': category,
      'isFavorite': isFavorite,
    };
  }

  Radio copyWith({
    String? id,
    String? name,
    String? frequency,
    String? logoUrl,
    List<String>? streamUrl,
    String? category,
    bool? isFavorite,
  }) {
    return Radio(
      id: id ?? this.id,
      name: name ?? this.name,
      frequency: frequency ?? this.frequency,
      logoUrl: logoUrl ?? this.logoUrl,
      streamUrl: streamUrl ?? this.streamUrl,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
