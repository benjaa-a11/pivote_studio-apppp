import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pivote/features/auth/data/services/auth_service.dart';
import 'package:pivote/features/movies/data/models/movie.dart';
import 'package:pivote/features/movies/data/services/movie_service.dart';

class MoviesProvider extends ChangeNotifier {
  MoviesProvider() {
    loadMovieFavorites();
  }
  List<Movie> _allMovies = [];
  bool _isLoading = false;
  String _selectedGenre = 'Todos';
  String _searchQuery = '';
  
  // In-memory cache of movie playback positions and durations
  final Map<String, Duration> _playbackPositions = {};
  final Map<String, Duration> _movieDurations = {};

  // Favorites / Wishlist state
  Set<String> _favoriteMovieIds = {};
  bool _isSyncingFavorites = false;
  static const String _favoriteMoviesKey = 'favorite_movie_ids_v2';

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

  // ── FAVORITES / MY LIST API ──

  bool get isSyncingFavorites => _isSyncingFavorites;

  List<Movie> get favoriteMovies {
    return _allMovies.map((movie) {
      final cachedPos = _playbackPositions[movie.id] ?? Duration.zero;
      return movie.copyWith(lastPosition: cachedPos);
    }).where((m) => _favoriteMovieIds.contains(m.id)).toList();
  }

  bool isMovieFavorite(String movieId) {
    return _favoriteMovieIds.contains(movieId);
  }

  /// Toggle movie favorite state with immediate sync to Firestore and local SharedPreferences
  Future<void> toggleMovieFavorite(Movie movie) async {
    final movieId = movie.id;
    if (_favoriteMovieIds.contains(movieId)) {
      _favoriteMovieIds.remove(movieId);
    } else {
      _favoriteMovieIds.add(movieId);
    }
    notifyListeners();

    await _saveMovieFavorites();
    await _syncMovieFavoritesToFirestore();
  }

  /// Load movie favorites from SharedPreferences and Firestore
  Future<void> loadMovieFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList(_favoriteMoviesKey) ?? [];
      _favoriteMovieIds = Set<String>.from(ids);
      notifyListeners();

      // Sync from Firestore in background
      _syncMovieFavoritesFromFirestore();
    } catch (e) {
      debugPrint('❌ Error loading movie favorites: $e');
    }
  }

  /// Save movie favorites to SharedPreferences
  Future<void> _saveMovieFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_favoriteMoviesKey, _favoriteMovieIds.toList());
    } catch (e) {
      debugPrint('❌ Error saving movie favorites locally: $e');
    }
  }

  /// Sync movie favorites to Firestore under the 'usuarios' collection (matching user channel favorites)
  Future<void> _syncMovieFavoritesToFirestore() async {
    final uid = AuthService.currentUserId;
    if (uid == null) return;

    try {
      _isSyncingFavorites = true;
      notifyListeners();

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .set({
        'favoriteMovies': _favoriteMovieIds.toList(),
      }, SetOptions(merge: true));

      debugPrint('✅ Movie favorites synced to Firestore: ${_favoriteMovieIds.length} items');
    } catch (e) {
      debugPrint('❌ Error syncing movie favorites to Firestore: $e');
    } finally {
      _isSyncingFavorites = false;
      notifyListeners();
    }
  }

  /// Sync movie favorites from Firestore
  Future<void> _syncMovieFavoritesFromFirestore() async {
    final uid = AuthService.currentUserId;
    if (uid == null) return;

    try {
      _isSyncingFavorites = true;
      notifyListeners();

      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null && data.containsKey('favoriteMovies')) {
          final List<dynamic> remoteFavorites = data['favoriteMovies'] ?? [];
          final List<String> remoteIds = remoteFavorites.cast<String>();

          if (remoteIds.isNotEmpty) {
            final remoteSet = Set<String>.from(remoteIds);
            
            // If they are different, update local state
            if (remoteSet.difference(_favoriteMovieIds).isNotEmpty ||
                _favoriteMovieIds.difference(remoteSet).isNotEmpty) {
              _favoriteMovieIds = remoteSet;
              await _saveMovieFavorites();
              notifyListeners();
              debugPrint('✅ Movie favorites synced from Firestore: ${_favoriteMovieIds.length} items');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error syncing movie favorites from Firestore: $e');
    } finally {
      _isSyncingFavorites = false;
      notifyListeners();
    }
  }
}
