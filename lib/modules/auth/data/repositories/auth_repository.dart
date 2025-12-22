import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:herramienta_case/core/config/app_config.dart';
import 'package:herramienta_case/core/errors/exceptions.dart';
import 'package:herramienta_case/modules/auth/data/datasources/auth_remote_datasource.dart';
import 'package:herramienta_case/modules/auth/data/models/user_model.dart';
import 'package:herramienta_case/modules/auth/domain/entities/user_entity.dart';

/// Repositorio de autenticación
class AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final SharedPreferences sharedPreferences;

  AuthRepository({
    required this.remoteDataSource,
    required this.sharedPreferences,
  });

  /// Realiza login
  Future<UserEntity> login({
    required String username,
    required String password,
    String? databaseName,
  }) async {
    try {
      // Usar API real para login
      final userModel = await remoteDataSource.login(
        username: username,
        password: password,
        databaseName: databaseName,
      );

      // Guardar usuario en caché local
      await _cacheUser(userModel);

      return userModel.toEntity();
    } on NetworkException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  /// Cierra sesión
  Future<void> logout() async {
    try {
      await remoteDataSource.logout();
      await _clearCache();
    } catch (e) {
      // Limpiar caché local aunque falle la petición al servidor
      await _clearCache();
    }
  }

  /// Obtiene el usuario cacheado
  Future<UserEntity?> getCachedUser() async {
    try {
      final userJson = sharedPreferences.getString(AppConfig.userKey);
      if (userJson != null) {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        final userModel = UserModel.fromJson(userMap);
        return userModel.toEntity();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Verifica si hay un usuario autenticado
  Future<bool> isAuthenticated() async {
    final token = sharedPreferences.getString(AppConfig.tokenKey);
    final user = await getCachedUser();
    return token != null && token.isNotEmpty && user != null;
  }

  /// Guarda el usuario en caché local
  Future<void> _cacheUser(UserModel user) async {
    await sharedPreferences.setString(
      AppConfig.userKey,
      jsonEncode(user.toJson()),
    );
    await sharedPreferences.setString(
      AppConfig.tokenKey,
      user.token,
    );
  }

  /// Limpia el caché de autenticación
  Future<void> _clearCache() async {
    await sharedPreferences.remove(AppConfig.userKey);
    await sharedPreferences.remove(AppConfig.tokenKey);
  }
}
