import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static FirebaseFirestore? _firestore;

  static Future<void> initialize() async {
    try {
      // Initialize Firebase
      await Firebase.initializeApp();
      _firestore = FirebaseFirestore.instance;

      if (kDebugMode) {
        debugPrint('Firebase initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error initializing Firebase: $e');
      }
    }
  }

  static FirebaseFirestore get firestore {
    if (_firestore == null) {
      throw Exception(
          'FirebaseService not initialized. Call initialize() first.');
    }
    return _firestore!;
  }

  // Channels collection reference
  static CollectionReference get channelsCollection {
    return firestore.collection('channels');
  }

  // Radios collection reference
  static CollectionReference get radiosCollection {
    return firestore.collection('radio');
  }

  // Matches collection reference (agenda)
  static CollectionReference get matchesCollection {
    return firestore.collection('agenda');
  }

  // Teams collection reference
  static CollectionReference get teamsCollection {
    return firestore.collection('teams');
  }

  // Tournaments collection reference
  static CollectionReference get tournamentsCollection {
    return firestore.collection('tournaments');
  }

  // Profile data collection reference
  static CollectionReference get profileCollection {
    return firestore.collection('profile');
  }

  // Fetch profile configuration (urls, etc)
  static Future<Map<String, dynamic>> getProfileData() async {
    try {
      final doc = await profileCollection.doc('data').get();
      if (doc.exists && doc.data() != null) {
        return doc.data() as Map<String, dynamic>;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching profile data: $e');
      }
    }
    return {};
  }
}
