import 'attribute_field.dart';

/// Representa una tabla/entidad de la base de datos
class TableEntity {
  final String id; // ID único para manejo en UI
  final String name;
  final String description;
  final List<AttributeField> attributes;

  TableEntity({
    required this.id,
    required this.name,
    this.description = '',
    List<AttributeField>? attributes,
  }) : attributes = attributes ?? [];

  /// Copia la entidad con cambios específicos
  TableEntity copyWith({
    String? id,
    String? name,
    String? description,
    List<AttributeField>? attributes,
  }) {
    return TableEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      attributes: attributes ?? this.attributes,
    );
  }

  /// Agrega un atributo a la tabla
  TableEntity addAttribute(AttributeField attribute) {
    return copyWith(
      attributes: [...attributes, attribute],
    );
  }

  /// Actualiza un atributo de la tabla
  TableEntity updateAttribute(String attributeId, AttributeField updatedAttribute) {
    return copyWith(
      attributes: attributes
          .map((attr) => attr.id == attributeId ? updatedAttribute : attr)
          .toList(),
    );
  }

  /// Elimina un atributo de la tabla
  TableEntity removeAttribute(String attributeId) {
    return copyWith(
      attributes: attributes.where((attr) => attr.id != attributeId).toList(),
    );
  }

  /// Convierte a JSON para enviar al backend (formato esperado por el backend)
  Map<String, dynamic> toJson() {
    return {
      'nombre': name,
      'columnas': attributes.map((attr) => attr.toJson()).toList(),
    };
  }

  /// Crea un TableEntity desde JSON
  factory TableEntity.fromJson(Map<String, dynamic> json, {String? id}) {
    return TableEntity(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      attributes: (json['attributes'] as List<dynamic>?)
              ?.map((attr) => AttributeField.fromJson(
                    attr as Map<String, dynamic>,
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                  ))
              .toList() ??
          [],
    );
  }

  @override
  String toString() {
    return 'TableEntity(id: $id, name: $name, attributes: ${attributes.length})';
  }

  /// Valida que la tabla tenga al menos un campo y un nombre válido
  bool isValid() {
    return name.isNotEmpty && attributes.isNotEmpty;
  }

  /// Obtiene errores de validación
  List<String> getValidationErrors() {
    final errors = <String>[];

    if (name.isEmpty) {
      errors.add('El nombre de la tabla es requerido');
    }

    if (attributes.isEmpty) {
      errors.add('La tabla debe tener al menos un atributo');
    }

    // Validar que no haya nombres de atributos duplicados
    final attributeNames = attributes.map((a) => a.name.toLowerCase()).toList();
    final duplicates = attributeNames
        .where((name) => attributeNames.where((n) => n == name).length > 1)
        .toSet();

    if (duplicates.isNotEmpty) {
      errors.add('Hay atributos con nombres duplicados: ${duplicates.join(", ")}');
    }

    return errors;
  }
}
