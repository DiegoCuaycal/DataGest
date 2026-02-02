import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:herramienta_case/modules/auth/data/repositories/auth_repository.dart';
import 'package:herramienta_case/modules/auth/domain/entities/user_entity.dart';
import 'package:herramienta_case/shared/providers/app_provider.dart';
import 'package:herramienta_case/core/config/env_config.dart'; 

/// Provider de autenticación
class AuthProvider extends AppProvider {
  final AuthRepository authRepository;

  UserEntity? _currentUser;
  bool _isAuthenticated = false;
  String? _currentDatabase;

  AuthProvider({required this.authRepository});

  /// Usuario actual
  UserEntity? get currentUser => _currentUser;

  /// Indica si el usuario está autenticado
  bool get isAuthenticated => _isAuthenticated;

  /// Base de datos actual
  String? get currentDatabase => _currentDatabase;

  /// Inicializa el provider verificando si hay una sesión activa
  Future<void> init() async {
    try {
      _isAuthenticated = await authRepository.isAuthenticated();
      if (_isAuthenticated) {
        _currentUser = await authRepository.getCachedUser();
      }
      notifyListeners();
    } catch (e) {
      _isAuthenticated = false;
      _currentUser = null;
      notifyListeners();
    }
  }

  /// Realiza login
  Future<bool> login({
    required String username,
    required String password,
    String? databaseName,
  }) async {
    try {
      setLoading(true);
      clearError();

      final user = await authRepository.login(
        username: username,
        password: password,
        databaseName: databaseName,
      );

      _currentUser = user;
      _isAuthenticated = true;
      _currentDatabase = databaseName;

      setLoading(false);
      return true;
    } catch (e) {
      setError(_getErrorMessage(e));
      _isAuthenticated = false;
      _currentUser = null;
      _currentDatabase = null;
      return false;
    }
  }

  /// Cierra sesión
  Future<void> logout() async {
    try {
      setLoading(true);
      await authRepository.logout();
    } catch (e) {
      // Ignorar errores en logout
    } finally {
      _currentUser = null;
      _isAuthenticated = false;
      _currentDatabase = null;
      clearState();
    }
  }

  // ===========================================================================
  // NUEVA FUNCIÓN: IMPORTAR MÓDULO (SQL -> API)
  // ===========================================================================
  Future<bool> createModule({
    required String dbName, 
    required String jsonTables
  }) async {
    try {
      setLoading(true); // Usamos tu método heredado
      clearError();

      // URL desde EnvConfig (configurado en .env)
      final uri = Uri.parse('${EnvConfig.apiUrl}/api/Auth/crear-modulo');

      debugPrint("📤 Enviando a: $uri");
      
      // 2. Preparamos el cuerpo exacto como pide el Swagger
      final body = jsonEncode({
        "nombreDb": dbName,
        "jsonTablas": jsonTables, // El JSON convertido a String
      });

      // 3. Hacemos el envío
      final response = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
          // Importante: Enviamos el token del usuario actual para tener permiso
          "Authorization": "Bearer ${currentUser?.token ?? ''}", 
        },
        body: body,
      );

      setLoading(false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("✅ Módulo creado exitosamente en el Backend");
        return true;
      } else {
        debugPrint("❌ Error del servidor (${response.statusCode}): ${response.body}");
        setError("Error al crear la base de datos: ${response.statusCode}");
        return false;
      }

    } catch (e) {
      setLoading(false);
      debugPrint("❌ Error de conexión: $e");
      setError("Error de conexión al importar: $e");
      return false;
    }
  }
  // ===========================================================================

  /// Obtiene un mensaje de error amigable
  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('credenciales incorrectas') ||
        errorStr.contains('incorrect') ||
        errorStr.contains('invalid') ||
        errorStr.contains('unauthorized') ||
        errorStr.contains('401')) {
      return 'Credenciales incorrectas. Verifica tu usuario y contraseña';
    } else if (errorStr.contains('not found') ||
        errorStr.contains('no existe') ||
        errorStr.contains('404')) {
      return 'Usuario no encontrado en esta base de datos';
    } else if (errorStr.contains('user not found') ||
        errorStr.contains('usuario no encontrado')) {
      return 'Usuario no registrado. Verifica las credenciales o crea un nuevo usuario';
    } else if (errorStr.contains('network') ||
        errorStr.contains('conexión') ||
        errorStr.contains('internet') ||
        errorStr.contains('socketexception')) {
      return 'Error de conexión. Verifica tu internet';
    } else if (errorStr.contains('timeout') ||
        errorStr.contains('time out')) {
      return 'Tiempo de espera agotado. Intenta de nuevo';
    } else if (errorStr.contains('server') ||
        errorStr.contains('500') ||
        errorStr.contains('502') ||
        errorStr.contains('503')) {
      return 'Error del servidor. Intenta más tarde';
    } else if (errorStr.contains('database') ||
        errorStr.contains('base de datos')) {
      return 'Error en la base de datos. Verifica que esté seleccionada correctamente';
    }

    return 'Error al iniciar sesión. Intenta de nuevo';
  }

  @override
  void dispose() {
    _currentUser = null;
    _isAuthenticated = false;
    super.dispose();
  }
}