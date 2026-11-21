import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:pivote/core/services/firebase_service.dart';
import 'package:pivote/features/auth/data/services/auth_service.dart';

/// Configuración remota sensible alojada en Firestore `config/app` detrás de las
/// reglas `esActivo() || esAdmin()`.
///
/// Evita hardcodear URLs de Workers/proxies o API keys dentro del APK compilado.
class AppRemoteConfigService {
  static Map<String, dynamic> _config = {};
  static bool _loaded = false;
  static Future<void>? _inFlightLoad;

  static bool get isLoaded => _loaded;

  static String? get matchesApiUrl => _readNonEmptyString('matchesApiUrl');
  static String? get webProxyUrl => _readNonEmptyString('webProxyUrl');
  static String get newsBaseUrl =>
      _readNonEmptyString('newsBaseUrl') ?? 'https://newsdata.io/api/1/latest';
  static String? get newsApiKey => _readNonEmptyString('newsApiKey');
  static bool get sendAuthTokenToWorkers =>
      _config['sendAuthTokenToWorkers'] != false;

  static String? _readNonEmptyString(String key) {
    final value = _config[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  /// Carga `config/app` desde Firestore únicamente si hay usuario autenticado.
  static Future<void> load({bool forceRefresh = false}) async {
    if (_loaded && !forceRefresh) return;
    if (_inFlightLoad != null && !forceRefresh) {
      return _inFlightLoad;
    }

    final uid = AuthService.currentUserId;
    if (uid == null || !FirebaseService.isInitialized) {
      return;
    }

    final future = _executeLoad(forceRefresh: forceRefresh);
    _inFlightLoad = future;
    try {
      await future;
    } finally {
      if (identical(_inFlightLoad, future)) {
        _inFlightLoad = null;
      }
    }
  }

  static Future<void> _executeLoad({required bool forceRefresh}) async {
    try {
      final doc = await FirebaseService.appConfigDoc.get(
        GetOptions(
          source: forceRefresh ? Source.server : Source.serverAndCache,
        ),
      );
      if (doc.exists && doc.data() != null) {
        _config = Map<String, dynamic>.from(doc.data()!);
        _loaded = true;
        debugPrint('🛡️ AppRemoteConfigService: config/app cargado correctamente');
      } else {
        debugPrint(
          '⚠️ AppRemoteConfigService: Falta el documento Firestore config/app',
        );
      }
    } catch (e) {
      debugPrint('⚠️ AppRemoteConfigService: Error leyendo config/app: $e');
    }
  }

  /// Construye headers HTTP adjuntando `Authorization: Bearer <Firebase ID Token>`
  /// para que los Cloudflare Workers/proxies validen la sesión en el servidor.
  static Future<Map<String, String>> buildAuthorizedHeaders({
    Map<String, String>? extra,
  }) async {
    final headers = <String, String>{
      if (extra != null) ...extra,
    };

    if (!sendAuthTokenToWorkers) return headers;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final token = await user.getIdToken();
        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
        }
      }
    } catch (e) {
      debugPrint('⚠️ AppRemoteConfigService: No se pudo obtener ID token: $e');
    }

    return headers;
  }

  /// Borra de memoria todas las URLs y claves al cerrar sesión o ser revocado.
  static void clear() {
    _config = {};
    _loaded = false;
    _inFlightLoad = null;
  }
}
