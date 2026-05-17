import 'dart:convert';

/// Model representing a user in the Pivote application.
/// Stored in the Firestore 'usuarios' collection.
class UserModel {
  final String uid;
  final String name;
  final String lastName;
  final String email;
  final String? photoUrl;
  final bool isVip;
  final String userType; // 'standard', 'vip', 'admin'
  final bool isSuspended;
  final String? fcmToken;
  final List<String> favorites;
  final String? createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.lastName,
    required this.email,
    this.photoUrl,
    this.isVip = false,
    this.userType = 'standard',
    this.isSuspended = false,
    this.fcmToken,
    this.favorites = const [],
    this.createdAt,
  });

  /// Create UserModel from Firestore document JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String? ?? '',
      name: json['name'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      isVip: json['isVip'] as bool? ?? false,
      userType: json['userType'] as String? ?? 'standard',
      isSuspended: json['isSuspended'] as bool? ?? false,
      fcmToken: json['fcmToken'] as String?,
      favorites: (json['favorites'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt: json['createdAt'] as String?,
    );
  }

  /// Convert UserModel to JSON for Firestore storage
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'lastName': lastName,
      'email': email,
      'photoUrl': photoUrl,
      'isVip': isVip,
      'userType': userType,
      'isSuspended': isSuspended,
      'fcmToken': fcmToken,
      'favorites': favorites,
      'createdAt': createdAt,
    };
  }

  /// Convert UserModel to JSON string for local storage
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
    String? uid,
    String? name,
    String? lastName,
    String? email,
    String? photoUrl,
    bool? isVip,
    String? userType,
    bool? isSuspended,
    String? fcmToken,
    List<String>? favorites,
    String? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      isVip: isVip ?? this.isVip,
      userType: userType ?? this.userType,
      isSuspended: isSuspended ?? this.isSuspended,
      fcmToken: fcmToken ?? this.fcmToken,
      favorites: favorites ?? this.favorites,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'UserModel(uid: $uid, name: $name, lastName: $lastName, email: $email, isVip: $isVip, userType: $userType, isSuspended: $isSuspended)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.uid == uid &&
        other.name == name &&
        other.lastName == lastName &&
        other.email == email &&
        other.isSuspended == isSuspended;
  }

  @override
  int get hashCode =>
      uid.hashCode ^
      name.hashCode ^
      lastName.hashCode ^
      email.hashCode ^
      isSuspended.hashCode;
}
