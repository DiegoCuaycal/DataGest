import '../models/database_metadata_model.dart';
import '../models/v2_schema_dto.dart';

class SchemaAdapter {
  static V2SchemaDto fromMetadata({
    required DatabaseMetadataModel metadata,
    required String targetTableName,
  }) {
    // 1. Buscar la info de la tabla específica
    final tableInfo = metadata.tables.firstWhere(
      (t) => t.table == targetTableName,
      orElse: () => throw Exception("Tabla $targetTableName no encontrada en metadata"),
    );

    // 2. Filtrar columnas - USAR PASCALCASE PARA .NET
    final columns = metadata.columns
        .where((c) => c.table == targetTableName)
        .map((c) => {
              "Table": c.table,          // PascalCase
              "Name": c.name,            // PascalCase
              "Type": c.type,            // PascalCase
              "Is_Identity": c.isIdentity,  // PascalCase con guión bajo
            })
        .toList();

    // 3. Filtrar PK info - USAR PASCALCASE PARA .NET
    final pkInfo = metadata.pkInfo
        .where((pk) => pk.table == targetTableName)
        .map((pk) => {
              "Table": pk.table,   // PascalCase
              "Column": pk.column, // PascalCase
            })
        .toList();

    return V2SchemaDto(
      tableName: targetTableName,
      databaseName: metadata.databaseName,
      tables: [
        {
          "Schema": tableInfo.schema,  // PascalCase
          "Table": tableInfo.table,    // PascalCase
        }
      ],
      columns: columns,
      pkInfo: pkInfo,
    );
  }
}