import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:herramienta_case/modules/auth/presentation/providers/auth_provider.dart';
import 'package:herramienta_case/modules/auth/data/repositories/auth_repository.dart';
import 'package:herramienta_case/modules/auth/domain/entities/user_entity.dart';
import 'package:herramienta_case/core/errors/exceptions.dart';

import 'auth_provider_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late AuthProvider authProvider;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    authProvider = AuthProvider(authRepository: mockAuthRepository);
  });

  group('AuthProvider - init', () {
    test('should set isAuthenticated to true when user session exists', () async {
      // Arrange
      final testUser = UserEntity(
        id: 1,
        email: 'test@example.com',
        nombre: 'Test User',
        token: 'test_token',
      );

      when(mockAuthRepository.isAuthenticated())
          .thenAnswer((_) async => true);
      when(mockAuthRepository.getCachedUser())
          .thenAnswer((_) async => testUser);

      // Act
      await authProvider.init();

      // Assert
      expect(authProvider.isAuthenticated, true);
      expect(authProvider.currentUser, isNotNull);
      expect(authProvider.currentUser?.email, 'test@example.com');
    });

    test('should set isAuthenticated to false when no session exists', () async {
      // Arrange
      when(mockAuthRepository.isAuthenticated())
          .thenAnswer((_) async => false);

      // Act
      await authProvider.init();

      // Assert
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.currentUser, isNull);
    });

    test('should handle errors during initialization', () async {
      // Arrange
      when(mockAuthRepository.isAuthenticated())
          .thenThrow(Exception('Error reading cache'));

      // Act
      await authProvider.init();

      // Assert
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.currentUser, isNull);
    });
  });

  group('AuthProvider - login', () {
    const testEmail = 'test@example.com';
    const testPassword = 'password123';
    final testUser = UserEntity(
      id: 1,
      email: testEmail,
      nombre: 'Test User',
      token: 'test_token_123',
    );

    test('should return true and update state on successful login', () async {
      // Arrange
      when(mockAuthRepository.login(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => testUser);

      // Act
      final result = await authProvider.login(
        email: testEmail,
        password: testPassword,
      );

      // Assert
      expect(result, true);
      expect(authProvider.isAuthenticated, true);
      expect(authProvider.currentUser, isNotNull);
      expect(authProvider.currentUser?.email, testEmail);
      expect(authProvider.currentUser?.nombre, 'Test User');
      expect(authProvider.isLoading, false);
      expect(authProvider.errorMessage, null);
    });

    test('should return false and set error on failed login', () async {
      // Arrange
      when(mockAuthRepository.login(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenThrow(Exception('Credenciales incorrectas'));

      // Act
      final result = await authProvider.login(
        email: testEmail,
        password: testPassword,
      );

      // Assert
      expect(result, false);
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.currentUser, isNull);
      expect(authProvider.isLoading, false);
      expect(authProvider.errorMessage, isNotNull);
    });

    test('should handle network exception with appropriate error message', () async {
      // Arrange
      when(mockAuthRepository.login(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenThrow(NetworkException('No network connection'));

      // Act
      final result = await authProvider.login(
        email: testEmail,
        password: testPassword,
      );

      // Assert
      expect(result, false);
      expect(authProvider.errorMessage, 'Error de conexión. Verifica tu internet');
    });

    test('should handle invalid credentials error message', () async {
      // Arrange
      when(mockAuthRepository.login(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenThrow(Exception('Credenciales incorrectas'));

      // Act
      final result = await authProvider.login(
        email: testEmail,
        password: testPassword,
      );

      // Assert
      expect(result, false);
      expect(authProvider.errorMessage, 'Credenciales incorrectas');
    });

    test('should handle timeout error message', () async {
      // Arrange
      when(mockAuthRepository.login(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenThrow(Exception('Request timeout'));

      // Act
      final result = await authProvider.login(
        email: testEmail,
        password: testPassword,
      );

      // Assert
      expect(result, false);
      expect(authProvider.errorMessage, 'Tiempo de espera agotado');
    });

    test('should handle server error message', () async {
      // Arrange
      when(mockAuthRepository.login(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenThrow(ServerException('Server error 500'));

      // Act
      final result = await authProvider.login(
        email: testEmail,
        password: testPassword,
      );

      // Assert
      expect(result, false);
      expect(authProvider.errorMessage, 'Error del servidor. Intenta más tarde');
    });

    test('should clear error before attempting login', () async {
      // Arrange
      when(mockAuthRepository.login(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => testUser);

      // Set initial error
      authProvider.setError('Previous error');

      // Act
      await authProvider.login(
        email: testEmail,
        password: testPassword,
      );

      // Assert
      expect(authProvider.errorMessage, null);
    });
  });

  group('AuthProvider - logout', () {
    test('should clear user state on successful logout', () async {
      // Arrange
      final testUser = UserEntity(
        id: 1,
        email: 'test@example.com',
        nombre: 'Test User',
        token: 'test_token',
      );

      when(mockAuthRepository.login(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => testUser);

      when(mockAuthRepository.logout()).thenAnswer((_) async => {});

      // First login
      await authProvider.login(
        email: 'test@example.com',
        password: 'password',
      );

      expect(authProvider.isAuthenticated, true);
      expect(authProvider.currentUser, isNotNull);

      // Act
      await authProvider.logout();

      // Assert
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.currentUser, isNull);
      expect(authProvider.isLoading, false);
    });

    test('should clear user state even when logout fails', () async {
      // Arrange
      final testUser = UserEntity(
        id: 1,
        email: 'test@example.com',
        nombre: 'Test User',
        token: 'test_token',
      );

      when(mockAuthRepository.login(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => testUser);

      when(mockAuthRepository.logout())
          .thenThrow(Exception('Server error'));

      // First login
      await authProvider.login(
        email: 'test@example.com',
        password: 'password',
      );

      // Act
      await authProvider.logout();

      // Assert
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.currentUser, isNull);
    });
  });

  group('AuthProvider - getters', () {
    test('should return correct currentUser', () async {
      // Arrange
      final testUser = UserEntity(
        id: 1,
        email: 'test@example.com',
        nombre: 'Test User',
        token: 'test_token',
      );

      when(mockAuthRepository.login(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => testUser);

      // Act
      await authProvider.login(
        email: 'test@example.com',
        password: 'password',
      );

      // Assert
      expect(authProvider.currentUser, isNotNull);
      expect(authProvider.currentUser?.id, 1);
      expect(authProvider.currentUser?.email, 'test@example.com');
    });

    test('should return correct isAuthenticated status', () {
      // Assert - Initially not authenticated
      expect(authProvider.isAuthenticated, false);
    });
  });

  group('AuthProvider - error messages', () {
    test('should return friendly error for incorrect credentials', () async {
      // Arrange
      when(mockAuthRepository.login(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenThrow(Exception('invalid credentials'));

      // Act
      await authProvider.login(
        email: 'test@example.com',
        password: 'wrong_password',
      );

      // Assert
      expect(authProvider.errorMessage, 'Credenciales incorrectas');
    });

    test('should return friendly error for network issues', () async {
      // Arrange
      when(mockAuthRepository.login(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenThrow(Exception('network error'));

      // Act
      await authProvider.login(
        email: 'test@example.com',
        password: 'password',
      );

      // Assert
      expect(authProvider.errorMessage, 'Error de conexión. Verifica tu internet');
    });

    test('should return generic error for unknown issues', () async {
      // Arrange
      when(mockAuthRepository.login(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenThrow(Exception('Unknown error'));

      // Act
      await authProvider.login(
        email: 'test@example.com',
        password: 'password',
      );

      // Assert
      expect(authProvider.errorMessage, 'Error al iniciar sesión. Intenta de nuevo');
    });
  });

  group('AuthProvider - dispose', () {
    test('should clear user state on dispose', () async {
      // Arrange
      final testUser = UserEntity(
        id: 1,
        email: 'test@example.com',
        nombre: 'Test User',
        token: 'test_token',
      );

      when(mockAuthRepository.login(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => testUser);

      await authProvider.login(
        email: 'test@example.com',
        password: 'password',
      );

      // Act
      authProvider.dispose();

      // Assert - After dispose, state should be cleared
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.currentUser, isNull);
    });
  });
}
