import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:herramienta_case/core/config/app_config.dart';
import 'package:herramienta_case/core/config/env_config.dart';
import 'package:herramienta_case/core/errors/exceptions.dart';
import 'api_endpoints.dart';

/// Centralized HTTP client for all API communication.
///
/// Wraps the [http.Client] with authentication token management,
/// connection profile routing, consistent header injection, and
/// structured HTTP error handling mapped to typed [AppException] subclasses.
///
/// The client persists the auth token and connection profile in
/// [SharedPreferences] so they survive application restarts.
class ApiClient {
  final http.Client _client;
  String? _authToken;
  String? _connectionProfile;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  /// Loads the persisted auth token and connection profile from [SharedPreferences].
  ///
  /// Must be called once during application startup before issuing any request.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString(AppConfig.tokenKey);
    _connectionProfile = prefs.getString(AppConfig.connectionProfileKey);
  }

  /// Sets the auth [token] in memory and persists it to [SharedPreferences].
  ///
  /// Pass `null` to remove the stored token (i.e. on logout).
  Future<void> setAuthToken(String? token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString(AppConfig.tokenKey, token);
    } else {
      await prefs.remove(AppConfig.tokenKey);
    }
  }

  /// Returns the current in-memory auth token, or `null` if not set.
  String? getAuthToken() => _authToken;

  /// Returns `true` if a non-empty auth token is currently set.
  bool isAuthenticated() => _authToken != null && _authToken!.isNotEmpty;

  /// Sets the active connection [profile] and persists it to [SharedPreferences].
  ///
  /// The profile value is forwarded as the `X-Connection-Profile` header on
  /// every subsequent request, allowing the backend to route traffic to the
  /// correct server instance. Pass `null` to clear the profile.
  Future<void> setConnectionProfile(String? profile) async {
    _connectionProfile = profile;
    final prefs = await SharedPreferences.getInstance();
    if (profile != null) {
      await prefs.setString(AppConfig.connectionProfileKey, profile);
    } else {
      await prefs.remove(AppConfig.connectionProfileKey);
    }
  }

  /// Returns the currently active connection profile name, or `null` if not set.
  String? getConnectionProfile() => _connectionProfile;

  /// Builds the base headers for every outgoing request.
  ///
  /// Always includes `Content-Type` and `Accept`. Conditionally adds
  /// `X-Connection-Profile` for multi-server routing, `Authorization`
  /// when [includeAuth] is true, and any [customHeaders] provided by
  /// the caller.
  Map<String, String> _getHeaders({
    bool includeAuth = true,
    Map<String, String>? customHeaders,
  }) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (_connectionProfile != null && _connectionProfile!.isNotEmpty) {
      headers['X-Connection-Profile'] = _connectionProfile!;
    }

    if (includeAuth && _authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }

    return headers;
  }

  /// Maps a non-2xx [response] to a typed [AppException].
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

  /// Extracts a human-readable error message from an HTTP [response] body.
  String _extractErrorMessage(http.Response response) {
    try {
      final json = jsonDecode(response.body);
      return json['message'] ?? json['error'] ?? 'Error desconocido';
    } catch (e) {
      return response.body.isNotEmpty ? response.body : 'Error desconocido';
    }
  }

  /// Sends an authenticated GET request to [endpoint] and returns the decoded JSON body.
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

  /// Sends an authenticated POST request to [endpoint] with an optional JSON [body].
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

  /// Sends an authenticated PUT request to [endpoint] with an optional JSON [body].
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

  /// Sends an authenticated DELETE request to [endpoint].
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

  /// Releases resources held by the underlying HTTP client.
  void dispose() {
    _client.close();
  }
}
