import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:herramienta_case/modules/auth/data/repositories/auth_repository.dart';
import 'package:herramienta_case/modules/auth/data/datasources/auth_remote_datasource.dart';
import 'package:herramienta_case/modules/auth/data/models/user_model.dart';
import 'package:herramienta_case/core/errors/exceptions.dart';
import 'package:herramienta_case/core/config/app_config.dart';

import 'auth_repository_test.mocks.dart';

@GenerateMocks([AuthRemoteDataSource, SharedPreferences])
void main() {
  late AuthRepository repository;
  late MockAuthRemoteDataSource mockRemoteDataSource;
  late MockSharedPreferences mockSharedPreferences;

  setUp(() {
    mockRemoteDataSource = MockAuthRemoteDataSource();
    mockSharedPreferences = MockSharedPreferences();
    repository = AuthRepository(
      remoteDataSource: mockRemoteDataSource,
      sharedPreferences: mockSharedPreferences,
    );
  });

  group('AuthRepository - login', () {
    const testUsername = 'test@example.com';
    const testPassword = 'password123';
    final testUserModel = UserModel(
      id: 1,
      email: testUsername,
      nombre: 'Test User',
      token: 'test_token_123',
    );

    test('should return UserEntity when login is successful', () async {
      // Arrange
      when(mockRemoteDataSource.login(
        username: anyNamed('username'),
        password: anyNamed('password'),
        databaseName: anyNamed('databaseName'),
      )).thenAnswer((_) async => testUserModel);

      when(mockSharedPreferences.setString(any, any))
          .thenAnswer((_) async => true);

      // Act
      final result = await repository.login(
        username: testUsername,
        password: testPassword,
      );

      // Assert
      expect(result.id, testUserModel.id);
      expect(result.email, testUserModel.email);
      expect(result.nombre, testUserModel.nombre);
      expect(result.token, testUserModel.token);

      verify(mockRemoteDataSource.login(
        username: testUsername,
        password: testPassword,
        databaseName: null,
      )).called(1);
    });

    test('should cache user data locally after successful login', () async {
      // Arrange
      when(mockRemoteDataSource.login(
        username: anyNamed('username'),
        password: anyNamed('password'),
        databaseName: anyNamed('databaseName'),
      )).thenAnswer((_) async => testUserModel);

      when(mockSharedPreferences.setString(any, any))
          .thenAnswer((_) async => true);

      // Act
      await repository.login(
        username: testUsername,
        password: testPassword,
      );

      // Assert
      verify(mockSharedPreferences.setString(
        AppConfig.userKey,
        any,
      )).called(1);

      verify(mockSharedPreferences.setString(
        AppConfig.tokenKey,
        testUserModel.token,
      )).called(1);
    });

    test('should throw NetworkException when remote datasource throws it', () async {
      // Arrange
      when(mockRemoteDataSource.login(
        username: anyNamed('username'),
        password: anyNamed('password'),
        databaseName: anyNamed('databaseName'),
      )).thenThrow(NetworkException('No internet connection'));

      // Act & Assert
      expect(
        () => repository.login(username: testUsername, password: testPassword),
        throwsA(isA<NetworkException>()),
      );
    });

    test('should throw ServerException when remote datasource throws it', () async {
      // Arrange
      when(mockRemoteDataSource.login(
        username: anyNamed('username'),
        password: anyNamed('password'),
        databaseName: anyNamed('databaseName'),
      )).thenThrow(ServerException('Server error'));

      // Act & Assert
      expect(
        () => repository.login(username: testUsername, password: testPassword),
        throwsA(isA<ServerException>()),
      );
    });

    test('should throw ServerException on unexpected error', () async {
      // Arrange
      when(mockRemoteDataSource.login(
        username: anyNamed('username'),
        password: anyNamed('password'),
        databaseName: anyNamed('databaseName'),
      )).thenThrow(Exception('Unexpected error'));

      // Act & Assert
      expect(
        () => repository.login(username: testUsername, password: testPassword),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('AuthRepository - logout', () {
    test('should clear cache after successful logout', () async {
      // Arrange
      when(mockRemoteDataSource.logout()).thenAnswer((_) async => {});
      when(mockSharedPreferences.remove(any)).thenAnswer((_) async => true);

      // Act
      await repository.logout();

      // Assert
      verify(mockRemoteDataSource.logout()).called(1);
      verify(mockSharedPreferences.remove(AppConfig.userKey)).called(1);
      verify(mockSharedPreferences.remove(AppConfig.tokenKey)).called(1);
    });

    test('should clear cache even when remote logout fails', () async {
      // Arrange
      when(mockRemoteDataSource.logout())
          .thenThrow(Exception('Server error'));
      when(mockSharedPreferences.remove(any)).thenAnswer((_) async => true);

      // Act
      await repository.logout();

      // Assert
      verify(mockSharedPreferences.remove(AppConfig.userKey)).called(1);
      verify(mockSharedPreferences.remove(AppConfig.tokenKey)).called(1);
    });
  });

  group('AuthRepository - getCachedUser', () {
    test('should return UserEntity when cache has valid data', () async {
      // Arrange
      const userJson = '{"id":1,"email":"test@example.com","nombre":"Test User","token":"test_token"}';
      when(mockSharedPreferences.getString(AppConfig.userKey))
          .thenReturn(userJson);

      // Act
      final result = await repository.getCachedUser();

      // Assert
      expect(result, isNotNull);
      expect(result!.id, 1);
      expect(result.email, 'test@example.com');
      expect(result.nombre, 'Test User');
      expect(result.token, 'test_token');
    });

    test('should return null when cache is empty', () async {
      // Arrange
      when(mockSharedPreferences.getString(AppConfig.userKey))
          .thenReturn(null);

      // Act
      final result = await repository.getCachedUser();

      // Assert
      expect(result, isNull);
    });

    test('should return null when cache data is invalid', () async {
      // Arrange
      when(mockSharedPreferences.getString(AppConfig.userKey))
          .thenReturn('invalid json');

      // Act
      final result = await repository.getCachedUser();

      // Assert
      expect(result, isNull);
    });
  });

  group('AuthRepository - isAuthenticated', () {
    test('should return true when token and user exist', () async {
      // Arrange
      const userJson = '{"id":1,"email":"test@example.com","nombre":"Test User","token":"test_token"}';
      when(mockSharedPreferences.getString(AppConfig.tokenKey))
          .thenReturn('test_token');
      when(mockSharedPreferences.getString(AppConfig.userKey))
          .thenReturn(userJson);

      // Act
      final result = await repository.isAuthenticated();

      // Assert
      expect(result, true);
    });

    test('should return false when token is null', () async {
      // Arrange
      const userJson = '{"id":1,"email":"test@example.com","nombre":"Test User","token":"test_token"}';
      when(mockSharedPreferences.getString(AppConfig.tokenKey))
          .thenReturn(null);
      when(mockSharedPreferences.getString(AppConfig.userKey))
          .thenReturn(userJson);

      // Act
      final result = await repository.isAuthenticated();

      // Assert
      expect(result, false);
    });

    test('should return false when token is empty', () async {
      // Arrange
      const userJson = '{"id":1,"email":"test@example.com","nombre":"Test User","token":"test_token"}';
      when(mockSharedPreferences.getString(AppConfig.tokenKey))
          .thenReturn('');
      when(mockSharedPreferences.getString(AppConfig.userKey))
          .thenReturn(userJson);

      // Act
      final result = await repository.isAuthenticated();

      // Assert
      expect(result, false);
    });

    test('should return false when user is null', () async {
      // Arrange
      when(mockSharedPreferences.getString(AppConfig.tokenKey))
          .thenReturn('test_token');
      when(mockSharedPreferences.getString(AppConfig.userKey))
          .thenReturn(null);

      // Act
      final result = await repository.isAuthenticated();

      // Assert
      expect(result, false);
    });

    test('should return false when both token and user are null', () async {
      // Arrange
      when(mockSharedPreferences.getString(AppConfig.tokenKey))
          .thenReturn(null);
      when(mockSharedPreferences.getString(AppConfig.userKey))
          .thenReturn(null);

      // Act
      final result = await repository.isAuthenticated();

      // Assert
      expect(result, false);
    });
  });
}
