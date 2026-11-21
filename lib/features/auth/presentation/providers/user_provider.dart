import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pivote/core/services/notification_service.dart';
import 'package:pivote/features/auth/data/models/user_model.dart';
import 'package:pivote/features/auth/data/services/auth_service.dart';

/// Estado global de control de acceso privado de la app.
enum AuthGateStatus {
  checking,
  unauthenticated,
  blocked,
  authenticatedActive,
}

/// Información de bloqueo mostrada en la pantalla "Cuenta pendiente / vencida".
class AccountBlockInfo {
  final AccountBlockReason reason;
  final String? email;
  final DateTime? vence;
  final String? plan;

  const AccountBlockInfo({
    required this.reason,
    this.email,
    this.vence,
    this.plan,
  });
}

class UserProvider with ChangeNotifier {
  UserModel? _user;
  Uint8List? _avatarBytes;
  String? _profileImagePath;
  bool _isLoading = false;
  AuthGateStatus _authStatus = AuthGateStatus.checking;
  AccountBlockInfo? _blockInfo;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userDocSub;
  Timer? _expirationTimer;
  VoidCallback? _onSessionRevoked;

  UserModel? get user => _user;
  Uint8List? get avatarBytes => _avatarBytes;
  String? get profileImagePath => _profileImagePath;
  bool get isLoading => _isLoading;
  AuthGateStatus get authStatus => _authStatus;
  AccountBlockInfo? get blockInfo => _blockInfo;
  bool get isAuthenticatedActive =>
      _authStatus == AuthGateStatus.authenticatedActive &&
      _user != null &&
      _user!.hasValidAccess;

  static const String _avatarCachePathKey = 'profile_image_path_v2';
  static const String _avatarCacheUidKey = 'profile_image_uid_v2';

  /// Callback opcional registrado por el wrapper raíz para limpiar stacks/providers al revocar.
  void setOnSessionRevoked(VoidCallback? callback) {
    _onSessionRevoked = callback;
  }

  // ─── Arranque y verificación inicial ────────────────────────────

  /// Verifica sesión actual en Firebase Auth + estado real de `users/{uid}` en servidor.
  Future<void> checkInitialAuth() async {
    _authStatus = AuthGateStatus.checking;
    _blockInfo = null;
    notifyListeners();

    final uid = AuthService.currentUserId;
    if (uid == null) {
      _authStatus = AuthGateStatus.unauthenticated;
      _user = null;
      notifyListeners();
      return;
    }

    try {
      final fetched = await AuthService.getUser(forceServer: true);
      if (fetched == null) {
        await _forceBlockAndSignOut(
          AccountBlockInfo(
            reason: AccountBlockReason.missingProfile,
            email: AuthService.currentFirebaseUser?.email,
          ),
        );
        return;
      }

      if (!fetched.activo) {
        await _forceBlockAndSignOut(
          AccountBlockInfo(
            reason: AccountBlockReason.pending,
            email: fetched.email,
            vence: fetched.vence,
            plan: fetched.plan,
          ),
        );
        return;
      }

      if (fetched.isExpired) {
        await _forceBlockAndSignOut(
          AccountBlockInfo(
            reason: AccountBlockReason.expired,
            email: fetched.email,
            vence: fetched.vence,
            plan: fetched.plan,
          ),
        );
        return;
      }

      await _activateVerifiedSession(fetched);
    } catch (e) {
      debugPrint('❌ UserProvider: Error verificando sesión inicial: $e');
      // Política fail-closed: si no podemos verificar acceso activo, nunca dejamos pasar a la home.
      await AuthService.logout();
      _user = null;
      _authStatus = AuthGateStatus.unauthenticated;
      notifyListeners();
    }
  }

  /// Activa una sesión ya verificada: arranca listener en tiempo real `snapshots()`,
  /// programa chequeo de vencimiento, carga avatar persistente y sincroniza FCM.
  Future<void> _activateVerifiedSession(UserModel verifiedUser) async {
    _user = verifiedUser;
    _blockInfo = null;
    _authStatus = AuthGateStatus.authenticatedActive;
    notifyListeners();

    _startRealtimeUserListener(verifiedUser.uid);
    _scheduleExpirationWatch(verifiedUser);

    unawaited(_loadAvatarForUser(verifiedUser.uid));
    unawaited(_syncFcmTokenSilently());
  }

  // ─── Escucha en tiempo real (`snapshots`) para expulsión instantánea ──

  void _startRealtimeUserListener(String uid) {
    _stopRealtimeUserListener();
    debugPrint('👁️ UserProvider: Iniciando listener en tiempo real para users/$uid');

    _userDocSub = AuthService.watchUserDocument(uid).listen(
      (snapshot) async {
        // Ignorar snapshots si ya no estamos autenticados
        if (_authStatus != AuthGateStatus.authenticatedActive) return;

        if (!snapshot.exists || snapshot.data() == null) {
          debugPrint('🚨 UserProvider: Documento users/$uid eliminado -> cerrando sesión');
          await _handleRealtimeRevocation(
            AccountBlockInfo(
              reason: AccountBlockReason.revoked,
              email: _user?.email,
            ),
          );
          return;
        }

        final updated = UserModel.fromJson(snapshot.data()!, docId: snapshot.id);
        _user = updated;

        if (!updated.activo) {
          debugPrint('🚨 UserProvider: Cuenta desactivada desde panel -> expulsión instantánea');
          await _handleRealtimeRevocation(
            AccountBlockInfo(
              reason: AccountBlockReason.revoked,
              email: updated.email,
              vence: updated.vence,
              plan: updated.plan,
            ),
          );
          return;
        }

        if (updated.isExpired) {
          debugPrint('🚨 UserProvider: Cuenta vencida en tiempo real -> expulsión instantánea');
          await _handleRealtimeRevocation(
            AccountBlockInfo(
              reason: AccountBlockReason.expired,
              email: updated.email,
              vence: updated.vence,
              plan: updated.plan,
            ),
          );
          return;
        }

        _scheduleExpirationWatch(updated);
        notifyListeners();
      },
      onError: (Object error) async {
        debugPrint('⚠️ UserProvider: Error en listener users/$uid: $error');
        final raw = error.toString().toLowerCase();
        if (raw.contains('permission-denied')) {
          await _handleRealtimeRevocation(
            AccountBlockInfo(
              reason: AccountBlockReason.revoked,
              email: _user?.email,
            ),
          );
        }
      },
    );
  }

  void _stopRealtimeUserListener() {
    _userDocSub?.cancel();
    _userDocSub = null;
    _expirationTimer?.cancel();
    _expirationTimer = null;
  }

  /// Si la cuenta vence mientras el usuario tiene la app abierta, la expulsa al llegar la hora exacta.
  void _scheduleExpirationWatch(UserModel user) {
    _expirationTimer?.cancel();
    final vence = user.vence;
    if (vence == null) return;

    final remaining = vence.difference(DateTime.now());
    if (remaining.isNegative || remaining == Duration.zero) {
      unawaited(_handleRealtimeRevocation(
        AccountBlockInfo(
          reason: AccountBlockReason.expired,
          email: user.email,
          vence: user.vence,
          plan: user.plan,
        ),
      ));
      return;
    }

    // Evitar overflow en Timer con duraciones muy largas (reprogramar cada 24h)
    const maxChunk = Duration(hours: 24);
    final delay = remaining > maxChunk ? maxChunk : remaining + const Duration(seconds: 1);
    _expirationTimer = Timer(delay, () {
      if (_user != null && _user!.isExpired) {
        unawaited(_handleRealtimeRevocation(
          AccountBlockInfo(
            reason: AccountBlockReason.expired,
            email: _user!.email,
            vence: _user!.vence,
            plan: _user!.plan,
          ),
        ));
      } else if (_user != null) {
        _scheduleExpirationWatch(_user!);
      }
    });
  }

  Future<void> _handleRealtimeRevocation(AccountBlockInfo info) async {
    await _forceBlockAndSignOut(info);
    _onSessionRevoked?.call();
  }

  Future<void> _forceBlockAndSignOut(AccountBlockInfo info) async {
    _stopRealtimeUserListener();
    _user = null;
    _avatarBytes = null;
    _profileImagePath = null;
    _blockInfo = info;
    _authStatus = AuthGateStatus.blocked;
    notifyListeners();

    try {
      await AuthService.logout();
    } catch (_) {}
  }

  /// Vuelve desde la pantalla "Cuenta pendiente / vencida" al formulario de login.
  void returnToLogin() {
    _blockInfo = null;
    _user = null;
    _authStatus = AuthGateStatus.unauthenticated;
    notifyListeners();
  }

  // ─── Login y Registro con Invitación ────────────────────────────

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final verifiedUser = await AuthService.signIn(email, password);
      await _activateVerifiedSession(verifiedUser);
    } on AccountAccessBlockedException catch (blocked) {
      _stopRealtimeUserListener();
      _user = null;
      _blockInfo = AccountBlockInfo(
        reason: blocked.reason,
        email: blocked.email,
        vence: blocked.vence,
        plan: blocked.plan,
      );
      _authStatus = AuthGateStatus.blocked;
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<SignUpResult> registerWithInvitation({
    required String invitationCode,
    required String email,
    required String password,
    required String nombre,
    required String apellido,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await AuthService.signUpWithInvitation(
        invitationCode: invitationCode,
        email: email,
        password: password,
        nombre: nombre,
        apellido: apellido,
      );

      if (result.requiresApproval) {
        _stopRealtimeUserListener();
        _user = null;
        _blockInfo = AccountBlockInfo(
          reason: AccountBlockReason.pending,
          email: result.user.email,
          plan: result.user.plan,
        );
        _authStatus = AuthGateStatus.blocked;
        notifyListeners();
      } else {
        await _activateVerifiedSession(result.user);
      }
      return result;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Avatar persistente en la nube (Firestore `datos/avatar`) ──

  Future<void> _loadAvatarForUser(String uid) async {
    try {
      // 1. Cargar caché local rápida si corresponde al mismo uid
      if (!kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        final cachedUid = prefs.getString(_avatarCacheUidKey);
        final cachedPath = prefs.getString(_avatarCachePathKey);
        if (cachedUid == uid && cachedPath != null) {
          final file = File(cachedPath);
          if (await file.exists()) {
            _profileImagePath = cachedPath;
            _avatarBytes = await file.readAsBytes();
            notifyListeners();
          }
        }
      }

      // 2. Sincronizar siempre desde la nube (sobrevive desinstalación y cambio de equipo)
      final remoteBytes = await AuthService.fetchUserAvatarBytes(uid);
      if (remoteBytes != null && remoteBytes.isNotEmpty) {
        _avatarBytes = remoteBytes;
        if (!kIsWeb) {
          await _writeLocalAvatarCache(uid, remoteBytes);
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('⚠️ UserProvider: Error cargando avatar: $e');
    }
  }

  Future<void> _writeLocalAvatarCache(String uid, Uint8List bytes) async {
    if (kIsWeb) return;
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final targetPath = '${appDir.path}/pivote_avatar_$uid.jpg';
      final file = File(targetPath);
      await file.writeAsBytes(bytes, flush: true);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_avatarCachePathKey, targetPath);
      await prefs.setString(_avatarCacheUidKey, uid);
      _profileImagePath = targetPath;
    } catch (e) {
      debugPrint('⚠️ UserProvider: Error guardando caché local de avatar: $e');
    }
  }

  /// Elige un nuevo logo/foto, lo comprime y lo guarda de forma persistente en Firestore.
  /// Nunca se pierde al cerrar sesión ni al desinstalar la app.
  Future<bool> updateProfileImage() async {
    final uid = AuthService.currentUserId;
    if (uid == null) return false;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 384,
      maxHeight: 384,
      imageQuality: 72,
    );

    if (pickedFile == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final bytes = await pickedFile.readAsBytes();
      await AuthService.saveUserAvatarBytes(bytes);

      _avatarBytes = bytes;
      if (!kIsWeb) {
        await _writeLocalAvatarCache(uid, bytes);
      }
      notifyListeners();
      return true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Elimina el logo/avatar de la nube y del dispositivo (solo cuando el usuario lo pide).
  Future<void> removeProfileImage() async {
    final uid = AuthService.currentUserId;
    if (uid == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      await AuthService.deleteUserAvatar();
      await _clearLocalAvatarCache();
      _avatarBytes = null;
      _profileImagePath = null;
      if (_user != null) {
        _user = _user!.copyWith(photoUrl: null);
      }
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _clearLocalAvatarCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!kIsWeb) {
        final cachedPath = prefs.getString(_avatarCachePathKey);
        if (cachedPath != null) {
          final file = File(cachedPath);
          if (await file.exists()) {
            await file.delete();
          }
        }
      }
      await prefs.remove(_avatarCachePathKey);
      await prefs.remove(_avatarCacheUidKey);
      await prefs.remove('profile_image_path'); // Limpieza legacy
    } catch (e) {
      debugPrint('⚠️ UserProvider: Error limpiando caché local de avatar: $e');
    }
  }

  // ─── Otros métodos de cuenta ────────────────────────────────────

  Future<void> _syncFcmTokenSilently() async {
    if (kIsWeb) return;
    try {
      final token = await NotificationService.getToken();
      if (token != null && token.isNotEmpty) {
        await AuthService.updateFcmToken(token);
      }
    } catch (e) {
      debugPrint('⚠️ UserProvider: Error sincronizando token FCM: $e');
    }
  }

  Future<void> updatePassword(
    String currentPassword,
    String newPassword,
  ) async {
    _isLoading = true;
    notifyListeners();
    try {
      await AuthService.updatePassword(currentPassword, newPassword);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshUser() async {
    final uid = AuthService.currentUserId;
    if (uid == null) return;

    final fetched = await AuthService.getUser(forceServer: true);
    if (fetched == null || !fetched.hasValidAccess) {
      await _handleRealtimeRevocation(
        AccountBlockInfo(
          reason: fetched == null
              ? AccountBlockReason.missingProfile
              : (!fetched.activo
                  ? AccountBlockReason.pending
                  : AccountBlockReason.expired),
          email: fetched?.email ?? _user?.email,
          vence: fetched?.vence,
          plan: fetched?.plan,
        ),
      );
      return;
    }

    _user = fetched;
    notifyListeners();
  }

  /// Limpia estado en memoria y caché local al cerrar sesión.
  /// NO borra avatar ni preferencias guardadas en la nube.
  Future<void> clearUser() async {
    _stopRealtimeUserListener();
    _user = null;
    _avatarBytes = null;
    _profileImagePath = null;
    _blockInfo = null;
    _authStatus = AuthGateStatus.unauthenticated;
    await _clearLocalAvatarCache();
    notifyListeners();
  }

  String get fullName {
    if (_user == null) return 'Usuario';
    return '${_user!.nombre} ${_user!.apellido}'.trim();
  }

  bool get hasProfileImage {
    return (_avatarBytes != null && _avatarBytes!.isNotEmpty) ||
        (_profileImagePath != null && _profileImagePath!.isNotEmpty) ||
        (_user?.photoUrl != null && _user!.photoUrl!.isNotEmpty);
  }

  @override
  void dispose() {
    _stopRealtimeUserListener();
    super.dispose();
  }
}
