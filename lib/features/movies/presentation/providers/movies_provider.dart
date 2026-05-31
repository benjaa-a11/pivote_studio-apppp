import 'package:flutter/material.dart';
import 'package:pivote/features/movies/data/models/movie.dart';
import 'package:pivote/features/movies/data/services/movie_service.dart';

class MoviesProvider extends ChangeNotifier {
  List<Movie> _allMovies = [];
  bool _isLoading = false;
  String _selectedGenre = 'Todos';
  String _searchQuery = '';

  List<Movie> get allMovies => _allMovies;
  bool get isLoading => _isLoading;
  String get selectedGenre => _selectedGenre;
  String get searchQuery => _searchQuery;

  /// Fetch movies from high-performance MovieService
  Future<void> loadMovies({bool force = false}) async {
    if (_allMovies.isNotEmpty && !force) return;

    _isLoading = true;
    notifyListeners();

    try {
      _allMovies = await MovieService.getMovies();
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
    return _allMovies.where((m) => m.isFeatured).toList();
  }

  /// Returns trending movies
  List<Movie> get trendingMovies {
    return _allMovies.where((m) => m.isTrending).toList();
  }

  /// Filtered movies based on genre and search query
  List<Movie> get movies {
    return _allMovies.where((movie) {
      final matchesGenre = _selectedGenre == 'Todos' ||
          movie.genres.any((g) => g.toLowerCase() == _selectedGenre.toLowerCase());
      
      final matchesSearch = _searchQuery.isEmpty ||
          movie.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          movie.genres.any((g) => g.toLowerCase().contains(_searchQuery.toLowerCase()));

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
