import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:herramienta_case/core/config/app_config.dart';
import 'package:herramienta_case/core/config/env_config.dart';
import 'package:herramienta_case/core/errors/exceptions.dart';
import 'api_endpoints.dart';

/// Cliente HTTP para comunicación con la API
class ApiClient {
  final http.Client _client;
  String? _authToken;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  /// Inicializa el cliente cargando el token almacenado
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString(AppConfig.tokenKey);
  }

  /// Establece el token de autenticación
  Future<void> setAuthToken(String? token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString(AppConfig.tokenKey, token);
    } else {
      await prefs.remove(AppConfig.tokenKey);
    }
  }

  /// Obtiene el token de autenticación
  String? getAuthToken() => _authToken;

  /// Verifica si el usuario está autenticado
  bool isAuthenticated() => _authToken != null && _authToken!.isNotEmpty;

  /// Headers base para todas las peticiones
  Map<String, String> _getHeaders({
    bool includeAuth = true,
    Map<String, String>? customHeaders,
  }) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth && _authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    // Agregar headers personalizados
    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }

    return headers;
  }

  /// Maneja errores de respuesta HTTP
  void _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    switch (response.statusCode) {
      case 400:
        throw BadRequestException(
          _extractErrorMessage(response),
        );
      case 401:
        throw UnauthorizedException(
          _extractErrorMessage(response),
        );
      case 403:
        throw ForbiddenException(
          _extractErrorMessage(response),
        );
      case 404:
        throw NotFoundException(
          _extractErrorMessage(response),
        );
      case 500:
      case 502:
      case 503:
        throw ServerException(
          _extractErrorMessage(response),
        );
      default:
        throw ServerException(
          'Error ${response.statusCode}: ${_extractErrorMessage(response)}',
        );
    }
  }

  /// Extrae el mensaje de error de la respuesta
  String _extractErrorMessage(http.Response response) {
    try {
      final json = jsonDecode(response.body);
      return json['message'] ?? json['error'] ?? 'Error desconocido';
    } catch (e) {
      return response.body.isNotEmpty ? response.body : 'Error desconocido';
    }
  }

  /// Realiza una petición GET
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParameters,
    bool includeAuth = true,
    Map<String, String>? customHeaders,
  }) async {
    try {
      final uri = Uri.parse(ApiEndpoints.buildUrl(endpoint))
          .replace(queryParameters: queryParameters);

      final response = await _client
          .get(
            uri,
            headers: _getHeaders(
              includeAuth: includeAuth,
              customHeaders: customHeaders,
            ),
          )
          .timeout(Duration(seconds: EnvConfig.apiTimeout));

      _handleResponse(response);
      return jsonDecode(response.body);
    } on SocketException {
      throw NetworkException('Sin conexión a internet');
    } on http.ClientException {
      throw NetworkException('Error de conexión');
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException('Error inesperado: $e');
    }
  }

  /// Realiza una petición POST
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool includeAuth = true,
    Map<String, String>? customHeaders,
  }) async {
    try {
      final uri = Uri.parse(ApiEndpoints.buildUrl(endpoint));

      final response = await _client
          .post(
            uri,
            headers: _getHeaders(
              includeAuth: includeAuth,
              customHeaders: customHeaders,
            ),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(Duration(seconds: EnvConfig.apiTimeout));

      _handleResponse(response);
      return jsonDecode(response.body);
    } on SocketException {
      throw NetworkException('Sin conexión a internet');
    } on http.ClientException {
      throw NetworkException('Error de conexión');
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException('Error inesperado: $e');
    }
  }

  /// Realiza una petición PUT
  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool includeAuth = true,
  }) async {
    try {
      final uri = Uri.parse(ApiEndpoints.buildUrl(endpoint));

      final response = await _client
          .put(
            uri,
            headers: _getHeaders(includeAuth: includeAuth),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(Duration(seconds: EnvConfig.apiTimeout));

      _handleResponse(response);
      return jsonDecode(response.body);
    } on SocketException {
      throw NetworkException('Sin conexión a internet');
    } on http.ClientException {
      throw NetworkException('Error de conexión');
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException('Error inesperado: $e');
    }
  }

  /// Realiza una petición DELETE
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    bool includeAuth = true,
  }) async {
    try {
      final uri = Uri.parse(ApiEndpoints.buildUrl(endpoint));

      final response = await _client
          .delete(
            uri,
            headers: _getHeaders(includeAuth: includeAuth),
          )
          .timeout(Duration(seconds: EnvConfig.apiTimeout));

      _handleResponse(response);
      return jsonDecode(response.body);
    } on SocketException {
      throw NetworkException('Sin conexión a internet');
    } on http.ClientException {
      throw NetworkException('Error de conexión');
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException('Error inesperado: $e');
    }
  }

  /// Cierra el cliente HTTP
  void dispose() {
    _client.close();
  }
}
