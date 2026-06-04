class Movie {
  final String id;
  final String title;
  final String description;
  final String posterUrl;
  final String backdropUrl;
  final double rating;
  final int year;
  final String duration;
  final List<String> genres;
  final String streamUrl;
  final List<String> cast;
  final List<String> directors;
  final bool isFeatured;
  final bool isTrending;
  final Duration lastPosition;
  final List<String> subtitleUrls;
  final List<String> audioTracks;

  Movie({
    required this.id,
    required this.title,
    required this.description,
    required this.posterUrl,
    required this.backdropUrl,
    required this.rating,
    required this.year,
    required this.duration,
    required this.genres,
    required this.streamUrl,
    required this.cast,
    required this.directors,
    this.isFeatured = false,
    this.isTrending = false,
    this.lastPosition = Duration.zero,
    this.subtitleUrls = const [],
    this.audioTracks = const [],
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      posterUrl: json['posterUrl'] ?? '',
      backdropUrl: json['backdropUrl'] ?? '',
      rating: (json['rating'] ?? 0.0) as double,
      year: json['year'] ?? DateTime.now().year,
      duration: json['duration'] ?? '',
      genres: List<String>.from(json['genres'] ?? []),
      streamUrl: json['streamUrl'] ?? '',
      cast: List<String>.from(json['cast'] ?? []),
      directors: List<String>.from(json['directors'] ?? []),
      isFeatured: json['isFeatured'] ?? false,
      isTrending: json['isTrending'] ?? false,
      lastPosition: Duration(milliseconds: json['lastPositionMs'] ?? 0),
      subtitleUrls: List<String>.from(json['subtitleUrls'] ?? []),
      audioTracks: List<String>.from(json['audioTracks'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'posterUrl': posterUrl,
      'backdropUrl': backdropUrl,
      'rating': rating,
      'year': year,
      'duration': duration,
      'genres': genres,
      'streamUrl': streamUrl,
      'cast': cast,
      'directors': directors,
      'isFeatured': isFeatured,
      'isTrending': isTrending,
      'lastPositionMs': lastPosition.inMilliseconds,
      'subtitleUrls': subtitleUrls,
      'audioTracks': audioTracks,
    };
  }

  Movie copyWith({
    String? id,
    String? title,
    String? description,
    String? posterUrl,
    String? backdropUrl,
    double? rating,
    int? year,
    String? duration,
    List<String>? genres,
    String? streamUrl,
    List<String>? cast,
    List<String>? directors,
    bool? isFeatured,
    bool? isTrending,
    Duration? lastPosition,
    List<String>? subtitleUrls,
    List<String>? audioTracks,
  }) {
    return Movie(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      posterUrl: posterUrl ?? this.posterUrl,
      backdropUrl: backdropUrl ?? this.backdropUrl,
      rating: rating ?? this.rating,
      year: year ?? this.year,
      duration: duration ?? this.duration,
      genres: genres ?? this.genres,
      streamUrl: streamUrl ?? this.streamUrl,
      cast: cast ?? this.cast,
      directors: directors ?? this.directors,
      isFeatured: isFeatured ?? this.isFeatured,
      isTrending: isTrending ?? this.isTrending,
      lastPosition: lastPosition ?? this.lastPosition,
      subtitleUrls: subtitleUrls ?? this.subtitleUrls,
      audioTracks: audioTracks ?? this.audioTracks,
    );
  }
}
