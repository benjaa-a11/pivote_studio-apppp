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
    _loadUserData();
    _loadProfileImage();
  }

  Future<void> _loadUserData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _user = await AuthService.getUser();
      if (_user?.photoUrl != null) {
        _downloadAndCacheProfileImage(_user!.photoUrl!);
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _downloadAndCacheProfileImage(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedUrl = prefs.getString('cached_photo_url');
      final currentPath = prefs.getString('profile_image_path');

      // If URL hasn't changed and file exists, we are good
      if (cachedUrl == url &&
          currentPath != null &&
          File(currentPath).existsSync()) {
        return;
      }

      // Download new image
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName =
            'profile_cache_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final file = File('${appDir.path}/$fileName');

        await file.writeAsBytes(response.bodyBytes);

        // Delete old cache if exists
        if (currentPath != null) {
          final oldFile = File(currentPath);
          if (oldFile.existsSync()) {
            // check if it's the same file to avoid deletion (unlikely with timestamp)
            if (oldFile.path != file.path) await oldFile.delete();
          }
        }

        // Update state
        _profileImagePath = file.path;
        await prefs.setString('profile_image_path', file.path);
        await prefs.setString('cached_photo_url', url);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error caching profile image: $e');
    }
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    _profileImagePath = prefs.getString('profile_image_path');
    if (_profileImagePath != null) {
      if (!File(_profileImagePath!).existsSync()) {
        _profileImagePath = null;
        await prefs.remove('profile_image_path');
      }
    }
    notifyListeners();
  }

  Future<void> updateProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      try {
        _isLoading = true;
        notifyListeners();

        // 1. Permanently save the image to the app's document directory
        final appDir = await getApplicationDocumentsDirectory();
        final fileName =
            'profile_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedImage =
            await File(pickedFile.path).copy('${appDir.path}/$fileName');

        // 2. Clear old cached local image if exists
        final prefs = await SharedPreferences.getInstance();
        final oldPath = prefs.getString('profile_image_path');
        if (oldPath != null && File(oldPath).existsSync()) {
          try {
            await File(oldPath).delete();
          } catch (e) {
            debugPrint('Error deleting old profile image: $e');
          }
        }

        // 3. Update local state and prefs
        _profileImagePath = savedImage.path;
        await prefs.setString('profile_image_path', savedImage.path);
        notifyListeners();

        // 4. Upload to remote storage
        final downloadUrl = await AuthService.uploadProfileImage(savedImage);

        // 5. Update user model and Firestore
        if (_user != null) {
          final updatedUser = _user!.copyWith(photoUrl: downloadUrl);
          await AuthService.updateUser(updatedUser);
          _user = updatedUser;
        }
      } catch (e) {
        debugPrint('Error uploading profile image: $e');
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      _isLoading = true;
      notifyListeners();
      await AuthService.updatePassword(newPassword);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshUser() async {
    await _loadUserData();
  }

  void clearUser() {
    _user = null;
    _profileImagePath = null;
    notifyListeners();
  }
}
