import 'table_entity.dart';

/// Representa el esquema completo de una base de datos personalizada
class DatabaseSchema {
  final String name;
  final String description;
  final List<TableEntity> tables;

  DatabaseSchema({
    required this.name,
    this.description = '',
    List<TableEntity>? tables,
  }) : tables = tables ?? [];

  /// Copia el esquema con cambios específicos
  DatabaseSchema copyWith({
    String? name,
    String? description,
    List<TableEntity>? tables,
  }) {
    return DatabaseSchema(
      name: name ?? this.name,
      description: description ?? this.description,
      tables: tables ?? this.tables,
    );
  }

  /// Agrega una tabla al esquema
  DatabaseSchema addTable(TableEntity table) {
    return copyWith(
      tables: [...tables, table],
    );
  }

  /// Actualiza una tabla del esquema
  DatabaseSchema updateTable(String tableId, TableEntity updatedTable) {
    return copyWith(
      tables: tables
          .map((table) => table.id == tableId ? updatedTable : table)
          .toList(),
    );
  }

  /// Elimina una tabla del esquema
  DatabaseSchema removeTable(String tableId) {
    return copyWith(
      tables: tables.where((table) => table.id != tableId).toList(),
    );
  }

  /// Convierte a JSON para enviar al backend (formato esperado por el backend)
  /// Retorna directamente la lista de tablas como espera el backend
  List<Map<String, dynamic>> toJson() {
    return tables.map((table) => table.toJson()).toList();
  }

  /// Convierte a JSON con metadata (para previsualización)
  Map<String, dynamic> toJsonWithMetadata() {
    return {
      'database_name': name,
      'description': description,
      'tables': toJson(),
    };
  }

  /// Crea un DatabaseSchema desde JSON
  factory DatabaseSchema.fromJson(Map<String, dynamic> json) {
    return DatabaseSchema(
      name: json['database_name'] as String,
      description: json['description'] as String? ?? '',
      tables: (json['tables'] as List<dynamic>?)
              ?.map((table) => TableEntity.fromJson(
                    table as Map<String, dynamic>,
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                  ))
              .toList() ??
          [],
    );
  }

  @override
  String toString() {
    return 'DatabaseSchema(name: $name, tables: ${tables.length})';
  }

  /// Valida que el esquema sea válido
  bool isValid() {
    return name.isNotEmpty &&
           tables.isNotEmpty &&
           tables.every((table) => table.isValid());
  }

  /// Obtiene errores de validación del esquema completo
  List<String> getValidationErrors() {
    final errors = <String>[];

    if (name.isEmpty) {
      errors.add('El nombre de la base de datos es requerido');
    }

    if (tables.isEmpty) {
      errors.add('La base de datos debe tener al menos una tabla');
    }

    // Validar que no haya nombres de tablas duplicados
    final tableNames = tables.map((t) => t.name.toLowerCase()).toList();
    final duplicates = tableNames
        .where((name) => tableNames.where((n) => n == name).length > 1)
        .toSet();

    if (duplicates.isNotEmpty) {
      errors.add('Hay tablas con nombres duplicados: ${duplicates.join(", ")}');
    }

    // Validar cada tabla
    for (var i = 0; i < tables.length; i++) {
      final tableErrors = tables[i].getValidationErrors();
      if (tableErrors.isNotEmpty) {
        errors.add('Tabla "${tables[i].name}": ${tableErrors.join(", ")}');
      }
    }

    return errors;
  }

  /// Genera un JSON formateado para previsualización
  String toFormattedJson() {
    final jsonList = toJson();
    return _prettyPrintList(jsonList);
  }

  String _prettyPrintList(List<Map<String, dynamic>> list, [int indent = 0]) {
    final buffer = StringBuffer();
    final indentStr = '  ' * indent;

    buffer.writeln('[');
    for (var i = 0; i < list.length; i++) {
      buffer.write('$indentStr  ');
      buffer.write(_prettyPrintJson(list[i], indent + 1));
      if (i < list.length - 1) buffer.write(',');
      buffer.writeln();
    }
    buffer.write('$indentStr]');
    return buffer.toString();
  }

  String _prettyPrintJson(Map<String, dynamic> json, [int indent = 0]) {
    final buffer = StringBuffer();
    final indentStr = '  ' * indent;

    buffer.writeln('{');
    final entries = json.entries.toList();

    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      buffer.write('$indentStr  "${entry.key}": ');

      if (entry.value is Map) {
        buffer.write(_prettyPrintJson(entry.value as Map<String, dynamic>, indent + 1));
      } else if (entry.value is List) {
        buffer.writeln('[');
        final list = entry.value as List;
        for (var j = 0; j < list.length; j++) {
          if (list[j] is Map) {
            buffer.write('$indentStr    ');
            buffer.write(_prettyPrintJson(list[j] as Map<String, dynamic>, indent + 2));
          } else {
            buffer.write('$indentStr    ${_jsonValue(list[j])}');
          }
          if (j < list.length - 1) buffer.write(',');
          buffer.writeln();
        }
        buffer.write('$indentStr  ]');
      } else {
        buffer.write(_jsonValue(entry.value));
      }

      if (i < entries.length - 1) buffer.write(',');
      buffer.writeln();
    }

    buffer.write('$indentStr}');
    return buffer.toString();
  }

  String _jsonValue(dynamic value) {
    if (value is String) return '"$value"';
    if (value is bool) return value.toString();
    if (value is num) return value.toString();
    return 'null';
  }
}
