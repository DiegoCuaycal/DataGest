import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:herramienta_case/core/config/app_config.dart';
import 'package:herramienta_case/core/errors/exceptions.dart';
import 'package:herramienta_case/modules/auth/data/datasources/auth_remote_datasource.dart';
import 'package:herramienta_case/modules/auth/data/models/user_model.dart';
import 'package:herramienta_case/modules/auth/domain/entities/user_entity.dart';

/// Repository that handles user authentication and local session persistence.
///
/// Delegates credential validation to [AuthRemoteDataSource] and persists
/// the resulting token and user profile in [SharedPreferences] so the
/// session survives application restarts. Also provides methods to read the
/// cached session and to perform a clean logout.
class AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final SharedPreferences sharedPreferences;

  AuthRepository({
    required this.remoteDataSource,
    required this.sharedPreferences,
  });

  /// Authenticates the user with [username] and [password] against the API.
  ///
  /// On success, persists the returned token and user data locally and
  /// returns a [UserEntity]. Rethrows [NetworkException] and [ServerException]
  /// directly; wraps any other error in a [ServerException].
  Future<UserEntity> login({
    required String username,
    required String password,
    String? databaseName,
  }) async {
    try {
      final userModel = await remoteDataSource.login(
        username: username,
        password: password,
        databaseName: databaseName,
      );

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

  /// Signs the user out and removes all locally cached session data.
  ///
  /// The local cache is cleared regardless of whether the remote logout
  /// call succeeds, ensuring the user is always signed out locally.
  Future<void> logout() async {
    try {
      await remoteDataSource.logout();
      await _clearCache();
    } catch (e) {
      await _clearCache();
    }
  }

  /// Returns the locally cached [UserEntity], or `null` if no session exists.
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

  /// Returns `true` if a valid token and cached user are both present.
  Future<bool> isAuthenticated() async {
    final token = sharedPreferences.getString(AppConfig.tokenKey);
    final user = await getCachedUser();
    return token != null && token.isNotEmpty && user != null;
  }

  /// Persists [user] data and token to [SharedPreferences].
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

  /// Removes all authentication data from local storage.
  Future<void> _clearCache() async {
    await sharedPreferences.remove(AppConfig.userKey);
    await sharedPreferences.remove(AppConfig.tokenKey);
  }
}
