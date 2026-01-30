import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

/// Service to manage user authentication and session using Firebase Auth
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _usersCollection = 'users';

  /// Stream of auth state changes
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Get current user ID or null
  static String? get currentUserId => _auth.currentUser?.uid;

  /// Sign in with email and password
  static Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Sign up with email, password and name
  static Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    if (userCredential.user != null) {
      // Create user document in Firestore
      await _createTextUserDocument(
        uid: userCredential.user!.uid,
        email: email.trim(),
        name: name.trim(),
      );

      // Update display name in Auth
      await userCredential.user!.updateDisplayName(name.trim());
    }
  }

  /// Create user document in Firestore
  static Future<void> _createTextUserDocument({
    required String uid,
    required String email,
    required String name,
  }) async {
    final userRef = _firestore.collection(_usersCollection).doc(uid);

    // Check if user already exists to avoid overwriting (though unlikely on signup)
    final doc = await userRef.get();
    if (!doc.exists) {
      await userRef.set({
        'uid': uid,
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'favorites': [], // Initialize empty favorites
      });
    }
  }

  /// Get current user model from Firestore
  static Future<UserModel?> getUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc =
          await _firestore.collection(_usersCollection).doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson(doc.data()!);
      } else {
        // Backup if document doesn't exist but user is logged in
        return UserModel(
            name: user.displayName ?? 'Usuario', email: user.email ?? '');
      }
    } catch (e) {
      debugPrint('Error getting user data: $e');
      return null;
    }
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    return _auth.currentUser != null;
  }

  /// Logout user
  static Future<void> logout() async {
    await _auth.signOut();
  }

  /// Update user information in Firestore
  static Future<void> updateUser(UserModel user) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    await _firestore.collection(_usersCollection).doc(currentUser.uid).update({
      'name': user.name,
      'email': user.email,
    });

    // Also update Auth profile
    if (user.name != currentUser.displayName) {
      await currentUser.updateDisplayName(user.name);
    }
  }
}
