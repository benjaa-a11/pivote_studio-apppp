import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
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
      final appDir = await getApplicationDocumentsDirectory();
      final fileName =
          'profile_${DateTime.now().millisecondsSinceEpoch}${path.extension(pickedFile.path)}';
      final savedImage =
          await File(pickedFile.path).copy('${appDir.path}/$fileName');

      // Delete old image if exists
      if (_profileImagePath != null) {
        final oldFile = File(_profileImagePath!);
        if (oldFile.existsSync()) {
          await oldFile.delete();
        }
      }

      _profileImagePath = savedImage.path;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image_path', _profileImagePath!);
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
