import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pivote/features/movies/data/models/movie.dart';
import 'package:pivote/features/movies/data/services/movie_service.dart';

class MoviesProvider extends ChangeNotifier {
  List<Movie> _allMovies = [];
  bool _isLoading = false;
  String _selectedGenre = 'Todos';
  String _searchQuery = '';
  
  // In-memory cache of movie playback positions and durations
  final Map<String, Duration> _playbackPositions = {};
  final Map<String, Duration> _movieDurations = {};

  List<Movie> get allMovies => _allMovies.map((movie) {
        final cachedPos = _playbackPositions[movie.id] ?? Duration.zero;
        return movie.copyWith(lastPosition: cachedPos);
      }).toList();

  bool get isLoading => _isLoading;
  String get selectedGenre => _selectedGenre;
  String get searchQuery => _searchQuery;

  /// Fetch movies from high-performance MovieService and load playback progress
  Future<void> loadMovies({bool force = false}) async {
    if (_allMovies.isNotEmpty && !force) return;

    _isLoading = true;
    notifyListeners();

    try {
      _allMovies = await MovieService.getMovies();
      
      // Load saved positions from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      _playbackPositions.clear();
      _movieDurations.clear();
      for (var movie in _allMovies) {
        final posMs = prefs.getInt('movie_pos_${movie.id}');
        if (posMs != null && posMs > 0) {
          _playbackPositions[movie.id] = Duration(milliseconds: posMs);
        }
        final durMs = prefs.getInt('movie_dur_${movie.id}');
        if (durMs != null && durMs > 0) {
          _movieDurations[movie.id] = Duration(milliseconds: durMs);
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading movies: $e');
      _allMovies = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Returns featured movies for top sliding carousel
  List<Movie> get featuredMovies {
    return _allMovies.map((movie) {
      final cachedPos = _playbackPositions[movie.id] ?? Duration.zero;
      return movie.copyWith(lastPosition: cachedPos);
    }).where((m) => m.isFeatured).toList();
  }

  /// Returns trending movies
  List<Movie> get trendingMovies {
    return _allMovies.map((movie) {
      final cachedPos = _playbackPositions[movie.id] ?? Duration.zero;
      return movie.copyWith(lastPosition: cachedPos);
    }).where((m) => m.isTrending).toList();
  }

  /// Returns movies with saved progress (Continue Watching)
  List<Movie> get resumeMovies {
    return _allMovies.map((movie) {
      final cachedPos = _playbackPositions[movie.id] ?? Duration.zero;
      return movie.copyWith(lastPosition: cachedPos);
    }).where((movie) {
      return movie.lastPosition > const Duration(seconds: 10);
    }).toList();
  }

  /// Filtered movies based on genre and search query
  List<Movie> get movies {
    return _allMovies.map((movie) {
      final cachedPos = _playbackPositions[movie.id] ?? Duration.zero;
      return movie.copyWith(lastPosition: cachedPos);
    }).where((movie) {
      final matchesGenre = _selectedGenre == 'Todos' ||
          movie.genres.any((g) => g.toLowerCase() == _selectedGenre.toLowerCase());
      
      final matchesSearch = _searchQuery.isEmpty ||
          movie.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          movie.genres.any((g) => g.toLowerCase().contains(_searchQuery.toLowerCase())) ||
          movie.directors.any((d) => d.toLowerCase().contains(_searchQuery.toLowerCase()));

      return matchesGenre && matchesSearch;
    }).toList();
  }

  /// Unique list of genres present in all movies
  List<String> get genres {
    final Set<String> genreSet = {'Todos'};
    for (var movie in _allMovies) {
      genreSet.addAll(movie.genres);
    }
    return genreSet.toList();
  }

  /// Get specific movie playback position
  Duration getPlaybackPosition(String movieId) {
    return _playbackPositions[movieId] ?? Duration.zero;
  }

  /// Get specific movie duration
  Duration getMovieDuration(String movieId) {
    return _movieDurations[movieId] ?? Duration.zero;
  }

  /// Save playback position and duration in memory and SharedPreferences
  Future<void> savePlaybackPosition(String movieId, Duration position, {Duration? duration}) async {
    // Only update and notify if there's a real change to avoid infinite cycles
    final currentPos = _playbackPositions[movieId] ?? Duration.zero;
    if ((position.inSeconds - currentPos.inSeconds).abs() < 1 && duration == null) return;

    _playbackPositions[movieId] = position;
    if (duration != null && duration > Duration.zero) {
      _movieDurations[movieId] = duration;
    }
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('movie_pos_$movieId', position.inMilliseconds);
      if (duration != null && duration > Duration.zero) {
        await prefs.setInt('movie_dur_$movieId', duration.inMilliseconds);
      }
    } catch (e) {
      debugPrint('❌ Error saving playback position: $e');
    }
  }

  /// Clear playback position when movie is completed
  Future<void> clearPlaybackPosition(String movieId) async {
    if (!_playbackPositions.containsKey(movieId) && !_movieDurations.containsKey(movieId)) return;

    _playbackPositions.remove(movieId);
    _movieDurations.remove(movieId);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('movie_pos_$movieId');
      await prefs.remove('movie_dur_$movieId');
    } catch (e) {
      debugPrint('❌ Error clearing playback position: $e');
    }
  }

  /// Update active genre
  void selectGenre(String genre) {
    if (_selectedGenre == genre) return;
    _selectedGenre = genre;
    notifyListeners();
  }

  /// Update search query
  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    notifyListeners();
  }

  /// Clear all search and category filters
  void clearFilters() {
    _selectedGenre = 'Todos';
    _searchQuery = '';
    notifyListeners();
  }
}
