import 'package:pivote/features/video/data/models/channel.dart';

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
    };
  }

  /// Converts this Movie into a Channel so it can play seamlessly in PlayerScreen
  Channel toChannel() {
    return Channel(
      id: 'movie_$id',
      name: title,
      category: 'Películas',
      logoUrl: [posterUrl, posterUrl], // [0] dark mode, [1] light mode
      streamUrl: [
        StreamSource(
          url: streamUrl,
          label: 'Servidor Principal (Auto)',
        ),
      ],
      description: description,
      type: streamUrl.contains('.mpd') ? 'dash' : (streamUrl.contains('.m3u8') ? 'hls' : 'mp4'),
      quality: 'Full HD',
    );
  }
}
