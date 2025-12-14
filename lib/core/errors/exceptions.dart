/// Excepción base de la aplicación
abstract class AppException implements Exception {
  final String message;

  AppException(this.message);

  @override
  String toString() => message;
}

/// Excepción de servidor (500, 502, 503)
class ServerException extends AppException {
  ServerException([String message = 'Error del servidor'])
      : super(message);
}

/// Excepción de petición incorrecta (400)
class BadRequestException extends AppException {
  BadRequestException([String message = 'Petición incorrecta'])
      : super(message);
}

/// Excepción de no autorizado (401)
class UnauthorizedException extends AppException {
  UnauthorizedException([String message = 'No autorizado'])
      : super(message);
}

/// Excepción de prohibido (403)
class ForbiddenException extends AppException {
  ForbiddenException([String message = 'Acceso prohibido'])
      : super(message);
}

/// Excepción de no encontrado (404)
class NotFoundException extends AppException {
  NotFoundException([String message = 'Recurso no encontrado'])
      : super(message);
}

/// Excepción de red/conexión
class NetworkException extends AppException {
  NetworkException([String message = 'Error de conexión'])
      : super(message);
}

/// Excepción de caché
class CacheException extends AppException {
  CacheException([String message = 'Error de caché'])
      : super(message);
}

/// Excepción de tiempo de espera agotado
class TimeoutException extends AppException {
  TimeoutException([String message = 'Tiempo de espera agotado'])
      : super(message);
}

/// Excepción de validación
class ValidationException extends AppException {
  final Map<String, String>? errors;

  ValidationException(String message, {this.errors}) : super(message);
}
