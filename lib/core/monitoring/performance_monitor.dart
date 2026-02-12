import 'package:flutter/foundation.dart';

/// Performance monitoring service for tracking app metrics
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final Map<String, DateTime> _startTimes = {};
  final Map<String, List<Duration>> _metrics = {};

  /// Start tracking a metric
  void startTracking(String metricName) {
    _startTimes[metricName] = DateTime.now();
  }

  /// Stop tracking and record the duration
  void stopTracking(String metricName) {
    final startTime = _startTimes[metricName];
    if (startTime == null) {
      debugPrint('⚠️ No start time found for metric: $metricName');
      return;
    }

    final duration = DateTime.now().difference(startTime);
    _metrics[metricName] ??= [];
    _metrics[metricName]!.add(duration);

    _startTimes.remove(metricName);

    debugPrint('📊 $metricName: ${duration.inMilliseconds}ms');
  }

  /// Get average duration for a metric
  Duration? getAverageDuration(String metricName) {
    final durations = _metrics[metricName];
    if (durations == null || durations.isEmpty) return null;

    final totalMs = durations.fold<int>(
      0,
      (sum, duration) => sum + duration.inMilliseconds,
    );

    return Duration(milliseconds: totalMs ~/ durations.length);
  }

  /// Get all metrics
  Map<String, Duration?> getAllAverages() {
    final averages = <String, Duration?>{};
    for (final key in _metrics.keys) {
      averages[key] = getAverageDuration(key);
    }
    return averages;
  }

  /// Clear all metrics
  void clearMetrics() {
    _metrics.clear();
    _startTimes.clear();
  }

  /// Print performance report
  void printReport() {
    debugPrint('📊 === Performance Report ===');
    final averages = getAllAverages();

    if (averages.isEmpty) {
      debugPrint('No metrics recorded');
      return;
    }

    for (final entry in averages.entries) {
      final avg = entry.value;
      if (avg != null) {
        debugPrint('${entry.key}: ${avg.inMilliseconds}ms (avg)');
      }
    }
    debugPrint('📊 === End Report ===');
  }

  /// Track a function execution
  Future<T> track<T>(String metricName, Future<T> Function() function) async {
    startTracking(metricName);
    try {
      return await function();
    } finally {
      stopTracking(metricName);
    }
  }

  /// Track a synchronous function execution
  T trackSync<T>(String metricName, T Function() function) {
    startTracking(metricName);
    try {
      return function();
    } finally {
      stopTracking(metricName);
    }
  }
}
