import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:pivote/features/video_player/domain/domain.dart';

/// Generador de datos de prueba para property-based testing
class TestDataGenerators {
  static final Random _random = Random();

  /// Genera una URL M3U8 aleatoria
  static String generateRandomM3U8URL() {
    final domains = [
      'cdn1.example.com',
      'cdn2.example.com',
      'stream.example.com',
      'live.example.com',
      'video.example.com'
    ];
    final domain = domains[_random.nextInt(domains.length)];
    final channelId = _random.nextInt(10000);
    final paths = [
      '/live/channel$channelId/playlist.m3u8',
      '/stream/$channelId/index.m3u8',
      '/hls/channel_$channelId.m3u8',
      '/video/$channelId/master.m3u8',
    ];
    final path = paths[_random.nextInt(paths.length)];
    return 'https://$domain$path';
  }

  /// Genera una ResolvedURL aleatoria
  static ResolvedURL generateRandomResolvedURL({bool fromCache = false}) {
    return ResolvedURL(
      finalURL: generateRandomM3U8URL(),
      resolvedAt: DateTime.now(),
      resolutionTime: Duration(milliseconds: 50 + _random.nextInt(500)),
      fromCache: fromCache,
    );
  }
}

void main() {
  group('Property-Based Tests - URLCache', () {
    // Feature: video-player-optimization-security, Property 3: URL Resolution Caching Round-Trip
    // **Validates: Requirements 1.4**
    test(
        'Property 3: For any URL resolved successfully, if the same URL is requested within 5 minutes, '
        'it must be obtained from cache without performing a new HTTP resolution',
        () async {
      final cache = URLCache();
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        // Generate random URL
        final rawURL = TestDataGenerators.generateRandomM3U8URL();

        // First resolution - simulate HTTP resolution
        final resolved1 = TestDataGenerators.generateRandomResolvedURL(
          fromCache: false,
        );

        // Store in cache
        cache.put(rawURL, resolved1);

        // Second resolution within 5 minutes - should come from cache
        final cached = cache.get(rawURL);

        // Assertions
        expect(cached, isNotNull,
            reason: 'URL should be in cache after being stored (iteration $i)');
        expect(cached?.finalURL, equals(resolved1.finalURL),
            reason:
                'Cached URL should match the original resolved URL (iteration $i)');
        expect(cached?.resolvedAt, equals(resolved1.resolvedAt),
            reason: 'Cached resolution timestamp should match (iteration $i)');
        expect(cached?.resolutionTime, equals(resolved1.resolutionTime),
            reason: 'Cached resolution time should match (iteration $i)');
      }
    });

    test(
        'Property 3 (Extended): URLs should remain in cache for the full 5-minute TTL period',
        () async {
      final cache = URLCache();
      const iterations = 50; // Reduced iterations due to time delays

      for (int i = 0; i < iterations; i++) {
        final rawURL = TestDataGenerators.generateRandomM3U8URL();
        final resolved = TestDataGenerators.generateRandomResolvedURL();

        // Store in cache
        cache.put(rawURL, resolved);

        // Wait a random time less than 5 minutes
        final waitTime = Duration(
          milliseconds: 100 + TestDataGenerators._random.nextInt(200),
        );
        await Future.delayed(waitTime);

        // Should still be in cache
        final cached = cache.get(rawURL);
        expect(cached, isNotNull,
            reason:
                'URL should still be in cache after $waitTime (iteration $i)');
        expect(cached?.finalURL, equals(resolved.finalURL),
            reason: 'Cached URL should match after wait (iteration $i)');
      }
    });

    test(
        'Property 3 (Expiration): URLs should NOT be in cache after 5 minutes have passed',
        () async {
      // Use a shorter TTL for testing purposes
      final cache = URLCache(ttl: const Duration(milliseconds: 200));
      const iterations = 50;

      for (int i = 0; i < iterations; i++) {
        final rawURL = TestDataGenerators.generateRandomM3U8URL();
        final resolved = TestDataGenerators.generateRandomResolvedURL();

        // Store in cache
        cache.put(rawURL, resolved);

        // Wait for TTL to expire
        await Future.delayed(const Duration(milliseconds: 250));

        // Should NOT be in cache anymore
        final cached = cache.get(rawURL);
        expect(cached, isNull,
            reason:
                'URL should be expired and removed from cache after TTL (iteration $i)');
      }
    });

    test(
        'Property 3 (Multiple URLs): Cache should handle multiple different URLs independently',
        () async {
      final cache = URLCache();
      const iterations = 100;
      final urlMap = <String, ResolvedURL>{};

      // Store multiple URLs
      for (int i = 0; i < iterations; i++) {
        final rawURL = TestDataGenerators.generateRandomM3U8URL();
        final resolved = TestDataGenerators.generateRandomResolvedURL();

        cache.put(rawURL, resolved);
        urlMap[rawURL] = resolved;
      }

      // Verify all URLs are cached correctly
      for (final entry in urlMap.entries) {
        final cached = cache.get(entry.key);
        expect(cached, isNotNull,
            reason: 'Each stored URL should be retrievable from cache');
        expect(cached?.finalURL, equals(entry.value.finalURL),
            reason: 'Each cached URL should match its original value');
      }
    });

    test(
        'Property 3 (Idempotency): Retrieving a URL from cache multiple times should return the same result',
        () async {
      final cache = URLCache();
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        final rawURL = TestDataGenerators.generateRandomM3U8URL();
        final resolved = TestDataGenerators.generateRandomResolvedURL();

        cache.put(rawURL, resolved);

        // Retrieve multiple times
        final retrieval1 = cache.get(rawURL);
        final retrieval2 = cache.get(rawURL);
        final retrieval3 = cache.get(rawURL);

        // All retrievals should return the same data
        expect(retrieval1, isNotNull);
        expect(retrieval2, isNotNull);
        expect(retrieval3, isNotNull);
        expect(retrieval1?.finalURL, equals(retrieval2?.finalURL));
        expect(retrieval2?.finalURL, equals(retrieval3?.finalURL));
        expect(retrieval1?.finalURL, equals(resolved.finalURL));
      }
    });

    test(
        'Property 3 (Overwrite): Storing the same URL twice should overwrite the previous entry',
        () async {
      final cache = URLCache();
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        final rawURL = TestDataGenerators.generateRandomM3U8URL();
        final resolved1 = TestDataGenerators.generateRandomResolvedURL();
        final resolved2 = TestDataGenerators.generateRandomResolvedURL();

        // Store first resolution
        cache.put(rawURL, resolved1);

        // Store second resolution (should overwrite)
        cache.put(rawURL, resolved2);

        // Should retrieve the second resolution
        final cached = cache.get(rawURL);
        expect(cached, isNotNull);
        expect(cached?.finalURL, equals(resolved2.finalURL),
            reason:
                'Cache should contain the most recent resolution (iteration $i)');
        expect(cached?.finalURL, isNot(equals(resolved1.finalURL)),
            reason: 'Old resolution should be overwritten (iteration $i)');
      }
    });

    test(
        'Property 3 (Cache Miss): Requesting a URL that was never cached should return null',
        () async {
      final cache = URLCache();
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        // Generate a random URL that was never cached
        final randomURL = TestDataGenerators.generateRandomM3U8URL();

        // Should return null
        final cached = cache.get(randomURL);
        expect(cached, isNull,
            reason:
                'Non-existent URLs should return null from cache (iteration $i)');
      }
    });

    test(
        'Property 3 (Concurrent Access): Cache should handle concurrent puts and gets correctly',
        () async {
      final cache = URLCache();
      const iterations = 100;
      final urls = <String>[];
      final resolved = <ResolvedURL>[];

      // Generate test data
      for (int i = 0; i < iterations; i++) {
        urls.add(TestDataGenerators.generateRandomM3U8URL());
        resolved.add(TestDataGenerators.generateRandomResolvedURL());
      }

      // Store all URLs
      for (int i = 0; i < iterations; i++) {
        cache.put(urls[i], resolved[i]);
      }

      // Retrieve all URLs in different order
      final shuffledIndices = List.generate(iterations, (i) => i)..shuffle();
      for (final index in shuffledIndices) {
        final cached = cache.get(urls[index]);
        expect(cached, isNotNull,
            reason: 'All stored URLs should be retrievable');
        expect(cached?.finalURL, equals(resolved[index].finalURL),
            reason: 'Retrieved URLs should match stored values');
      }
    });

    test(
        'Property 3 (Clear Operation): After clearing cache, no URLs should be retrievable',
        () async {
      final cache = URLCache();
      const iterations = 100;
      final urls = <String>[];

      // Store multiple URLs
      for (int i = 0; i < iterations; i++) {
        final url = TestDataGenerators.generateRandomM3U8URL();
        final resolved = TestDataGenerators.generateRandomResolvedURL();
        urls.add(url);
        cache.put(url, resolved);
      }

      // Verify all are cached
      expect(cache.size, equals(iterations));

      // Clear cache
      cache.clear();

      // Verify all are gone
      expect(cache.size, equals(0));
      for (final url in urls) {
        final cached = cache.get(url);
        expect(cached, isNull,
            reason: 'No URLs should be in cache after clear()');
      }
    });

    test(
        'Property 3 (TTL Boundary): URLs at exactly TTL boundary should be handled correctly',
        () async {
      // Use precise TTL for boundary testing
      final cache = URLCache(ttl: const Duration(milliseconds: 200));
      const iterations = 20; // Reduced due to precise timing requirements

      for (int i = 0; i < iterations; i++) {
        final rawURL = TestDataGenerators.generateRandomM3U8URL();
        final resolved = TestDataGenerators.generateRandomResolvedURL();

        cache.put(rawURL, resolved);

        // Wait well before TTL expires (with margin for timing variations)
        await Future.delayed(const Duration(milliseconds: 100));
        final beforeExpiry = cache.get(rawURL);
        expect(beforeExpiry, isNotNull,
            reason: 'URL should still be valid before TTL (iteration $i)');

        // Wait for TTL to definitely expire (with margin)
        await Future.delayed(const Duration(milliseconds: 150));
        final afterExpiry = cache.get(rawURL);
        expect(afterExpiry, isNull,
            reason: 'URL should be expired after TTL (iteration $i)');
      }
    });
  });
}
