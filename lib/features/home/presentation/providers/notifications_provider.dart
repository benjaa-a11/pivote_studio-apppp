import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pivote/features/home/data/models/app_notification.dart';
import 'package:pivote/features/home/data/services/notification_feed_service.dart';
import 'package:pivote/features/soccer/data/models/soccer_models.dart';

class NotificationsProvider extends ChangeNotifier {
  static const _readKey = 'pivote_read_notification_ids';
  static const _historyKey = 'pivote_notification_history';

  List<AppNotification> _items = const [];
  bool _isLoading = false;
  String? _error;

  List<AppNotification> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _items.where((item) => !item.isRead).length;

  Future<void> refresh({SoccerData? soccerData}) async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final fresh = await NotificationFeedService.load(soccerData: soccerData);
      final prefs = await SharedPreferences.getInstance();
      final readIds = prefs.getStringList(_readKey)?.toSet() ?? {};
      final history = _loadHistory(prefs);
      final merged = <String, AppNotification>{};
      for (final item in [...history, ...fresh]) {
        merged[item.id] = item;
      }
      _items = merged.values
          .map((item) => item.copyWith(isRead: readIds.contains(item.id)))
          .toList()
        ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
      await _saveHistory(prefs, _items);
    } catch (_) {
      _error = 'No pudimos actualizar las notificaciones.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addRemoteNotification({
    required String id,
    required String title,
    required String body,
    String? imageUrl,
    String? deepLink,
    String source = 'Pivote',
    AppNotificationType type = AppNotificationType.system,
    DateTime? publishedAt,
  }) async {
    final item = AppNotification(
      id: id,
      title: title,
      body: body,
      imageUrl: imageUrl,
      deepLink: deepLink,
      source: source,
      type: type,
      publishedAt: publishedAt ?? DateTime.now(),
    );
    final map = {for (final current in _items) current.id: current};
    map[id] = item;
    _items = map.values.toList()..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await _saveHistory(prefs, _items);
  }

  Future<void> markAsRead(String id) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index < 0 || _items[index].isRead) return;
    _items = [..._items]..[index] = _items[index].copyWith(isRead: true);
    notifyListeners();
    await _persistReadIds();
  }

  Future<void> markAllAsRead() async {
    _items = _items.map((item) => item.copyWith(isRead: true)).toList();
    notifyListeners();
    await _persistReadIds();
  }

  List<AppNotification> _loadHistory(SharedPreferences prefs) {
    final raw = prefs.getStringList(_historyKey) ?? const [];
    return raw.map((value) {
      try {
        return AppNotification.fromJson(jsonDecode(value) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }).whereType<AppNotification>().take(50).toList();
  }

  Future<void> _saveHistory(SharedPreferences prefs, List<AppNotification> items) async {
    await prefs.setStringList(
      _historyKey,
      items.take(50).map((item) => jsonEncode(item.toJson())).toList(),
    );
  }

  Future<void> _persistReadIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _readKey,
      _items.where((item) => item.isRead).map((item) => item.id).take(100).toList(),
    );
    await _saveHistory(prefs, _items);
  }
}
