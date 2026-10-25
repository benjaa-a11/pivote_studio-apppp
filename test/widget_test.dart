// Test básico de arranque de Pivote.
// No intenta conectar a Firebase ni servicios externos.
// Verifica que los modelos y servicios de auth compilan correctamente.

import 'package:flutter_test/flutter_test.dart';
import 'package:pivote/features/auth/data/models/user_model.dart';
import 'package:pivote/features/auth/data/services/auth_service.dart';

void main() {
  group('UserModel', () {
    test('fromJson crea el modelo correctamente', () {
      final json = {
        'uid': 'test-uid-123',
        'name': 'Juan',
        'lastName': 'García',
        'email': 'juan@test.com',
        'isVip': false,
        'userType': 'standard',
        'isSuspended': false,
        'favorites': <String>[],
        'createdAt': '2026-01-01T00:00:00',
      };

      final user = UserModel.fromJson(json);

      expect(user.uid, 'test-uid-123');
      expect(user.name, 'Juan');
      expect(user.lastName, 'García');
      expect(user.email, 'juan@test.com');
      expect(user.isVip, false);
      expect(user.isSuspended, false);
      expect(user.favorites, isEmpty);
    });

    test('toJson / fromJson round-trip', () {
      final original = UserModel(
        uid: 'uid-456',
        name: 'María',
        lastName: 'López',
        email: 'maria@test.com',
        isVip: true,
        userType: 'vip',
        isSuspended: false,
        favorites: ['channel-1', 'channel-2'],
      );

      final json = original.toJson();
      final restored = UserModel.fromJson(json);

      expect(restored.uid, original.uid);
      expect(restored.name, original.name);
      expect(restored.lastName, original.lastName);
      expect(restored.email, original.email);
      expect(restored.isVip, original.isVip);
      expect(restored.favorites, original.favorites);
    });

    test('fromJson maneja campos nulos con defaults', () {
      final json = <String, dynamic>{'uid': '', 'email': ''};
      final user = UserModel.fromJson(json);

      expect(user.uid, '');
      expect(user.name, '');
      expect(user.isSuspended, false);
      expect(user.favorites, isEmpty);
    });

    test('isValidEmail detecta correos válidos e inválidos', () {
      expect(UserModel.isValidEmail('user@example.com'), true);
      expect(UserModel.isValidEmail('invalido'), false);
      expect(UserModel.isValidEmail('sin-arroba.com'), false);
    });

    test('isSuspended se lee correctamente del JSON', () {
      final suspended = UserModel.fromJson({
        'uid': 'x',
        'email': 'x@x.com',
        'isSuspended': true,
      });
      expect(suspended.isSuspended, true);
    });

    test('copyWith actualiza solo los campos especificados', () {
      final user = UserModel(
        uid: 'u1',
        name: 'Original',
        lastName: 'Name',
        email: 'orig@test.com',
      );

      final updated = user.copyWith(name: 'Actualizado');
      expect(updated.name, 'Actualizado');
      expect(updated.uid, 'u1'); // sin cambio
      expect(updated.email, 'orig@test.com'); // sin cambio
    });
  });

  group('AuthService error messages', () {
    test('getErrorMessage retorna mensaje legible para PivoteAuthException', () {
      final ex = PivoteAuthException(
        code: 'email-already-in-use',
        message: 'raw message',
      );
      final msg = AuthService.getErrorMessage(ex);
      expect(msg, isNotEmpty);
      expect(msg, contains('correo electrónico'));
    });

    test('getErrorMessage retorna mensaje para error de red', () {
      final msg =
          AuthService.getErrorMessage('network error: connection refused');
      expect(msg, isNotEmpty);
    });

    test('PivoteAuthException tiene toString útil', () {
      final ex = PivoteAuthException(code: 'test', message: 'Test error');
      expect(ex.toString(), contains('test'));
      expect(ex.toString(), contains('Test error'));
    });
  });
}
