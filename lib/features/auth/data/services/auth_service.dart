import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pivote/features/auth/data/models/user_model.dart';
import 'package:pivote/core/services/firebase_service.dart';

/// Custom authentication exception for the Pivote auth system.
class PivoteAuthException implements Exception {
  final String code;
  final String message;
  PivoteAuthException({required this.code, required this.message});

  @override
  String toString() => 'PivoteAuthException(code: $code, message: $message)';
}

/// Fully custom authentication service for Pivote Studio.
/// Uses Firestore 'usuarios' collection as the user database.
/// Passwords are hashed with SHA-256 + random salt.
/// Session is managed via SharedPreferences (no Firebase Auth).
class AuthService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _usersCollection = 'usuarios';
  static const String _sessionKey = 'pivote_session_uid';
  static const String _sessionUserKey = 'pivote_session_user';

  // Cached current user ID for synchronous access
  static String? _cachedUid;

  /// Get current user ID or null (synchronous, from cache)
  static String? get currentUserId => _cachedUid;

  /// Initialize session from SharedPreferences (call once at app start)
  static Future<void> initSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedUid = prefs.getString(_sessionKey);
      debugPrint('🔵 AuthService: Session initialized, uid=$_cachedUid');
    } catch (e) {
      debugPrint('❌ AuthService: Error initializing session: $e');
    }
  }

  /// Check if a user session exists
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString(_sessionKey);
    _cachedUid = uid;
    return uid != null && uid.isNotEmpty;
  }

  // ─── Password Hashing ───────────────────────────────────────────

  /// Generate a random 16-byte salt
  static String _generateSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Encode(saltBytes);
  }

  /// Hash a password with SHA-256 using a salt
  static String _hashPassword(String password, String salt) {
    final bytes = utf8.encode('$salt:$password');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verify a password against a stored hash and salt
  static bool _verifyPassword(String password, String storedHash, String salt) {
    final computedHash = _hashPassword(password, salt);
    return computedHash == storedHash;
  }

  // ─── Sign Up ────────────────────────────────────────────────────

  /// Register a new user with email, password, name and lastName.
  /// Stores user data in the 'usuarios' Firestore collection.
  static Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
    required String lastName,
  }) async {
    try {
      _requireFirebase();
      debugPrint('🔵 AuthService: Starting sign-up for $email...');

      final normalizedEmail = email.trim().toLowerCase();

      // 1. Check if email is already registered
      final existing = await _firestore
          .collection(_usersCollection)
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        throw PivoteAuthException(
          code: 'email-already-in-use',
          message: 'Este correo electrónico ya está registrado.',
        );
      }

      // 2. Generate unique user ID
      final uid = _firestore.collection(_usersCollection).doc().id;

      // 3. Hash the password
      final salt = _generateSalt();
      final hashedPassword = _hashPassword(password, salt);

      // 4. Create user document
      final now = DateTime.now().toIso8601String();
      final userData = {
        'uid': uid,
        'name': name.trim(),
        'lastName': lastName.trim(),
        'email': normalizedEmail,
        'passwordHash': hashedPassword,
        'passwordSalt': salt,
        'isVip': false,
        'userType': 'standard',
        'isSuspended': false,
        'fcmToken': null,
        'favorites': <String>[],
        'createdAt': now,
        'updatedAt': now,
      };

      await _firestore.collection(_usersCollection).doc(uid).set(userData);
      debugPrint('✅ AuthService: User document created: $uid');

      // 5. Save session locally
      await _saveSession(uid, userData);

      // 6. Return the user model
      return UserModel.fromJson(userData);
    } on PivoteAuthException {
      rethrow;
    } catch (e) {
      debugPrint('❌ AuthService: Error in sign-up: $e');
      throw PivoteAuthException(
        code: 'signup-error',
        message: 'Error al crear la cuenta. Inténtalo de nuevo.',
      );
    }
  }

  // ─── Sign In ────────────────────────────────────────────────────

  /// Sign in with email and password.
  static Future<UserModel> signIn(String email, String password) async {
    try {
      _requireFirebase();
      debugPrint('🔵 AuthService: Starting sign-in for $email...');

      final normalizedEmail = email.trim().toLowerCase();

      // 1. Find user by email
      final query = await _firestore
          .collection(_usersCollection)
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        throw PivoteAuthException(
          code: 'user-not-found',
          message: 'No encontramos una cuenta con este correo electrónico.',
        );
      }

      final doc = query.docs.first;
      final data = doc.data();

      // 2. Verify password
      final storedHash = data['passwordHash'] as String? ?? '';
      final storedSalt = data['passwordSalt'] as String? ?? '';

      if (!_verifyPassword(password, storedHash, storedSalt)) {
        throw PivoteAuthException(
          code: 'wrong-password',
          message: 'La contraseña es incorrecta.',
        );
      }

      debugPrint('✅ AuthService: Password verified for ${data['uid']}');

      // 3. Update last login timestamp
      await doc.reference.update({
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // 4. Save session locally
      await _saveSession(data['uid'] as String, data);

      // 5. Return user model
      return UserModel.fromJson(data);
    } on PivoteAuthException {
      rethrow;
    } catch (e) {
      debugPrint('❌ AuthService: Error in sign-in: $e');
      throw PivoteAuthException(
        code: 'signin-error',
        message: 'Error al iniciar sesión. Inténtalo de nuevo.',
      );
    }
  }

  // ─── Session Management ─────────────────────────────────────────

  /// Save session to SharedPreferences
  static Future<void> _saveSession(
      String uid, Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionKey, uid);

      // Cache user data locally for fast loading
      final safeData = Map<String, dynamic>.from(userData);
      safeData.remove('passwordHash');
      safeData.remove('passwordSalt');
      await prefs.setString(_sessionUserKey, jsonEncode(safeData));

      _cachedUid = uid;
      debugPrint('✅ AuthService: Session saved for $uid');
    } catch (e) {
      debugPrint('❌ AuthService: Error saving session: $e');
    }
  }

  /// Logout — clear session
  static Future<void> logout() async {
    try {
      debugPrint('🔵 AuthService: Starting logout...');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionKey);
      await prefs.remove(_sessionUserKey);
      _cachedUid = null;
      debugPrint('✅ AuthService: Logout completed');
    } catch (e) {
      debugPrint('❌ AuthService: Error during logout: $e');
      rethrow;
    }
  }

  // ─── User Data ──────────────────────────────────────────────────

  /// Get current user model from Firestore
  static Future<UserModel?> getUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString(_sessionKey);

      if (uid == null || uid.isEmpty) {
        debugPrint('⚠️ AuthService: No session found');
        return null;
      }

      _cachedUid = uid;

      // Try loading from Firestore first
      _requireFirebase();
      debugPrint('🔵 AuthService: Fetching user data from Firestore: $uid');

      final doc =
          await _firestore.collection(_usersCollection).doc(uid).get();

      if (doc.exists && doc.data() != null) {
        debugPrint('✅ AuthService: User data retrieved from Firestore');
        final data = doc.data()!;
        return UserModel.fromJson(data);
      }

      // Fallback: load from local cache
      final cachedUserJson = prefs.getString(_sessionUserKey);
      if (cachedUserJson != null) {
        debugPrint('⚠️ AuthService: Using cached user data');
        return UserModel.fromJsonString(cachedUserJson);
      }

      return null;
    } catch (e) {
      debugPrint('❌ AuthService: Error getting user data: $e');

      // Last resort: try local cache
      try {
        final prefs = await SharedPreferences.getInstance();
        final cachedUserJson = prefs.getString(_sessionUserKey);
        if (cachedUserJson != null) {
          return UserModel.fromJsonString(cachedUserJson);
        }
      } catch (_) {}

      return null;
    }
  }

  /// Update user information in Firestore
  static Future<void> updateUser(UserModel user) async {
    if (_cachedUid == null) {
      debugPrint('⚠️ AuthService: No current user to update');
      return;
    }

    try {
      _requireFirebase();
      debugPrint('🔵 AuthService: Updating user information...');

      final updateData = {
        'name': user.name,
        'lastName': user.lastName,
        'email': user.email,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (user.photoUrl != null) {
        updateData['photoUrl'] = user.photoUrl!;
      }

      await _firestore
          .collection(_usersCollection)
          .doc(_cachedUid)
          .update(updateData);

      // Update local cache
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_sessionUserKey);
      if (cachedJson != null) {
        final cached = jsonDecode(cachedJson) as Map<String, dynamic>;
        cached.addAll(updateData);
        await prefs.setString(_sessionUserKey, jsonEncode(cached));
      }

      debugPrint('✅ AuthService: User information updated successfully');
    } catch (e) {
      debugPrint('❌ AuthService: Error updating user: $e');
      rethrow;
    }
  }

  /// Update password (requires knowledge of old password)
  static Future<void> updatePassword(
      String currentPassword, String newPassword) async {
    if (_cachedUid == null) {
      throw PivoteAuthException(
        code: 'no-current-user',
        message: 'No hay usuario autenticado.',
      );
    }

    try {
      _requireFirebase();

      // Fetch current user data to verify old password
      final doc =
          await _firestore.collection(_usersCollection).doc(_cachedUid).get();

      if (!doc.exists) {
        throw PivoteAuthException(
          code: 'user-not-found',
          message: 'Usuario no encontrado.',
        );
      }

      final data = doc.data()!;
      final storedHash = data['passwordHash'] as String? ?? '';
      final storedSalt = data['passwordSalt'] as String? ?? '';

      if (!_verifyPassword(currentPassword, storedHash, storedSalt)) {
        throw PivoteAuthException(
          code: 'wrong-password',
          message: 'La contraseña actual es incorrecta.',
        );
      }

      // Generate new hash
      final newSalt = _generateSalt();
      final newHash = _hashPassword(newPassword, newSalt);

      await doc.reference.update({
        'passwordHash': newHash,
        'passwordSalt': newSalt,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ AuthService: Password updated successfully');
    } on PivoteAuthException {
      rethrow;
    } catch (e) {
      debugPrint('❌ AuthService: Error updating password: $e');
      throw PivoteAuthException(
        code: 'password-update-error',
        message: 'Error al actualizar la contraseña.',
      );
    }
  }

  /// Update FCM token for push notifications
  static Future<void> updateFcmToken(String token) async {
    if (_cachedUid == null) return;

    try {
      await _firestore.collection(_usersCollection).doc(_cachedUid).update({
        'fcmToken': token,
      });
      debugPrint('✅ AuthService: FCM token updated');
    } catch (e) {
      debugPrint('❌ AuthService: Error updating FCM token: $e');
    }
  }

  /// Delete user account and all data
  static Future<void> deleteAccount() async {
    if (_cachedUid == null) {
      throw PivoteAuthException(
        code: 'no-current-user',
        message: 'No hay usuario autenticado.',
      );
    }

    try {
      _requireFirebase();
      debugPrint('🔵 AuthService: Deleting user account: $_cachedUid');

      // Delete Firestore document
      await _firestore.collection(_usersCollection).doc(_cachedUid).delete();

      // Clear session
      await logout();

      debugPrint('✅ AuthService: Account deleted successfully');
    } catch (e) {
      debugPrint('❌ AuthService: Error deleting account: $e');
      rethrow;
    }
  }

  // ─── Helpers ────────────────────────────────────────────────────

  static void _requireFirebase() {
    if (!FirebaseService.isInitialized) {
      throw PivoteAuthException(
        code: 'firebase-not-initialized',
        message:
            'La app no pudo conectarse. Verifica tu conexión e inténtalo de nuevo.',
      );
    }
  }

  /// Map error codes to professional Spanish messages
  static String getErrorMessage(dynamic error) {
    debugPrint('🔍 AuthService: Processing error: $error');

    if (error is PivoteAuthException) {
      switch (error.code) {
        case 'firebase-not-initialized':
          return 'No se pudo conectar al servidor. Revisa tu internet.';
        case 'email-already-in-use':
          return 'Este correo electrónico ya está registrado. Intenta iniciar sesión.';
        case 'user-not-found':
          return 'No encontramos una cuenta con este correo electrónico.';
        case 'wrong-password':
          return 'La contraseña es incorrecta. Verificá tus datos.';
        case 'no-current-user':
          return 'No hay usuario autenticado.';
        default:
          return error.message;
      }
    }

    final errorString = error.toString().toLowerCase();
    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Error de conexión. Revisa tu internet e inténtalo de nuevo.';
    }

    return 'Ha ocurrido un error inesperado. Por favor, inténtalo de nuevo.';
  }
}
