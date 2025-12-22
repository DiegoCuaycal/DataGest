import 'field_type.dart';

/// Representa un atributo/campo de una tabla
class AttributeField {
  final String id; // ID único para manejo en UI
  final String name;
  final FieldType type;
  final bool isRequired;
  final bool isPrimaryKey;
  final bool isUnique;
  final int? maxLength;
  final String? defaultValue;

  AttributeField({
    required this.id,
    required this.name,
    required this.type,
    this.isRequired = false,
    this.isPrimaryKey = false,
    this.isUnique = false,
    this.maxLength,
    this.defaultValue,
  });

  /// Copia el atributo con cambios específicos
  AttributeField copyWith({
    String? id,
    String? name,
    FieldType? type,
    bool? isRequired,
    bool? isPrimaryKey,
    bool? isUnique,
    int? maxLength,
    String? defaultValue,
  }) {
    return AttributeField(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      isRequired: isRequired ?? this.isRequired,
      isPrimaryKey: isPrimaryKey ?? this.isPrimaryKey,
      isUnique: isUnique ?? this.isUnique,
      maxLength: maxLength ?? this.maxLength,
      defaultValue: defaultValue ?? this.defaultValue,
    );
  }

  /// Convierte a JSON para enviar al backend (formato esperado por el backend)
  Map<String, dynamic> toJson() {
    // Construir el campo "extra" combinando todas las restricciones
    final extraParts = <String>[];

    if (isPrimaryKey) {
      extraParts.add('PRIMARY KEY');
    }

    if (isUnique && !isPrimaryKey) {
      extraParts.add('UNIQUE');
    }

    if (isRequired || isPrimaryKey) {
      extraParts.add('NOT NULL');
    } else {
      extraParts.add('NULL');
    }

    if (defaultValue != null && defaultValue!.isNotEmpty) {
      // Determinar si el valor por defecto necesita comillas o es una función
      if (defaultValue!.toUpperCase().contains('GETDATE') ||
          defaultValue!.toUpperCase().contains('NEWID') ||
          defaultValue!.toUpperCase().contains('NULL')) {
        extraParts.add('DEFAULT $defaultValue');
      } else if (type == FieldType.string || type == FieldType.text || type == FieldType.date || type == FieldType.datetime) {
        extraParts.add("DEFAULT '$defaultValue'");
      } else {
        extraParts.add('DEFAULT $defaultValue');
      }
    }

    // Construir el tipo completo con longitud si aplica
    String fullType = type.sqlType;
    if ((type == FieldType.string || type == FieldType.text) && maxLength != null) {
      fullType = 'NVARCHAR($maxLength)';
    } else if (type == FieldType.decimal) {
      fullType = 'DECIMAL(18,2)'; // Precisión por defecto
    }

    return {
      'campo': name,
      'tipo': fullType,
      'extra': extraParts.join(' '),
    };
  }

  /// Crea un AttributeField desde JSON
  factory AttributeField.fromJson(Map<String, dynamic> json, {String? id}) {
    return AttributeField(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] as String,
      type: FieldType.values.firstWhere(
        (t) => t.sqlType == json['type'],
        orElse: () => FieldType.string,
      ),
      isRequired: json['is_required'] as bool? ?? false,
      isPrimaryKey: json['is_primary_key'] as bool? ?? false,
      isUnique: json['is_unique'] as bool? ?? false,
      maxLength: json['max_length'] as int?,
      defaultValue: json['default_value'] as String?,
    );
  }

  @override
  String toString() {
    return 'AttributeField(id: $id, name: $name, type: ${type.displayName}, '
        'isRequired: $isRequired, isPrimaryKey: $isPrimaryKey)';
  }
}
