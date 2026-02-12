import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:pivote/firebase_options.dart';

class FirebaseService {
  static FirebaseFirestore? _firestore;
  static bool _isInitialized = false;
  static String? _initializationError;

  /// Initialize Firebase with proper error handling
  static Future<void> initialize() async {
    // Avoid re-initialization
    if (_isInitialized) {
      debugPrint('✅ Firebase already initialized');
      return;
    }

    // Check if Firebase apps already exist
    if (Firebase.apps.isNotEmpty) {
      debugPrint('✅ Firebase app already exists');
      _firestore = FirebaseFirestore.instance;
      _isInitialized = true;
      return;
    }

    try {
      debugPrint('🔵 Initializing Firebase...');

      // Initialize Firebase with platform-specific options
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      _firestore = FirebaseFirestore.instance;

      // Enable offline persistence (optional but recommended)
      if (!kIsWeb) {
        try {
          _firestore!.settings.persistenceEnabled;
          debugPrint('✅ Firestore offline persistence enabled');
        } catch (e) {
          debugPrint('⚠️ Could not enable offline persistence: $e');
        }
      }

      _isInitialized = true;
      _initializationError = null;

      debugPrint('✅ Firebase initialized successfully');
      debugPrint(
          '   - Project ID: ${DefaultFirebaseOptions.currentPlatform.projectId}');
      debugPrint(
          '   - App ID: ${DefaultFirebaseOptions.currentPlatform.appId}');
    } catch (e, stackTrace) {
      _isInitialized = false;
      _initializationError = e.toString();

      debugPrint('❌ Error initializing Firebase: $e');
      debugPrint('Stack trace: $stackTrace');

      if (kDebugMode) {
        debugPrint('⚠️ App will continue with limited functionality');
      }

      // Don't throw - allow app to continue without Firebase
      // This is useful for development or when Firebase is temporarily unavailable
    }
  }

  /// Check if Firebase is initialized
  static bool get isInitialized => _isInitialized;

  /// Get initialization error if any
  static String? get initializationError => _initializationError;

  /// Get Firestore instance (throws if not initialized)
  static FirebaseFirestore get firestore {
    if (!_isInitialized || _firestore == null) {
      throw Exception(
        'FirebaseService not initialized. Call initialize() first. '
        'Error: ${_initializationError ?? "Unknown"}',
      );
    }
    return _firestore!;
  }

  /// Get Firestore instance safely (returns null if not initialized)
  static FirebaseFirestore? get firestoreSafe {
    return _isInitialized ? _firestore : null;
  }

  // ============================================
  // COLLECTION REFERENCES
  // ============================================

  /// Users collection reference
  static CollectionReference get usersCollection {
    return firestore.collection('usuarios-pivote');
  }

  /// Channels collection reference
  static CollectionReference get channelsCollection {
    return firestore.collection('channels');
  }

  /// Radios collection reference
  static CollectionReference get radiosCollection {
    return firestore.collection('radio');
  }

  /// Matches collection reference (agenda)
  static CollectionReference get matchesCollection {
    return firestore.collection('agenda');
  }

  /// Teams collection reference
  static CollectionReference get teamsCollection {
    return firestore.collection('teams');
  }

  /// Tournaments collection reference
  static CollectionReference get tournamentsCollection {
    return firestore.collection('tournaments');
  }

  /// Profile data collection reference
  static CollectionReference get profileCollection {
    return firestore.collection('profile');
  }

  // ============================================
  // HELPER METHODS
  // ============================================

  /// Fetch profile configuration (urls, etc)
  static Future<Map<String, dynamic>> getProfileData() async {
    try {
      if (!_isInitialized) {
        debugPrint('⚠️ Firebase not initialized, cannot fetch profile data');
        return {};
      }

      final doc = await profileCollection.doc('data').get();
      if (doc.exists && doc.data() != null) {
        return doc.data() as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('❌ Error fetching profile data: $e');
    }
    return {};
  }

  /// Check if a document exists
  static Future<bool> documentExists(String collection, String docId) async {
    try {
      if (!_isInitialized) return false;

      final doc = await firestore.collection(collection).doc(docId).get();
      return doc.exists;
    } catch (e) {
      debugPrint('❌ Error checking document existence: $e');
      return false;
    }
  }

  /// Batch write helper
  static WriteBatch batch() {
    return firestore.batch();
  }

  /// Transaction helper
  static Future<T> runTransaction<T>(
    TransactionHandler<T> transactionHandler, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    return await firestore.runTransaction(
      transactionHandler,
      timeout: timeout,
    );
  }

  /// Clear all local cache (useful for logout)
  static Future<void> clearCache() async {
    try {
      if (!_isInitialized || kIsWeb) return;

      debugPrint('🔵 Clearing Firestore cache...');
      await _firestore!.clearPersistence();
      debugPrint('✅ Firestore cache cleared');
    } catch (e) {
      debugPrint('⚠️ Error clearing Firestore cache: $e');
    }
  }

  /// Terminate Firebase (useful for testing)
  static Future<void> terminate() async {
    try {
      if (!_isInitialized) return;

      debugPrint('🔵 Terminating Firebase...');
      await _firestore!.terminate();
      _isInitialized = false;
      _firestore = null;
      debugPrint('✅ Firebase terminated');
    } catch (e) {
      debugPrint('⚠️ Error terminating Firebase: $e');
    }
  }
}
