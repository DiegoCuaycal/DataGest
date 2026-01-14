import 'dart:convert';

class V2DynamicRequest {
  final V2SchemaDto schema;
  final dynamic data; 

  V2DynamicRequest({required this.schema, this.data});

  Map<String, dynamic> toJson() {
    // Estructura raíz que espera DynamicRequestDto en C#
    final Map<String, dynamic> json = {
      "Schema": schema.toJson(), // PascalCase para .NET
    };
    
    if (data != null) {
      json["Data"] = data; // PascalCase para .NET
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
    // Mapeo exacto a DbSchema de C#
    return {
      "Tables": tables,     // PascalCase
      "Columns": columns,   // PascalCase
      "Pk_Info": pkInfo,    // PascalCase (según tu JSON del backend)
      "database_name": databaseName, // Este suele ir en snake_case según tu ejemplo anterior
    };
  }
}