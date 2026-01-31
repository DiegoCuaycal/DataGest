import '../models/database_metadata_model.dart';
import '../models/v2_schema_dto.dart';

class SchemaAdapter {
  static V2SchemaDto fromMetadata({
    required DatabaseMetadataModel metadata,
    required String targetTableName,
  }) {
    // 1. Buscar la tabla
    final tableInfo = metadata.tables.firstWhere(
      (t) => t.table == targetTableName,
      orElse: () => throw Exception("Tabla $targetTableName no encontrada en metadata"),
    );

    // 2. Filtrar y convertir Columnas a PascalCase
    final columns = metadata.columns
        .where((c) => c.table == targetTableName)
        .map((c) => {
              "Table": c.table,
              "Name": c.name,
              "Type": c.type,
              "Is_Identity": c.isIdentity,
            })
        .toList();

    // 3. Filtrar y convertir PKs a PascalCase
    final pkInfo = metadata.pkInfo
        .where((pk) => pk.table == targetTableName)
        .map((pk) => {
              "Table": pk.table,
              "Column": pk.column,
            })
        .toList();

    return V2SchemaDto(
      tableName: targetTableName,
      databaseName: metadata.databaseName,
      tables: [
        {
          "Schema": tableInfo.schema,
          "Table": tableInfo.table,
        }
      ],
      columns: columns,
      pkInfo: pkInfo,
    );
  }
}