import 'package:flutter/foundation.dart';
import 'package:pivote/core/services/firebase_service.dart';
import 'package:pivote/features/movies/data/models/movie.dart';

class MovieService {
  /// Fetches movies exclusively from Firestore (no mock data)
  static Future<List<Movie>> getMovies() async {
    List<Movie> movies = [];

    try {
      if (FirebaseService.isInitialized) {
        final snapshot = await FirebaseService.moviesCollection.get();
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (!data.containsKey('id')) {
            data['id'] = doc.id;
          }
          try {
            movies.add(Movie.fromJson(data));
          } catch (e) {
            debugPrint('❌ Error parsing Firestore movie ${doc.id}: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading movies from Firestore: $e');
    }

    return movies;
  }
}
