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
      final endpoint = ApiEndpoints.login;

      print('🔐 Intentando login con usuario: $username');
      print('🗄️ Base de datos: ${databaseName ?? "No especificada (Modo Selección de Server)"}');
      print('📍 URL: ${ApiEndpoints.buildUrl(endpoint)}');

      // Preparar headers personalizados con las credenciales
      final headers = {
        'X-Usuario': username,
        'X-Password': password,
      };

      // Siempre enviar "master" para login (requerido por el backend)
      // El SP sp_ValidarLoginFinal siempre corre en master,
      // independientemente de la BD seleccionada por el usuario
      headers['X-DbName'] = 'master';

      print('📤 Headers: ${headers.keys.join(", ")}');

      final response = await apiClient.post(
        endpoint,
        includeAuth: false,
        customHeaders: headers,
      );

      print('✅ Respuesta recibida: $response');

      // Validamos que exista al menos el token
      if (response.containsKey('token')) {
        
        // 1. Parseamos la respuesta completa usando el Modelo actualizado
        // Esto extraerá rol, moduloOrigen, email, etc. directamente del SP
        final userModel = UserModel.fromJson(response);

        // 2. Guardamos el token (necesario para ambos casos)
        await apiClient.setAuthToken(userModel.token);
        print('✅ Token guardado.');

        // 3. Lógica Especial: Detección de Perfil de Conexión
        // Si el login fue para configurar el servidor (Remote, Azure, etc.)
        if (userModel.role == 'ProfileConnection') {
          print('🌐 Perfil de conexión detectado: ${userModel.moduloOrigen}');
          
          if (userModel.moduloOrigen != null && userModel.moduloOrigen!.isNotEmpty) {
            // Guardamos el perfil en SharedPreferences/Memoria del ApiClient
            // Esto asegura que la próxima petición (listar BDs) lleve el header X-Connection-Profile
            await apiClient.setConnectionProfile(userModel.moduloOrigen!);
            print('✅ Header X-Connection-Profile configurado a: ${userModel.moduloOrigen}');
          }
        }

        return userModel;
      }

      throw Exception('La respuesta del servidor no contiene un token válido.');
      
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
      // Opcional: ¿Quieres limpiar el ConnectionProfile al hacer logout?
      // Generalmente NO, para que el usuario no tenga que re-elegir servidor.
      // await apiClient.setConnectionProfile(null); 
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
        moduloOrigen: 'Local',
      );

      await apiClient.setAuthToken(mockUser.token);
      return mockUser;
    } else {
      throw Exception('Credenciales incorrectas');
    }
  }
}