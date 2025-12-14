class TableInfoModel {
  final String schema;
  final String table;
  final int rowCount;
  final String tableType;

  TableInfoModel({
    required this.schema,
    required this.table,
    required this.rowCount,
    required this.tableType,
  });

  factory TableInfoModel.fromJson(Map<String, dynamic> json) {
    return TableInfoModel(
      schema: json['schema'] as String,
      table: json['table'] as String,
      rowCount: json['row_count'] as int,
      tableType: json['table_type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schema': schema,
      'table': table,
      'row_count': rowCount,
      'table_type': tableType,
    };
  }

  @override
  String toString() => 'TableInfoModel(schema: $schema, table: $table, rowCount: $rowCount)';
}
