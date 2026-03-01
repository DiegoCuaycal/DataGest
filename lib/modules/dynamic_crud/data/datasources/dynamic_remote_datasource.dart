import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config/env_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/endpoint_mapper.dart';
import '../models/database_metadata_model.dart';
import '../models/dropdown_item_model.dart';
import '../models/v2_schema_dto.dart';
import 'schema_adapter.dart';

/// Remote data source for all dynamic CRUD operations.
///
/// Communicates with the V2 DynamicCrud API for read, create, and update
/// operations, and falls back to the legacy V1 endpoint for deletions.
/// All requests include the `X-Connection-Profile` and `X-DbName` headers
/// required for multi-tenant server routing.
class DynamicRemoteDataSource {
  final http.Client client;
  final ApiClient? apiClient;

  DynamicRemoteDataSource({required this.client, this.apiClient});

  Duration get _timeout => Duration(seconds: EnvConfig.apiTimeout);

  String get _v2BaseUrl => '${ApiEndpoints.baseUrl}/api/DynamicCrud/V2';

  /// Builds the HTTP headers for every request.
  ///
  /// Includes Bearer authentication, ngrok compatibility, and optionally
  /// the `X-Connection-Profile` and `X-DbName` headers used by the backend
  /// to route requests to the correct database server.
  Map<String, String> _buildHeaders(String token, {String? databaseName}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
      'ngrok-skip-browser-warning': 'true',
    };

    final connectionProfile = apiClient?.getConnectionProfile();
    if (connectionProfile != null && connectionProfile.isNotEmpty) {
      headers['X-Connection-Profile'] = connectionProfile;
    }

    if (databaseName != null && databaseName.isNotEmpty) {
      headers['X-DbName'] = databaseName;
    }

    return headers;
  }

  /// Fetches the full database metadata for [databaseName].
  ///
  /// Returns a [DatabaseMetadataModel] containing table definitions,
  /// column info, primary keys, and foreign key relationships.
  Future<DatabaseMetadataModel> getMetadata({
    required String databaseName,
    required String token,
  }) async {
    final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.metadata(databaseName)}';

    final response = await client.get(
      Uri.parse(url),
      headers: _buildHeaders(token, databaseName: databaseName),
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      return DatabaseMetadataModel.fromJson(jsonDecode(response.body));
    }

    throw Exception('Error loading metadata (${response.statusCode}): ${response.body}');
  }

  /// Retrieves all records for [tableName] using the V2 API.
  ///
  /// The V2 endpoint requires a POST with the table schema in the body and
  /// the table name as a query parameter. The response may be either a plain
  /// list or an object with a `rowsAffected` key.
  Future<List<Map<String, dynamic>>> getTableRecords({
    required DatabaseMetadataModel metadata,
    required String tableName,
    required String token,
  }) async {
    try {
      final v2Schema = SchemaAdapter.fromMetadata(metadata: metadata, targetTableName: tableName);
      final requestBody = V2DynamicRequest(schema: v2Schema);

      final uri = Uri.parse('$_v2BaseUrl/GETALL').replace(
        queryParameters: {'tableName': tableName},
      );

      final response = await client.post(
        uri,
        headers: _buildHeaders(token, databaseName: metadata.databaseName),
        body: jsonEncode(requestBody.toJson()),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final dynamic jsonData = jsonDecode(response.body);

        if (jsonData is Map && jsonData.containsKey('rowsAffected')) {
          return (jsonData['rowsAffected'] as List).cast<Map<String, dynamic>>();
        }
        if (jsonData is List) {
          return jsonData.cast<Map<String, dynamic>>();
        }
        return [];
      } else {
        throw Exception('V2 Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error V2 Get: $e');
    }
  }

  /// Returns a paginated and optionally filtered subset of records for
  /// [tableName].
  ///
  /// Pagination is applied client-side on the full V2 result set.
  /// Records are sorted in descending order before slicing.
  Future<Map<String, dynamic>> getTableRecordsPaginated({
    required DatabaseMetadataModel metadata,
    required String tableName,
    required String token,
    required int page,
    required int pageSize,
    String? searchTerm,
  }) async {
    try {
      final allRecords = await getTableRecords(
        metadata: metadata,
        tableName: tableName,
        token: token,
      );

      _sortRecordsDescending(allRecords);

      var filteredRecords = allRecords;
      if (searchTerm != null && searchTerm.isNotEmpty) {
        filteredRecords = allRecords.where((record) {
          return record.values.any((value) =>
              value.toString().toLowerCase().contains(searchTerm.toLowerCase()));
        }).toList();
      }

      final totalRecords = filteredRecords.length;
      final startIndex = (page - 1) * pageSize;
      final endIndex = (startIndex + pageSize).clamp(0, totalRecords);

      final paginatedRecords = startIndex < totalRecords
          ? filteredRecords.sublist(startIndex.clamp(0, totalRecords), endIndex)
          : <Map<String, dynamic>>[];

      return {
        'records': paginatedRecords,
        'totalRecords': totalRecords,
      };
    } catch (e) {
      throw Exception('Error paginating: $e');
    }
  }

  /// Creates a new record in [tableName] using the V2 API.
  ///
  /// Date string values are normalized to UTC format (appending `Z`) to
  /// ensure compatibility with Azure SQL datetime parsing.
  ///
  /// Note: the backend endpoint name `CREADTE` is a known typo in the
  /// backend contract and must be preserved.
  Future<Map<String, dynamic>> createTableRecord({
    required DatabaseMetadataModel metadata,
    required String tableName,
    required Map<String, dynamic> data,
    required String token,
  }) async {
    try {
      // Normalize date strings to UTC format for Azure SQL compatibility
      final Map<String, dynamic> optimizedData = Map.from(data);
      optimizedData.forEach((key, value) {
        if ((key.toLowerCase().contains('fecha') || key.toLowerCase().contains('visita')) &&
            value is String && !value.endsWith('Z')) {
          optimizedData[key] = "${value}Z";
        }
      });

      final v2Schema = SchemaAdapter.fromMetadata(metadata: metadata, targetTableName: tableName);
      final requestBody = V2DynamicRequest(schema: v2Schema, data: optimizedData);

      // Note: 'CREADTE' is the backend endpoint name (typo preserved intentionally)
      final uri = Uri.parse('$_v2BaseUrl/CREADTE').replace(
        queryParameters: {'tableName': tableName},
      );

      final response = await client.post(
        uri,
        headers: _buildHeaders(token, databaseName: metadata.databaseName),
        body: jsonEncode(requestBody.toJson()),
      ).timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('V2 Create Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating record: $e');
    }
  }

  /// Updates an existing record identified by [id] in [tableName].
  Future<Map<String, dynamic>> updateTableRecord({
    required DatabaseMetadataModel metadata,
    required String tableName,
    required dynamic id,
    required Map<String, dynamic> data,
    required String token,
  }) async {
    try {
      final dataWithId = Map<String, dynamic>.from(data);

      final v2Schema = SchemaAdapter.fromMetadata(metadata: metadata, targetTableName: tableName);
      final requestBody = V2DynamicRequest(schema: v2Schema, data: dataWithId);

      final uri = Uri.parse('$_v2BaseUrl/UPDATE').replace(
        queryParameters: {'tableName': tableName},
      );

      final response = await client.post(
        uri,
        headers: _buildHeaders(token, databaseName: metadata.databaseName),
        body: jsonEncode(requestBody.toJson()),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Actualizado correctamente'};
      } else {
        throw Exception('V2 Update Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating record: $e');
    }
  }

  /// Fetches a single record by [id] from [tableName] using the V2 API.
  ///
  /// Only the schema is sent in the request body (not wrapped in a data object),
  /// as required by the GETBYID contract.
  Future<Map<String, dynamic>> getTableRecord({
    required DatabaseMetadataModel metadata,
    required String tableName,
    required dynamic id,
    required String token,
  }) async {
    try {
      final v2Schema = SchemaAdapter.fromMetadata(metadata: metadata, targetTableName: tableName);

      final uri = Uri.parse('$_v2BaseUrl/GETBYID/$id').replace(
        queryParameters: {'tableName': tableName},
      );

      final response = await client.post(
        uri,
        headers: _buildHeaders(token, databaseName: metadata.databaseName),
        body: jsonEncode(v2Schema.toJson()),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('V2 GetById Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching record: $e');
    }
  }

  /// Deletes a record by [id] from [tableName] using the legacy V1 endpoint.
  ///
  /// Returns `true` on success. On referential integrity violations (HTTP 500),
  /// throws a user-friendly exception message via [_getDeleteErrorMessage].
  Future<bool> deleteTableRecord({
    required String databaseName,
    required String tableName,
    required dynamic id,
    required String token,
  }) async {
    try {
      final endpoint = EndpointMapper.getDeleteEndpoint(
        databaseName: databaseName,
        tableName: tableName,
        id: id,
      );
      final dbHeaderValue = EndpointMapper.getDatabaseHeaderValue(databaseName);

      final deleteHeaders = _buildHeaders(token);
      deleteHeaders['X-DbName'] = dbHeaderValue;

      final response = await client.delete(
        Uri.parse('${ApiEndpoints.baseUrl}$endpoint'),
        headers: deleteHeaders,
      ).timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else if (response.statusCode == 500) {
        throw Exception(response.body.isNotEmpty
            ? response.body
            : 'No se puede eliminar el registro. Verifique dependencias.');
      } else {
        throw Exception('Failed to delete: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting record: $e');
    }
  }

  /// Sorts [records] in descending order in place.
  ///
  /// Column priority for sorting:
  /// 1. Creation date columns (`created_at`, `fecha_creacion`).
  /// 2. Any column ending in `id`.
  /// 3. First numeric field found.
  void _sortRecordsDescending(List<Map<String, dynamic>> records) {
    if (records.isEmpty) return;

    String? sortColumn;
    final firstRecord = records.first;

    for (var key in firstRecord.keys) {
      final lowerKey = key.toLowerCase();
      if (lowerKey.contains('created') || lowerKey.contains('fecha_creacion')) {
        sortColumn = key;
        break;
      }
    }

    if (sortColumn == null) {
      for (var key in firstRecord.keys) {
        final lowerKey = key.toLowerCase();
        if (lowerKey == 'id' || lowerKey.endsWith('id')) {
          sortColumn = key;
          break;
        }
      }
    }

    if (sortColumn == null) {
      for (var key in firstRecord.keys) {
        if (firstRecord[key] is num) {
          sortColumn = key;
          break;
        }
      }
    }

    if (sortColumn != null) {
      final column = sortColumn;
      records.sort((a, b) {
        final aValue = a[column];
        final bValue = b[column];

        if (aValue == null && bValue == null) return 0;
        if (aValue == null) return 1;
        if (bValue == null) return -1;

        if (aValue is num && bValue is num) {
          return bValue.compareTo(aValue);
        }

        if (aValue is String && bValue is String) {
          try {
            final dateA = DateTime.parse(aValue);
            final dateB = DateTime.parse(bValue);
            return dateB.compareTo(dateA);
          } catch (_) {
            return bValue.compareTo(aValue);
          }
        }

        return 0;
      });
    }
  }

  /// Fetches the list of items for a foreign key dropdown for [tableName].
  ///
  /// Uses legacy V1 endpoints routed through [EndpointMapper]. Returns an
  /// empty list on 404 (endpoint not yet implemented in backend) to allow
  /// the form to remain functional with optional fields.
  Future<List<DropdownItemModel>> getDropdownData({
    required String databaseName,
    required String tableName,
    required String token,
    List<String>? displayColumns,
  }) async {
    try {
      final endpoint = EndpointMapper.getDropdownEndpoint(
        databaseName: databaseName,
        tableName: tableName,
      );
      final dbHeaderValue = EndpointMapper.getDatabaseHeaderValue(databaseName);

      final dropdownHeaders = _buildHeaders(token);
      dropdownHeaders['X-DbName'] = dbHeaderValue;

      final response = await client.get(
        Uri.parse('${ApiEndpoints.baseUrl}$endpoint'),
        headers: dropdownHeaders,
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        if (response.body.isEmpty) return [];

        try {
          final dynamic jsonData = jsonDecode(response.body);

          if (jsonData is List) {
            return jsonData.map((json) => DropdownItemModel.fromJson(
              json as Map<String, dynamic>,
              displayColumns: displayColumns,
            )).toList();
          }

          if (jsonData is Map && jsonData.containsKey('success')) {
            final apiResponse = ApiResponse.fromJson(jsonData as Map<String, dynamic>, null);
            if (apiResponse.success) {
              final List<dynamic> data = apiResponse.data as List<dynamic>;
              return data.map((json) => DropdownItemModel.fromJson(
                json as Map<String, dynamic>,
                displayColumns: displayColumns,
              )).toList();
            } else {
              throw Exception(apiResponse.message);
            }
          }

          throw Exception('Formato de respuesta no reconocido: ${jsonData.runtimeType}');
        } catch (e) {
          if (e is FormatException) {
            throw Exception('El endpoint $endpoint devolvió texto plano en lugar de JSON. Respuesta: ${response.body}');
          }
          rethrow;
        }
      } else if (response.statusCode == 404) {
        // Endpoint not yet implemented for this table; return empty list
        // so nullable FK fields remain accessible in the form.
        return [];
      } else {
        throw Exception('Error ${response.statusCode} al cargar dropdown desde $endpoint: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching dropdown data: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Mock data helpers (used for offline testing and UI development)
  // ---------------------------------------------------------------------------

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

  Future<List<Map<String, dynamic>>> getMockTableRecords(String tableName) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (tableName == 'Usuarios') {
      return List.generate(25, (index) => {
        'UsuarioID': index + 1,
        'Nombre': 'Usuario ${index + 1}',
        'Email': 'usuario${index + 1}@email.com',
      });
    } else if (tableName == 'ListasTareas') {
      return List.generate(30, (index) => {
        'ListaID': index + 1,
        'UsuarioID': (index % 25) + 1,
        'Nombre': 'Lista de tareas ${index + 1}',
      });
    } else if (tableName == 'Tareas') {
      return List.generate(50, (index) => {
        'TareaID': index + 1,
        'ListaID': (index % 30) + 1,
        'Descripcion': 'Tarea ${index + 1}',
        'Estado': index % 2 == 0 ? 'Pendiente' : 'Completado',
      });
    }

    return [];
  }

  Future<Map<String, dynamic>> getMockTableRecordsPaginated({
    required String tableName,
    required int page,
    required int pageSize,
    String? searchTerm,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final allRecords = await getMockTableRecords(tableName);

    var filteredRecords = allRecords;
    if (searchTerm != null && searchTerm.isNotEmpty) {
      filteredRecords = allRecords.where((record) {
        return record.values.any((value) =>
            value.toString().toLowerCase().contains(searchTerm.toLowerCase()));
      }).toList();
    }

    final totalRecords = filteredRecords.length;
    final startIndex = (page - 1) * pageSize;
    final endIndex = (startIndex + pageSize).clamp(0, totalRecords);

    final paginatedRecords = filteredRecords.sublist(
      startIndex.clamp(0, totalRecords),
      endIndex,
    );

    return {
      'records': paginatedRecords,
      'totalRecords': totalRecords,
    };
  }

}
