import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

/// Service to manage user authentication and session using Firebase Auth
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();
  static const String _usersCollection = 'usuarios-pivote';

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

  /// Sign in with Google
  static Future<void> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return; // User canceled

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        final user = userCredential.user!;
        final nameParts = user.displayName?.split(' ') ?? ['Usuario', ''];
        final firstName = nameParts.first;
        final lastName =
            nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

        // Check/Create user in Firestore
        await _createTextUserDocument(
          uid: user.uid,
          email: user.email ?? '',
          name: firstName,
          lastName: lastName,
        );
      }
    } catch (e) {
      debugPrint('Error in Google Sign-In: $e');
      rethrow;
    }
  }

  /// Sign up with email, password, name and lastName
  static Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String lastName,
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
        lastName: lastName.trim(),
      );

      // Update display name in Auth
      final fullName = '${name.trim()} ${lastName.trim()}';
      await userCredential.user!.updateDisplayName(fullName);
    }
  }

  /// Create user document in Firestore
  static Future<void> _createTextUserDocument({
    required String uid,
    required String email,
    required String name,
    required String lastName,
  }) async {
    final userRef = _firestore.collection(_usersCollection).doc(uid);

    // Check if user already exists to avoid overwriting
    final doc = await userRef.get();
    if (!doc.exists) {
      await userRef.set({
        'uid': uid,
        'name': name,
        'lastName': lastName,
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
            name: user.displayName ?? 'Usuario',
            lastName: '',
            email: user.email ?? '');
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
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
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
