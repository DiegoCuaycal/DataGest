import 'package:flutter_test/flutter_test.dart';
import 'package:herramienta_case/modules/auth/domain/entities/user_entity.dart';

void main() {
  group('UserEntity', () {
    test('should create a UserEntity with all properties', () {
      // Arrange & Act
      final user = UserEntity(
        id: 1,
        email: 'test@example.com',
        nombre: 'Test User',
        token: 'test_token_123',
      );

      // Assert
      expect(user.id, 1);
      expect(user.email, 'test@example.com');
      expect(user.nombre, 'Test User');
      expect(user.token, 'test_token_123');
    });

    test('should create a UserEntity with only token (minimal)', () {
      // Arrange & Act
      final user = UserEntity(
        token: 'test_token_123',
      );

      // Assert
      expect(user.id, null);
      expect(user.email, null);
      expect(user.nombre, null);
      expect(user.token, 'test_token_123');
    });

    test('should be equal when all properties are the same', () {
      // Arrange
      final user1 = UserEntity(
        id: 1,
        email: 'test@example.com',
        nombre: 'Test User',
        token: 'test_token_123',
      );

      final user2 = UserEntity(
        id: 1,
        email: 'test@example.com',
        nombre: 'Test User',
        token: 'test_token_123',
      );

      // Act & Assert
      expect(user1, equals(user2));
      expect(user1.hashCode, equals(user2.hashCode));
    });

    test('should not be equal when properties differ', () {
      // Arrange
      final user1 = UserEntity(
        id: 1,
        email: 'test1@example.com',
        nombre: 'Test User 1',
        token: 'test_token_123',
      );

      final user2 = UserEntity(
        id: 2,
        email: 'test2@example.com',
        nombre: 'Test User 2',
        token: 'test_token_456',
      );

      // Act & Assert
      expect(user1, isNot(equals(user2)));
      expect(user1.hashCode, isNot(equals(user2.hashCode)));
    });

    test('should have correct toString representation', () {
      // Arrange
      final user = UserEntity(
        id: 1,
        email: 'test@example.com',
        nombre: 'Test User',
        token: 'test_token_123',
      );

      // Act
      final result = user.toString();

      // Assert
      expect(result, 'UserEntity(id: 1, email: test@example.com, nombre: Test User)');
    });

    test('should handle null values in toString', () {
      // Arrange
      final user = UserEntity(
        token: 'test_token_123',
      );

      // Act
      final result = user.toString();

      // Assert
      expect(result, 'UserEntity(id: null, email: null, nombre: null)');
    });
  });
}
