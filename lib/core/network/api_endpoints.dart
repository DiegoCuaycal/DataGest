import 'package:herramienta_case/core/config/env_config.dart';

class ApiEndpoints {
  /// URL base de la API
  static String get baseUrl => EnvConfig.apiUrl;

  // Endpoints de autenticación
  static const String login = '/api/Auth/login';
  static const String logout = '/api/Auth/logout';
  static const String register = '/api/Auth/register';
  static const String refreshToken = '/api/Auth/refresh';
  static const String forgotPassword = '/api/Auth/forgot-password';
  static const String resetPassword = '/api/Auth/reset-password';
  static const String profile = '/api/Auth/profile';

  // Endpoints de herramientas CASE
  static const String tools = '/tools';
  static String toolById(int id) => '/tools/$id';
  static const String toolsSearch = '/tools/search';
  static const String toolsCategories = '/tools/categories';

  // Endpoints de usuarios (admin)
  static const String users = '/users';
  static String userById(int id) => '/users/$id';

  // Endpoints públicos (sin BD específica)
  static const String databases = '/api/Schema/databases';

  // Endpoints dinámicos (requieren databaseName)
  static String loginDynamic(String dbName) => '/api/$dbName/auth/login';
  static const String schemaGenerate = '/api/Schema/generate';
  static String metadata(String dbName) => '/api/Schema/generate?db=$dbName';
  static String tableList(String dbName, String table) => '/api/$dbName/table/$table';
  static String tableRecord(String dbName, String table, dynamic id) => '/api/$dbName/table/$table/$id';
  static String tableDropdown(String dbName, String table) => '/api/$dbName/table/$table/dropdown';

  /// Construye una URL completa
  static String buildUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }

  ApiEndpoints._();
}
