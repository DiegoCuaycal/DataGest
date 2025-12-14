import 'package:herramienta_case/core/network/api_client.dart';
import 'package:herramienta_case/core/network/api_endpoints.dart';
import 'package:herramienta_case/core/network/api_response.dart';
import 'package:herramienta_case/modules/auth/data/models/user_model.dart';

/// Fuente de datos remota para autenticación
class AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSource({required this.apiClient});

  /// Realiza login con email y contraseña
  /// Las credenciales se envían en los headers según la API:
  /// X-Usuario: usuario
  /// X-Password: contraseña
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 Intentando login con usuario: $email');
      print('📍 URL: ${ApiEndpoints.buildUrl(ApiEndpoints.login)}');

      final response = await apiClient.post(
        ApiEndpoints.login,
        includeAuth: false,
        customHeaders: {
          'X-Usuario': email,
          'X-Password': password,
        },
      );

      print('✅ Respuesta recibida: $response');

      // Intentar parsear como ApiResponse primero
      try {
        final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
          response,
          (data) => data as Map<String, dynamic>,
        );

        if (!apiResponse.success || apiResponse.data == null) {
          throw Exception(apiResponse.message);
        }

        final userModel = UserModel.fromJson(apiResponse.data!);
        await apiClient.setAuthToken(userModel.token);
        return userModel;
      } catch (e) {
        print('⚠️ Error al parsear como ApiResponse: $e');
        print('📄 Intentando parsear respuesta directa...');

        // Si falla, intentar parsear directamente (algunos backends no usan ApiResponse)
        final userModel = UserModel.fromJson(response);
        await apiClient.setAuthToken(userModel.token);
        return userModel;
      }
    } catch (e) {
      print('❌ Error en login: $e');
      rethrow;
    }
  }

  /// Cierra sesión
  Future<void> logout() async {
    try {
      await apiClient.post(
        ApiEndpoints.logout,
        includeAuth: true,
      );
    } catch (e) {
      // Ignorar errores del servidor en logout
    } finally {
      // Siempre limpiar el token localmente
      await apiClient.setAuthToken(null);
    }
  }

  /// Obtiene el perfil del usuario actual
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

  /// Mock de login para testing sin backend
  Future<UserModel> mockLogin({
    required String email,
    required String password,
  }) async {
    // Simular delay de red
    await Future.delayed(const Duration(seconds: 1));

    // Credenciales de prueba
    if (email == 'admin@test.com' && password == '123456') {
      final mockUser = UserModel(
        id: 1,
        email: email,
        nombre: 'Usuario Administrador',
        token: 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}',
      );

      // Guardar el token en el cliente API
      await apiClient.setAuthToken(mockUser.token);

      return mockUser;
    } else {
      throw Exception('Credenciales incorrectas');
    }
  }
}
