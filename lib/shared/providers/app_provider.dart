import 'package:flutter/material.dart';

/// Provider base para estado de la aplicación
class AppProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  /// Indica si hay una operación en progreso
  bool get isLoading => _isLoading;

  /// Mensaje de error actual
  String? get errorMessage => _errorMessage;

  /// Indica si hay un error
  bool get hasError => _errorMessage != null;

  /// Establece el estado de carga
  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Establece un mensaje de error
  void setError(String? message) {
    _errorMessage = message;
    _isLoading = false;
    notifyListeners();
  }

  /// Limpia el mensaje de error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Limpia el estado
  void clearState() {
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Ejecuta una acción asíncrona manejando el estado de carga y errores
  Future<T?> executeAsync<T>(
    Future<T> Function() action, {
    String? errorMessage,
  }) async {
    try {
      setLoading(true);
      clearError();
      final result = await action();
      setLoading(false);
      return result;
    } catch (e) {
      setError(errorMessage ?? e.toString());
      return null;
    }
  }
}
