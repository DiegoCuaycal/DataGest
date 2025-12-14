import 'package:equatable/equatable.dart';

/// Clase base para errores de la capa de dominio
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];

  @override
  String toString() => message;
}

/// Fallo de servidor
class ServerFailure extends Failure {
  const ServerFailure([String message = 'Error del servidor']) : super(message);
}

/// Fallo de red/conexión
class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'Error de conexión']) : super(message);
}

/// Fallo de caché
class CacheFailure extends Failure {
  const CacheFailure([String message = 'Error de caché']) : super(message);
}

/// Fallo de validación
class ValidationFailure extends Failure {
  final Map<String, String>? errors;

  const ValidationFailure(String message, {this.errors}) : super(message);

  @override
  List<Object?> get props => [message, errors];
}

/// Fallo de autenticación
class AuthFailure extends Failure {
  const AuthFailure([String message = 'Error de autenticación']) : super(message);
}

/// Fallo de autorización
class AuthorizationFailure extends Failure {
  const AuthorizationFailure([String message = 'No autorizado']) : super(message);
}

/// Fallo de no encontrado
class NotFoundFailure extends Failure {
  const NotFoundFailure([String message = 'Recurso no encontrado']) : super(message);
}

/// Fallo genérico
class GenericFailure extends Failure {
  const GenericFailure([String message = 'Ha ocurrido un error']) : super(message);
}
