class PrimaryKeyModel {
  final String schema;
  final String table;
  final String column;
  final String pkDef;

  PrimaryKeyModel({
    required this.schema,
    required this.table,
    required this.column,
    required this.pkDef,
  });

  factory PrimaryKeyModel.fromJson(Map<String, dynamic> json) {
    return PrimaryKeyModel(
      schema: json['schema'] as String,
      table: json['table'] as String,
      column: json['column'] as String,
      pkDef: json['pk_def'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schema': schema,
      'table': table,
      'column': column,
      'pk_def': pkDef,
    };
  }

  @override
  String toString() => 'PrimaryKeyModel(table: $table, column: $column)';
}
