import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pivote/core/services/firebase_service.dart';
import 'package:pivote/features/auth/data/services/auth_service.dart';
import 'package:pivote/features/video/data/models/channel.dart';

/// Proveedor de canales favoritos sincronizados con `users/{uid}/datos/preferencias`.
/// Los favoritos sobreviven a cierres de sesión y desinstalaciones.
class FavoritesProvider extends ChangeNotifier {
  Set<String> _favoriteIds = {};
  Map<String, int> _favoriteAddedDates = {};
  bool _isSyncing = false;

  static const String _favoritesKey = 'favorite_channel_ids_v2';
  static const String _favoriteDatesKey = 'favorite_added_dates_v2';

  FavoritesProvider() {
    _loadLocalFavorites();
  }

  List<String> get favoriteIds => _favoriteIds.toList();
  bool get isSyncing => _isSyncing;

  bool isFavorite(String channelId) => _favoriteIds.contains(channelId);

  Future<void> toggleFavorite(Channel channel) async {
    final channelId = channel.id;

    if (_favoriteIds.contains(channelId)) {
      _favoriteIds.remove(channelId);
      _favoriteAddedDates.remove(channelId);
    } else {
      _favoriteIds.add(channelId);
      _favoriteAddedDates[channelId] = DateTime.now().millisecondsSinceEpoch;
    }

    notifyListeners();
    await _saveFavorites();
    await _syncToFirestore();
  }

  List<Channel> getSortedFavorites(List<Channel> allChannels) {
    final favorites =
        allChannels.where((c) => _favoriteIds.contains(c.id)).toList();

    favorites.sort((a, b) {
      final aDate = _favoriteAddedDates[a.id] ?? 0;
      final bDate = _favoriteAddedDates[b.id] ?? 0;
      return bDate.compareTo(aDate);
    });

    return favorites;
  }

  Future<void> _loadLocalFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList(_favoritesKey) ?? [];
      _favoriteIds = Set<String>.from(ids);

      final datesJson = prefs.getString(_favoriteDatesKey);
      if (datesJson != null) {
        final decoded = json.decode(datesJson) as Map<String, dynamic>;
        _favoriteAddedDates =
            decoded.map((key, value) => MapEntry(key, (value as num).toInt()));
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading local favorites: $e');
    }
  }

  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_favoritesKey, _favoriteIds.toList());
      await prefs.setString(
        _favoriteDatesKey,
        json.encode(_favoriteAddedDates),
      );
    } catch (e) {
      debugPrint('Error saving local favorites: $e');
    }
  }

  Future<void> _syncToFirestore() async {
    final uid = AuthService.currentUserId;
    if (uid == null || !FirebaseService.isInitialized) return;

    try {
      _isSyncing = true;
      notifyListeners();

      await FirebaseService.userPrefsDoc(uid).set({
        'favoriteChannels': _favoriteIds.toList(),
        'favoriteChannelDates': _favoriteAddedDates,
        'actualizadoEn': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint(
          '✅ Canales favoritos guardados en la nube: ${_favoriteIds.length}');
    } catch (e) {
      debugPrint('❌ Error syncing favorites to Firestore: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> _syncFromFirestore() async {
    final uid = AuthService.currentUserId;
    if (uid == null || !FirebaseService.isInitialized) return;

    try {
      _isSyncing = true;
      notifyListeners();

      final doc = await FirebaseService.userPrefsDoc(uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data.containsKey('favoriteChannels')) {
          final List<dynamic> remoteFavorites = data['favoriteChannels'] ?? [];
          final remoteSet = remoteFavorites.map((e) => e.toString()).toSet();

          _favoriteIds = remoteSet;

          final remoteDates = data['favoriteChannelDates'];
          if (remoteDates is Map) {
            _favoriteAddedDates = remoteDates.map(
              (k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0),
            );
          }

          for (final id in remoteSet) {
            _favoriteAddedDates.putIfAbsent(
              id,
              () => DateTime.now().millisecondsSinceEpoch,
            );
          }
          _favoriteAddedDates
              .removeWhere((key, _) => !_favoriteIds.contains(key));

          await _saveFavorites();
          notifyListeners();
          debugPrint(
              '✅ Canales favoritos restaurados desde la nube: ${_favoriteIds.length}');
        }
      }
    } catch (e) {
      debugPrint('❌ Error syncing favorites from Firestore: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> clearAllFavorites() async {
    _favoriteIds.clear();
    _favoriteAddedDates.clear();
    notifyListeners();

    await _saveFavorites();
    await _syncToFirestore();
  }

  /// Limpia favoritos locales (ej. al cerrar sesión) SIN borrar los datos en Firestore.
  void clearLocalFavorites() {
    _favoriteIds.clear();
    _favoriteAddedDates.clear();
    notifyListeners();
    unawaited(_saveFavorites());
  }

  Future<void> refreshFromFirestore() async {
    await _syncFromFirestore();
  }
}
