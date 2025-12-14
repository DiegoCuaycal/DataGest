import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../models/database_metadata_model.dart';
import '../models/dropdown_item_model.dart';

class DynamicRemoteDataSource {
  final http.Client client;

  DynamicRemoteDataSource({required this.client});

  Future<DatabaseMetadataModel> getMetadata({
    required String databaseName,
    required String token,
  }) async {
    try {
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.metadata(databaseName)}';
      print('📊 Solicitando metadata para DB: $databaseName');
      print('🔗 URL completa: $url');
      print('🔑 Token: ${token.isNotEmpty && token.length > 20 ? token.substring(0, 20) : token}...');

      final response = await client.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 Status code: ${response.statusCode}');
      final responsePreview = response.body.length > 200
          ? response.body.substring(0, 200)
          : response.body;
      print('📄 Respuesta: $responsePreview');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return DatabaseMetadataModel.fromJson(jsonData);
      } else {
        throw Exception('Failed to load metadata: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error en getMetadata: $e');
      throw Exception('Error fetching metadata: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getTableRecords({
    required String databaseName,
    required String tableName,
    required String token,
  }) async {
    try {
      final response = await client.get(
        Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.tableList(databaseName, tableName)}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse.fromJson(jsonDecode(response.body), null);
        if (apiResponse.success) {
          final List<dynamic> data = apiResponse.data as List<dynamic>;
          return data.cast<Map<String, dynamic>>();
        } else {
          throw Exception(apiResponse.message);
        }
      } else {
        throw Exception('Failed to load records: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching records: $e');
    }
  }

  Future<Map<String, dynamic>> getTableRecord({
    required String databaseName,
    required String tableName,
    required dynamic id,
    required String token,
  }) async {
    try {
      final response = await client.get(
        Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.tableRecord(databaseName, tableName, id)}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse.fromJson(jsonDecode(response.body), null);
        if (apiResponse.success) {
          return apiResponse.data as Map<String, dynamic>;
        } else {
          throw Exception(apiResponse.message);
        }
      } else {
        throw Exception('Failed to load record: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching record: $e');
    }
  }

  Future<Map<String, dynamic>> createTableRecord({
    required String databaseName,
    required String tableName,
    required Map<String, dynamic> data,
    required String token,
  }) async {
    try {
      final response = await client.post(
        Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.tableList(databaseName, tableName)}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final apiResponse = ApiResponse.fromJson(jsonDecode(response.body), null);
        if (apiResponse.success) {
          return apiResponse.data as Map<String, dynamic>;
        } else {
          throw Exception(apiResponse.message);
        }
      } else {
        throw Exception('Failed to create record: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating record: $e');
    }
  }

  Future<Map<String, dynamic>> updateTableRecord({
    required String databaseName,
    required String tableName,
    required dynamic id,
    required Map<String, dynamic> data,
    required String token,
  }) async {
    try {
      final response = await client.put(
        Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.tableRecord(databaseName, tableName, id)}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse.fromJson(jsonDecode(response.body), null);
        if (apiResponse.success) {
          return apiResponse.data as Map<String, dynamic>;
        } else {
          throw Exception(apiResponse.message);
        }
      } else {
        throw Exception('Failed to update record: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating record: $e');
    }
  }

  Future<bool> deleteTableRecord({
    required String databaseName,
    required String tableName,
    required dynamic id,
    required String token,
  }) async {
    try {
      final response = await client.delete(
        Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.tableRecord(databaseName, tableName, id)}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse.fromJson(jsonDecode(response.body), null);
        return apiResponse.success;
      } else {
        throw Exception('Failed to delete record: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting record: $e');
    }
  }

  Future<List<DropdownItemModel>> getDropdownData({
    required String databaseName,
    required String tableName,
    required String token,
  }) async {
    try {
      final response = await client.get(
        Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.tableDropdown(databaseName, tableName)}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse.fromJson(jsonDecode(response.body), null);
        if (apiResponse.success) {
          final List<dynamic> data = apiResponse.data as List<dynamic>;
          return data.map((json) => DropdownItemModel.fromJson(json)).toList();
        } else {
          throw Exception(apiResponse.message);
        }
      } else {
        throw Exception('Failed to load dropdown data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching dropdown data: $e');
    }
  }

  // Mock metadata for testing
  Future<DatabaseMetadataModel> getMockMetadata() async {
    await Future.delayed(const Duration(seconds: 1));

    const mockJson = {
      "database_name": "ToList",
      "tables": [
        {"schema": "dbo", "table": "Usuarios", "row_count": 6, "table_type": "USER_TABLE"},
        {"schema": "dbo", "table": "ListasTareas", "row_count": 7, "table_type": "USER_TABLE"},
        {"schema": "dbo", "table": "Tareas", "row_count": 11, "table_type": "USER_TABLE"},
      ],
      "columns": [
        {"schema": "dbo", "table": "Usuarios", "name": "UsuarioID", "ordinal_position": 1, "type": "int", "character_maximum_length": "null", "nullable": false, "is_identity": true},
        {"schema": "dbo", "table": "Usuarios", "name": "Nombre", "ordinal_position": 2, "type": "varchar", "character_maximum_length": "100", "nullable": true, "is_identity": false},
        {"schema": "dbo", "table": "Usuarios", "name": "Email", "ordinal_position": 3, "type": "varchar", "character_maximum_length": "100", "nullable": true, "is_identity": false},
        {"schema": "dbo", "table": "ListasTareas", "name": "ListaID", "ordinal_position": 1, "type": "int", "character_maximum_length": "null", "nullable": false, "is_identity": true},
        {"schema": "dbo", "table": "ListasTareas", "name": "UsuarioID", "ordinal_position": 2, "type": "int", "character_maximum_length": "null", "nullable": true, "is_identity": false},
        {"schema": "dbo", "table": "ListasTareas", "name": "Nombre", "ordinal_position": 3, "type": "varchar", "character_maximum_length": "255", "nullable": true, "is_identity": false},
        {"schema": "dbo", "table": "Tareas", "name": "TareaID", "ordinal_position": 1, "type": "int", "character_maximum_length": "null", "nullable": false, "is_identity": true},
        {"schema": "dbo", "table": "Tareas", "name": "ListaID", "ordinal_position": 2, "type": "int", "character_maximum_length": "null", "nullable": true, "is_identity": false},
        {"schema": "dbo", "table": "Tareas", "name": "Descripcion", "ordinal_position": 3, "type": "varchar", "character_maximum_length": "50", "nullable": true, "is_identity": false},
        {"schema": "dbo", "table": "Tareas", "name": "Estado", "ordinal_position": 4, "type": "varchar", "character_maximum_length": "10", "nullable": true, "is_identity": false},
      ],
      "pk_info": [
        {"schema": "dbo", "table": "Usuarios", "column": "UsuarioID", "pk_def": "PRIMARY KEY (UsuarioID)"},
        {"schema": "dbo", "table": "ListasTareas", "column": "ListaID", "pk_def": "PRIMARY KEY (ListaID)"},
        {"schema": "dbo", "table": "Tareas", "column": "TareaID", "pk_def": "PRIMARY KEY (TareaID)"},
      ],
      "fk_info": [
        {"schema": "dbo", "table": "Tareas", "column": "ListaID", "foreign_key_name": "Tareas_ListaID_fk", "reference_schema": "dbo", "reference_table": "ListasTareas", "reference_column": "ListaID"},
        {"schema": "dbo", "table": "ListasTareas", "column": "UsuarioID", "foreign_key_name": "ListasTareas_UsuarioID_fk", "reference_schema": "dbo", "reference_table": "Usuarios", "reference_column": "UsuarioID"},
      ],
      "indexes": [],
      "views": []
    };

    return DatabaseMetadataModel.fromJson(mockJson);
  }

  // Mock dropdown data
  Future<List<DropdownItemModel>> getMockDropdownData(String tableName) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (tableName == 'Usuarios') {
      return [
        DropdownItemModel(id: 1, displayValue: 'Juan Pérez'),
        DropdownItemModel(id: 2, displayValue: 'María García'),
        DropdownItemModel(id: 3, displayValue: 'Carlos López'),
      ];
    } else if (tableName == 'ListasTareas') {
      return [
        DropdownItemModel(id: 1, displayValue: 'Lista de compras'),
        DropdownItemModel(id: 2, displayValue: 'Trabajo'),
        DropdownItemModel(id: 3, displayValue: 'Personal'),
      ];
    }

    return [];
  }

  // Mock table records
  Future<List<Map<String, dynamic>>> getMockTableRecords(String tableName) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (tableName == 'Usuarios') {
      return [
        {'UsuarioID': 1, 'Nombre': 'Juan Pérez', 'Email': 'juan@email.com'},
        {'UsuarioID': 2, 'Nombre': 'María García', 'Email': 'maria@email.com'},
        {'UsuarioID': 3, 'Nombre': 'Carlos López', 'Email': 'carlos@email.com'},
      ];
    } else if (tableName == 'ListasTareas') {
      return [
        {'ListaID': 1, 'UsuarioID': 1, 'Nombre': 'Lista de compras'},
        {'ListaID': 2, 'UsuarioID': 1, 'Nombre': 'Trabajo'},
        {'ListaID': 3, 'UsuarioID': 2, 'Nombre': 'Personal'},
      ];
    } else if (tableName == 'Tareas') {
      return [
        {'TareaID': 1, 'ListaID': 1, 'Descripcion': 'Comprar leche', 'Estado': 'Pendiente'},
        {'TareaID': 2, 'ListaID': 1, 'Descripcion': 'Comprar pan', 'Estado': 'Completado'},
        {'TareaID': 3, 'ListaID': 2, 'Descripcion': 'Revisar emails', 'Estado': 'Pendiente'},
      ];
    }

    return [];
  }
}
