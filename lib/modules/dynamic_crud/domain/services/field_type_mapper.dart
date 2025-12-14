import 'package:flutter/material.dart';

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

  static String getFlutterType(String sqlType) {
    final type = sqlType.toLowerCase();
    return _sqlToFlutterType[type] ?? 'String';
  }

  static bool isNumericType(String sqlType) {
    final type = sqlType.toLowerCase();
    return ['int', 'bigint', 'smallint', 'tinyint', 'decimal', 'numeric', 'float', 'real', 'money', 'smallmoney'].contains(type);
  }

  static bool isIntegerType(String sqlType) {
    final type = sqlType.toLowerCase();
    return ['int', 'bigint', 'smallint', 'tinyint'].contains(type);
  }

  static bool isDecimalType(String sqlType) {
    final type = sqlType.toLowerCase();
    return ['decimal', 'numeric', 'float', 'real', 'money', 'smallmoney'].contains(type);
  }

  static bool isStringType(String sqlType) {
    final type = sqlType.toLowerCase();
    return ['varchar', 'nvarchar', 'char', 'nchar', 'text', 'ntext'].contains(type);
  }

  static bool isDateTimeType(String sqlType) {
    final type = sqlType.toLowerCase();
    return ['datetime', 'datetime2', 'date', 'time'].contains(type);
  }

  static bool isBooleanType(String sqlType) {
    final type = sqlType.toLowerCase();
    return type == 'bit';
  }

  static bool isTextType(String sqlType) {
    final type = sqlType.toLowerCase();
    return ['text', 'ntext'].contains(type);
  }

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
        if (value is DateTime) return value;
        return DateTime.tryParse(value.toString());
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
