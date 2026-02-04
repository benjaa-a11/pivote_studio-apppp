import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/channel.dart';
import '../services/firebase_service.dart';
import '../services/viewing_history_service.dart';
import '../services/search_service.dart';
import 'theme_provider.dart';
import 'dart:async';
import 'dart:convert';

class ChannelProvider extends ChangeNotifier {
  List<Channel> _channels = [];
  List<Channel> _filteredChannels = [];
  String _searchQuery = '';
  String _selectedCategory = 'Todos';
  bool _isLoading = false;
  bool _isDarkMode = true;
  bool _isInitialized = false;
  Map<String, int> _viewCounts = {};
  Map<String, int> _lastViewed = {};
  Timer? _refreshTimer;
  List<Channel>? _cachedSortedChannels;
  bool _needsResort = true;

  ChannelProvider(ThemeProvider themeProvider) {
    themeProvider.addListener(_onThemeChanged);
    _isDarkMode = themeProvider.isDarkMode;
    loadChannelsFromFirestore();
    _loadViewCounts();
    _setupPeriodicRefresh();
  }

  void _setupPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _loadViewCounts();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _onThemeChanged() {
    // Theme change handler
  }

  List<Channel> get channels {
    List<Channel> channelsToReturn;

    if (_filteredChannels.isEmpty &&
        _searchQuery.isEmpty &&
        _selectedCategory == 'Todos') {
      channelsToReturn = List.from(_getVisibleChannels(_channels));
    } else {
      channelsToReturn = List.from(_getVisibleChannels(_filteredChannels));
    }

    // Use cached sorted results if available and no resort needed
    if (!_needsResort && _cachedSortedChannels != null) {
      return _cachedSortedChannels!;
    }

    final sorted = _sortChannelsByViewCount(channelsToReturn);
    _cachedSortedChannels = sorted;
    _needsResort = false;
    return sorted;
  }

  List<Channel> _sortChannelsByViewCount(List<Channel> channels) {
    channels.sort((a, b) {
      // 1. Order field (lower number = higher priority)
      if (a.order != b.order) {
        return a.order.compareTo(b.order);
      }

      // 2. View count (higher = first)
      final aCount = _viewCounts[a.id] ?? 0;
      final bCount = _viewCounts[b.id] ?? 0;
      if (aCount != bCount) {
        return bCount.compareTo(aCount);
      }

      // 3. Last viewed (more recent = first)
      final aLastViewed = _lastViewed[a.id] ?? 0;
      final bLastViewed = _lastViewed[b.id] ?? 0;
      if (aLastViewed != bLastViewed) {
        return bLastViewed.compareTo(aLastViewed);
      }

      // 4. Name (alphabetical)
      return a.name.compareTo(b.name);
    });

    return channels;
  }

  Future<void> _loadViewCounts() async {
    try {
      _viewCounts = await ViewingHistoryService.getAllViewCounts();
      _lastViewed = await _loadLastViewed();
      _needsResort = true; // Invalidate cache
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading view counts: $e');
    }
  }

  Future<Map<String, int>> _loadLastViewed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastViewedJson = prefs.getString('channel_last_viewed');

      if (lastViewedJson != null) {
        final decoded = json.decode(lastViewedJson) as Map<String, dynamic>;
        return decoded.map((key, value) => MapEntry(key, value as int));
      }
    } catch (e) {
      debugPrint('Error loading last viewed timestamps: $e');
    }
    return {};
  }

  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isDarkMode => _isDarkMode;

  List<String> get categories {
    final cats =
        _getVisibleChannels(_channels).map((c) => c.category).toSet().toList();
    cats.insert(0, 'Todos');
    return cats;
  }

  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  Future<void> loadChannelsFromFirestore() async {
    _isLoading = true;
    _isInitialized = false;
    notifyListeners();

    try {
      final snapshot = await FirebaseService.channelsCollection.get();
      _channels = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Channel.fromJson(data);
      }).toList();

      // Debug: Mostrar todos los IDs de canales cargados
      debugPrint('📺 Canales cargados desde Firestore:');
      for (var channel in _channels) {
        debugPrint('  - ${channel.id}: ${channel.name}');
      }

      _applyFilters();
      _isInitialized = true;
      await _loadViewCounts();
    } catch (e) {
      debugPrint('Error loading channels from Firestore: $e');
      _isInitialized = true; // Still mark as initialized to not block app
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Channel> getRelatedChannels(Channel channel, {int limit = 4}) {
    final relatedChannels = _getVisibleChannels(_channels)
        .where((c) => c.category == channel.category && c.id != channel.id)
        .take(limit)
        .toList();

    return relatedChannels;
  }

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    _needsResort = true; // Invalidate cache
    _applyFilters();
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    _needsResort = true; // Invalidate cache
    _applyFilters();
    notifyListeners();
  }

  void setDarkMode(bool isDarkMode) {
    _isDarkMode = isDarkMode;
    notifyListeners();
  }

  void _applyFilters() {
    if (_searchQuery.isEmpty && _selectedCategory == 'Todos') {
      _filteredChannels = [];
      return;
    }

    List<Channel> channelsToFilter = _getVisibleChannels(_channels);

    // Apply category filter first
    if (_selectedCategory != 'Todos') {
      channelsToFilter = channelsToFilter
          .where((channel) => channel.category == _selectedCategory)
          .toList();
    }

    // Apply advanced search with fuzzy matching
    if (_searchQuery.isNotEmpty) {
      _filteredChannels = SearchService.searchChannels(
        channelsToFilter,
        _searchQuery,
        minSimilarity: 30.0, // Adjust threshold for more/less strict matching
      );
    } else {
      _filteredChannels = channelsToFilter;
    }
  }

  List<Channel> _getVisibleChannels(List<Channel> channels) {
    return channels.where((channel) => !channel.isHidden).toList();
  }

  List<Channel> get allChannels {
    final channels = List<Channel>.from(_getVisibleChannels(_channels));
    return _sortChannelsByViewCount(channels);
  }

  Future<void> refreshViewCounts() async {
    await _loadViewCounts();
  }

  Channel? getChannelById(String id) {
    debugPrint('🔎 getChannelById llamado con ID: "$id"');
    debugPrint('📊 Total de canales en memoria: ${_channels.length}');

    try {
      final channel = _channels.firstWhere(
        (channel) {
          final match = channel.id == id;
          if (match) {
            debugPrint('✅ Match encontrado: ${channel.id} == $id');
          }
          return match;
        },
      );

      debugPrint('✅ Canal encontrado exitosamente: ${channel.name}');
      return channel;
    } catch (e) {
      debugPrint('❌ Canal NO encontrado con ID: "$id"');
      debugPrint('📋 IDs disponibles:');
      for (var channel in _channels.take(10)) {
        debugPrint('  - "${channel.id}" (${channel.name})');
      }
      if (_channels.length > 10) {
        debugPrint('  ... y ${_channels.length - 10} canales más');
      }
      return null;
    }
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = 'Todos';
    _filteredChannels = [];
    notifyListeners();
  }

  Future<void> recordView(Channel channel) async {
    // 1. Update local state immediately for UI responsiveness
    final now = DateTime.now().millisecondsSinceEpoch;
    _viewCounts[channel.id] = (_viewCounts[channel.id] ?? 0) + 1;
    _lastViewed[channel.id] = now;
    _needsResort = true; // Invalidate cache

    // 2. Persist to storage
    await ViewingHistoryService.trackChannelView(channel.id);

    // 3. Notify listeners to trigger re-sort
    notifyListeners();

    debugPrint(
        '📈 Canal registrado: ${channel.name} (Vistas: ${_viewCounts[channel.id]})');
  }

  void searchChannels(String query) {
    setSearchQuery(query);
    // Save to search history if query is not empty
    if (query.trim().isNotEmpty) {
      SearchService.saveSearchQuery(query);
    }
  }

  void filterByCategory(String category) {
    setSelectedCategory(category);
  }
}
