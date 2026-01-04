class DropdownItemModel {
  final dynamic id;
  final String displayValue;
  final Map<String, dynamic> rawData; // Datos completos para referencia

  DropdownItemModel({
    required this.id,
    required this.displayValue,
    Map<String, dynamic>? rawData,
  }) : rawData = rawData ?? {};

  /// Crea un DropdownItemModel a partir de JSON con columnas específicas para mostrar
  factory DropdownItemModel.fromJson(
    Map<String, dynamic> json, {
    List<String>? displayColumns,
  }) {
    // Normalizar el JSON convirtiendo keys a minúsculas para comparación
    final normalizedJson = <String, dynamic>{};
    for (var entry in json.entries) {
      normalizedJson[entry.key.toLowerCase()] = entry.value;
    }

    String? displayValue;

    // Si se especifican columnas para mostrar, intentar con ellas primero
    if (displayColumns != null && displayColumns.isNotEmpty) {
      final parts = <String>[];
      for (var column in displayColumns) {
        final normalizedColumn = column.toLowerCase();
        if (normalizedJson.containsKey(normalizedColumn) &&
            normalizedJson[normalizedColumn] != null) {
          parts.add(normalizedJson[normalizedColumn].toString());
        }
      }
      if (parts.isNotEmpty) {
        displayValue = parts.join(' - ');
      }
    }

    // Si no se encontró valor con displayColumns, usar la lógica anterior
    if (displayValue == null) {
      // Intentar campos comunes para nombre/descripción (en orden de prioridad)
      final priorityFields = [
        'displayvalue',
        'nombres',
        'apellidos',
        'nombre',
        'name',
        'descripcion',
        'description',
        'codigo',
        'sku',
        'legajo',
        'numerohistoria',
        'especialidad',
        'contacto',
      ];

      // Intentar combinar Nombres + Apellidos si ambos existen
      if (normalizedJson.containsKey('nombres') &&
          normalizedJson.containsKey('apellidos') &&
          normalizedJson['nombres'] != null &&
          normalizedJson['apellidos'] != null) {
        displayValue =
            '${normalizedJson['apellidos']}, ${normalizedJson['nombres']}';
      }

      // Si no se encontró la combinación, intentar campos individuales
      if (displayValue == null) {
        for (var field in priorityFields) {
          if (normalizedJson.containsKey(field) &&
              normalizedJson[field] != null) {
            displayValue = normalizedJson[field].toString();
            break;
          }
        }
      }

      // Fallback final: usar el primer valor no-null que encontremos (excepto id)
      if (displayValue == null) {
        for (var entry in normalizedJson.entries) {
          if (entry.key != 'id' && entry.value != null) {
            displayValue = entry.value.toString();
            break;
          }
        }
      }
    }

    return DropdownItemModel(
      id: json['Id'] ?? json['id'],
      displayValue: displayValue ?? 'ID: ${json['Id'] ?? json['id']}',
      rawData: json,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayValue': displayValue,
    };
  }

  @override
  String toString() => 'DropdownItemModel(id: $id, displayValue: $displayValue)';
}
