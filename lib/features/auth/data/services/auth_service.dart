import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pivote/core/services/firebase_service.dart';
import 'package:pivote/features/auth/data/models/user_model.dart';
import 'package:pivote/features/auth/data/services/device_identity_service.dart';

/// Excepción controlada del flujo de autenticación privada de Pivote.
class PivoteAuthException implements Exception {
  final String code;
  final String message;

  const PivoteAuthException({required this.code, required this.message});

  @override
  String toString() => 'PivoteAuthException(code: $code, message: $message)';
}

/// Excepción emitida cuando el usuario autenticó en Firebase Auth pero su cuenta
/// no tiene acceso habilitado (pendiente de aprobación, vencida o desactivada).
class AccountAccessBlockedException implements Exception {
  final AccountBlockReason reason;
  final String? email;
  final DateTime? vence;
  final String? plan;
  final int? maxDispositivos;
  final int? linkedDevicesCount;

  const AccountAccessBlockedException({
    required this.reason,
    this.email,
    this.vence,
    this.plan,
    this.maxDispositivos,
    this.linkedDevicesCount,
  });

  @override
  String toString() =>
      'AccountAccessBlockedException(reason: $reason, email: $email, vence: $vence, maxDispositivos: $maxDispositivos)';
}

/// Resultado del registro con código de invitación.
class SignUpResult {
  final UserModel user;
  final bool requiresApproval;

  const SignUpResult({
    required this.user,
    required this.requiresApproval,
  });
}

/// Servicio de autenticación privada basado en Firebase Auth + Firestore Security Rules.
///
/// - `users/{uid}` almacena estado de acceso (`activo`, `vence`, `plan`, `deviceId`, `maxDispositivos`).
/// - `invitaciones/{codigo}` valida y canjea códigos de invitación de forma atómica.
/// - `users/{uid}/datos/avatar` persiste el logo/avatar del usuario en Firestore (plan Spark gratuito).
class AuthService {
  static FirebaseAuth get _auth => FirebaseAuth.instance;
  static FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  static const String _legacySessionKey = 'pivote_session_uid';
  static const String _legacySessionUserKey = 'pivote_session_user';
  static const int maxAvatarBase64Length = 340000; // Margen bajo el límite 350000 de Rules

  /// UID actual de Firebase Auth (fuente real de `request.auth.uid`).
  static String? get currentUserId {
    if (!FirebaseService.isInitialized) return null;
    return _auth.currentUser?.uid;
  }

  /// Usuario actual de Firebase Auth.
  static User? get currentFirebaseUser {
    if (!FirebaseService.isInitialized) return null;
    return _auth.currentUser;
  }

  /// Inicializa sesión y limpia rastros de la antigua autenticación custom.
  static Future<void> initSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(_legacySessionKey)) {
        await prefs.remove(_legacySessionKey);
      }
      if (prefs.containsKey(_legacySessionUserKey)) {
        await prefs.remove(_legacySessionUserKey);
      }
      debugPrint('🔵 AuthService: Firebase Auth uid=$currentUserId');
    } catch (e) {
      debugPrint('⚠️ AuthService: Error limpiando sesión legada: $e');
    }
  }

  /// Verifica si hay una sesión activa en Firebase Auth.
  static Future<bool> isLoggedIn() async {
    if (!FirebaseService.isInitialized) return false;
    return _auth.currentUser != null;
  }

  // ─── Registro con código de invitación (Transacción Atómica) ────

  /// Registra un usuario nuevo validando y marcando como usado `invitaciones/{codigo}`
  /// en la misma transacción atómica que crea `users/{uid}`.
  ///
  /// Política de activación (aplicada y exigida por Firestore Rules):
  /// - Por defecto (`autoActivar != true`): se crea con `activo: false` hasta aprobación manual.
  /// - Si el admin creó la invitación con `autoActivar: true` y `venceAcceso` futuro:
  ///   se crea con `activo: true` y exactamente esa fecha de vencimiento.
  static Future<SignUpResult> signUpWithInvitation({
    required String invitationCode,
    required String email,
    required String password,
    required String nombre,
    required String apellido,
  }) async {
    _requireFirebase();

    final normalizedCode = invitationCode.trim().toUpperCase();
    final normalizedEmail = email.trim().toLowerCase();
    final cleanNombre = nombre.trim();
    final cleanApellido = apellido.trim();

    if (normalizedCode.length < 6 ||
        normalizedCode.length > 64 ||
        normalizedCode.contains('/')) {
      throw const PivoteAuthException(
        code: 'invalid-invitation',
        message: 'Ingresá un código de invitación válido.',
      );
    }
    if (cleanNombre.isEmpty || cleanApellido.isEmpty) {
      throw const PivoteAuthException(
        code: 'invalid-name',
        message: 'Ingresá tu nombre y apellido.',
      );
    }
    if (!UserModel.isValidEmail(normalizedEmail)) {
      throw const PivoteAuthException(
        code: 'invalid-email',
        message: 'Ingresá un correo electrónico válido.',
      );
    }
    if (password.length < 6) {
      throw const PivoteAuthException(
        code: 'weak-password',
        message: 'La contraseña debe tener al menos 6 caracteres.',
      );
    }

    UserCredential? credential;
    bool createdInAuth = false;

    try {
      debugPrint('🔵 AuthService: Creando cuenta Auth para $normalizedEmail...');
      credential = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      createdInAuth = true;

      final authUser = credential.user!;
      final uid = authUser.uid;
      final authEmail = (authUser.email ?? normalizedEmail).toLowerCase();

      // Asegura que el ID Token recién emitido esté disponible antes de la transacción.
      await authUser.getIdToken(true);

      bool willAutoActivate = false;
      DateTime? assignedVence;
      String assignedPlan = 'standard';
      int assignedMaxDevices = 1;

      final invRef = FirebaseService.invitacionesCollection.doc(normalizedCode);
      final userRef = FirebaseService.usersCollection.doc(uid);

      await _firestore.runTransaction((tx) async {
        final invSnap = await tx.get(invRef);

        if (!invSnap.exists || invSnap.data() == null) {
          throw const PivoteAuthException(
            code: 'invalid-invitation',
            message: 'El código de invitación no existe. Verificalo e intentá otra vez.',
          );
        }

        final invData = invSnap.data()!;
        if (invData['usado'] == true) {
          throw const PivoteAuthException(
            code: 'invitation-used',
            message: 'Este código de invitación ya fue utilizado.',
          );
        }

        final invVenceTs = invData['vence'];
        if (invVenceTs is! Timestamp ||
            !invVenceTs.toDate().isAfter(DateTime.now())) {
          throw const PivoteAuthException(
            code: 'invitation-expired',
            message: 'Este código de invitación venció. Pedí uno nuevo al administrador.',
          );
        }

        final autoActivar = invData['autoActivar'] == true;
        final venceAccesoTs = invData['venceAcceso'];
        final hasValidAutoExpiration = autoActivar &&
            venceAccesoTs is Timestamp &&
            venceAccesoTs.toDate().isAfter(DateTime.now());

        willAutoActivate = hasValidAutoExpiration;
        assignedVence = hasValidAutoExpiration ? venceAccesoTs.toDate() : null;
        assignedPlan = (invData['plan'] as String?) ?? 'standard';
        assignedMaxDevices = (invData['maxDispositivos'] as num?)?.toInt() ?? 1;

        // 1. Marcar invitación como usada atómicamente
        tx.update(invRef, {
          'usado': true,
          'usadoPor': uid,
          'usadoEn': FieldValue.serverTimestamp(),
        });

        // 2. Crear `users/{uid}` cumpliendo exactamente el contrato de las Rules
        tx.set(userRef, {
          'uid': uid,
          'email': authEmail,
          'nombre': cleanNombre,
          'apellido': cleanApellido,
          'activo': willAutoActivate,
          'plan': assignedPlan,
          'vence': willAutoActivate
              ? venceAccesoTs
              : FieldValue.serverTimestamp(),
          'deviceId': null,
          'dispositivos': <String>[],
          'maxDispositivos': assignedMaxDevices,
          'photoUrl': null,
          'fcmToken': null,
          'codigoInvitacion': normalizedCode,
          'creadoEn': FieldValue.serverTimestamp(),
          'actualizadoEn': FieldValue.serverTimestamp(),
        });
      });

      // Actualizar displayName en Auth (no crítico si falla)
      try {
        await authUser.updateDisplayName('$cleanNombre $cleanApellido');
      } catch (_) {}

      final createdModel = UserModel(
        uid: uid,
        nombre: cleanNombre,
        apellido: cleanApellido,
        email: authEmail,
        activo: willAutoActivate,
        plan: assignedPlan,
        vence: assignedVence,
        maxDispositivos: assignedMaxDevices,
        codigoInvitacion: normalizedCode,
        creadoEn: DateTime.now(),
      );

      // Si requiere aprobación manual (`activo == false`), cerramos sesión inmediatamente:
      // nunca queda una sesión abierta esperando en segundo plano ni entra a la home.
      if (!willAutoActivate) {
        await _auth.signOut();
        debugPrint('🔒 AuthService: Registro completado (pendiente de aprobación). Sesión cerrada.');
        return SignUpResult(user: createdModel, requiresApproval: true);
      }

      // Si el admin marcó la invitación como pre-aprobada (`autoActivar: true`), releer y vincular dispositivo
      final verified = await fetchUserFromServer(uid);
      if (verified == null || !verified.hasValidAccess) {
        await _auth.signOut();
        return SignUpResult(user: createdModel, requiresApproval: true);
      }

      final boundUser = await verifyAndBindDevice(verified);

      debugPrint('✅ AuthService: Registro pre-aprobado exitoso para $uid');
      return SignUpResult(user: boundUser, requiresApproval: false);
    } on PivoteAuthException {
      if (createdInAuth) {
        await _rollbackCreatedAuthUser(credential?.user);
      }
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } on FirebaseException catch (e) {
      if (createdInAuth) {
        await _rollbackCreatedAuthUser(credential?.user);
      }
      if (e.code == 'permission-denied') {
        throw const PivoteAuthException(
          code: 'invalid-invitation',
          message: 'El código de invitación es inválido, ya fue usado o venció.',
        );
      }
      throw PivoteAuthException(
        code: e.code,
        message: 'No se pudo completar el registro. Verificá tu conexión e intentá de nuevo.',
      );
    } catch (e) {
      if (createdInAuth) {
        await _rollbackCreatedAuthUser(credential?.user);
      }
      debugPrint('❌ AuthService: Error inesperado en registro: $e');
      throw const PivoteAuthException(
        code: 'signup-error',
        message: 'No se pudo crear la cuenta. Intentá nuevamente.',
      );
    }
  }

  /// Elimina el usuario recién creado en Firebase Auth si falló el canje de invitación
  /// para que el correo no quede huérfano ni bloqueado.
  static Future<void> _rollbackCreatedAuthUser(User? user) async {
    try {
      if (user != null) {
        await user.delete();
        debugPrint('↩️ AuthService: Rollback de cuenta Auth tras código inválido');
      }
    } catch (e) {
      debugPrint('⚠️ AuthService: No se pudo eliminar cuenta Auth en rollback: $e');
      try {
        await _auth.signOut();
      } catch (_) {}
    }
  }

  // ─── Inicio de sesión con verificación obligatoria en servidor ──

  /// Autentica con Firebase Auth y valida `users/{uid}` directamente desde el servidor.
  /// Si `activo == false`, el documento no existe o `vence <= ahora`, CIERRA SESIÓN
  /// y lanza [AccountAccessBlockedException]. Nunca deja pasar a la home.
  static Future<UserModel> signIn(String email, String password) async {
    _requireFirebase();

    final normalizedEmail = email.trim().toLowerCase();

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      final uid = credential.user!.uid;
      await credential.user!.getIdToken(true);

      final user = await fetchUserFromServer(uid);

      if (user == null) {
        await _auth.signOut();
        throw AccountAccessBlockedException(
          reason: AccountBlockReason.missingProfile,
          email: normalizedEmail,
        );
      }

      if (!user.activo) {
        await _auth.signOut();
        throw AccountAccessBlockedException(
          reason: AccountBlockReason.pending,
          email: user.email,
          vence: user.vence,
          plan: user.plan,
        );
      }

      if (user.isExpired) {
        await _auth.signOut();
        throw AccountAccessBlockedException(
          reason: AccountBlockReason.expired,
          email: user.email,
          vence: user.vence,
          plan: user.plan,
        );
      }

      // Control de dispositivos (ETAPA 3): verificar o vincular `deviceId` respetando `maxDispositivos`
      final boundUser = await verifyAndBindDevice(user);

      debugPrint('✅ AuthService: Login y dispositivo verificados en servidor para $uid');
      return boundUser;
    } on AccountAccessBlockedException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } on FirebaseException catch (e) {
      await _auth.signOut();
      throw PivoteAuthException(
        code: e.code,
        message: 'No pudimos verificar el estado de tu cuenta. Revisá tu conexión.',
      );
    }
  }

  // ─── Control de dispositivos (ETAPA 3) ──────────────────────────

  /// Verifica que el dispositivo actual esté autorizado para [user] o lo vincula
  /// en `users/{uid}` si aún hay cupo (`deviceId == null` o `dispositivos.length < maxDispositivos`).
  ///
  /// Seguridad del lado del servidor:
  /// Las Firestore Rules (`vincularDispositivoPropio`) garantizan que ningún cliente
  /// pueda sobrescribir un `deviceId` ya vinculado ni exceder `maxDispositivos`.
  /// Si se supera el límite, CIERRA SESIÓN y lanza [AccountAccessBlockedException].
  static Future<UserModel> verifyAndBindDevice(UserModel user) async {
    _requireFirebase();
    final identity = await DeviceIdentityService.getDeviceIdentity();

    // 1. Dispositivo ya autorizado -> solo refrescar metadatos legibles en preferencias
    if (user.isDeviceAuthorized(identity.id)) {
      _saveDeviceMetadataSilently(user.uid, identity);
      return user;
    }

    // 2. Cupo agotado -> bloquear nuevo dispositivo y cerrar sesión
    if (!user.hasAvailableDeviceSlot) {
      await _auth.signOut();
      throw AccountAccessBlockedException(
        reason: AccountBlockReason.deviceLimitReached,
        email: user.email,
        vence: user.vence,
        plan: user.plan,
        maxDispositivos: user.maxDispositivos,
        linkedDevicesCount: user.effectiveDevices.length,
      );
    }

    // 3. Hay cupo disponible -> vincular respetando exactamente el contrato de Firestore Rules
    final isFirstBind = user.deviceId == null || user.deviceId!.isEmpty;
    final nextPrimaryDeviceId = isFirstBind ? identity.id : user.deviceId!;
    final nextDevices = isFirstBind
        ? <String>[identity.id]
        : <String>[...user.effectiveDevices, identity.id];

    try {
      await FirebaseService.usersCollection.doc(user.uid).update({
        'deviceId': nextPrimaryDeviceId,
        'dispositivos': nextDevices,
        'actualizadoEn': FieldValue.serverTimestamp(),
      });

      _saveDeviceMetadataSilently(user.uid, identity);
      debugPrint(
        '📱 AuthService: Dispositivo vinculado (${identity.label}) -> ${nextDevices.length}/${user.maxDispositivos}',
      );

      return user.copyWith(
        deviceId: nextPrimaryDeviceId,
        dispositivos: nextDevices,
      );
    } on FirebaseException catch (e) {
      // Si dos dispositivos compitieron al mismo tiempo o las Rules rechazaron el cupo
      if (e.code == 'permission-denied') {
        await _auth.signOut();
        throw AccountAccessBlockedException(
          reason: AccountBlockReason.deviceLimitReached,
          email: user.email,
          vence: user.vence,
          plan: user.plan,
          maxDispositivos: user.maxDispositivos,
          linkedDevicesCount: user.maxDispositivos,
        );
      }
      rethrow;
    }
  }

  /// Guarda el modelo y sistema operativo legibles en `users/{uid}/datos/preferencias`
  /// para que el panel admin aparte pueda mostrar el nombre del equipo junto al `deviceId`.
  static void _saveDeviceMetadataSilently(
    String uid,
    DeviceIdentity identity,
  ) {
    FirebaseService.userPrefsDoc(uid).set({
      'ultimoDispositivo': {
        ...identity.toMetadataMap(),
        'ultimaConexion': FieldValue.serverTimestamp(),
      },
      'dispositivosInfo': {
        identity.id: {
          ...identity.toMetadataMap(),
          'ultimaConexion': FieldValue.serverTimestamp(),
        },
      },
      'actualizadoEn': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)).catchError((Object e) {
      debugPrint('⚠️ AuthService: Error guardando metadata de dispositivo: $e');
    });
  }

  // ─── Lectura y escucha en tiempo real de `users/{uid}` ──────────

  /// Lee `users/{uid}` priorizando el servidor para evitar saltear bloqueos con caché local.
  static Future<UserModel?> fetchUserFromServer(String uid) async {
    _requireFirebase();
    final doc = await FirebaseService.usersCollection
        .doc(uid)
        .get(const GetOptions(source: Source.server));
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromJson(doc.data()!, docId: doc.id);
  }

  /// Obtiene el usuario actual (intenta servidor primero; si no hay red temporal, cae a caché).
  static Future<UserModel?> getUser({bool forceServer = true}) async {
    final uid = currentUserId;
    if (uid == null) return null;

    _requireFirebase();
    try {
      final doc = await FirebaseService.usersCollection.doc(uid).get(
            GetOptions(
              source: forceServer ? Source.server : Source.serverAndCache,
            ),
          );
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromJson(doc.data()!, docId: doc.id);
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable' && forceServer) {
        final cached = await FirebaseService.usersCollection
            .doc(uid)
            .get(const GetOptions(source: Source.cache));
        if (cached.exists && cached.data() != null) {
          return UserModel.fromJson(cached.data()!, docId: cached.id);
        }
      }
      rethrow;
    }
  }

  /// Stream en tiempo real sobre `users/{uid}` para expulsión inmediata si se desactiva o vence.
  static Stream<DocumentSnapshot<Map<String, dynamic>>> watchUserDocument(
    String uid,
  ) {
    return FirebaseService.usersCollection.doc(uid).snapshots();
  }

  // ─── Avatar persistente en la nube (`users/{uid}/datos/avatar`) ─

  /// Guarda el avatar comprimido en Firestore (100% gratis en plan Spark).
  /// Sobrevive a cierres de sesión y desinstalaciones de la app.
  static Future<void> saveUserAvatarBytes(Uint8List bytes) async {
    final uid = currentUserId;
    if (uid == null) {
      throw const PivoteAuthException(
        code: 'no-current-user',
        message: 'No hay una sesión activa.',
      );
    }
    _requireFirebase();

    final encoded = base64Encode(bytes);
    if (encoded.length > maxAvatarBase64Length) {
      throw const PivoteAuthException(
        code: 'avatar-too-large',
        message: 'La imagen es demasiado pesada. Elegí una foto más liviana.',
      );
    }

    await FirebaseService.userAvatarDoc(uid).set({
      'base64': encoded,
      'mimeType': 'image/jpeg',
      'actualizadoEn': FieldValue.serverTimestamp(),
    });
    debugPrint('✅ AuthService: Avatar guardado en Firestore (${bytes.length} bytes)');
  }

  /// Recupera el avatar guardado en la nube para el usuario actual.
  static Future<Uint8List?> fetchUserAvatarBytes(String uid) async {
    try {
      _requireFirebase();
      final doc = await FirebaseService.userAvatarDoc(uid).get();
      if (!doc.exists || doc.data() == null) return null;
      final raw = doc.data()!['base64'] as String?;
      if (raw == null || raw.isEmpty) return null;
      return base64Decode(raw);
    } catch (e) {
      debugPrint('⚠️ AuthService: No se pudo cargar avatar remoto: $e');
      return null;
    }
  }

  /// Borra el avatar de la nube (solo cuando el usuario lo solicita explícitamente).
  static Future<void> deleteUserAvatar() async {
    final uid = currentUserId;
    if (uid == null) return;
    _requireFirebase();

    await FirebaseService.userAvatarDoc(uid).delete();
    try {
      await FirebaseService.usersCollection.doc(uid).update({
        'photoUrl': null,
        'actualizadoEn': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
    debugPrint('🗑️ AuthService: Avatar eliminado de la nube por el usuario');
  }

  // ─── Perfil, contraseña y token FCM ─────────────────────────────

  /// Actualiza únicamente los campos seguros del perfil permitidos por Rules (`nombre`, `apellido`).
  static Future<void> updateUser(UserModel user) async {
    final uid = currentUserId;
    if (uid == null) return;

    _requireFirebase();
    final cleanNombre = user.nombre.trim();
    final cleanApellido = user.apellido.trim();

    if (cleanNombre.isEmpty || cleanApellido.isEmpty) {
      throw const PivoteAuthException(
        code: 'invalid-name',
        message: 'Ingresá tu nombre y apellido.',
      );
    }

    await FirebaseService.usersCollection.doc(uid).update({
      'nombre': cleanNombre,
      'apellido': cleanApellido,
      'actualizadoEn': FieldValue.serverTimestamp(),
    });

    try {
      await _auth.currentUser?.updateDisplayName('$cleanNombre $cleanApellido');
    } catch (_) {}
  }

  /// Cambia la contraseña real en Firebase Auth tras reautenticar.
  static Future<void> updatePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final user = currentFirebaseUser;
    if (user == null || user.email == null) {
      throw const PivoteAuthException(
        code: 'no-current-user',
        message: 'No hay usuario autenticado.',
      );
    }

    try {
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);
      debugPrint('✅ AuthService: Contraseña actualizada en Firebase Auth');
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    }
  }

  /// Envía correo real de recuperación de contraseña vía Firebase Auth.
  static Future<void> sendPasswordResetEmail(String email) async {
    _requireFirebase();
    final normalized = email.trim().toLowerCase();
    if (!UserModel.isValidEmail(normalized)) {
      throw const PivoteAuthException(
        code: 'invalid-email',
        message: 'Ingresá un correo electrónico válido.',
      );
    }
    try {
      await _auth.sendPasswordResetEmail(email: normalized);
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    }
  }

  /// Guarda el token FCM en `users/{uid}` (allowlisted por Rules) y en `datos/preferencias`.
  static Future<void> updateFcmToken(String token) async {
    final uid = currentUserId;
    if (uid == null || token.isEmpty) return;

    try {
      _requireFirebase();
      await FirebaseService.usersCollection.doc(uid).update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        'notificationsDisabled': false,
        'actualizadoEn': FieldValue.serverTimestamp(),
      });
      await FirebaseService.userPrefsDoc(uid).set({
        'fcmToken': token,
        'actualizadoEn': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('✅ AuthService: Token FCM guardado en la nube');
    } catch (e) {
      debugPrint('⚠️ AuthService: Error actualizando token FCM: $e');
    }
  }

  /// Cierra sesión de Firebase Auth (sin borrar datos persistentes de la nube).
  static Future<void> logout() async {
    try {
      if (FirebaseService.isInitialized) {
        await _auth.signOut();
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_legacySessionKey);
      await prefs.remove(_legacySessionUserKey);
      debugPrint('✅ AuthService: Sesión cerrada en Firebase Auth');
    } catch (e) {
      debugPrint('❌ AuthService: Error al cerrar sesión: $e');
      rethrow;
    }
  }

  // ─── Helpers y mapeo de errores ─────────────────────────────────

  static void _requireFirebase() {
    if (!FirebaseService.isInitialized) {
      throw const PivoteAuthException(
        code: 'firebase-not-initialized',
        message:
            'No se pudo conectar al servidor. Revisá tu conexión e intentá de nuevo.',
      );
    }
  }

  static PivoteAuthException _mapFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return const PivoteAuthException(
          code: 'email-already-in-use',
          message: 'Este correo ya está registrado. Probá iniciar sesión.',
        );
      case 'invalid-email':
        return const PivoteAuthException(
          code: 'invalid-email',
          message: 'El correo electrónico no tiene un formato válido.',
        );
      case 'weak-password':
        return const PivoteAuthException(
          code: 'weak-password',
          message: 'La contraseña es demasiado débil (mínimo 6 caracteres).',
        );
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return const PivoteAuthException(
          code: 'invalid-credential',
          message: 'Correo o contraseña incorrectos.',
        );
      case 'user-disabled':
        return const PivoteAuthException(
          code: 'user-disabled',
          message: 'Tu cuenta fue deshabilitada por el administrador.',
        );
      case 'too-many-requests':
        return const PivoteAuthException(
          code: 'too-many-requests',
          message: 'Demasiados intentos seguidos. Esperá unos minutos e intentá otra vez.',
        );
      case 'network-request-failed':
        return const PivoteAuthException(
          code: 'network-request-failed',
          message: 'Sin conexión a internet. Revisá tu red e intentá nuevamente.',
        );
      default:
        return PivoteAuthException(
          code: e.code,
          message: e.message ?? 'Error de autenticación. Intentá nuevamente.',
        );
    }
  }

  static String getErrorMessage(dynamic error) {
    if (error is PivoteAuthException) return error.message;
    if (error is FirebaseAuthException) {
      return _mapFirebaseAuthException(error).message;
    }
    if (error is AccountAccessBlockedException) {
      switch (error.reason) {
        case AccountBlockReason.pending:
          return 'Tu cuenta está pendiente de aprobación por el administrador.';
        case AccountBlockReason.expired:
          return 'Tu plan venció. Contactá al administrador para renovarlo.';
        case AccountBlockReason.revoked:
          return 'Tu acceso fue desactivado por el administrador.';
        case AccountBlockReason.missingProfile:
          return 'Tu cuenta no tiene perfil activo asignado.';
        case AccountBlockReason.deviceLimitReached:
          return 'Esta cuenta ya alcanzó el límite máximo de dispositivos autorizados.';
        case AccountBlockReason.deviceRevoked:
          return 'Este dispositivo fue desvinculado por el administrador.';
      }
    }
    final raw = error.toString().toLowerCase();
    if (raw.contains('network') ||
        raw.contains('unavailable') ||
        raw.contains('connection')) {
      return 'Error de conexión. Revisá tu internet e intentá de nuevo.';
    }
    if (raw.contains('permission-denied')) {
      return 'Acceso denegado por el servidor.';
    }
    return 'Ocurrió un error inesperado. Intentá de nuevo.';
  }
}
