import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pivote/features/auth/data/models/user_model.dart';
import 'package:pivote/core/services/firebase_service.dart';
import 'package:flutter/services.dart';

/// Service to manage user authentication and session using Firebase Auth
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // NOTE:
  // - Android: no necesita clientId, pero para garantizar idToken estable usamos el Web OAuth Client ID
  //   (google-services.json -> oauth_client client_type 3).
  // - Web: usamos el flujo de FirebaseAuth (popup/redirect) por compatibilidad.
  static const String _googleWebOAuthClientId =
      '451817571128-ch6b02prjtv8njpek34v233bv3itfpjn.apps.googleusercontent.com';

  static const String _usersCollection = 'usuarios-pivote';

  /// Stream of auth state changes
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Get current user ID or null
  static String? get currentUserId => _auth.currentUser?.uid;

  static void _requireFirebase() {
    if (!FirebaseService.isInitialized) {
      throw FirebaseAuthException(
        code: 'firebase-not-initialized',
        message:
            'La app no pudo inicializar Firebase. Verifica la configuración e inténtalo de nuevo.',
      );
    }
  }

  /// Sign in with email and password
  static Future<void> signIn(String email, String password) async {
    try {
      _requireFirebase();
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } catch (e) {
      debugPrint('Error in email sign in: $e');
      rethrow;
    }
  }

  /// Sign in with Google - ROBUST IMPLEMENTATION
  static Future<User?> signInWithGoogle() async {
    try {
      _requireFirebase();
      debugPrint('🔵 Starting Google Sign-In process...');

      if (kIsWeb) {
        final provider = GoogleAuthProvider()
          ..addScope('email')
          ..addScope('profile')
          ..setCustomParameters(<String, String>{
            'prompt': 'select_account',
          });

        try {
          final userCredential = await _auth.signInWithPopup(provider);
          final user = userCredential.user;
          if (user == null) {
            throw FirebaseAuthException(
              code: 'null-user',
              message: 'Error al obtener usuario de Firebase',
            );
          }
          await _createOrUpdateUserDocument(
            uid: user.uid,
            email: user.email ?? '',
            name: (user.displayName?.split(' ').firstOrNull) ?? 'Usuario',
            lastName: (user.displayName?.split(' ').skip(1).join(' ')) ?? '',
            photoUrl: user.photoURL,
          );
          return user;
        } on FirebaseAuthException catch (e) {
          // Popup puede ser bloqueado; damos fallback a redirect.
          final code = e.code.toLowerCase();
          if (code.contains('popup') || code.contains('cancel')) rethrow;

          try {
            await _auth.signInWithRedirect(provider);
            // La sesión se completará tras el redirect; el wrapper de authStateChanges lo capturará.
            return _auth.currentUser;
          } catch (_) {
            rethrow;
          }
        }
      }

      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        throw FirebaseAuthException(
          code: 'platform-not-supported',
          message: 'Google Sign-In no está disponible en esta plataforma.',
        );
      }

      final googleSignIn = GoogleSignIn(
        serverClientId: _googleWebOAuthClientId,
        scopes: const ['email', 'profile', 'openid'],
      );

      // 1. Force sign out to ensure account picker works reliably
      try {
        await googleSignIn.signOut();
      } catch (e) {
        debugPrint('⚠️ Error signing out from Google (non-fatal): $e');
      }

      // 2. Trigger the authentication flow
      // IMPORTANTE: Asegúrate de que el SHA-1 y SHA-256 estén agregados en Firebase Console
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('⚠️ Google Sign-In canceled by user');
        throw FirebaseAuthException(
          code: 'sign_in_canceled',
          message: 'Inicio de sesión cancelado',
        );
      }

      debugPrint('✅ Google account selected: ${googleUser.email}');

      // 3. Obtain the auth details
      GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 4. Verify tokens
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        debugPrint('❌ Failed to obtain Google tokens');
        throw FirebaseAuthException(
          code: 'missing-google-tokens',
          message: 'Error de autenticación con Google (Tokens faltantes)',
        );
      }

      debugPrint('✅ Google tokens obtained successfully');

      // 5. Create credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      debugPrint('🔵 Signing in to Firebase with Google credential...');

      // 6. Sign in to Firebase
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      if (userCredential.user == null) {
        throw FirebaseAuthException(
          code: 'null-user',
          message: 'Error al obtener usuario de Firebase',
        );
      }

      final user = userCredential.user!;
      debugPrint('✅ Firebase sign-in successful: ${user.uid}');

      // 7. Parse name
      final nameParts = user.displayName?.split(' ') ?? ['Usuario', 'Google'];
      final firstName = nameParts.first;
      final lastName =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      // 8. Update Firestore
      await _createOrUpdateUserDocument(
        uid: user.uid,
        email: user.email ?? '',
        name: firstName,
        lastName: lastName,
        photoUrl: user.photoURL,
      );

      return user;
    } on PlatformException catch (e) {
      final msg = (e.message ?? '').toLowerCase();
      if (msg.contains('api') && msg.contains('10') ||
          msg.contains('developer_error')) {
        throw FirebaseAuthException(
          code: 'google-developer-error',
          message:
              'Google Sign-In no está configurado correctamente (SHA-1/SHA-256 o OAuth).',
        );
      }
      throw FirebaseAuthException(
        code: 'google-platform-error',
        message: e.message ?? 'Error de Google Sign-In',
      );
    } on FirebaseAuthException {
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('❌ Unexpected error in Google Sign-In: $e');
      debugPrint('Stack trace: $stackTrace');
      throw FirebaseAuthException(
        code: 'unknown-error',
        message: 'Error inesperado: $e',
      );
    }
  }

  /// Sign up with email, password, name and lastName
  static Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String lastName,
  }) async {
    try {
      _requireFirebase();
      debugPrint('🔵 Starting email sign-up...');

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (userCredential.user != null) {
        final user = userCredential.user!;
        debugPrint('✅ User created: ${user.uid}');

        // Create user document in Firestore
        await _createOrUpdateUserDocument(
          uid: user.uid,
          email: email.trim(),
          name: name.trim(),
          lastName: lastName.trim(),
        );

        // Update display name in Auth
        final fullName = '${name.trim()} ${lastName.trim()}';
        await user.updateDisplayName(fullName);

        debugPrint('✅ Sign-up completed successfully');
      }
    } catch (e) {
      debugPrint('❌ Error in sign-up: $e');
      rethrow;
    }
  }

  /// Create or update user document in Firestore - VERSIÓN MEJORADA
  static Future<void> _createOrUpdateUserDocument({
    required String uid,
    required String email,
    required String name,
    required String lastName,
    String? photoUrl,
  }) async {
    try {
      final userRef = _firestore.collection(_usersCollection).doc(uid);

      // Check if user already exists
      final doc = await userRef.get();

      final userData = {
        'uid': uid,
        'name': name,
        'lastName': lastName,
        'email': email,
        'favorites': [], // Initialize empty favorites
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (photoUrl != null && photoUrl.isNotEmpty) {
        userData['photoUrl'] = photoUrl;
      }

      if (!doc.exists) {
        // New user - create document
        userData['createdAt'] = FieldValue.serverTimestamp();
        await userRef.set(userData);
        debugPrint('✅ New user document created in Firestore');
      } else {
        // Existing user - update document (merge to keep other fields)
        await userRef.update(userData);
        debugPrint('✅ User document updated in Firestore');
      }
    } catch (e) {
      debugPrint('❌ Error creating/updating user document: $e');
      rethrow;
    }
  }

  /// Get current user model from Firestore
  static Future<UserModel?> getUser() async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('⚠️ No current user in Firebase Auth');
      return null;
    }

    try {
      _requireFirebase();
      debugPrint('🔵 Fetching user data from Firestore: ${user.uid}');

      final doc =
          await _firestore.collection(_usersCollection).doc(user.uid).get();

      if (doc.exists && doc.data() != null) {
        debugPrint('✅ User data retrieved from Firestore');
        return UserModel.fromJson(doc.data()!);
      } else {
        // Fallback if document doesn't exist but user is logged in
        debugPrint('⚠️ User document not found in Firestore, using Auth data');
        final nameParts = user.displayName?.split(' ') ?? ['Usuario', ''];
        return UserModel(
          name: nameParts.isNotEmpty ? nameParts.first : 'Usuario',
          lastName: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
          email: user.email ?? '',
          photoUrl: user.photoURL,
        );
      }
    } catch (e) {
      debugPrint('❌ Error getting user data: $e');
      return null;
    }
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final isLogged = _auth.currentUser != null;
    debugPrint('🔍 User logged in: $isLogged');
    return isLogged;
  }

  /// Logout user - VERSIÓN MEJORADA
  static Future<void> logout() async {
    try {
      debugPrint('🔵 Starting logout process...');

      await _auth.signOut();
      if (!kIsWeb &&
          !(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        try {
          final googleSignIn =
              GoogleSignIn(serverClientId: _googleWebOAuthClientId);
          await googleSignIn.signOut();
        } catch (e) {
          debugPrint('⚠️ Google sign out failed (non-fatal): $e');
        }
      }

      debugPrint('✅ Logout completed successfully');
    } catch (e) {
      debugPrint('❌ Error during logout: $e');
      rethrow;
    }
  }

  /// Update user information in Firestore
  static Future<void> updateUser(UserModel user) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      debugPrint('⚠️ No current user to update');
      return;
    }

    try {
      _requireFirebase();
      debugPrint('🔵 Updating user information...');

      final updateData = {
        'name': user.name,
        'lastName': user.lastName,
        'email': user.email,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (user.photoUrl != null) {
        updateData['photoUrl'] = user.photoUrl as Object;
      }

      await _firestore
          .collection(_usersCollection)
          .doc(currentUser.uid)
          .update(updateData);

      // Also update Auth profile
      final fullName = '${user.name} ${user.lastName}';
      if (fullName != currentUser.displayName) {
        await currentUser.updateDisplayName(fullName);
      }

      if (user.photoUrl != null && user.photoUrl != currentUser.photoURL) {
        await currentUser.updatePhotoURL(user.photoUrl);
      }

      debugPrint('✅ User information updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating user: $e');
      rethrow;
    }
  }

  /// Update password (requires recent login)
  static Future<void> updatePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No hay usuario autenticado',
      );
    }

    try {
      _requireFirebase();
      await user.updatePassword(newPassword);
      debugPrint('✅ Password updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating password: $e');
      rethrow;
    }
  }

  /// Upload profile image to Firebase Storage and return URL
  static Future<String> uploadProfileImage(File imageFile) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No hay usuario autenticado',
      );
    }

    try {
      _requireFirebase();
      debugPrint('🔵 Uploading profile image...');

      final ref = FirebaseStorage.instance
          .ref()
          .child('user_profiles')
          .child('${user.uid}.jpg');

      final uploadTask = await ref.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      debugPrint('✅ Profile image uploaded: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Error uploading profile image: $e');
      rethrow;
    }
  }

  /// Map Firebase Auth error codes to professional Spanish messages
  static String getErrorMessage(dynamic error) {
    debugPrint('🔍 Processing error: $error');

    if (error is! FirebaseAuthException) {
      // Handle generic errors
      final errorString = error.toString().toLowerCase();
      if (errorString.contains('cancel') || errorString.contains('cancelad')) {
        return 'Inicio de sesión cancelado.';
      }
      if (errorString.contains('network')) {
        return 'Error de conexión. Revisa tu internet e inténtalo de nuevo.';
      }
      return 'Ha ocurrido un error inesperado. Por favor, inténtalo de nuevo.';
    }

    switch (error.code) {
      case 'firebase-not-initialized':
        return 'La app no pudo conectarse a Firebase. Reinstala/actualiza la app o contacta soporte.';
      case 'platform-not-supported':
        return 'Google no está disponible en esta plataforma.';
      case 'google-developer-error':
        return 'Google Sign-In no está configurado correctamente. Verifica SHA-1/SHA-256 y OAuth en Firebase.';
      case 'google-platform-error':
        return 'No se pudo abrir Google Sign-In. Intenta de nuevo.';
      case 'sign_in_canceled':
        return 'Inicio de sesión cancelado.';
      case 'user-not-found':
        return 'No hemos encontrado una cuenta con este correo electrónico.';
      case 'wrong-password':
        return 'La contraseña es incorrecta. Por favor, verifica tus datos.';
      case 'email-already-in-use':
        return 'Este correo electrónico ya está registrado. Intenta iniciar sesión.';
      case 'invalid-email':
        return 'El formato del correo electrónico no es válido.';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada. Contacta al soporte.';
      case 'operation-not-allowed':
        return 'El inicio de sesión con este método no está habilitado.';
      case 'weak-password':
        return 'La contraseña es muy débil. Intenta con una más segura.';
      case 'network-request-failed':
        return 'Error de conexión. Revisa tu internet e inténtalo de nuevo.';
      case 'too-many-requests':
        return 'Demasiados intentos. Por favor, inténtalo más tarde.';
      case 'account-exists-with-different-credential':
        return 'Ya existe una cuenta con este correo usando otro método de inicio de sesión.';
      case 'invalid-credential':
        return 'Las credenciales proporcionadas son inválidas o han expirado.';
      case 'popup-closed-by-user':
      case 'cancelled-popup-request':
        return 'Inicio de sesión cancelado.';
      case 'missing-google-tokens':
        return 'No se pudieron obtener los tokens de Google. Inténtalo de nuevo.';
      case 'null-user':
        return 'Error al obtener la información del usuario. Inténtalo de nuevo.';
      case 'no-current-user':
        return 'No hay usuario autenticado.';
      default:
        return 'Algo salió mal: ${error.message ?? "Error desconocido"}';
    }
  }
}

extension on List<String> {
  String? get firstOrNull => isEmpty ? null : first;
}
