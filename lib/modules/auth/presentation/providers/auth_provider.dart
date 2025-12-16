import 'package:herramienta_case/modules/auth/data/repositories/auth_repository.dart';
import 'package:herramienta_case/modules/auth/domain/entities/user_entity.dart';
import 'package:herramienta_case/shared/providers/app_provider.dart';

/// Provider de autenticación
class AuthProvider extends AppProvider {
  final AuthRepository authRepository;

  UserEntity? _currentUser;
  bool _isAuthenticated = false;

  AuthProvider({required this.authRepository});

  /// Usuario actual
  UserEntity? get currentUser => _currentUser;

  /// Indica si el usuario está autenticado
  bool get isAuthenticated => _isAuthenticated;

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
    required String email,
    required String password,
  }) async {
    try {
      setLoading(true);
      clearError();

      final user = await authRepository.login(
        email: email,
        password: password,
      );

      _currentUser = user;
      _isAuthenticated = true;

      setLoading(false);
      return true;
    } catch (e) {
      setError(_getErrorMessage(e));
      _isAuthenticated = false;
      _currentUser = null;
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
      clearState();
    }
  }

  /// Obtiene un mensaje de error amigable
  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('credenciales incorrectas') ||
        errorStr.contains('incorrect') ||
        errorStr.contains('invalid')) {
      return 'Credenciales incorrectas';
    } else if (errorStr.contains('network') ||
        errorStr.contains('conexión') ||
        errorStr.contains('internet')) {
      return 'Error de conexión. Verifica tu internet';
    } else if (errorStr.contains('timeout') ||
        errorStr.contains('time out')) {
      return 'Tiempo de espera agotado';
    } else if (errorStr.contains('server') ||
        errorStr.contains('500') ||
        errorStr.contains('502') ||
        errorStr.contains('503')) {
      return 'Error del servidor. Intenta más tarde';
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
