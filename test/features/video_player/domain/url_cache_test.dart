import 'package:flutter_test/flutter_test.dart';
import 'package:pivote/features/video_player/domain/domain.dart';

void main() {
  group('URLCache', () {
    late URLCache cache;

    setUp(() {
      cache = URLCache();
    });

    test('should store and retrieve URLs within TTL', () {
      // Arrange
      const key = 'https://example.com/stream.m3u8';
      final resolvedURL = ResolvedURL(
        finalURL: 'https://cdn.example.com/stream.m3u8',
        resolvedAt: DateTime.now(),
        resolutionTime: const Duration(milliseconds: 100),
        fromCache: false,
      );

      // Act
      cache.put(key, resolvedURL);
      final retrieved = cache.get(key);

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved?.finalURL, equals(resolvedURL.finalURL));
    });

    test('should return null for non-existent keys', () {
      // Act
      final retrieved = cache.get('non-existent-key');

      // Assert
      expect(retrieved, isNull);
    });

    test('should expire entries after TTL', () async {
      // Arrange
      final shortTTLCache = URLCache(ttl: const Duration(milliseconds: 100));
      const key = 'https://example.com/stream.m3u8';
      final resolvedURL = ResolvedURL(
        finalURL: 'https://cdn.example.com/stream.m3u8',
        resolvedAt: DateTime.now(),
        resolutionTime: const Duration(milliseconds: 50),
        fromCache: false,
      );

      // Act
      shortTTLCache.put(key, resolvedURL);
      
      // Wait for TTL to expire
      await Future.delayed(const Duration(milliseconds: 150));
      
      final retrieved = shortTTLCache.get(key);

      // Assert
      expect(retrieved, isNull);
    });

    test('should clear all entries', () {
      // Arrange
      cache.put('key1', ResolvedURL(
        finalURL: 'url1',
        resolvedAt: DateTime.now(),
        resolutionTime: const Duration(milliseconds: 100),
        fromCache: false,
      ));
      cache.put('key2', ResolvedURL(
        finalURL: 'url2',
        resolvedAt: DateTime.now(),
        resolutionTime: const Duration(milliseconds: 100),
        fromCache: false,
      ));

      // Act
      cache.clear();

      // Assert
      expect(cache.size, equals(0));
      expect(cache.get('key1'), isNull);
      expect(cache.get('key2'), isNull);
    });

    test('should clear only expired entries', () async {
      // Arrange
      final shortTTLCache = URLCache(ttl: const Duration(milliseconds: 100));
      
      shortTTLCache.put('expired-key', ResolvedURL(
        finalURL: 'expired-url',
        resolvedAt: DateTime.now(),
        resolutionTime: const Duration(milliseconds: 50),
        fromCache: false,
      ));

      // Wait for first entry to expire
      await Future.delayed(const Duration(milliseconds: 150));

      shortTTLCache.put('valid-key', ResolvedURL(
        finalURL: 'valid-url',
        resolvedAt: DateTime.now(),
        resolutionTime: const Duration(milliseconds: 50),
        fromCache: false,
      ));

      // Act
      shortTTLCache.clearExpired();

      // Assert
      expect(shortTTLCache.get('expired-key'), isNull);
      expect(shortTTLCache.get('valid-key'), isNotNull);
    });

    test('should report correct cache size', () {
      // Arrange & Act
      cache.put('key1', ResolvedURL(
        finalURL: 'url1',
        resolvedAt: DateTime.now(),
        resolutionTime: const Duration(milliseconds: 100),
        fromCache: false,
      ));
      cache.put('key2', ResolvedURL(
        finalURL: 'url2',
        resolvedAt: DateTime.now(),
        resolutionTime: const Duration(milliseconds: 100),
        fromCache: false,
      ));

      // Assert
      expect(cache.size, equals(2));
    });

    test('should report correct valid size excluding expired entries', () async {
      // Arrange
      final shortTTLCache = URLCache(ttl: const Duration(milliseconds: 100));
      
      shortTTLCache.put('expired-key', ResolvedURL(
        finalURL: 'expired-url',
        resolvedAt: DateTime.now(),
        resolutionTime: const Duration(milliseconds: 50),
        fromCache: false,
      ));

      // Wait for first entry to expire
      await Future.delayed(const Duration(milliseconds: 150));

      shortTTLCache.put('valid-key', ResolvedURL(
        finalURL: 'valid-url',
        resolvedAt: DateTime.now(),
        resolutionTime: const Duration(milliseconds: 50),
        fromCache: false,
      ));

      // Assert
      expect(shortTTLCache.size, equals(2)); // Total entries
      expect(shortTTLCache.validSize, equals(1)); // Only valid entries
    });

    test('should overwrite existing entries with same key', () {
      // Arrange
      const key = 'https://example.com/stream.m3u8';
      final firstURL = ResolvedURL(
        finalURL: 'https://cdn1.example.com/stream.m3u8',
        resolvedAt: DateTime.now(),
        resolutionTime: const Duration(milliseconds: 100),
        fromCache: false,
      );
      final secondURL = ResolvedURL(
        finalURL: 'https://cdn2.example.com/stream.m3u8',
        resolvedAt: DateTime.now(),
        resolutionTime: const Duration(milliseconds: 150),
        fromCache: false,
      );

      // Act
      cache.put(key, firstURL);
      cache.put(key, secondURL);
      final retrieved = cache.get(key);

      // Assert
      expect(cache.size, equals(1));
      expect(retrieved?.finalURL, equals(secondURL.finalURL));
    });

    test('should have default TTL of 5 minutes', () {
      // Assert
      expect(cache.ttl, equals(const Duration(minutes: 5)));
    });

    test('should allow custom TTL', () {
      // Arrange
      final customCache = URLCache(ttl: const Duration(minutes: 10));

      // Assert
      expect(customCache.ttl, equals(const Duration(minutes: 10)));
    });
  });

  group('CachedEntry', () {
    test('should correctly identify expired entries', () async {
      // Arrange
      final entry = CachedEntry(
        value: ResolvedURL(
          finalURL: 'https://example.com/stream.m3u8',
          resolvedAt: DateTime.now(),
          resolutionTime: const Duration(milliseconds: 100),
          fromCache: false,
        ),
        timestamp: DateTime.now(),
      );
      const ttl = Duration(milliseconds: 100);

      // Assert - Not expired initially
      expect(entry.isExpired(ttl), isFalse);

      // Wait for expiration
      await Future.delayed(const Duration(milliseconds: 150));

      // Assert - Expired after TTL
      expect(entry.isExpired(ttl), isTrue);
    });
  });
}
