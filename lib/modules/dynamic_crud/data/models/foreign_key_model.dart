class ForeignKeyModel {
  final String schema;
  final String table;
  final String column;
  final String foreignKeyName;
  final String referenceSchema;
  final String referenceTable;
  final String referenceColumn;

  ForeignKeyModel({
    required this.schema,
    required this.table,
    required this.column,
    required this.foreignKeyName,
    required this.referenceSchema,
    required this.referenceTable,
    required this.referenceColumn,
  });

  factory ForeignKeyModel.fromJson(Map<String, dynamic> json) {
    return ForeignKeyModel(
      schema: json['schema'] as String,
      table: json['table'] as String,
      column: json['column'] as String,
      foreignKeyName: json['foreign_key_name'] as String,
      referenceSchema: json['reference_schema'] as String,
      referenceTable: json['reference_table'] as String,
      referenceColumn: json['reference_column'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schema': schema,
      'table': table,
      'column': column,
      'foreign_key_name': foreignKeyName,
      'reference_schema': referenceSchema,
      'reference_table': referenceTable,
      'reference_column': referenceColumn,
    };
  }

  @override
  String toString() => 'ForeignKeyModel(table: $table, column: $column -> $referenceTable.$referenceColumn)';
}
