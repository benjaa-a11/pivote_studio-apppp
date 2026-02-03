import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
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
    } catch (e) {
      debugPrint('Error loading user data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
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
      _profileImagePath = pickedFile.path;
      notifyListeners();

      try {
        final downloadUrl =
            await AuthService.uploadProfileImage(File(pickedFile.path));

        // Update user model with new photo URL
        if (_user != null) {
          final updatedUser = _user!.copyWith(photoUrl: downloadUrl);
          await AuthService.updateUser(updatedUser);
          _user = updatedUser;

          // Also save path locally as cache
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('profile_image_path', pickedFile.path);
        }
      } catch (e) {
        debugPrint('Error uploading profile image: $e');
        // Revert or show error handled by UI
      }
      notifyListeners();
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
