import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

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

  /// Load user data from Firestore
  Future<void> _loadUserData() async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('🔵 UserProvider: Loading user data...');
      _user = await AuthService.getUser();
      
      if (_user != null) {
        debugPrint('✅ UserProvider: User data loaded: ${_user!.email}');
        
        // Download and cache profile image if URL exists
        if (_user!.photoUrl != null && _user!.photoUrl!.isNotEmpty) {
          debugPrint('🔵 UserProvider: Profile URL found, caching image...');
          await _downloadAndCacheProfileImage(_user!.photoUrl!);
        }
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

  /// Download and cache profile image from URL
  Future<void> _downloadAndCacheProfileImage(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedUrl = prefs.getString('cached_photo_url');
      final currentPath = prefs.getString('profile_image_path');

      // If URL hasn't changed and file exists, skip download
      if (cachedUrl == url && currentPath != null) {
        final file = File(currentPath);
        if (await file.exists()) {
          debugPrint('✅ UserProvider: Using cached profile image');
          _profileImagePath = currentPath;
          notifyListeners();
          return;
        }
      }

      debugPrint('🔵 UserProvider: Downloading profile image from: $url');

      // Download new image
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout downloading profile image');
        },
      );

      if (response.statusCode == 200) {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'profile_cache_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final file = File('${appDir.path}/$fileName');

        await file.writeAsBytes(response.bodyBytes);
        debugPrint('✅ UserProvider: Profile image cached at: ${file.path}');

        // Delete old cache if exists and it's different
        if (currentPath != null && currentPath != file.path) {
          final oldFile = File(currentPath);
          if (await oldFile.exists()) {
            try {
              await oldFile.delete();
              debugPrint('🗑️ UserProvider: Old cache deleted');
            } catch (e) {
              debugPrint('⚠️ UserProvider: Could not delete old cache: $e');
            }
          }
        }

        // Update state
        _profileImagePath = file.path;
        await prefs.setString('profile_image_path', file.path);
        await prefs.setString('cached_photo_url', url);
        notifyListeners();
      } else {
        debugPrint('⚠️ UserProvider: Failed to download image. Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ UserProvider: Error caching profile image: $e');
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
          await prefs.remove('cached_photo_url');
          _profileImagePath = null;
          debugPrint('⚠️ UserProvider: Cached image file not found, cleared cache');
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('❌ UserProvider: Error loading profile image: $e');
    }
  }

  /// Update profile image - pick from gallery and upload
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
      final fileName = 'profile_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');
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

      // 4. Upload to Firebase Storage
      debugPrint('🔵 UserProvider: Uploading to Firebase Storage...');
      final downloadUrl = await AuthService.uploadProfileImage(savedImage);
      debugPrint('✅ UserProvider: Upload complete: $downloadUrl');

      // 5. Update user model and Firestore
      if (_user != null) {
        final updatedUser = _user!.copyWith(photoUrl: downloadUrl);
        await AuthService.updateUser(updatedUser);
        _user = updatedUser;
        
        // Update cached URL
        await prefs.setString('cached_photo_url', downloadUrl);
        debugPrint('✅ UserProvider: User profile updated in Firestore');
      }
    } catch (e) {
      debugPrint('❌ UserProvider: Error updating profile image: $e');
      // Optionally show error to user via callback
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update user password
  Future<void> updatePassword(String newPassword) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      debugPrint('🔵 UserProvider: Updating password...');
      await AuthService.updatePassword(newPassword);
      debugPrint('✅ UserProvider: Password updated successfully');
    } catch (e) {
      debugPrint('❌ UserProvider: Error updating password: $e');
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
      await prefs.remove('profile_image_path');
      await prefs.remove('cached_photo_url');
      
      // Optionally delete cached image file
      final cachedPath = prefs.getString('profile_image_path');
      if (cachedPath != null) {
        final file = File(cachedPath);
        if (await file.exists()) {
          await file.delete();
        }
      }
      
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
    return _profileImagePath != null || (_user?.photoUrl != null && _user!.photoUrl!.isNotEmpty);
  }
}