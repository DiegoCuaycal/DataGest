import '../../data/models/column_info_model.dart';

/// Service providing field-level validation logic for dynamically generated forms.
class ValidationService {
  /// Validates [value] against the constraints defined in [column].
  ///
  /// Returns an error message string if validation fails, or `null` if the
  /// value is acceptable. Checks:
  /// - Required fields (non-nullable columns must have a non-empty value).
  /// - Maximum string length for character types.
  /// - Integer and decimal parseability.
  /// - Date/time parseability.
  static String? validateField(
    ColumnInfoModel column,
    dynamic value,
  ) {
    // Check if required field is empty
    if (!column.nullable && (value == null || value.toString().isEmpty)) {
      return 'Campo requerido';
    }

    // If value is null or empty and field is nullable, it's valid
    if (value == null || value.toString().isEmpty) {
      return null;
    }

    final type = column.type.toLowerCase();

    // Validate string length
    if (['varchar', 'nvarchar', 'char', 'nchar'].contains(type)) {
      final maxLength = column.maxLength;
      if (maxLength != null && value.toString().length > maxLength) {
        return 'Máximo $maxLength caracteres';
      }
    }

    // Validate integer
    if (['int', 'bigint', 'smallint', 'tinyint'].contains(type)) {
      if (int.tryParse(value.toString()) == null) {
        return 'Debe ser un número entero';
      }
    }

    // Validate decimal
    if (['decimal', 'numeric', 'float', 'real', 'money', 'smallmoney'].contains(type)) {
      if (double.tryParse(value.toString()) == null) {
        return 'Debe ser un número válido';
      }
    }

    // Validate date
    if (['datetime', 'datetime2', 'date', 'time'].contains(type)) {
      if (value is! DateTime && DateTime.tryParse(value.toString()) == null) {
        return 'Fecha inválida';
      }
    }

    return null;
  }

  /// Returns `true` if [email] matches a standard email format.
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Returns `true` if [url] is a valid HTTP or HTTPS URL.
  static bool isValidUrl(String url) {
    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );
    return urlRegex.hasMatch(url);
  }

  /// Returns `true` if [phone] contains only digits, spaces, and common
  /// phone separators, and has at least 7 numeric digits.
  static bool isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^[\d\s\-\+\(\)]+$');
    return phoneRegex.hasMatch(phone) && phone.replaceAll(RegExp(r'[\s\-\+\(\)]'), '').length >= 7;
  }
}
