import 'package:herramienta_case/core/network/api_client.dart';
import 'package:herramienta_case/core/network/api_endpoints.dart';
import 'package:herramienta_case/core/network/api_response.dart';
import 'package:herramienta_case/modules/auth/data/models/user_model.dart';

/// Fuente de datos remota para autenticación
class AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSource({required this.apiClient});

  Future<UserModel> login({
    required String username,
    required String password,
    String? databaseName,
  }) async {
    try {
      // La API de Azure usa el endpoint /api/Auth/login para todas las bases de datos
      // y requiere el nombre de la BD en el header X-DbName
      final endpoint = ApiEndpoints.login;

      print('🔐 Intentando login con usuario: $username');
      print('🗄️  Base de datos: ${databaseName ?? "No especificada"}');
      print('📍 URL: ${ApiEndpoints.buildUrl(endpoint)}');

      // Preparar headers personalizados
      final headers = {
        'X-Usuario': username,
        'X-Password': password,
      };

      // Agregar el header X-DbName solo si se especifica una base de datos
      if (databaseName != null && databaseName.isNotEmpty) {
        headers['X-DbName'] = databaseName;
      }

      final response = await apiClient.post(
        endpoint,
        includeAuth: false,
        customHeaders: headers,
      );

      print('✅ Respuesta recibida: $response');

      // La API de Azure devuelve solo el token en el formato: {"token": "jwt_token"}
      // No devuelve información del usuario, solo el token
      if (response.containsKey('token')) {
        final token = response['token'] as String;

        // Crear un UserModel con la información disponible
        // Como la API solo devuelve el token, usamos los datos que tenemos
        final userModel = UserModel(
          id: 1, // Se podría decodificar del JWT si es necesario
          username: username,
          email: '', // No disponible en la respuesta
          nombre: username, // Usar username como nombre temporal
          role: 'Usuario', // Rol por defecto
          roleId: 1,
          token: token,
        );

        await apiClient.setAuthToken(token);
        print('✅ Login exitoso. Token guardado.');
        return userModel;
      }

      throw Exception('Respuesta inválida del servidor');
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
    required String username,
    required String password,
  }) async {
    // Simular delay de red
    await Future.delayed(const Duration(seconds: 1));

    // Credenciales de prueba
    if (username == 'admin' && password == '123456') {
      final mockUser = UserModel(
        id: 1,
        username: username,
        email: 'admin@test.com',
        nombre: 'Usuario Administrador',
        role: 'Administrador',
        roleId: 1,
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
