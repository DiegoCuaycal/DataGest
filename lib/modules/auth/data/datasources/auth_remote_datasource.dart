import 'package:herramienta_case/core/network/api_client.dart';
import 'package:herramienta_case/core/network/api_endpoints.dart';
import 'package:herramienta_case/core/network/api_response.dart';
import 'package:herramienta_case/modules/auth/data/models/user_model.dart';

/// Remote data source for authentication operations.
class AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSource({required this.apiClient});

  /// Authenticates the user with [username] and [password].
  ///
  /// Sends credentials via custom headers (`X-Usuario`, `X-Password`,
  /// `X-DbName`) to the login endpoint. On success, stores the returned
  /// JWT token in [ApiClient] and — when the response indicates a
  /// connection profile — sets the `X-Connection-Profile` header for
  /// subsequent requests.
  ///
  /// Throws an [Exception] if the response does not contain a valid token.
  Future<UserModel> login({
    required String username,
    required String password,
    String? databaseName,
  }) async {
    try {
      final endpoint = ApiEndpoints.login;

      final headers = {
        'X-Usuario': username,
        'X-Password': password,
        // The login stored procedure always runs against 'master',
        // regardless of the database the user will access afterwards.
        'X-DbName': 'master',
      };

      final response = await apiClient.post(
        endpoint,
        includeAuth: false,
        customHeaders: headers,
      );

      if (response.containsKey('token')) {
        final userModel = UserModel.fromJson(response);

        await apiClient.setAuthToken(userModel.token);

        // When the role is 'ProfileConnection', the login response carries
        // the server profile name in moduloOrigen. Persist it so that the
        // next request includes the correct X-Connection-Profile header.
        if (userModel.role == 'ProfileConnection') {
          if (userModel.moduloOrigen != null && userModel.moduloOrigen!.isNotEmpty) {
            await apiClient.setConnectionProfile(userModel.moduloOrigen!);
          }
        }

        return userModel;
      }

      throw Exception('La respuesta del servidor no contiene un token válido.');
    } catch (e) {
      rethrow;
    }
  }

  /// Signs the user out by calling the logout endpoint and clearing the local token.
  ///
  /// Server-side errors are intentionally suppressed — the local session is
  /// always cleaned up regardless of the API response.
  Future<void> logout() async {
    try {
      await apiClient.post(
        ApiEndpoints.logout,
        includeAuth: true,
      );
    } catch (e) {
      // Server-side logout failure is non-critical; local cleanup proceeds.
    } finally {
      await apiClient.setAuthToken(null);
    }
  }

  /// Fetches the profile of the currently authenticated user.
  Future<UserModel> getProfile() async {
    final response = await apiClient.get(
      ApiEndpoints.profile,
      includeAuth: true,
    );

    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      response,
      (data) => data as Map<String, dynamic>,
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw Exception(apiResponse.message);
    }

    return UserModel.fromJson(apiResponse.data!);
  }

  /// Returns a mock [UserModel] for offline UI development.
  ///
  /// Accepts `admin` / `123456` as valid credentials.
  Future<UserModel> mockLogin({
    required String username,
    required String password,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    if (username == 'admin' && password == '123456') {
      final mockUser = UserModel(
        id: 1,
        username: username,
        email: 'admin@test.com',
        nombre: 'Usuario Administrador',
        role: 'Administrador',
        roleId: 1,
        token: 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}',
        moduloOrigen: 'Local',
      );

      await apiClient.setAuthToken(mockUser.token);
      return mockUser;
    } else {
      throw Exception('Credenciales incorrectas');
    }
  }
}
