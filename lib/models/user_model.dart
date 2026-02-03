import 'dart:convert';

/// Model representing a user in the application
class UserModel {
  final String name;
  final String lastName;
  final String email;
  final String? photoUrl;

  UserModel({
    required this.name,
    required this.lastName,
    required this.email,
    this.photoUrl,
  });

  /// Create UserModel from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      name: json['name'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
    );
  }

  /// Convert UserModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'lastName': lastName,
      'email': email,
      'photoUrl': photoUrl,
    };
  }

  /// Convert UserModel to JSON string for storage
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// Create UserModel from JSON string
  factory UserModel.fromJsonString(String jsonString) {
    return UserModel.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  /// Validate email format
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    );
    return emailRegex.hasMatch(email);
  }

  /// Validate name (not empty and reasonable length)
  static bool isValidName(String name) {
    return name.trim().isNotEmpty && name.trim().length >= 2;
  }

  /// Create a copy with updated fields
  UserModel copyWith({
    String? name,
    String? lastName,
    String? email,
    String? photoUrl,
  }) {
    return UserModel(
      name: name ?? this.name,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  @override
  String toString() =>
      'UserModel(name: $name, lastName: $lastName, email: $email, photoUrl: $photoUrl)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.name == name &&
        other.lastName == lastName &&
        other.email == email &&
        other.photoUrl == photoUrl;
  }

  @override
  int get hashCode =>
      name.hashCode ^ lastName.hashCode ^ email.hashCode ^ photoUrl.hashCode;
}
