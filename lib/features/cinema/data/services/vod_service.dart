import 'dart:async';
import '../models/vod_content.dart';

/// Servicio para gestionar el contenido VOD (Cine, Series, Programas)
/// En una implementación real, esto conectaría con Firestore
class VodService {
  // Simulación de delay para efectos de carga (Skeleton loading)
  static const Duration _delay = Duration(milliseconds: 800);

  /// Obtiene el contenido destacado para el carrusel Hero
  Future<List<VodContent>> getFeaturedContent() async {
    await Future.delayed(_delay);
    return _mockAllContent.where((c) => c.isFeatured).toList();
  }

  /// Obtiene contenido por categoría (películas, series, programas)
  Future<List<VodContent>> getContentByType(ContentType type) async {
    await Future.delayed(_delay);
    return _mockAllContent.where((c) => c.type == type).toList();
  }

  /// Búsqueda de contenido
  Future<List<VodContent>> searchContent(String query) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (query.isEmpty) return [];

    final lowercaseQuery = query.toLowerCase();
    return _mockAllContent.where((c) {
      final titleMatch = c.title.toLowerCase().contains(lowercaseQuery);
      final descMatch =
          (c.description ?? '').toLowerCase().contains(lowercaseQuery);
      return titleMatch || descMatch;
    }).toList();
  }

  // ═══════════════════════════════════════
  // MOCK DATA (Para desarrollo de UI)
  // ═══════════════════════════════════════

  final List<VodContent> _mockAllContent = [
    // PELÍCULAS
    Movie(
      id: 'm1',
      title: 'Deadpool & Wolverine',
      description:
          'Un apático Wade Wilson se afana en la vida civil. Sus días como el mercenario moralmente flexible, Deadpool, han quedado atrás. Cuando su mundo natal se enfrenta a una amenaza existencial, Wade debe volver a ponerse el traje.',
      posterUrl:
          'https://image.tmdb.org/t/p/w500/8cdWjvZQUmMWWmNYpSjUzmwDH4A.jpg',
      backdropUrl:
          'https://image.tmdb.org/t/p/original/yDHYT7VpUnnOVdn5Z2n6H1P9o5u.jpg',
      year: 2024,
      rating: 7.8,
      isFeatured: true,
      genres: ['Acción', 'Comedia', 'Ciencia Ficción'],
      servers: [
        VideoServer(
            id: 's1',
            name: 'Server 1 (HLS)',
            embedUrl: 'https://sendvid.com/embed/dzqruilf'),
        VideoServer(
            id: 's2',
            name: 'Server 2 (Backup)',
            embedUrl: 'https://streamtape.com/e/x1'),
      ],
    ),
    Movie(
      id: 'm2',
      title: 'Intensa-Mente 2',
      description:
          'Riley, ahora una adolescente, se encuentra con nuevas emociones que llegan a la sede central para cambiarlo todo.',
      posterUrl:
          'https://image.tmdb.org/t/p/w500/vpnVM9B6NMmQpWeZvzLv1oYI9fs.jpg',
      backdropUrl:
          'https://image.tmdb.org/t/p/original/stKGOmbuSnC69S0YvC96X9Z69U0.jpg',
      year: 2024,
      rating: 7.6,
      isFeatured: true,
      genres: ['Animación', 'Familia', 'Aventura'],
      servers: [
        VideoServer(
            id: 's3', name: 'Principal', embedUrl: 'https://dood.to/e/d1'),
      ],
    ),
    Movie(
      id: 'm3',
      title: 'El Planeta de los Simios: Nuevo Reino',
      description:
          'Muchos años después del reinado de César, un joven simio emprende un viaje que lo llevará a cuestionar todo lo que le han enseñado sobre el pasado.',
      posterUrl:
          'https://image.tmdb.org/t/p/w500/gKkl37BQuKT6S6fKW9LXdnv5Mxp.jpg',
      backdropUrl:
          'https://image.tmdb.org/t/p/original/fqv8vS49EYH66yhygSVcc6X7vBM.jpg',
      rating: 7.1,
      genres: ['Acción', 'Aventura', 'Ciencia Ficción'],
      servers: [
        VideoServer(
            id: 's4', name: 'Server 1', embedUrl: 'https://mixdrop.co/e/m1'),
      ],
    ),

    // SERIES
    Series(
      id: 's1',
      title: 'The Boys',
      description:
          'En un mundo donde los superhéroes abrazan el lado oscuro de su masiva celebridad y fama, un grupo de vigilantes conocidos informalmente como "The Boys" se propone derribar a los superhéroes corruptos.',
      posterUrl:
          'https://image.tmdb.org/t/p/w500/79969Wp5pY698GveV7952vM9G.jpg',
      backdropUrl:
          'https://image.tmdb.org/t/p/original/n6bUgiCUvNC70o46fsy6R6vUunw.jpg',
      rating: 8.5,
      isFeatured: true,
      genres: ['Sci-Fi & Fantasy', 'Action & Adventure'],
      seasons: [
        Season(
          id: 's1_se1',
          seasonNumber: 1,
          title: 'Season 1',
          episodes: [
            Episode(
              id: 's1_se1_e1',
              title: 'La regla del juego',
              episodeNumber: 1,
              seasonNumber: 1,
              servers: [
                VideoServer(
                    id: 's5',
                    name: 'Main',
                    embedUrl: 'https://sendvid.com/embed/dzqruilf'),
              ],
            ),
          ],
        ),
      ],
    ),
    Series(
      id: 's2',
      title: 'House of the Dragon',
      description:
          'La historia de la familia Targaryen, 200 años antes de los eventos que tuvieron lugar en Game of Thrones.',
      posterUrl:
          'https://image.tmdb.org/t/p/w500/t9XkeE79v6SgyeXvY7vY8uS5XU.jpg',
      backdropUrl:
          'https://image.tmdb.org/t/p/original/2meXBs9YnSOU3UT78BT75p9Wp6P.jpg',
      rating: 8.4,
      isFeatured: false,
      genres: ['Sci-Fi & Fantasy', 'Drama', 'Action & Adventure'],
      seasons: [],
    ),

    // PROGRAMAS
    Program(
      id: 'p1',
      title: 'La Velada del Año IV',
      description:
          'El evento de boxeo entre streamers y creadores de contenido más grande del mundo, organizado por Ibai Llanos.',
      posterUrl: 'https://pbs.twimg.com/media/GOvYn4vXwAAyEXY.jpg',
      backdropUrl: 'https://pbs.twimg.com/media/GOvYn4vXwAAyEXY.jpg',
      rating: 9.0,
      genres: ['Deporte', 'Entretenimiento'],
      servers: [
        VideoServer(
            id: 's6', name: 'Replay TV', embedUrl: 'https://sendvid.com/embed/dzqruilf'),
      ],
    ),
  ];
}
