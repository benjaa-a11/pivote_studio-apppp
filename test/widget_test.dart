// Pruebas unitarias del modelo de usuario privado y control de acceso de Pivote.
// No conecta a Firebase ni servicios externos.

import 'package:flutter_test/flutter_test.dart';
import 'package:pivote/features/auth/data/models/user_model.dart';
import 'package:pivote/features/auth/data/services/auth_service.dart';

void main() {
  group('UserModel (users/{uid})', () {
    test('fromJson crea el modelo correctamente con el nuevo esquema', () {
      final futureDate = DateTime.now().add(const Duration(days: 30));
      final json = {
        'uid': 'test-uid-123',
        'nombre': 'Juan',
        'apellido': 'García',
        'email': 'juan@test.com',
        'activo': true,
        'plan': 'standard',
        'vence': futureDate.toIso8601String(),
        'deviceId': 'device-abc-123',
        'maxDispositivos': 1,
        'creadoEn': '2026-01-01T00:00:00.000Z',
      };

      final user = UserModel.fromJson(json);

      expect(user.uid, 'test-uid-123');
      expect(user.nombre, 'Juan');
      expect(user.apellido, 'García');
      expect(user.name, 'Juan');
      expect(user.lastName, 'García');
      expect(user.email, 'juan@test.com');
      expect(user.activo, true);
      expect(user.isVip, false);
      expect(user.isExpired, false);
      expect(user.hasValidAccess, true);
      expect(user.deviceId, 'device-abc-123');
      expect(user.maxDispositivos, 1);
    });

    test('toJson / fromJson round-trip conserva campos de acceso', () {
      final futureDate = DateTime.now().add(const Duration(days: 60));
      final original = UserModel(
        uid: 'uid-456',
        nombre: 'María',
        apellido: 'López',
        email: 'maria@test.com',
        activo: true,
        plan: 'vip',
        vence: futureDate,
        deviceId: 'dev-99999999',
        dispositivos: const ['dev-99999999'],
        maxDispositivos: 2,
      );

      final json = original.toJson();
      final restored = UserModel.fromJson(json);

      expect(restored.uid, original.uid);
      expect(restored.nombre, original.nombre);
      expect(restored.apellido, original.apellido);
      expect(restored.email, original.email);
      expect(restored.activo, true);
      expect(restored.isVip, true);
      expect(restored.maxDispositivos, 2);
      expect(restored.deviceId, 'dev-99999999');
      expect(restored.hasValidAccess, true);
    });

    test('bloquea acceso si activo == false o vence está vencido', () {
      final past = DateTime.now().subtract(const Duration(minutes: 5));
      final future = DateTime.now().add(const Duration(days: 5));

      final pendingUser = UserModel(
        uid: 'u-pending',
        nombre: 'A',
        apellido: 'B',
        email: 'a@b.com',
        activo: false,
        vence: future,
      );
      expect(pendingUser.hasValidAccess, false);
      expect(pendingUser.blockReason, AccountBlockReason.pending);

      final expiredUser = UserModel(
        uid: 'u-expired',
        nombre: 'A',
        apellido: 'B',
        email: 'a@b.com',
        activo: true,
        vence: past,
      );
      expect(expiredUser.isExpired, true);
      expect(expiredUser.hasValidAccess, false);
      expect(expiredUser.blockReason, AccountBlockReason.expired);
    });

    test('control de dispositivos respeta maxDispositivos y autorización', () {
      final future = DateTime.now().add(const Duration(days: 30));
      final singleSlotFree = UserModel(
        uid: 'u-dev-1',
        nombre: 'Test',
        apellido: 'User',
        email: 'dev@test.com',
        activo: true,
        vence: future,
        deviceId: null,
        maxDispositivos: 1,
      );
      expect(singleSlotFree.hasAvailableDeviceSlot, true);
      expect(singleSlotFree.isDeviceAuthorized('and_11111111'), false);

      final singleSlotFull = singleSlotFree.copyWith(
        deviceId: 'and_11111111',
        dispositivos: const ['and_11111111'],
      );
      expect(singleSlotFull.hasAvailableDeviceSlot, false);
      expect(singleSlotFull.isDeviceAuthorized('and_11111111'), true);
      expect(singleSlotFull.isDeviceAuthorized('and_22222222'), false);

      final multiDevice = singleSlotFull.copyWith(maxDispositivos: 2);
      expect(multiDevice.hasAvailableDeviceSlot, true);
      final multiFull = multiDevice.copyWith(
        dispositivos: const ['and_11111111', 'and_22222222'],
      );
      expect(multiFull.hasAvailableDeviceSlot, false);
      expect(multiFull.isDeviceAuthorized('and_22222222'), true);
      expect(multiFull.isDeviceAuthorized('and_33333333'), false);
    });

    test('isValidEmail detecta correos válidos e inválidos', () {
      expect(UserModel.isValidEmail('user@example.com'), true);
      expect(UserModel.isValidEmail('invalido'), false);
      expect(UserModel.isValidEmail('sin-arroba.com'), false);
    });

    test('copyWith actualiza solo los campos especificados', () {
      const user = UserModel(
        uid: 'u1',
        nombre: 'Original',
        apellido: 'Name',
        email: 'orig@test.com',
      );

      final updated = user.copyWith(nombre: 'Actualizado');
      expect(updated.nombre, 'Actualizado');
      expect(updated.uid, 'u1');
      expect(updated.email, 'orig@test.com');
    });
  });

  group('AuthService error messages', () {
    test('getErrorMessage retorna mensaje legible para PivoteAuthException',
        () {
      const ex = PivoteAuthException(
        code: 'email-already-in-use',
        message: 'Este correo ya está registrado.',
      );
      final msg = AuthService.getErrorMessage(ex);
      expect(msg, 'Este correo ya está registrado.');
    });

    test('getErrorMessage retorna mensaje legible para AccountAccessBlockedException',
        () {
      const pending = AccountAccessBlockedException(
        reason: AccountBlockReason.pending,
      );
      const expired = AccountAccessBlockedException(
        reason: AccountBlockReason.expired,
      );
      expect(AuthService.getErrorMessage(pending), contains('pendiente'));
      expect(AuthService.getErrorMessage(expired), contains('venció'));
    });

    test('getErrorMessage retorna mensaje para error de red', () {
      final msg =
          AuthService.getErrorMessage('network error: connection refused');
      expect(msg, isNotEmpty);
    });
  });
}
