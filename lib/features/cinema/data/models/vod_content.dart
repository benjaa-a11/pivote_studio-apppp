enum ContentType {
  movie,
  series,
  program,
}

enum VideoQuality {
  sd,
  hd,
  fullHd,
  uhd,
  unknown,
}

/// Servidor de video con embed URL
class VideoServer {
  final String id;
  final String name;
  final String embedUrl;
  final VideoQuality quality;
  final String? language;
  final bool isRecommended;

  VideoServer({
    required this.id,
    required this.name,
    required this.embedUrl,
    this.quality = VideoQuality.unknown,
    this.language,
    this.isRecommended = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'embedUrl': embedUrl,
        'quality': quality.toString(),
        'language': language,
        'isRecommended': isRecommended,
      };

  factory VideoServer.fromJson(Map<String, dynamic> json) {
    return VideoServer(
      id: json['id'],
      name: json['name'],
      embedUrl: json['embedUrl'],
      quality: VideoQuality.values.firstWhere(
        (e) => e.toString() == json['quality'],
        orElse: () => VideoQuality.unknown,
      ),
      language: json['language'],
      isRecommended: json['isRecommended'] ?? false,
    );
  }
}

/// Episodio de una serie
class Episode {
  final String id;
  final int episodeNumber;
  final int seasonNumber;
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final int? durationMinutes;
  final List<VideoServer> servers;
  final DateTime? releaseDate;

  Episode({
    required this.id,
    required this.episodeNumber,
    required this.seasonNumber,
    required this.title,
    this.description,
    this.thumbnailUrl,
    this.durationMinutes,
    required this.servers,
    this.releaseDate,
  });

  String get displayTitle => 'E$episodeNumber - $title';
  String get shortTitle => 'E$episodeNumber';

  Map<String, dynamic> toJson() => {
        'id': id,
        'episodeNumber': episodeNumber,
        'seasonNumber': seasonNumber,
        'title': title,
        'description': description,
        'thumbnailUrl': thumbnailUrl,
        'durationMinutes': durationMinutes,
        'servers': servers.map((s) => s.toJson()).toList(),
        'releaseDate': releaseDate?.toIso8601String(),
      };

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      id: json['id'],
      episodeNumber: json['episodeNumber'],
      seasonNumber: json['seasonNumber'],
      title: json['title'],
      description: json['description'],
      thumbnailUrl: json['thumbnailUrl'],
      durationMinutes: json['durationMinutes'],
      servers: (json['servers'] as List)
          .map((s) => VideoServer.fromJson(s))
          .toList(),
      releaseDate: json['releaseDate'] != null
          ? DateTime.parse(json['releaseDate'])
          : null,
    );
  }
}

/// Temporada de una serie
class Season {
  final String id;
  final int seasonNumber;
  final String title;
  final String? description;
  final String? posterUrl;
  final List<Episode> episodes;
  final int? year;

  Season({
    required this.id,
    required this.seasonNumber,
    required this.title,
    this.description,
    this.posterUrl,
    required this.episodes,
    this.year,
  });

  String get displayTitle => 'Temporada $seasonNumber';
  int get episodeCount => episodes.length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'seasonNumber': seasonNumber,
        'title': title,
        'description': description,
        'posterUrl': posterUrl,
        'episodes': episodes.map((e) => e.toJson()).toList(),
        'year': year,
      };

  factory Season.fromJson(Map<String, dynamic> json) {
    return Season(
      id: json['id'],
      seasonNumber: json['seasonNumber'],
      title: json['title'],
      description: json['description'],
      posterUrl: json['posterUrl'],
      episodes:
          (json['episodes'] as List).map((e) => Episode.fromJson(e)).toList(),
      year: json['year'],
    );
  }
}

/// Contenido VOD base (Movie o Series)
abstract class VodContent {
  final String id;
  final String title;
  final String? description;
  final String? posterUrl;
  final String? backdropUrl;
  final ContentType type;
  final List<String> genres;
  final double? rating;
  final int? year;
  final String? director;
  final List<String> cast;
  final String? trailer;
  final bool isFeatured;

  VodContent({
    required this.id,
    required this.title,
    this.description,
    this.posterUrl,
    this.backdropUrl,
    required this.type,
    this.genres = const [],
    this.rating,
    this.year,
    this.director,
    this.cast = const [],
    this.trailer,
    this.isFeatured = false,
  });

  Map<String, dynamic> toBaseJson() => {
        'id': id,
        'title': title,
        'description': description,
        'posterUrl': posterUrl,
        'backdropUrl': backdropUrl,
        'type': type.toString(),
        'genres': genres,
        'rating': rating,
        'year': year,
        'director': director,
        'cast': cast,
        'trailer': trailer,
        'isFeatured': isFeatured,
      };
}

/// Película
class Movie extends VodContent {
  final int? durationMinutes;
  final List<VideoServer> servers;

  Movie({
    required super.id,
    required super.title,
    super.description,
    super.posterUrl,
    super.backdropUrl,
    super.genres,
    super.rating,
    super.year,
    super.director,
    super.cast,
    super.trailer,
    super.isFeatured,
    this.durationMinutes,
    required this.servers,
    super.type = ContentType.movie,
  });

  String get durationFormatted {
    if (durationMinutes == null) return 'N/A';
    final hours = durationMinutes! ~/ 60;
    final minutes = durationMinutes! % 60;
    return hours > 0 ? '${hours}h ${minutes}min' : '${minutes}min';
  }

  Map<String, dynamic> toJson() {
    final json = super.toBaseJson();
    json.addAll({
      'durationMinutes': durationMinutes,
      'servers': servers.map((s) => s.toJson()).toList(),
    });
    return json;
  }

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      posterUrl: json['posterUrl'],
      backdropUrl: json['backdropUrl'],
      genres:
          (json['genres'] as List?)?.map((e) => e.toString()).toList() ?? [],
      rating: json['rating']?.toDouble(),
      year: json['year'],
      director: json['director'],
      cast: (json['cast'] as List?)?.map((e) => e.toString()).toList() ?? [],
      trailer: json['trailer'],
      isFeatured: json['isFeatured'] ?? false,
      durationMinutes: json['durationMinutes'],
      servers: (json['servers'] as List)
          .map((s) => VideoServer.fromJson(s))
          .toList(),
      type: ContentType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => ContentType.movie,
      ),
    );
  }
}

/// Programa / Evento Especial
class Program extends Movie {
  Program({
    required super.id,
    required super.title,
    super.description,
    super.posterUrl,
    super.backdropUrl,
    super.genres,
    super.rating,
    super.year,
    super.director,
    super.cast,
    super.trailer,
    super.isFeatured,
    super.durationMinutes,
    required super.servers,
  }) : super(type: ContentType.program);

  @override
  factory Program.fromJson(Map<String, dynamic> json) {
    return Program(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      posterUrl: json['posterUrl'],
      backdropUrl: json['backdropUrl'],
      genres:
          (json['genres'] as List?)?.map((e) => e.toString()).toList() ?? [],
      rating: json['rating']?.toDouble(),
      year: json['year'],
      director: json['director'],
      cast: (json['cast'] as List?)?.map((e) => e.toString()).toList() ?? [],
      trailer: json['trailer'],
      isFeatured: json['isFeatured'] ?? false,
      durationMinutes: json['durationMinutes'],
      servers: (json['servers'] as List)
          .map((s) => VideoServer.fromJson(s))
          .toList(),
    );
  }
}

/// Serie
class Series extends VodContent {
  final List<Season> seasons;
  final String? status; // "Ongoing", "Finished", etc.
  final int? totalEpisodes;

  Series({
    required super.id,
    required super.title,
    super.description,
    super.posterUrl,
    super.backdropUrl,
    super.genres,
    super.rating,
    super.year,
    super.director,
    super.cast,
    super.trailer,
    super.isFeatured,
    required this.seasons,
    this.status,
    this.totalEpisodes,
  }) : super(type: ContentType.series);

  int get seasonCount => seasons.length;
  int get episodeCount =>
      totalEpisodes ?? seasons.fold(0, (sum, s) => sum + s.episodeCount);

  String get statusText {
    switch (status?.toLowerCase()) {
      case 'ongoing':
        return 'En emisión';
      case 'finished':
        return 'Finalizada';
      case 'cancelled':
        return 'Cancelada';
      default:
        return status ?? 'N/A';
    }
  }

  Map<String, dynamic> toJson() {
    final json = super.toBaseJson();
    json.addAll({
      'seasons': seasons.map((s) => s.toJson()).toList(),
      'status': status,
      'totalEpisodes': totalEpisodes,
    });
    return json;
  }

  factory Series.fromJson(Map<String, dynamic> json) {
    return Series(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      posterUrl: json['posterUrl'],
      backdropUrl: json['backdropUrl'],
      genres:
          (json['genres'] as List?)?.map((e) => e.toString()).toList() ?? [],
      rating: json['rating']?.toDouble(),
      year: json['year'],
      director: json['director'],
      cast: (json['cast'] as List?)?.map((e) => e.toString()).toList() ?? [],
      trailer: json['trailer'],
      isFeatured: json['isFeatured'] ?? false,
      seasons:
          (json['seasons'] as List).map((s) => Season.fromJson(s)).toList(),
      status: json['status'],
      totalEpisodes: json['totalEpisodes'],
    );
  }
}

/// Historial de reproducción
class WatchProgress {
  final String contentId;
  final String? episodeId;
  final Duration position;
  final Duration duration;
  final DateTime lastWatched;

  WatchProgress({
    required this.contentId,
    this.episodeId,
    required this.position,
    required this.duration,
    required this.lastWatched,
  });

  double get progressPercentage {
    if (duration.inMilliseconds == 0) return 0;
    return (position.inMilliseconds / duration.inMilliseconds * 100)
        .clamp(0, 100);
  }

  bool get isCompleted => progressPercentage >= 90;

  Map<String, dynamic> toJson() => {
        'contentId': contentId,
        'episodeId': episodeId,
        'positionMs': position.inMilliseconds,
        'durationMs': duration.inMilliseconds,
        'lastWatched': lastWatched.toIso8601String(),
      };

  factory WatchProgress.fromJson(Map<String, dynamic> json) {
    return WatchProgress(
      contentId: json['contentId'],
      episodeId: json['episodeId'],
      position: Duration(milliseconds: json['positionMs']),
      duration: Duration(milliseconds: json['durationMs']),
      lastWatched: DateTime.parse(json['lastWatched']),
    );
  }
}
