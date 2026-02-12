import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:pivote/features/video/data/models/channel.dart';
import 'package:pivote/features/auth/data/services/auth_service.dart';

/// Rebuilt favorites provider with proper validation and sync
class FavoritesProvider extends ChangeNotifier {
  Set<String> _favoriteIds = {};
  Map<String, int> _favoriteAddedDates = {};
  bool _isSyncing = false;

  static const String _favoritesKey = 'favorite_channel_ids_v2';
  static const String _favoriteDatesKey = 'favorite_added_dates_v2';

  FavoritesProvider() {
    _loadFavorites();
    _initAuthListener();
  }

  void _initAuthListener() {
    AuthService.authStateChanges.listen((user) {
      if (user != null) {
        // User logged in, sync from firestore
        _syncFromFirestore();
      } else {
        // User logged out
        // Optional: clear favorites or keep local?
        // Let's keep local for guest experience but stop syncing
      }
    });
  }

  List<String> get favoriteIds => _favoriteIds.toList();
  bool get isSyncing => _isSyncing;

  bool isFavorite(String channelId) {
    return _favoriteIds.contains(channelId);
  }

  /// Toggle favorite with immediate sync
  Future<void> toggleFavorite(Channel channel) async {
    final channelId = channel.id;

    if (_favoriteIds.contains(channelId)) {
      // Remove from favorites
      _favoriteIds.remove(channelId);
      _favoriteAddedDates.remove(channelId);
    } else {
      // Add to favorites
      _favoriteIds.add(channelId);
      _favoriteAddedDates[channelId] = DateTime.now().millisecondsSinceEpoch;
    }

    notifyListeners();

    // Save locally and sync to Firestore
    await _saveFavorites();
    await _syncToFirestore();
  }

  /// Get sorted favorites
  List<Channel> getSortedFavorites(List<Channel> allChannels) {
    final favorites =
        allChannels.where((c) => _favoriteIds.contains(c.id)).toList();

    // Sort by date added (newest first)
    favorites.sort((a, b) {
      final aDate = _favoriteAddedDates[a.id] ?? 0;
      final bDate = _favoriteAddedDates[b.id] ?? 0;
      return bDate.compareTo(aDate);
    });

    return favorites;
  }

  /// Load favorites from local storage
  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load favorite IDs
      final ids = prefs.getStringList(_favoritesKey) ?? [];
      _favoriteIds = Set<String>.from(ids);

      // Load dates
      final datesJson = prefs.getString(_favoriteDatesKey);
      if (datesJson != null) {
        final decoded = json.decode(datesJson) as Map<String, dynamic>;
        _favoriteAddedDates =
            decoded.map((key, value) => MapEntry(key, value as int));
      }

      notifyListeners();

      // Sync with Firestore in background
      _syncFromFirestore();
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }
  }

  /// Save favorites to local storage
  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_favoritesKey, _favoriteIds.toList());
      await prefs.setString(
          _favoriteDatesKey, json.encode(_favoriteAddedDates));
    } catch (e) {
      debugPrint('Error saving favorites: $e');
    }
  }

  /// Sync favorites to Firestore
  Future<void> _syncToFirestore() async {
    final uid = AuthService.currentUserId;
    if (uid == null) return;

    try {
      _isSyncing = true;
      notifyListeners();

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'favorites': _favoriteIds.toList(),
      }, SetOptions(merge: true));

      debugPrint(
          '✅ Favorites synced to Firestore: ${_favoriteIds.length} items');
    } catch (e) {
      debugPrint('❌ Error syncing favorites to Firestore: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Sync favorites from Firestore (overwrite local)
  Future<void> _syncFromFirestore() async {
    final uid = AuthService.currentUserId;
    if (uid == null) return;

    try {
      _isSyncing = true;
      notifyListeners();

      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null && data.containsKey('favorites')) {
          final List<dynamic> remoteFavorites = data['favorites'] ?? [];
          final List<String> remoteIds = remoteFavorites.cast<String>();

          // Only update if remote has data and is different
          if (remoteIds.isNotEmpty) {
            final remoteSet = Set<String>.from(remoteIds);

            // Only update if different from local
            if (remoteSet.difference(_favoriteIds).isNotEmpty ||
                _favoriteIds.difference(remoteSet).isNotEmpty) {
              // Update local with remote data
              _favoriteIds = remoteSet;

              // Update dates for new favorites
              for (final id in remoteIds) {
                if (!_favoriteAddedDates.containsKey(id)) {
                  _favoriteAddedDates[id] =
                      DateTime.now().millisecondsSinceEpoch;
                }
              }

              // Remove dates for removed favorites
              _favoriteAddedDates
                  .removeWhere((key, value) => !_favoriteIds.contains(key));

              await _saveFavorites();
              notifyListeners();

              debugPrint(
                  '✅ Favorites synced from Firestore: ${_favoriteIds.length} items');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error syncing favorites from Firestore: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Clear all favorites
  Future<void> clearAllFavorites() async {
    _favoriteIds.clear();
    _favoriteAddedDates.clear();
    notifyListeners();

    await _saveFavorites();
    await _syncToFirestore();
  }

  /// Force refresh from Firestore
  Future<void> refreshFromFirestore() async {
    await _syncFromFirestore();
  }
}
