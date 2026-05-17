import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pivote/features/auth/data/models/user_model.dart';
import 'package:pivote/features/auth/data/services/auth_service.dart';

class UserProvider with ChangeNotifier {
  UserModel? _user;
  String? _profileImagePath;
  bool _isLoading = false;

  UserModel? get user => _user;
  String? get profileImagePath => _profileImagePath;
  bool get isLoading => _isLoading;

  UserProvider() {
    _initialize();
  }

  /// Initialize provider - load user data and profile image
  Future<void> _initialize() async {
    debugPrint('🔵 UserProvider: Initializing...');
    await _loadUserData();
    await _loadProfileImage();
    debugPrint('✅ UserProvider: Initialization complete');
  }

  /// Load user data from Firestore (via AuthService)
  Future<void> _loadUserData() async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('🔵 UserProvider: Loading user data...');
      _user = await AuthService.getUser();

      if (_user != null) {
        debugPrint('✅ UserProvider: User data loaded: ${_user!.email}');
      } else {
        debugPrint('⚠️ UserProvider: No user data found');
      }
    } catch (e) {
      debugPrint('❌ UserProvider: Error loading user data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load cached profile image path from SharedPreferences
  Future<void> _loadProfileImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedPath = prefs.getString('profile_image_path');

      if (cachedPath != null) {
        final file = File(cachedPath);
        if (await file.exists()) {
          _profileImagePath = cachedPath;
          debugPrint('✅ UserProvider: Loaded cached profile image');
        } else {
          // File no longer exists, clear cache
          await prefs.remove('profile_image_path');
          _profileImagePath = null;
          debugPrint(
              '⚠️ UserProvider: Cached image file not found, cleared cache');
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('❌ UserProvider: Error loading profile image: $e');
    }
  }

  /// Update profile image - pick from gallery and save locally
  Future<void> updateProfileImage() async {
    final picker = ImagePicker();

    try {
      debugPrint('🔵 UserProvider: Opening image picker...');

      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        debugPrint('⚠️ UserProvider: Image selection canceled');
        return;
      }

      debugPrint('✅ UserProvider: Image selected: ${pickedFile.path}');

      _isLoading = true;
      notifyListeners();

      // 1. Save image permanently to app's document directory
      final appDir = await getApplicationDocumentsDirectory();
      final fileName =
          'profile_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage =
          await File(pickedFile.path).copy('${appDir.path}/$fileName');
      debugPrint('✅ UserProvider: Image saved locally: ${savedImage.path}');

      // 2. Clear old cached image if exists
      final prefs = await SharedPreferences.getInstance();
      final oldPath = prefs.getString('profile_image_path');
      if (oldPath != null) {
        final oldFile = File(oldPath);
        if (await oldFile.exists()) {
          try {
            await oldFile.delete();
            debugPrint('🗑️ UserProvider: Old profile image deleted');
          } catch (e) {
            debugPrint('⚠️ UserProvider: Error deleting old image: $e');
          }
        }
      }

      // 3. Update local state and cache
      _profileImagePath = savedImage.path;
      await prefs.setString('profile_image_path', savedImage.path);
      notifyListeners();

      debugPrint('✅ UserProvider: Profile image updated locally');
    } catch (e) {
      debugPrint('❌ UserProvider: Error updating profile image: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign in with Email/Password (Pivote custom auth)
  Future<void> login(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      debugPrint('🔵 UserProvider: Starting Pivote Login...');
      _user = await AuthService.signIn(email, password);
      await _loadProfileImage();
      debugPrint('✅ UserProvider: Login complete');
    } catch (e) {
      debugPrint('❌ UserProvider: Login error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign up with Email/Password (Pivote custom auth)
  Future<void> register(
      String email, String password, String name, String lastName) async {
    try {
      _isLoading = true;
      notifyListeners();

      debugPrint('🔵 UserProvider: Starting Pivote Registration...');
      _user = await AuthService.signUp(
        email: email,
        password: password,
        name: name,
        lastName: lastName,
      );
      debugPrint('✅ UserProvider: Registration complete');
    } catch (e) {
      debugPrint('❌ UserProvider: Registration error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update user password (requires current password verification)
  Future<void> updatePassword(
      String currentPassword, String newPassword) async {
    try {
      _isLoading = true;
      notifyListeners();

      debugPrint('🔵 UserProvider: Updating password...');
      await AuthService.updatePassword(currentPassword, newPassword);
      debugPrint('✅ UserProvider: Password updated successfully');
    } catch (e) {
      debugPrint('❌ UserProvider: Error updating password: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Delete user account and all data
  Future<void> deleteAccount() async {
    try {
      _isLoading = true;
      notifyListeners();

      debugPrint('🔵 UserProvider: Starting Account Deletion...');
      await AuthService.deleteAccount();

      // Clear local state after successful deletion
      await clearUser();
      debugPrint('✅ UserProvider: Account deletion complete');
    } catch (e) {
      debugPrint('❌ UserProvider: Error deleting account: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh user data from Firestore
  Future<void> refreshUser() async {
    debugPrint('🔵 UserProvider: Refreshing user data...');
    await _loadUserData();
  }

  /// Clear user data (on logout)
  Future<void> clearUser() async {
    debugPrint('🔵 UserProvider: Clearing user data...');

    // Clear in-memory state
    _user = null;
    _profileImagePath = null;

    // Clear cached data
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedPath = prefs.getString('profile_image_path');
      if (cachedPath != null) {
        final file = File(cachedPath);
        if (await file.exists()) {
          await file.delete();
        }
      }
      await prefs.remove('profile_image_path');

      debugPrint('✅ UserProvider: User data cleared');
    } catch (e) {
      debugPrint('⚠️ UserProvider: Error clearing cache: $e');
    }

    notifyListeners();
  }

  /// Get user's full name
  String get fullName {
    if (_user == null) return 'Usuario';
    return '${_user!.name} ${_user!.lastName}'.trim();
  }

  /// Check if user has profile image
  bool get hasProfileImage {
    return _profileImagePath != null;
  }
}
