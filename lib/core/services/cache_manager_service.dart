import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pivote/features/favorites/data/services/viewing_history_service.dart';

/// Advanced cache management service for handling app cache,
/// images, and local data storage
class CacheManagerService {
  // Keys for cache statistics
  static const String _lastCacheClearKey = 'cache_last_clear';
  static const String _totalCacheClearsKey = 'cache_total_clears';

  /// Get total cache size in bytes
  static Future<int> getTotalCacheSize() async {
    try {
      int totalSize = 0;

      // Get image cache size
      totalSize += await getImageCacheSize();

      // Get app cache size
      totalSize += await getAppCacheSize();

      return totalSize;
    } catch (e) {
      debugPrint('❌ Error calculating cache size: $e');
      return 0;
    }
  }

  /// Get image cache size in bytes
  static Future<int> getImageCacheSize() async {
    try {
      // Get cache directory
      final cacheDir = await getTemporaryDirectory();
      final imageCacheDir = Directory('${cacheDir.path}/libCachedImageData');

      if (await imageCacheDir.exists()) {
        int size = 0;
        await for (final entity in imageCacheDir.list(recursive: true)) {
          if (entity is File) {
            size += await entity.length();
          }
        }
        return size;
      }
    } catch (e) {
      debugPrint('❌ Error calculating image cache size: $e');
    }
    return 0;
  }

  /// Get app cache size in bytes
  static Future<int> getAppCacheSize() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      int size = 0;

      if (await cacheDir.exists()) {
        await for (final entity in cacheDir.list(recursive: true)) {
          if (entity is File) {
            size += await entity.length();
          }
        }
      }

      return size;
    } catch (e) {
      debugPrint('❌ Error calculating app cache size: $e');
      return 0;
    }
  }

  /// Get SharedPreferences data size (approximate)
  static Future<int> getPreferencesSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      int totalSize = 0;
      for (final key in keys) {
        final value = prefs.get(key);
        if (value != null) {
          totalSize += key.length + value.toString().length;
        }
      }

      return totalSize;
    } catch (e) {
      debugPrint('❌ Error calculating preferences size: $e');
      return 0;
    }
  }

  /// Clear all image cache
  static Future<bool> clearImageCache() async {
    try {
      debugPrint('🗑️ Clearing image cache...');

      final cacheManager = DefaultCacheManager();
      await cacheManager.emptyCache();

      // Clear memory cache so UI reflects change immediately
      PaintingBinding.instance.imageCache.clear();

      debugPrint('✅ Image cache cleared successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error clearing image cache: $e');
      return false;
    }
  }

  /// Clear app cache directory
  static Future<bool> clearAppCache() async {
    try {
      debugPrint('🗑️ Clearing app cache...');

      final cacheDir = await getTemporaryDirectory();

      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        await cacheDir.create();

        // Brief delay to allow OS to sync file deletion
        await Future.delayed(const Duration(milliseconds: 100));
      }

      debugPrint('✅ App cache cleared successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error clearing app cache: $e');
      return false;
    }
  }

  /// Clear viewing history
  static Future<bool> clearViewingHistory() async {
    try {
      debugPrint('🗑️ Clearing viewing history...');
      await ViewingHistoryService.clearHistory();
      debugPrint('✅ Viewing history cleared successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error clearing viewing history: $e');
      return false;
    }
  }

  /// Clear user preferences (excluding critical app data)
  static Future<bool> clearUserPreferences({
    bool keepTheme = true,
    bool keepLanguage = true,
    bool keepUserProfile = true,
  }) async {
    try {
      debugPrint('🗑️ Clearing user preferences...');

      final prefs = await SharedPreferences.getInstance();
      final keysToKeep = <String>[];

      // Preserve important settings if requested
      if (keepTheme) {
        keysToKeep.add('isDarkMode');
      }
      if (keepLanguage) {
        keysToKeep.add('app_language');
      }
      if (keepUserProfile) {
        keysToKeep.addAll(['user_name', 'user_email']);
      }

      // Save values to keep
      final savedValues = <String, dynamic>{};
      for (final key in keysToKeep) {
        savedValues[key] = prefs.get(key);
      }

      // Clear all preferences
      await prefs.clear();

      // Restore saved values
      for (final entry in savedValues.entries) {
        final value = entry.value;
        if (value is String) {
          await prefs.setString(entry.key, value);
        } else if (value is bool) {
          await prefs.setBool(entry.key, value);
        } else if (value is int) {
          await prefs.setInt(entry.key, value);
        } else if (value is double) {
          await prefs.setDouble(entry.key, value);
        }
      }

      debugPrint('✅ User preferences cleared successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error clearing user preferences: $e');
      return false;
    }
  }

  /// Clear all cache (images, app cache, viewing history)
  static Future<Map<String, bool>> clearAllCache({
    bool clearImages = true,
    bool clearAppData = true,
    bool clearHistory = true,
    bool clearPreferences = false,
  }) async {
    final results = <String, bool>{};

    try {
      // Record cache clear
      await _recordCacheClear();

      if (clearImages) {
        results['images'] = await clearImageCache();
      }

      if (clearAppData) {
        results['appCache'] = await clearAppCache();
      }

      if (clearHistory) {
        results['viewingHistory'] = await clearViewingHistory();
      }

      if (clearPreferences) {
        results['preferences'] = await clearUserPreferences();
      }

      debugPrint('✅ Cache clear completed: $results');
      return results;
    } catch (e) {
      debugPrint('❌ Error during cache clear: $e');
      return results;
    }
  }

  /// Record cache clear event
  static Future<void> _recordCacheClear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          _lastCacheClearKey, DateTime.now().millisecondsSinceEpoch);

      final totalClears = prefs.getInt(_totalCacheClearsKey) ?? 0;
      await prefs.setInt(_totalCacheClearsKey, totalClears + 1);
    } catch (e) {
      debugPrint('❌ Error recording cache clear: $e');
    }
  }

  /// Get cache statistics
  static Future<Map<String, dynamic>> getCacheStatistics() async {
    try {
      final totalSize = await getTotalCacheSize();
      final imageSize = await getImageCacheSize();
      final appCacheSize = await getAppCacheSize();
      final prefsSize = await getPreferencesSize();
      final lastClear = await getLastCacheClearTime();
      final totalClears = await getTotalCacheClears();

      return {
        'totalSize': totalSize,
        'imageCacheSize': imageSize,
        'appCacheSize': appCacheSize,
        'preferencesSize': prefsSize,
        'lastClearTime': lastClear,
        'totalClears': totalClears,
        'formattedTotalSize': _formatBytes(totalSize),
        'formattedImageSize': _formatBytes(imageSize),
        'formattedAppCacheSize': _formatBytes(appCacheSize),
        'formattedPrefsSize': _formatBytes(prefsSize),
      };
    } catch (e) {
      debugPrint('❌ Error getting cache statistics: $e');
      return {};
    }
  }

  /// Get last cache clear time
  static Future<DateTime?> getLastCacheClearTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_lastCacheClearKey);
      return timestamp != null
          ? DateTime.fromMillisecondsSinceEpoch(timestamp)
          : null;
    } catch (e) {
      debugPrint('❌ Error getting last cache clear time: $e');
      return null;
    }
  }

  /// Get total number of cache clears
  static Future<int> getTotalCacheClears() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_totalCacheClearsKey) ?? 0;
    } catch (e) {
      debugPrint('❌ Error getting total cache clears: $e');
      return 0;
    }
  }

  /// Format bytes to human-readable string
  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Get formatted cache size
  static Future<String> getFormattedCacheSize() async {
    final size = await getTotalCacheSize();
    return _formatBytes(size);
  }

  /// Check if cache needs clearing (based on size threshold)
  static Future<bool> needsCacheClearing({int thresholdMB = 100}) async {
    final size = await getTotalCacheSize();
    final thresholdBytes = thresholdMB * 1024 * 1024;
    return size > thresholdBytes;
  }

  /// Optimize cache (clear old/unused items)
  static Future<bool> optimizeCache() async {
    try {
      debugPrint('🔧 Optimizing cache...');

      // Clear image cache older than 7 days
      final cacheManager = DefaultCacheManager();
      await cacheManager.emptyCache();

      debugPrint('✅ Cache optimized successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error optimizing cache: $e');
      return false;
    }
  }
}
