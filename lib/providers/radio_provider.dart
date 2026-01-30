import 'package:flutter/material.dart';
import '../models/radio.dart' as model;
import '../services/firebase_service.dart';

/// Provider for managing radio stations and categories
class RadioProvider extends ChangeNotifier {
  List<model.Radio> _stations = [];
  List<model.Radio> _filteredStations = [];
  final List<String> _categories = [
    'Todo',
    'Electrónica',
    'Jazz',
    'Indie',
    'Folk',
    'Soul'
  ];
  String _selectedCategory = 'Todo';
  bool _isLoading = false;
  String? _error;

  List<model.Radio> get stations =>
      _filteredStations.isEmpty && _selectedCategory == 'Todo'
          ? _stations
          : _filteredStations;
  List<String> get categories => _categories;
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  RadioProvider() {
    fetchStations();
  }

  /// Fetch stations from Firestore
  Future<void> fetchStations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot =
          await FirebaseService.radiosCollection.orderBy('name').get();

      _stations = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return model.Radio.fromJson({...data, 'id': doc.id});
      }).toList();

      _applyFilter();
      debugPrint('📡 Fetched ${_stations.length} radio stations');
    } catch (e) {
      _error = 'Error al cargar las estaciones: $e';
      debugPrint('❌ $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Set and apply category filter
  void setCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    if (_selectedCategory == 'Todo') {
      _filteredStations = List.from(_stations);
    } else {
      // In a real app, radios would have a 'category' or 'genre' field
      // For now, we simulate filtering or keep it simple
      _filteredStations = _stations.where((s) {
        // Simple heuristic: check if category is in name or frequency/description
        return s.name.toLowerCase().contains(_selectedCategory.toLowerCase()) ||
            s.frequency.toLowerCase().contains(_selectedCategory.toLowerCase());
      }).toList();
    }
  }

  /// Search stations by name
  void searchStations(String query) {
    if (query.isEmpty) {
      _applyFilter();
    } else {
      _filteredStations = _stations.where((s) {
        return s.name.toLowerCase().contains(query.toLowerCase());
      }).toList();
    }
    notifyListeners();
  }

  /// Get the next station in the current list
  model.Radio? getNextStation(model.Radio current) {
    final list = stations;
    final index = list.indexWhere((s) => s.id == current.id);
    if (index == -1 || list.isEmpty) return null;
    return list[(index + 1) % list.length];
  }

  /// Get the previous station in the current list
  model.Radio? getPreviousStation(model.Radio current) {
    final list = stations;
    final index = list.indexWhere((s) => s.id == current.id);
    if (index == -1 || list.isEmpty) return null;
    return list[(index - 1 + list.length) % list.length];
  }
}
