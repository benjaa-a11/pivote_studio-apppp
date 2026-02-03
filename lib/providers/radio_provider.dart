import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/radio.dart' as radio_model;
import '../services/firebase_service.dart';

class RadioProvider extends ChangeNotifier {
  List<radio_model.Radio> _radios = [];
  List<radio_model.Radio> _filteredRadios = [];
  String _searchQuery = '';
  bool _isLoading = false;
  bool _isInitialized = false;

  RadioProvider() {
    loadRadiosFromFirestore();
    _loadFavorites();
  }

  List<radio_model.Radio> get radios => _filteredRadios.isEmpty && _searchQuery.isEmpty
      ? _radios 
      : _filteredRadios;

  bool get isLoading => _isLoading;

  bool get isInitialized => _isInitialized;

  String get searchQuery => _searchQuery;

  Future<void> loadRadiosFromFirestore() async {
    _isLoading = true;
    _isInitialized = false;
    notifyListeners();

    try {
      final snapshot = await FirebaseService.radiosCollection.get();
      _radios = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return radio_model.Radio.fromJson(data);
      }).toList();

      _applyFilters();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error loading radios from Firestore: $e');
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
      final favoriteIds = _radios.where((r) => r.isFavorite).map((r) => r.id).toList();
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
    if (_searchQuery.isEmpty) {
      _filteredRadios = [];
      return;
    }

    _filteredRadios = _radios.where((radio) {
      final matchesSearch = _searchQuery.isEmpty || 
          radio.name.toLowerCase().contains(_searchQuery);
      
      return matchesSearch;
    }).toList();
  }

  void clearFilters() {
    _searchQuery = '';
    _filteredRadios = [];
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