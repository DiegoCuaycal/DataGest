class ColumnInfoModel {
  final String schema;
  final String table;
  final String name;
  final int ordinalPosition;
  final String type;
  final String? characterMaximumLength;
  final bool nullable;
  final bool isIdentity;

  ColumnInfoModel({
    required this.schema,
    required this.table,
    required this.name,
    required this.ordinalPosition,
    required this.type,
    this.characterMaximumLength,
    required this.nullable,
    required this.isIdentity,
  });

  factory ColumnInfoModel.fromJson(Map<String, dynamic> json) {
    return ColumnInfoModel(
      schema: json['schema'] as String,
      table: json['table'] as String,
      name: json['name'] as String,
      ordinalPosition: json['ordinal_position'] as int,
      type: json['type'] as String,
      characterMaximumLength: json['character_maximum_length'] as String?,
      nullable: json['nullable'] as bool,
      isIdentity: json['is_identity'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schema': schema,
      'table': table,
      'name': name,
      'ordinal_position': ordinalPosition,
      'type': type,
      'character_maximum_length': characterMaximumLength,
      'nullable': nullable,
      'is_identity': isIdentity,
    };
  }

  int? get maxLength {
    if (characterMaximumLength == null || characterMaximumLength == 'null') {
      return null;
    }
    final parsed = int.tryParse(characterMaximumLength!);
    // Si el parsing falla o el valor es negativo o cero, retornar null (sin límite)
    if (parsed == null || parsed <= 0) {
      return null;
    }
    return parsed;
  }

  @override
  String toString() => 'ColumnInfoModel(table: $table, name: $name, type: $type, nullable: $nullable, isIdentity: $isIdentity)';
}
