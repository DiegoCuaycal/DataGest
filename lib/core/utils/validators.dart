class Validators {
  /// Valida que un campo no esté vacío
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null
          ? '$fieldName es requerido'
          : 'Este campo es requerido';
    }
    return null;
  }

  /// Valida el formato de un correo electrónico
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El correo electrónico es requerido';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Ingresa un correo electrónico válido';
    }

    return null;
  }

  /// Valida la longitud mínima de una contraseña
  static String? password(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }

    if (value.length < minLength) {
      return 'La contraseña debe tener al menos $minLength caracteres';
    }

    return null;
  }

  /// Valida que las contraseñas coincidan
  static String? confirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Confirma tu contraseña';
    }

    if (value != password) {
      return 'Las contraseñas no coinciden';
    }

    return null;
  }

  /// Valida longitud mínima de un campo
  static String? minLength(String? value, int min, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return fieldName != null
          ? '$fieldName es requerido'
          : 'Este campo es requerido';
    }

    if (value.length < min) {
      return fieldName != null
          ? '$fieldName debe tener al menos $min caracteres'
          : 'Debe tener al menos $min caracteres';
    }

    return null;
  }

  /// Valida longitud máxima de un campo
  static String? maxLength(String? value, int max, {String? fieldName}) {
    if (value != null && value.length > max) {
      return fieldName != null
          ? '$fieldName no puede exceder $max caracteres'
          : 'No puede exceder $max caracteres';
    }

    return null;
  }

  /// Valida que un valor sea numérico
  static String? numeric(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return fieldName != null
          ? '$fieldName es requerido'
          : 'Este campo es requerido';
    }

    if (double.tryParse(value) == null) {
      return fieldName != null
          ? '$fieldName debe ser un número válido'
          : 'Debe ser un número válido';
    }

    return null;
  }

  /// Valida que un número sea positivo
  static String? positiveNumber(String? value, {String? fieldName}) {
    final numericError = numeric(value, fieldName: fieldName);
    if (numericError != null) return numericError;

    final number = double.parse(value!);
    if (number <= 0) {
      return fieldName != null
          ? '$fieldName debe ser un número positivo'
          : 'Debe ser un número positivo';
    }

    return null;
  }

  /// Valida formato de teléfono (ejemplo básico)
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El teléfono es requerido';
    }

    final phoneRegex = RegExp(r'^[0-9]{8,15}$');
    final cleanValue = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    if (!phoneRegex.hasMatch(cleanValue)) {
      return 'Ingresa un teléfono válido (8-15 dígitos)';
    }

    return null;
  }

  /// Valida formato de URL
  static String? url(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La URL es requerida';
    }

    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );

    if (!urlRegex.hasMatch(value.trim())) {
      return 'Ingresa una URL válida';
    }

    return null;
  }

  /// Combina múltiples validadores
  static String? combine(List<String? Function()> validators) {
    for (final validator in validators) {
      final error = validator();
      if (error != null) return error;
    }
    return null;
  }

  /// Constructor privado para evitar instanciación
  Validators._();
}
