import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pivote/core/services/firebase_service.dart';
import 'package:pivote/features/auth/data/services/auth_service.dart';

/// Advanced viewing history service for tracking channel views
/// and persisting user viewing history in Firestore (`users/{uid}/datos/preferencias`).
class ViewingHistoryService {
  // Keys for SharedPreferences
  static const String _viewCountsKey = 'channel_view_counts';
  static const String _lastViewedKey = 'channel_last_viewed';
  static const String _firstViewedKey = 'channel_first_viewed';
  static const String _totalWatchTimeKey = 'channel_total_watch_time';
  static const String _lastClearKey = 'viewing_history_last_clear';

  /// Track a channel view
  /// Increments view count and updates timestamps (local + nube)
  static Future<void> trackChannelView(String channelId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;

      // Get current view counts
      final viewCounts = await getAllViewCounts();
      viewCounts[channelId] = (viewCounts[channelId] ?? 0) + 1;

      // Get last viewed timestamps
      final lastViewed = await _getLastViewed();
      lastViewed[channelId] = now;

      // Get first viewed timestamps (if not exists)
      final firstViewed = await _getFirstViewed();
      if (!firstViewed.containsKey(channelId)) {
        firstViewed[channelId] = now;
      }

      // Save all data locally
      await prefs.setString(_viewCountsKey, json.encode(viewCounts));
      await prefs.setString(_lastViewedKey, json.encode(lastViewed));
      await prefs.setString(_firstViewedKey, json.encode(firstViewed));

      // Sincronizar con la nube en background
      unawaited(syncToCloud(
        viewCounts: viewCounts,
        lastViewed: lastViewed,
        firstViewed: firstViewed,
      ));

      debugPrint(
          '📊 View tracked: $channelId (Total: ${viewCounts[channelId]})');
    } catch (e) {
      debugPrint('❌ Error tracking view: $e');
    }
  }

  /// Sube el historial actual a `users/{uid}/datos/preferencias`.
  static Future<void> syncToCloud({
    Map<String, int>? viewCounts,
    Map<String, int>? lastViewed,
    Map<String, int>? firstViewed,
  }) async {
    final uid = AuthService.currentUserId;
    if (uid == null || !FirebaseService.isInitialized) return;
    try {
      final counts = viewCounts ?? await getAllViewCounts();
      final last = lastViewed ?? await _getLastViewed();
      final first = firstViewed ?? await _getFirstViewed();
      await FirebaseService.userPrefsDoc(uid).set({
        'viewingHistory': {
          'viewCounts': counts,
          'lastViewed': last,
          'firstViewed': first,
        },
        'actualizadoEn': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('⚠️ ViewingHistoryService: Error sincronizando a la nube: $e');
    }
  }

  /// Restaura y fusiona el historial desde `users/{uid}/datos/preferencias`.
  static Future<void> syncFromCloud() async {
    final uid = AuthService.currentUserId;
    if (uid == null || !FirebaseService.isInitialized) return;
    try {
      final doc = await FirebaseService.userPrefsDoc(uid).get();
      if (!doc.exists || doc.data() == null) return;
      final rawHistory = doc.data()!['viewingHistory'];
      if (rawHistory is! Map) return;

      final prefs = await SharedPreferences.getInstance();
      final localCounts = await getAllViewCounts();
      final localLast = await _getLastViewed();
      final localFirst = await _getFirstViewed();

      final remoteCountsRaw = rawHistory['viewCounts'];
      final remoteLastRaw = rawHistory['lastViewed'];
      final remoteFirstRaw = rawHistory['firstViewed'];

      if (remoteCountsRaw is Map) {
        remoteCountsRaw.forEach((k, v) {
          final key = k.toString();
          final val = (v as num?)?.toInt() ?? 0;
          if (val > (localCounts[key] ?? 0)) localCounts[key] = val;
        });
      }
      if (remoteLastRaw is Map) {
        remoteLastRaw.forEach((k, v) {
          final key = k.toString();
          final val = (v as num?)?.toInt() ?? 0;
          if (val > (localLast[key] ?? 0)) localLast[key] = val;
        });
      }
      if (remoteFirstRaw is Map) {
        remoteFirstRaw.forEach((k, v) {
          final key = k.toString();
          final val = (v as num?)?.toInt() ?? 0;
          if (val > 0 &&
              (!localFirst.containsKey(key) || val < localFirst[key]!)) {
            localFirst[key] = val;
          }
        });
      }

      await prefs.setString(_viewCountsKey, json.encode(localCounts));
      await prefs.setString(_lastViewedKey, json.encode(localLast));
      await prefs.setString(_firstViewedKey, json.encode(localFirst));
      debugPrint(
          '✅ ViewingHistoryService: Historial restaurado (${localCounts.length} canales)');
    } catch (e) {
      debugPrint('⚠️ ViewingHistoryService: Error restaurando desde la nube: $e');
    }
  }

  /// Limpia solo el caché local al cerrar sesión (NO borra el historial en la nube).
  static Future<void> clearLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_viewCountsKey);
      await prefs.remove(_lastViewedKey);
      await prefs.remove(_firstViewedKey);
      await prefs.remove(_totalWatchTimeKey);
    } catch (e) {
      debugPrint('⚠️ ViewingHistoryService: Error limpiando caché local: $e');
    }
  }

  /// Get all view counts
  static Future<Map<String, int>> getAllViewCounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final viewCountsJson = prefs.getString(_viewCountsKey);

      if (viewCountsJson != null) {
        final decoded = json.decode(viewCountsJson) as Map<String, dynamic>;
        return decoded.map((key, value) => MapEntry(key, value as int));
      }
    } catch (e) {
      debugPrint('❌ Error loading view counts: $e');
    }
    return {};
  }

  /// Get view count for a specific channel
  static Future<int> getViewCount(String channelId) async {
    final viewCounts = await getAllViewCounts();
    return viewCounts[channelId] ?? 0;
  }

  /// Get last viewed timestamps for all channels
  static Future<Map<String, int>> _getLastViewed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastViewedJson = prefs.getString(_lastViewedKey);

      if (lastViewedJson != null) {
        final decoded = json.decode(lastViewedJson) as Map<String, dynamic>;
        return decoded.map((key, value) => MapEntry(key, value as int));
      }
    } catch (e) {
      debugPrint('❌ Error loading last viewed: $e');
    }
    return {};
  }

  /// Get first viewed timestamps for all channels
  static Future<Map<String, int>> _getFirstViewed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final firstViewedJson = prefs.getString(_firstViewedKey);

      if (firstViewedJson != null) {
        final decoded = json.decode(firstViewedJson) as Map<String, dynamic>;
        return decoded.map((key, value) => MapEntry(key, value as int));
      }
    } catch (e) {
      debugPrint('❌ Error loading first viewed: $e');
    }
    return {};
  }

  /// Get last viewed timestamp for a specific channel
  static Future<DateTime?> getLastViewedTime(String channelId) async {
    final lastViewed = await _getLastViewed();
    final timestamp = lastViewed[channelId];
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  /// Get viewing statistics for a channel
  static Future<Map<String, dynamic>> getChannelStats(String channelId) async {
    final viewCount = await getViewCount(channelId);
    final lastViewed = await _getLastViewed();
    final firstViewed = await _getFirstViewed();

    return {
      'viewCount': viewCount,
      'lastViewed': lastViewed[channelId],
      'firstViewed': firstViewed[channelId],
      'hasViewed': viewCount > 0,
    };
  }

  /// Get top N most viewed channels (effectively unlimited by default)
  static Future<List<String>> getTopChannels({int limit = 1000}) async {
    final viewCounts = await getAllViewCounts();
    final lastViewed = await _getLastViewed();

    // Sort by view count (descending), then by last viewed (descending)
    final sortedEntries = viewCounts.entries.toList()
      ..sort((a, b) {
        // Primary sort: view count
        final countCompare = b.value.compareTo(a.value);
        if (countCompare != 0) return countCompare;

        // Secondary sort: last viewed timestamp
        final aLastViewed = lastViewed[a.key] ?? 0;
        final bLastViewed = lastViewed[b.key] ?? 0;
        return bLastViewed.compareTo(aLastViewed);
      });

    // If limit is very high, just return all
    if (limit >= sortedEntries.length) {
      return sortedEntries.map((e) => e.key).toList();
    }

    return sortedEntries.take(limit).map((e) => e.key).toList();
  }

  /// Get total number of channels viewed
  static Future<int> getTotalChannelsViewed() async {
    final viewCounts = await getAllViewCounts();
    return viewCounts.length;
  }

  /// Get history count (alias for getTotalChannelsViewed)
  static Future<int> getHistoryCount() async {
    return await getTotalChannelsViewed();
  }

  /// Get total view count across all channels
  static Future<int> getTotalViews() async {
    final viewCounts = await getAllViewCounts();
    return viewCounts.values.fold<int>(0, (int sum, int count) => sum + count);
  }

  /// Clear all viewing history (local y nube, cuando el usuario lo pide)
  static Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_viewCountsKey);
      await prefs.remove(_lastViewedKey);
      await prefs.remove(_firstViewedKey);
      await prefs.remove(_totalWatchTimeKey);
      await prefs.setInt(_lastClearKey, DateTime.now().millisecondsSinceEpoch);

      await syncToCloud(
        viewCounts: {},
        lastViewed: {},
        firstViewed: {},
      );

      debugPrint('🗑️ Viewing history cleared');
    } catch (e) {
      debugPrint('❌ Error clearing history: $e');
    }
  }

  /// Get viewing history summary
  static Future<Map<String, dynamic>> getHistorySummary() async {
    final totalChannels = await getTotalChannelsViewed();
    final totalViews = await getTotalViews();
    final topChannels = await getTopChannels(limit: 5);

    return {
      'totalChannelsViewed': totalChannels,
      'totalViews': totalViews,
      'topChannels': topChannels,
      'hasHistory': totalChannels > 0,
    };
  }

  /// Export viewing history as JSON
  static Future<String> exportHistory() async {
    final viewCounts = await getAllViewCounts();
    final lastViewed = await _getLastViewed();
    final firstViewed = await _getFirstViewed();

    final export = {
      'exportDate': DateTime.now().toIso8601String(),
      'viewCounts': viewCounts,
      'lastViewed': lastViewed,
      'firstViewed': firstViewed,
    };

    return json.encode(export);
  }

  /// Import viewing history from JSON
  static Future<bool> importHistory(String jsonData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = json.decode(jsonData) as Map<String, dynamic>;

      if (data.containsKey('viewCounts')) {
        await prefs.setString(_viewCountsKey, json.encode(data['viewCounts']));
      }
      if (data.containsKey('lastViewed')) {
        await prefs.setString(_lastViewedKey, json.encode(data['lastViewed']));
      }
      if (data.containsKey('firstViewed')) {
        await prefs.setString(
            _firstViewedKey, json.encode(data['firstViewed']));
      }

      debugPrint('✅ Viewing history imported successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error importing history: $e');
      return false;
    }
  }

  /// Get last time history was cleared
  static Future<DateTime?> getLastClearTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_lastClearKey);
      return timestamp != null
          ? DateTime.fromMillisecondsSinceEpoch(timestamp)
          : null;
    } catch (e) {
      debugPrint('❌ Error getting last clear time: $e');
      return null;
    }
  }

  /// Check if a channel has been viewed recently (within last 24 hours)
  static Future<bool> isRecentlyViewed(String channelId) async {
    final lastViewed = await getLastViewedTime(channelId);
    if (lastViewed == null) return false;

    final now = DateTime.now();
    final difference = now.difference(lastViewed);
    return difference.inHours < 24;
  }

  /// Get channels viewed in the last N days
  static Future<List<String>> getRecentChannels({int days = 7}) async {
    final lastViewed = await _getLastViewed();
    final cutoffTime =
        DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch;

    return lastViewed.entries
        .where((entry) => entry.value >= cutoffTime)
        .map((entry) => entry.key)
        .toList();
  }
}
