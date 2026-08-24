import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pivote/features/auth/data/services/auth_service.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _channelId = 'pivote_notifications';
  static const String _channelName = 'Pivote Notifications';
  static const String _channelDescription = 'Notificaciones de la aplicación Pivote';
  static ValueChanged<RemoteMessage>? onMessageReceived;
  static final List<RemoteMessage> _pendingMessages = [];

  static List<RemoteMessage> takePendingMessages() {
    final messages = List<RemoteMessage>.from(_pendingMessages);
    _pendingMessages.clear();
    return messages;
  }

  static Future<void> initializeWithoutPermission() async {
    try {
      final settings = await _messaging.getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.authorized) await _setupNotificationHandlers();
    } catch (e) { debugPrint('❌ Error initializing Notification Service: $e'); }
  }

  static Future<void> initialize() async {
    try {
      final settings = await _messaging.requestPermission(alert: true, badge: true, sound: true, provisional: false);
      if (settings.authorizationStatus == AuthorizationStatus.authorized) await _setupNotificationHandlers();
    } catch (e) { debugPrint('❌ Error initializing Notification Service: $e'); }
  }

  static Future<void> _setupNotificationHandlers() async {
    await _initializeLocalNotifications();
    final token = await getToken();
    if (token != null) await _saveTokenToFirestore(token);
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) _handleNotificationTap(initialMessage);
    _messaging.onTokenRefresh.listen(_saveTokenToFirestore);
  }

  static Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(requestAlertPermission: true, requestBadgePermission: true, requestSoundPermission: true);
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _localNotifications.initialize(initSettings, onDidReceiveNotificationResponse: _onNotificationTapped);
    const androidChannel = AndroidNotificationChannel(_channelId, _channelName, description: _channelDescription, importance: Importance.high, enableVibration: true, playSound: true);
    await _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(androidChannel);
  }

  static Future<String?> getToken() async { try { return await _messaging.getToken(); } catch (e) { debugPrint('❌ Error getting FCM token: $e'); return null; } }

  static Future<void> _saveTokenToFirestore(String token) async {
    try {
      final uid = AuthService.currentUserId;
      if (uid == null) return;
      await _firestore.collection('usuarios').doc(uid).update({'fcmToken': token, 'fcmTokenUpdatedAt': FieldValue.serverTimestamp(), 'notificationsDisabled': false});
    } catch (e) { debugPrint('❌ Error saving FCM token: $e'); }
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    _pendingMessages.add(message);
    onMessageReceived?.call(message);
    final notification = message.notification;
    final android = message.notification?.android;
    if (notification != null) {
      await _localNotifications.show(notification.hashCode, notification.title, notification.body, NotificationDetails(android: AndroidNotificationDetails(_channelId, _channelName, channelDescription: _channelDescription, importance: Importance.high, priority: Priority.high, icon: android?.smallIcon ?? '@mipmap/ic_launcher'), iOS: const DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true)), payload: message.data.toString());
    }
  }

  static void _handleNotificationTap(RemoteMessage message) {
    _pendingMessages.add(message);
    onMessageReceived?.call(message);
  }

  static void _onNotificationTapped(NotificationResponse response) { debugPrint('🔔 Local notification tapped: ${response.payload}'); }

  static Future<bool> areNotificationsEnabled() async { final settings = await _messaging.getNotificationSettings(); return settings.authorizationStatus == AuthorizationStatus.authorized; }

  static Future<bool> requestPermission() async {
    try {
      if (await Permission.notification.isDenied) { final status = await Permission.notification.request(); if (status.isDenied) return false; }
      final settings = await _messaging.requestPermission(alert: true, badge: true, sound: true);
      final authorized = settings.authorizationStatus == AuthorizationStatus.authorized;
      if (authorized) await initialize();
      return authorized;
    } catch (_) { return false; }
  }

  static Future<void> disableNotifications() async {
    try {
      final uid = AuthService.currentUserId;
      if (uid == null) return;
      await _firestore.collection('usuarios').doc(uid).update({'fcmToken': FieldValue.delete(), 'notificationsDisabled': true});
      await _messaging.deleteToken();
    } catch (e) { debugPrint('❌ Error disabling notifications: $e'); }
  }

  static Future<void> sendTestNotification() async {
    await _localNotifications.show(0, 'Notificación de prueba', 'Las notificaciones están funcionando correctamente', const NotificationDetails(android: AndroidNotificationDetails(_channelId, _channelName, channelDescription: _channelDescription, importance: Importance.high, priority: Priority.high), iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true)));
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async { debugPrint('🔔 Background message received: ${message.messageId}'); }
