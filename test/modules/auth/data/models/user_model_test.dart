import 'package:flutter_test/flutter_test.dart';
import 'package:herramienta_case/modules/auth/data/models/user_model.dart';
import 'package:herramienta_case/modules/auth/domain/entities/user_entity.dart';

void main() {
  group('UserModel', () {
    test('should create a UserModel with all properties', () {
      // Arrange & Act
      final user = UserModel(
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

    group('fromJson', () {
      test('should parse JSON with all fields', () {
        // Arrange
        final json = {
          'id': 1,
          'email': 'test@example.com',
          'nombre': 'Test User',
          'token': 'test_token_123',
        };

        // Act
        final user = UserModel.fromJson(json);

        // Assert
        expect(user.id, 1);
        expect(user.email, 'test@example.com');
        expect(user.nombre, 'Test User');
        expect(user.token, 'test_token_123');
      });

      test('should parse JSON with usuario instead of email', () {
        // Arrange
        final json = {
          'id': 1,
          'usuario': 'admin@example.com',
          'nombre': 'Admin User',
          'token': 'test_token_123',
        };

        // Act
        final user = UserModel.fromJson(json);

        // Assert
        expect(user.email, 'admin@example.com');
      });

      test('should parse JSON with name instead of nombre', () {
        // Arrange
        final json = {
          'id': 1,
          'email': 'test@example.com',
          'name': 'English Name',
          'token': 'test_token_123',
        };

        // Act
        final user = UserModel.fromJson(json);

        // Assert
        expect(user.nombre, 'English Name');
      });

      test('should use default values when email is missing', () {
        // Arrange
        final json = {
          'id': 1,
          'token': 'test_token_123',
        };

        // Act
        final user = UserModel.fromJson(json);

        // Assert
        expect(user.email, 'admin');
        expect(user.nombre, 'Administrador');
      });

      test('should parse JSON with only token', () {
        // Arrange
        final json = {
          'token': 'test_token_123',
        };

        // Act
        final user = UserModel.fromJson(json);

        // Assert
        expect(user.id, null);
        expect(user.email, 'admin');
        expect(user.nombre, 'Administrador');
        expect(user.token, 'test_token_123');
      });
    });

    group('toJson', () {
      test('should convert to JSON with all fields', () {
        // Arrange
        final user = UserModel(
          id: 1,
          email: 'test@example.com',
          nombre: 'Test User',
          token: 'test_token_123',
        );

        // Act
        final json = user.toJson();

        // Assert
        expect(json['id'], 1);
        expect(json['email'], 'test@example.com');
        expect(json['nombre'], 'Test User');
        expect(json['token'], 'test_token_123');
      });

      test('should convert to JSON with null values', () {
        // Arrange
        final user = UserModel(
          token: 'test_token_123',
        );

        // Act
        final json = user.toJson();

        // Assert
        expect(json['id'], null);
        expect(json['email'], null);
        expect(json['nombre'], null);
        expect(json['token'], 'test_token_123');
      });
    });

    group('copyWith', () {
      test('should create a copy with updated values', () {
        // Arrange
        final user = UserModel(
          id: 1,
          email: 'test@example.com',
          nombre: 'Test User',
          token: 'test_token_123',
        );

        // Act
        final updatedUser = user.copyWith(
          email: 'updated@example.com',
          nombre: 'Updated User',
        );

        // Assert
        expect(updatedUser.id, 1);
        expect(updatedUser.email, 'updated@example.com');
        expect(updatedUser.nombre, 'Updated User');
        expect(updatedUser.token, 'test_token_123');
      });

      test('should keep original values when no parameters provided', () {
        // Arrange
        final user = UserModel(
          id: 1,
          email: 'test@example.com',
          nombre: 'Test User',
          token: 'test_token_123',
        );

        // Act
        final copiedUser = user.copyWith();

        // Assert
        expect(copiedUser.id, user.id);
        expect(copiedUser.email, user.email);
        expect(copiedUser.nombre, user.nombre);
        expect(copiedUser.token, user.token);
      });
    });

    group('toEntity', () {
      test('should convert UserModel to UserEntity', () {
        // Arrange
        final model = UserModel(
          id: 1,
          email: 'test@example.com',
          nombre: 'Test User',
          token: 'test_token_123',
        );

        // Act
        final entity = model.toEntity();

        // Assert
        expect(entity, isA<UserEntity>());
        expect(entity.id, 1);
        expect(entity.email, 'test@example.com');
        expect(entity.nombre, 'Test User');
        expect(entity.token, 'test_token_123');
      });
    });

    group('fromEntity', () {
      test('should create UserModel from UserEntity', () {
        // Arrange
        final entity = UserEntity(
          id: 1,
          email: 'test@example.com',
          nombre: 'Test User',
          token: 'test_token_123',
        );

        // Act
        final model = UserModel.fromEntity(entity);

        // Assert
        expect(model, isA<UserModel>());
        expect(model.id, 1);
        expect(model.email, 'test@example.com');
        expect(model.nombre, 'Test User');
        expect(model.token, 'test_token_123');
      });
    });

    test('should have correct toString representation', () {
      // Arrange
      final user = UserModel(
        id: 1,
        email: 'test@example.com',
        nombre: 'Test User',
        token: 'test_token_123',
      );

      // Act
      final result = user.toString();

      // Assert
      expect(result, 'UserModel(id: 1, email: test@example.com, nombre: Test User)');
    });

    test('should be equal to parent UserEntity when properties match', () {
      // Arrange
      final model = UserModel(
        id: 1,
        email: 'test@example.com',
        nombre: 'Test User',
        token: 'test_token_123',
      );

      final entity = UserEntity(
        id: 1,
        email: 'test@example.com',
        nombre: 'Test User',
        token: 'test_token_123',
      );

      // Act & Assert
      expect(model, equals(entity));
    });
  });
}
