import 'dart:convert';

class V2DynamicRequest {
  final V2SchemaDto schema;
  final dynamic data;

  V2DynamicRequest({required this.schema, this.data});

  Map<String, dynamic> toJson() {
    // SOLUCIÓN CORRECTA: El backend .NET espera SOLO Schema y Data en el body.
    // El tableName va como query parameter en la URL, NO en el body JSON.
    // Ver: DynamicCrudController.cs línea ~100
    final Map<String, dynamic> json = {
      "Schema": schema.toJson(),  // PascalCase para .NET
    };

    if (data != null) {
      json["Data"] = data;  // PascalCase para .NET
    }
    return json;
  }
}

class V2SchemaDto {
  final String tableName; 
  final String databaseName;
  final List<Map<String, dynamic>> tables;
  final List<Map<String, dynamic>> columns;
  final List<Map<String, dynamic>> pkInfo;

  V2SchemaDto({
    required this.tableName,
    required this.databaseName,
    required this.tables,
    required this.columns,
    required this.pkInfo,
  });

  Map<String, dynamic> toJson() {
    // ESTRUCTURA EXACTA QUE ESPERA EL BACKEND .NET
    // Ver: DbSchema.cs en BackFabrica/Dapper/Dtos/DbSchema.cs
    // Nota: database_name usa JsonPropertyName en el backend, por eso es snake_case
    return {
      "Tables": tables,           // PascalCase - List<TableInfo>
      "Columns": columns,         // PascalCase - List<ColumnInfo>
      "Pk_Info": pkInfo,          // PascalCase con guión bajo - List<PkInfo>
      "database_name": databaseName,  // snake_case (tiene [JsonPropertyName] en .NET)
    };
  }
}