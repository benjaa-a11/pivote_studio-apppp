import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:pivote/features/radio/data/models/radio.dart' as radio_model;
import 'package:pivote/core/services/firebase_service.dart';

class RadioProvider extends ChangeNotifier {
  List<radio_model.Radio> _radios = [];
  List<radio_model.Radio> _filteredRadios = [];
  String _searchQuery = '';
  String _activeCategory = 'Todas';
  bool _isLoading = false;
  bool _isInitialized = false;

  RadioProvider() {
    loadRadiosFromFirestore();
    _loadFavorites();
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

  Future<void> loadRadiosFromFirestore() async {
    _isLoading = true;
    _isInitialized = false;
    notifyListeners();

    try {
      final snapshot = await FirebaseService.radiosCollection.get();
      _radios = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // Ensure the ID is set from doc if not in data
        return radio_model.Radio.fromJson({...data, 'id': doc.id});
      }).toList();

      _applyFilters();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error loading radios from Firestore: $e');
      _isInitialized = true; // Still mark as initialized to not block app
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? favoritesJson = prefs.getString('favorite_radios');
      if (favoritesJson != null) {
        final List<dynamic> favoriteIds = json.decode(favoritesJson);
        for (var radio in _radios) {
          radio.isFavorite = favoriteIds.contains(radio.id);
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading favorite radios: $e');
    }
  }

  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoriteIds =
          _radios.where((r) => r.isFavorite).map((r) => r.id).toList();
      await prefs.setString('favorite_radios', json.encode(favoriteIds));
    } catch (e) {
      debugPrint('Error saving favorite radios: $e');
    }
  }

  void toggleFavorite(radio_model.Radio radio) {
    radio.isFavorite = !radio.isFavorite;
    _saveFavorites();
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
