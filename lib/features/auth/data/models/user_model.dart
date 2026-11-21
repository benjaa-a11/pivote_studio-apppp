import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Motivo por el cual una cuenta no puede ingresar a la app privada.
enum AccountBlockReason {
  pending,
  expired,
  revoked,
  missingProfile,
  deviceLimitReached,
  deviceRevoked,
}

/// Modelo de usuario vinculado a `users/{uid}` en Firestore.
class UserModel {
  final String uid;
  final String nombre;
  final String apellido;
  final String email;
  final bool activo;
  final String plan; // 'standard', 'vip', 'admin'
  final DateTime? vence;
  final String? deviceId;
  final List<String> dispositivos;
  final int maxDispositivos;
  final String? photoUrl;
  final String? fcmToken;
  final String? codigoInvitacion;
  final DateTime? creadoEn;
  final DateTime? actualizadoEn;

  const UserModel({
    required this.uid,
    required this.nombre,
    required this.apellido,
    required this.email,
    this.activo = false,
    this.plan = 'standard',
    this.vence,
    this.deviceId,
    this.dispositivos = const [],
    this.maxDispositivos = 1,
    this.photoUrl,
    this.fcmToken,
    this.codigoInvitacion,
    this.creadoEn,
    this.actualizadoEn,
  });

  // Getters de compatibilidad con la UI existente
  String get name => nombre;
  String get lastName => apellido;
  String get userType => plan;
  bool get isVip =>
      plan.toLowerCase() == 'vip' || plan.toLowerCase() == 'admin';
  bool get isSuspended => !activo;
  String? get createdAt => creadoEn?.toIso8601String();

  /// Verdadero únicamente si existe fecha `vence` y ya expiró.
  /// Si `vence == null`, la cuenta no tiene fecha de caducidad (solo depende de `activo`).
  bool get isExpired {
    if (vence == null) return false;
    return !vence!.isAfter(DateTime.now());
  }

  /// Verdadero únicamente si la cuenta está activa y vigente.
  bool get hasValidAccess => activo && !isExpired;

  /// Motivo de bloqueo cuando [hasValidAccess] es falso.
  AccountBlockReason? get blockReason {
    if (!activo) return AccountBlockReason.pending;
    if (isExpired) return AccountBlockReason.expired;
    return null;
  }

  /// Lista efectiva y sin duplicados de dispositivos vinculados (`deviceId` + `dispositivos`).
  List<String> get effectiveDevices {
    final result = <String>[];
    if (deviceId != null && deviceId!.isNotEmpty) {
      result.add(deviceId!);
    }
    for (final d in dispositivos) {
      if (d.isNotEmpty && !result.contains(d)) {
        result.add(d);
      }
    }
    return result;
  }

  /// Verdadero si [currentDeviceId] ya figura entre los dispositivos autorizados.
  bool isDeviceAuthorized(String currentDeviceId) {
    if (currentDeviceId.isEmpty) return false;
    return effectiveDevices.contains(currentDeviceId);
  }

  /// Verdadero si todavía hay cupo para vincular un nuevo dispositivo según `maxDispositivos`.
  bool get hasAvailableDeviceSlot {
    final limit = maxDispositivos < 1 ? 1 : maxDispositivos;
    return effectiveDevices.length < limit;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }

  /// Construye [UserModel] desde un documento de Firestore `users/{uid}` o JSON local.
  factory UserModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    final rawDevices = json['dispositivos'];
    final devicesList = rawDevices is List
        ? rawDevices.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
        : <String>[];

    final parsedDeviceId = json['deviceId'] as String?;
    if (parsedDeviceId != null &&
        parsedDeviceId.isNotEmpty &&
        !devicesList.contains(parsedDeviceId)) {
      devicesList.insert(0, parsedDeviceId);
    }

    final rawPlan = (json['plan'] ?? json['userType'] ?? 'standard').toString();
    final rawActivo = json.containsKey('activo')
        ? json['activo'] == true
        : !(json['isSuspended'] == true);

    return UserModel(
      uid: (json['uid'] as String?)?.isNotEmpty == true
          ? json['uid'] as String
          : (docId ?? ''),
      nombre: (json['nombre'] ?? json['name'] ?? '').toString(),
      apellido: (json['apellido'] ?? json['lastName'] ?? '').toString(),
      email: (json['email'] ?? '').toString().trim().toLowerCase(),
      activo: rawActivo,
      plan: rawPlan,
      vence: _parseDate(json['vence']),
      deviceId: parsedDeviceId,
      dispositivos: devicesList,
      maxDispositivos: (json['maxDispositivos'] as num?)?.toInt() ?? 1,
      photoUrl: json['photoUrl'] as String?,
      fcmToken: json['fcmToken'] as String?,
      codigoInvitacion: json['codigoInvitacion'] as String?,
      creadoEn: _parseDate(json['creadoEn'] ?? json['createdAt']),
      actualizadoEn: _parseDate(json['actualizadoEn'] ?? json['updatedAt']),
    );
  }

  /// Serialización JSON para caché local (sin tipos Firestore).
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'nombre': nombre,
      'apellido': apellido,
      'email': email,
      'activo': activo,
      'plan': plan,
      'vence': vence?.toIso8601String(),
      'deviceId': deviceId,
      'dispositivos': dispositivos,
      'maxDispositivos': maxDispositivos,
      'photoUrl': photoUrl,
      'fcmToken': fcmToken,
      'codigoInvitacion': codigoInvitacion,
      'creadoEn': creadoEn?.toIso8601String(),
      'actualizadoEn': actualizadoEn?.toIso8601String(),
    };
  }

  String toJsonString() => jsonEncode(toJson());

  factory UserModel.fromJsonString(String jsonString) {
    return UserModel.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    );
    return emailRegex.hasMatch(email.trim());
  }

  static bool isValidName(String name) {
    return name.trim().isNotEmpty && name.trim().length >= 2;
  }

  UserModel copyWith({
    String? uid,
    String? nombre,
    String? name,
    String? apellido,
    String? lastName,
    String? email,
    bool? activo,
    String? plan,
    DateTime? vence,
    String? deviceId,
    List<String>? dispositivos,
    int? maxDispositivos,
    String? photoUrl,
    String? fcmToken,
    String? codigoInvitacion,
    DateTime? creadoEn,
    DateTime? actualizadoEn,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      nombre: nombre ?? name ?? this.nombre,
      apellido: apellido ?? lastName ?? this.apellido,
      email: email ?? this.email,
      activo: activo ?? this.activo,
      plan: plan ?? this.plan,
      vence: vence ?? this.vence,
      deviceId: deviceId ?? this.deviceId,
      dispositivos: dispositivos ?? this.dispositivos,
      maxDispositivos: maxDispositivos ?? this.maxDispositivos,
      photoUrl: photoUrl ?? this.photoUrl,
      fcmToken: fcmToken ?? this.fcmToken,
      codigoInvitacion: codigoInvitacion ?? this.codigoInvitacion,
      creadoEn: creadoEn ?? this.creadoEn,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
    );
  }

  @override
  String toString() =>
      'UserModel(uid: $uid, email: $email, activo: $activo, plan: $plan, vence: $vence, maxDispositivos: $maxDispositivos)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.uid == uid &&
        other.nombre == nombre &&
        other.apellido == apellido &&
        other.email == email &&
        other.activo == activo &&
        other.plan == plan &&
        other.vence == vence &&
        other.deviceId == deviceId &&
        other.maxDispositivos == maxDispositivos &&
        other.photoUrl == photoUrl;
  }

  @override
  int get hashCode => Object.hash(
        uid,
        nombre,
        apellido,
        email,
        activo,
        plan,
        vence,
        deviceId,
        maxDispositivos,
        photoUrl,
      );
}
