import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pivote/features/home/data/models/app_notification.dart';
import 'package:pivote/features/home/data/services/notification_feed_service.dart';
import 'package:pivote/features/soccer/data/models/soccer_models.dart';

class NotificationsProvider extends ChangeNotifier {
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
      final readIds = prefs.getStringList('pivote_read_notification_ids')?.toSet() ?? {};
      _items = fresh.map((item) => item.copyWith(isRead: readIds.contains(item.id))).toList();
    } catch (e) {
      _error = 'No pudimos actualizar las notificaciones.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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

  Future<void> _persistReadIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'pivote_read_notification_ids',
      _items.where((item) => item.isRead).map((item) => item.id).toList(),
    );
  }
}
