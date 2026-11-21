import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pivote/core/services/firebase_service.dart';
import 'package:pivote/core/services/image_cache_helper.dart';
import 'package:pivote/features/auth/data/services/auth_service.dart';
import 'package:pivote/features/radio/data/models/radio.dart' as radio_model;

class RadioProvider extends ChangeNotifier {
  List<radio_model.Radio> _radios = [];
  List<radio_model.Radio> _filteredRadios = [];
  Set<String> _favoriteRadioIds = {};
  String _searchQuery = '';
  String _activeCategory = 'Todas';
  bool _isLoading = false;
  bool _isInitialized = false;

  static const String _localFavoritesKey = 'favorite_radios';

  RadioProvider() {
    // No consultar Firestore en el constructor: las reglas exigen `esActivo()`.
    // Se carga en `loadForAuthenticatedUser()` al verificar sesión activa.
  }

  List<radio_model.Radio> get radios => (_filteredRadios.isEmpty &&
          _searchQuery.isEmpty &&
          _activeCategory == 'Todas')
      ? _radios
      : _filteredRadios;

  bool get isLoading => _isLoading;

  bool get isInitialized => _isInitialized;

  String get searchQuery => _searchQuery;

  String get activeCategory => _activeCategory;

  List<String> get categories {
    final cats = _radios
        .map((r) => r.category ?? 'Otras')
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();
    cats.sort();
    return ['Todas', ...cats];
  }

  void setActiveCategory(String category) {
    _activeCategory = category;
    _applyFilters();
    notifyListeners();
  }

  /// Carga emisoras y restaura las emisoras favoritas del usuario desde la nube.
  Future<void> loadForAuthenticatedUser() async {
    await _loadLocalFavorites();
    await Future.wait([
      loadRadiosFromFirestore(),
      _syncFavoritesFromFirestore(),
    ]);
    _applyFavoriteFlags();
    notifyListeners();
  }

  Future<void> loadRadiosFromFirestore() async {
    if (AuthService.currentUserId == null) return;
    _isLoading = true;
    _isInitialized = false;
    notifyListeners();

    try {
      final snapshot = await FirebaseService.radiosCollection.get();
      _radios = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final radio = radio_model.Radio.fromJson({...data, 'id': doc.id});
        radio.isFavorite = _favoriteRadioIds.contains(radio.id);
        return radio;
      }).toList();

      _applyFilters();
      _isInitialized = true;
      _warmUpRadioLogos();
    } catch (e) {
      debugPrint('Error loading radios from Firestore: $e');
      _isInitialized = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _warmUpRadioLogos() {
    try {
      final logoUrls = _radios
          .map((r) => r.logoUrl)
          .where((url) => url.isNotEmpty && url.startsWith('http'))
          .toList();

      if (logoUrls.isNotEmpty) {
        debugPrint('📻 Pre-cargando ${logoUrls.length} logos de radio...');
        ImageCacheHelper.warmUpCache(logoUrls, isLogos: true);
      }
    } catch (e) {
      debugPrint('Error in radio logo warm-up: $e');
    }
  }

  void _applyFavoriteFlags() {
    for (final radio in _radios) {
      radio.isFavorite = _favoriteRadioIds.contains(radio.id);
    }
  }

  Future<void> _loadLocalFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? favoritesJson = prefs.getString(_localFavoritesKey);
      if (favoritesJson != null) {
        final List<dynamic> ids = json.decode(favoritesJson);
        _favoriteRadioIds = ids.map((e) => e.toString()).toSet();
        _applyFavoriteFlags();
      }
    } catch (e) {
      debugPrint('Error loading local favorite radios: $e');
    }
  }

  Future<void> _saveLocalFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _localFavoritesKey,
        json.encode(_favoriteRadioIds.toList()),
      );
    } catch (e) {
      debugPrint('Error saving local favorite radios: $e');
    }
  }

  /// Sincroniza emisoras favoritas desde `users/{uid}/datos/preferencias`.
  Future<void> _syncFavoritesFromFirestore() async {
    final uid = AuthService.currentUserId;
    if (uid == null || !FirebaseService.isInitialized) return;

    try {
      final doc = await FirebaseService.userPrefsDoc(uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data.containsKey('favoriteRadios')) {
          final remoteList = (data['favoriteRadios'] as List<dynamic>? ?? [])
              .map((e) => e.toString())
              .toSet();
          _favoriteRadioIds = remoteList;
          _applyFavoriteFlags();
          await _saveLocalFavorites();
          debugPrint(
              '✅ Emisoras favoritas sincronizadas desde la nube: ${_favoriteRadioIds.length}');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error sincronizando emisoras favoritas desde Firestore: $e');
    }
  }

  /// Persiste emisoras favoritas en `users/{uid}/datos/preferencias` (sobrevive desinstalación).
  Future<void> _syncFavoritesToFirestore() async {
    final uid = AuthService.currentUserId;
    if (uid == null || !FirebaseService.isInitialized) return;

    try {
      await FirebaseService.userPrefsDoc(uid).set({
        'favoriteRadios': _favoriteRadioIds.toList(),
        'actualizadoEn': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint(
          '✅ Emisoras favoritas guardadas en la nube: ${_favoriteRadioIds.length}');
    } catch (e) {
      debugPrint('⚠️ Error guardando emisoras favoritas en Firestore: $e');
    }
  }

  void toggleFavorite(radio_model.Radio radio) {
    radio.isFavorite = !radio.isFavorite;
    if (radio.isFavorite) {
      _favoriteRadioIds.add(radio.id);
    } else {
      _favoriteRadioIds.remove(radio.id);
    }
    notifyListeners();
    unawaited(_saveLocalFavorites());
    unawaited(_syncFavoritesToFirestore());
  }

  /// Limpia memoria y caché local al cerrar sesión (SIN borrar la nube).
  void clearOnLogout() {
    _radios = [];
    _filteredRadios = [];
    _favoriteRadioIds = {};
    _searchQuery = '';
    _activeCategory = 'Todas';
    _isLoading = false;
    _isInitialized = false;
    unawaited(_saveLocalFavorites());
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredRadios = _radios.where((radio) {
      final matchesSearch = _searchQuery.isEmpty ||
          radio.name.toLowerCase().contains(_searchQuery);

      final matchesCategory = _activeCategory == 'Todas' ||
          (radio.category ?? 'Otras') == _activeCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  void clearFilters() {
    _searchQuery = '';
    _activeCategory = 'Todas';
    _applyFilters();
    notifyListeners();
  }

  radio_model.Radio? getRadioById(String id) {
    try {
      return _radios.firstWhere((radio) => radio.id == id);
    } catch (e) {
      return null;
    }
  }

  List<radio_model.Radio> get favoriteRadios {
    return _radios.where((radio) => radio.isFavorite).toList();
  }

  void searchRadios(String query) {
    setSearchQuery(query);
  }
}
