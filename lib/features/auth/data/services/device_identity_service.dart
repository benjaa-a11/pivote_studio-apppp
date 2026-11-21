import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Identidad estable del dispositivo actual generada con `device_info_plus`.
class DeviceIdentity {
  final String id;
  final String label;
  final String platform;
  final String model;
  final String osVersion;

  const DeviceIdentity({
    required this.id,
    required this.label,
    required this.platform,
    required this.model,
    required this.osVersion,
  });

  Map<String, dynamic> toMetadataMap() {
    return {
      'id': id,
      'label': label,
      'platform': platform,
      'model': model,
      'osVersion': osVersion,
    };
  }
}

/// Servicio para obtener un identificador estable, único y seguro del dispositivo
/// usando `device_info_plus` + salt persistente local (para evitar colisiones en Android 10+).
class DeviceIdentityService {
  static const String _installSaltKey = 'pivote_device_install_salt_v1';
  static DeviceIdentity? _cached;

  /// Retorna la identidad del dispositivo actual (cacheadas en memoria durante la sesión).
  static Future<DeviceIdentity> getDeviceIdentity() async {
    if (_cached != null) return _cached!;

    final installSalt = await _getOrCreateInstallSalt();
    final plugin = DeviceInfoPlugin();

    String prefix = 'dev';
    String fingerprintSource = installSalt;
    String label = 'Dispositivo desconocido';
    String platform = 'unknown';
    String model = 'Desconocido';
    String osVersion = '';

    try {
      if (kIsWeb) {
        final info = await plugin.webBrowserInfo;
        prefix = 'web';
        platform = 'web';
        final browser = info.browserName.name;
        final webPlatform = info.platform ?? 'Web';
        model = browser;
        osVersion = webPlatform;
        label = '$browser ($webPlatform)';
        fingerprintSource =
            '${info.vendor}|${info.userAgent}|${info.hardwareConcurrency}|$installSalt';
      } else {
        switch (defaultTargetPlatform) {
          case TargetPlatform.android:
            final info = await plugin.androidInfo;
            prefix = 'and';
            platform = 'android';
            final brand = _capitalize(info.brand);
            model = '${brand.isNotEmpty ? '$brand ' : ''}${info.model}'.trim();
            osVersion = 'Android ${info.version.release}';
            label = '$model ($osVersion)';
            // Nota de seguridad: en Android 10+, `info.id` es Build.ID (compartido por
            // equipos idénticos con el mismo parche). Combinamos hardware + fingerprint
            // con un salt único por instalación para garantizar unicidad real por equipo.
            fingerprintSource =
                '${info.brand}|${info.manufacturer}|${info.model}|${info.device}|${info.hardware}|${info.fingerprint}|$installSalt';
            break;

          case TargetPlatform.iOS:
            final info = await plugin.iosInfo;
            prefix = 'ios';
            platform = 'ios';
            final vendorId = (info.identifierForVendor ?? '').trim();
            model = info.utsname.machine;
            osVersion = 'iOS ${info.systemVersion}';
            label = '${info.name} ($osVersion)';
            // En iOS `identifierForVendor` es único por dispositivo + vendor.
            fingerprintSource = vendorId.isNotEmpty
                ? '$vendorId|${info.utsname.machine}'
                : '${info.model}|${info.utsname.machine}|$installSalt';
            break;

          case TargetPlatform.windows:
            final info = await plugin.windowsInfo;
            prefix = 'win';
            platform = 'windows';
            model = info.computerName;
            osVersion = 'Windows ${info.displayVersion}';
            label = '$model ($osVersion)';
            fingerprintSource =
                '${info.deviceId}|${info.computerName}|$installSalt';
            break;

          case TargetPlatform.macOS:
            final info = await plugin.macOsInfo;
            prefix = 'mac';
            platform = 'macos';
            model = info.model;
            osVersion = info.osRelease;
            label = '${info.computerName} (macOS)';
            fingerprintSource =
                '${info.systemGUID ?? ''}|${info.model}|$installSalt';
            break;

          case TargetPlatform.linux:
            final info = await plugin.linuxInfo;
            prefix = 'lin';
            platform = 'linux';
            model = info.prettyName;
            osVersion = info.version ?? '';
            label = info.prettyName;
            fingerprintSource =
                '${info.machineId ?? ''}|${info.name}|$installSalt';
            break;

          default:
            fingerprintSource = 'other|$installSalt';
        }
      }
    } catch (e) {
      debugPrint('⚠️ DeviceIdentityService: Fallback por error en device_info_plus: $e');
      fingerprintSource = 'fallback|$installSalt';
    }

    final hashHex = sha256.convert(utf8.encode(fingerprintSource)).toString();
    final deviceId = '${prefix}_${hashHex.substring(0, 32)}';

    _cached = DeviceIdentity(
      id: deviceId,
      label: label,
      platform: platform,
      model: model,
      osVersion: osVersion,
    );
    return _cached!;
  }

  /// Versión abreviada segura para mostrar en la UI del perfil.
  static String shortId(String? deviceId) {
    if (deviceId == null || deviceId.isEmpty) return 'Sin vincular';
    if (deviceId.length <= 14) return deviceId;
    return '${deviceId.substring(0, 8)}…${deviceId.substring(deviceId.length - 4)}';
  }

  static Future<String> _getOrCreateInstallSalt() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_installSaltKey);
    if (existing != null && existing.length >= 24) {
      return existing;
    }

    final random = Random.secure();
    final bytes = List<int>.generate(24, (_) => random.nextInt(256));
    final generated = base64UrlEncode(bytes);
    await prefs.setString(_installSaltKey, generated);
    return generated;
  }

  static String _capitalize(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';
    return trimmed[0].toUpperCase() + trimmed.substring(1);
  }
}
