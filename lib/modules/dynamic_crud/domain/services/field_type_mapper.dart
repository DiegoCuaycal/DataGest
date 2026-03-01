import 'package:flutter/material.dart';

/// Utility class for mapping SQL Server data types to their Flutter equivalents.
///
/// Provides type classification predicates, keyboard type resolution,
/// and value parsing used throughout the dynamic form generation pipeline.
class FieldTypeMapper {
  static const Map<String, String> _sqlToFlutterType = {
    'int': 'int',
    'bigint': 'int',
    'smallint': 'int',
    'tinyint': 'int',
    'decimal': 'double',
    'numeric': 'double',
    'float': 'double',
    'real': 'double',
    'money': 'double',
    'smallmoney': 'double',
    'varchar': 'String',
    'nvarchar': 'String',
    'char': 'String',
    'nchar': 'String',
    'text': 'String',
    'ntext': 'String',
    'datetime': 'DateTime',
    'datetime2': 'DateTime',
    'date': 'DateTime',
    'time': 'DateTime',
    'bit': 'bool',
  };

  /// Returns the Dart type name for a given [sqlType], defaulting to `'String'`.
  static String getFlutterType(String sqlType) {
    final type = sqlType.toLowerCase();
    return _sqlToFlutterType[type] ?? 'String';
  }

  /// Returns `true` if [sqlType] is any numeric SQL type.
  static bool isNumericType(String sqlType) {
    final type = sqlType.toLowerCase();
    return ['int', 'bigint', 'smallint', 'tinyint', 'decimal', 'numeric', 'float', 'real', 'money', 'smallmoney'].contains(type);
  }

  /// Returns `true` if [sqlType] is an integer SQL type.
  static bool isIntegerType(String sqlType) {
    final type = sqlType.toLowerCase();
    return ['int', 'bigint', 'smallint', 'tinyint'].contains(type);
  }

  /// Returns `true` if [sqlType] is a fixed or floating-point decimal SQL type.
  static bool isDecimalType(String sqlType) {
    final type = sqlType.toLowerCase();
    return ['decimal', 'numeric', 'float', 'real', 'money', 'smallmoney'].contains(type);
  }

  /// Returns `true` if [sqlType] is a character/string SQL type.
  static bool isStringType(String sqlType) {
    final type = sqlType.toLowerCase();
    return ['varchar', 'nvarchar', 'char', 'nchar', 'text', 'ntext'].contains(type);
  }

  /// Returns `true` if [sqlType] is a date or time SQL type.
  static bool isDateTimeType(String sqlType) {
    final type = sqlType.toLowerCase();
    return ['datetime', 'datetime2', 'date', 'time'].contains(type);
  }

  /// Returns `true` if [sqlType] is a boolean (`bit`) SQL type.
  static bool isBooleanType(String sqlType) {
    final type = sqlType.toLowerCase();
    return type == 'bit';
  }

  /// Returns `true` if [sqlType] is a large text SQL type (`text` or `ntext`).
  static bool isTextType(String sqlType) {
    final type = sqlType.toLowerCase();
    return ['text', 'ntext'].contains(type);
  }

  /// Returns the most appropriate [TextInputType] for a form field whose
  /// column has the given [sqlType].
  static TextInputType getKeyboardType(String sqlType) {
    if (isIntegerType(sqlType)) {
      return TextInputType.number;
    } else if (isDecimalType(sqlType)) {
      return const TextInputType.numberWithOptions(decimal: true);
    } else if (isStringType(sqlType) || isTextType(sqlType)) {
      return TextInputType.text;
    }
    return TextInputType.text;
  }

  /// Parses [value] to the Dart type that corresponds to [sqlType].
  ///
  /// - Integer types → `int`
  /// - Decimal types → `double`
  /// - DateTime types → ISO 8601 `String`
  /// - Boolean types → `bool`
  /// - All others → `String`
  ///
  /// Returns `null` if [value] is `null` or cannot be parsed.
  static dynamic parseValue(String sqlType, dynamic value) {
    if (value == null) return null;

    try {
      if (isIntegerType(sqlType)) {
        if (value is int) return value;
        return int.tryParse(value.toString());
      } else if (isDecimalType(sqlType)) {
        if (value is double) return value;
        return double.tryParse(value.toString());
      } else if (isDateTimeType(sqlType)) {
        if (value is DateTime) {
          return value.toIso8601String();
        }
        final dateTime = DateTime.tryParse(value.toString());
        return dateTime?.toIso8601String();
      } else if (isBooleanType(sqlType)) {
        if (value is bool) return value;
        if (value is int) return value == 1;
        if (value is String) {
          return value.toLowerCase() == 'true' || value == '1';
        }
        return false;
      }
      return value.toString();
    } catch (e) {
      return null;
    }
  }
}
