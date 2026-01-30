import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/channel.dart';

/// Advanced search service with fuzzy matching and search history
class SearchService {
  static const String _searchHistoryKey = 'search_history';
  static const int _maxHistoryItems = 10;

  /// Calculate Levenshtein distance between two strings
  static int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    final len1 = s1.length;
    final len2 = s2.length;
    final matrix = List.generate(
      len1 + 1,
      (i) => List.generate(len2 + 1, (j) => 0),
    );

    for (int i = 0; i <= len1; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= len2; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= len1; i++) {
      for (int j = 1; j <= len2; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1, // deletion
          matrix[i][j - 1] + 1, // insertion
          matrix[i - 1][j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[len1][len2];
  }

  /// Calculate similarity score (0-100) between query and text
  static double calculateSimilarity(String query, String text) {
    if (query.isEmpty || text.isEmpty) return 0.0;

    final queryLower = query.toLowerCase();
    final textLower = text.toLowerCase();

    // Exact match
    if (textLower == queryLower) return 100.0;

    // Starts with
    if (textLower.startsWith(queryLower)) return 90.0;

    // Contains
    if (textLower.contains(queryLower)) return 80.0;

    // Fuzzy match using Levenshtein distance
    final distance = _levenshteinDistance(queryLower, textLower);
    final maxLen = queryLower.length > textLower.length
        ? queryLower.length
        : textLower.length;

    if (maxLen == 0) return 0.0;

    final similarity = ((maxLen - distance) / maxLen) * 70.0;
    return similarity.clamp(0.0, 70.0);
  }

  /// Search channels with advanced ranking
  static List<Channel> searchChannels(
    List<Channel> channels,
    String query, {
    double minSimilarity = 30.0,
  }) {
    if (query.isEmpty) return channels;

    final results = <({Channel channel, double score})>[];

    for (final channel in channels) {
      // Calculate scores for name and description
      final nameScore = calculateSimilarity(query, channel.name);
      final descScore = calculateSimilarity(query, channel.description);
      final categoryScore = calculateSimilarity(query, channel.category);

      // Weighted score (name is most important)
      final totalScore =
          (nameScore * 0.6) + (descScore * 0.3) + (categoryScore * 0.1);

      if (totalScore >= minSimilarity) {
        results.add((channel: channel, score: totalScore));
      }
    }

    // Sort by score (highest first)
    results.sort((a, b) => b.score.compareTo(a.score));

    return results.map((r) => r.channel).toList();
  }

  /// Save search query to history
  static Future<void> saveSearchQuery(String query) async {
    if (query.trim().isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final history = await getSearchHistory();

      // Remove if already exists
      history.remove(query);

      // Add to beginning
      history.insert(0, query);

      // Limit size
      if (history.length > _maxHistoryItems) {
        history.removeRange(_maxHistoryItems, history.length);
      }

      await prefs.setString(_searchHistoryKey, json.encode(history));
    } catch (e) {
      debugPrint('Error saving search query: $e');
    }
  }

  /// Get search history
  static Future<List<String>> getSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_searchHistoryKey);

      if (historyJson != null) {
        final List<dynamic> decoded = json.decode(historyJson);
        return decoded.map((e) => e.toString()).toList();
      }
    } catch (e) {
      debugPrint('Error loading search history: $e');
    }

    return [];
  }

  /// Clear search history
  static Future<void> clearSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_searchHistoryKey);
    } catch (e) {
      debugPrint('Error clearing search history: $e');
    }
  }

  /// Get search suggestions based on channels
  static List<String> getSearchSuggestions(
    List<Channel> channels,
    String query, {
    int maxSuggestions = 5,
  }) {
    if (query.isEmpty) return [];

    final suggestions = <String>{};

    for (final channel in channels) {
      // Add channel name if it matches
      if (channel.name.toLowerCase().contains(query.toLowerCase())) {
        suggestions.add(channel.name);
      }

      // Add category if it matches
      if (channel.category.toLowerCase().contains(query.toLowerCase())) {
        suggestions.add(channel.category);
      }

      if (suggestions.length >= maxSuggestions) break;
    }

    return suggestions.take(maxSuggestions).toList();
  }
}
