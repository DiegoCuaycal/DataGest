import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config/env_config.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/endpoint_mapper.dart';
import '../models/database_metadata_model.dart';
import '../models/dropdown_item_model.dart';
import '../models/v2_schema_dto.dart'; // <--- IMPORTANTE
import 'schema_adapter.dart'; // <--- IMPORTANTE

class DynamicRemoteDataSource {
  final http.Client client;

  DynamicRemoteDataSource({required this.client});

  Duration get _timeout => Duration(seconds: EnvConfig.apiTimeout);
  
  // URL Base para V2
  String get _v2BaseUrl => '${ApiEndpoints.baseUrl}/api/DynamicCrud/V2';

  // --- 1. METADATA (V1 - Se mantiene igual) ---
  Future<DatabaseMetadataModel> getMetadata({
    required String databaseName,
    required String token,
  }) async {
<<<<<<< HEAD
    const int maxRetries = 3;
    int attempt = 0;
=======
    // ... (Mantén tu código original de getMetadata aquí, es correcto) ...
    // Para abreviar aquí, asumo que copias tu lógica de reintentos existente.
    // ...
    // COPIA TU MÉTODO getMetadata ORIGINAL AQUÍ
    final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.metadata(databaseName)}';
    print('📊 Solicitando metadata: $databaseName');
    final response = await client.get(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    ).timeout(_timeout);
>>>>>>> dynamic

    if (response.statusCode == 200) {
      return DatabaseMetadataModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('Error loading metadata');
  }

  // --- 2. GET ALL (V2 - Actualizado) ---
  Future<List<Map<String, dynamic>>> getTableRecords({
<<<<<<< HEAD
    required DatabaseMetadataModel metadata,
=======
    required DatabaseMetadataModel metadata, // Necesitamos metadata para el schema
>>>>>>> dynamic
    required String tableName,
    required String token,
  }) async {
    try {
      // Adaptar Metadata a Schema V2
      final v2Schema = SchemaAdapter.fromMetadata(metadata: metadata, targetTableName: tableName);
      final requestBody = V2DynamicRequest(schema: v2Schema);

<<<<<<< HEAD
      print('🚀 V2 GETALL: $tableName');

      // 3. Llamada POST al endpoint V2
=======
      // QUERY PARAMETER: tableName
>>>>>>> dynamic
      final uri = Uri.parse('$_v2BaseUrl/GETALL').replace(
        queryParameters: {'tableName': tableName},
      );

      print('🚀 V2 GETALL: $tableName');

      final response = await client.post(
        uri,
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode(requestBody.toJson()),
      ).timeout(_timeout);

      print('📡 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic jsonData = jsonDecode(response.body);
<<<<<<< HEAD

        // Adaptar según venga la respuesta (Lista directa o envuelta)
        if (jsonData is List) {
          return jsonData.cast<Map<String, dynamic>>();
        }

        // V2 Backend devuelve datos en 'rowsAffected'
        if (jsonData is Map && jsonData.containsKey('rowsAffected')) {
          print('✅ Datos encontrados en rowsAffected');
          return (jsonData['rowsAffected'] as List).cast<Map<String, dynamic>>();
        }

        // Otras variantes posibles
        if (jsonData is Map && jsonData.containsKey('data')) {
           return (jsonData['data'] as List).cast<Map<String, dynamic>>();
        }

=======
        
        // Manejar estructura { message: "...", rowsAffected: [...] }
        if (jsonData is Map && jsonData.containsKey('rowsAffected')) {
           return (jsonData['rowsAffected'] as List).cast<Map<String, dynamic>>();
        }
        if (jsonData is List) {
          return jsonData.cast<Map<String, dynamic>>();
        }
>>>>>>> dynamic
        return [];
      } else {
        throw Exception('V2 Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Error V2 Get: $e');
      throw Exception('Error V2 Get: $e');
    }
  }

  // --- 3. PAGINACIÓN (Cliente sobre V2) ---
  // Reutilizamos tu lógica de paginación local porque el endpoint V2 GETALL devuelve todo
  Future<Map<String, dynamic>> getTableRecordsPaginated({
    required DatabaseMetadataModel metadata,
    required String tableName,
    required String token,
    required int page,
    required int pageSize,
    String? searchTerm,
  }) async {
    try {
<<<<<<< HEAD
      print('📱 Usando paginación del lado del cliente sobre datos V2');
=======
      print('📱 Paginando localmente sobre datos V2');
>>>>>>> dynamic
      final allRecords = await getTableRecords(
        metadata: metadata,
        tableName: tableName,
        token: token,
      );

      // Tu lógica de ordenamiento (copiada de tu código)
      _sortRecordsDescending(allRecords);
<<<<<<< HEAD
=======

      // Tu lógica de filtrado
>>>>>>> dynamic
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

  // --- 4. CREATE (V2 - Actualizado) ---
  Future<Map<String, dynamic>> createTableRecord({
    required DatabaseMetadataModel metadata,
    required String tableName,
    required Map<String, dynamic> data,
    required String token,
  }) async {
    try {
      // 1. Optimizar Fechas (Tu parche Azure)
      final Map<String, dynamic> optimizedData = Map.from(data);
      optimizedData.forEach((key, value) {
        if ((key.toLowerCase().contains('fecha') || key.toLowerCase().contains('visita')) && 
            value is String && !value.endsWith('Z')) {
             optimizedData[key] = "${value}Z"; 
        }
      });

      // 2. Preparar Request
      final v2Schema = SchemaAdapter.fromMetadata(metadata: metadata, targetTableName: tableName);
      final requestBody = V2DynamicRequest(schema: v2Schema, data: optimizedData);

      // 3. Endpoint CREADTE (Typo del backend)
      final uri = Uri.parse('$_v2BaseUrl/CREADTE').replace(
        queryParameters: {'tableName': tableName},
      );

      print('📝 V2 CREATE: $tableName');

      final response = await client.post(
        uri,
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
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

  // --- 5. UPDATE (V2 - Actualizado) ---
  Future<Map<String, dynamic>> updateTableRecord({
    required DatabaseMetadataModel metadata,
    required String tableName,
    required dynamic id,
    required Map<String, dynamic> data,
    required String token,
  }) async {
    try {
      final dataWithId = Map<String, dynamic>.from(data);
      // dataWithId['id'] = id; // Opcional, si el backend requiere el ID dentro del data

      final v2Schema = SchemaAdapter.fromMetadata(metadata: metadata, targetTableName: tableName);
      final requestBody = V2DynamicRequest(schema: v2Schema, data: dataWithId);

      final uri = Uri.parse('$_v2BaseUrl/UPDATE').replace(
        queryParameters: {'tableName': tableName},
      );

      print('✏️ V2 UPDATE: $tableName');

      final response = await client.post(
        uri,
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
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

  // --- 6. GET BY ID (V2 - Actualizado) ---
  Future<Map<String, dynamic>> getTableRecord({
    required DatabaseMetadataModel metadata,
    required String tableName,
    required dynamic id,
    required String token,
  }) async {
    try {
      final v2Schema = SchemaAdapter.fromMetadata(metadata: metadata, targetTableName: tableName);
<<<<<<< HEAD

      // Según el backend: POST .../GETBYID/{id}?tableName=xxx
      // El body solo lleva el Schema (DbSchema), no DynamicRequestDto completo
      final uri = Uri.parse('$_v2BaseUrl/GETBYID/$id').replace(
        queryParameters: {'tableName': tableName},
      );
      print('🔍 V2 GETBYID: $tableName/$id');

      final response = await client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(v2Schema.toJson()), // Solo el schema, no el wrapper
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final dynamic jsonData = jsonDecode(response.body);
        // Retornamos el objeto directo
        if (jsonData is Map<String, dynamic>) return jsonData;
        return {};
      } else {
         throw Exception('V2 Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Error obteniendo registro V2: $e');
=======
      
      // POST V2/GETBYID/{id}
      final uri = Uri.parse('$_v2BaseUrl/GETBYID/$id').replace(
        queryParameters: {'tableName': tableName},
      );

      final response = await client.post(
        uri,
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        // GETBYID solo envía el Schema, no el wrapper completo con Data
        body: jsonEncode(v2Schema.toJson()), 
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('V2 GetById Error: ${response.statusCode}');
      }
    } catch (e) {
>>>>>>> dynamic
      throw Exception('Error fetching record: $e');
    }
  }

<<<<<<< HEAD
  // --- 7. DELETE (Legacy / V1) ---
=======
  // --- MÉTODO FALTANTE: DELETE (Legacy / V1) ---
>>>>>>> dynamic
  Future<bool> deleteTableRecord({
    required String databaseName,
    required String tableName,
    required dynamic id,
    required String token,
  }) async {
    try {
      // Usamos EndpointMapper (Lógica Antigua)
      final endpoint = EndpointMapper.getDeleteEndpoint(
        databaseName: databaseName,
        tableName: tableName,
        id: id,
      );
      final dbHeaderValue = EndpointMapper.getDatabaseHeaderValue(databaseName);

      print('🗑️ Eliminando registro (Legacy): $endpoint');

      final response = await client.delete(
        Uri.parse('${ApiEndpoints.baseUrl}$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'X-DbName': dbHeaderValue,
        },
      ).timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else if (response.statusCode == 500) {
        // Manejo básico de error de integridad referencial
        throw Exception(response.body.isNotEmpty 
            ? response.body 
            : 'No se puede eliminar el registro. Verifique dependencias.');
      } else {
        throw Exception('Failed to delete: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error eliminando registro: $e');
      throw Exception('Error deleting record: $e');
    }
  }

<<<<<<< HEAD
  // --- HELPERS (Sorting y Error Messages) ---
  void _sortRecordsDescending(List<Map<String, dynamic>> records) {
    if (records.isEmpty) return;
    String? sortColumn;
    final firstRecord = records.first;

    // Prioridad 1: Buscar columnas de fecha de creación
    for (var key in firstRecord.keys) {
      final lowerKey = key.toLowerCase();
      if (lowerKey.contains('created') || lowerKey.contains('fecha_creacion')) {
        sortColumn = key;
        break;
      }
    }

    // Prioridad 2: Buscar columnas de ID
    if (sortColumn == null) {
      for (var key in firstRecord.keys) {
        final lowerKey = key.toLowerCase();
        if (lowerKey == 'id' || lowerKey.endsWith('id')) {
          sortColumn = key;
          break;
        }
      }
    }

    // Prioridad 3: Primer campo numérico encontrado
    if (sortColumn == null) {
      for (var key in firstRecord.keys) {
        if (firstRecord[key] is num) {
          sortColumn = key;
          break;
        }
      }
    }

    // Si encontramos una columna para ordenar, ordenamos descendente
    if (sortColumn != null) {
      final column = sortColumn;
      records.sort((a, b) {
        final aValue = a[column];
        final bValue = b[column];

        // Manejo de valores null
        if (aValue == null && bValue == null) return 0;
        if (aValue == null) return 1;
        if (bValue == null) return -1;

        // Comparación descendente (más nuevo primero)
        if (aValue is num && bValue is num) {
          return bValue.compareTo(aValue);
        }

        if (aValue is String && bValue is String) {
          // Intentar parsear como fecha
          try {
            final dateA = DateTime.parse(aValue);
            final dateB = DateTime.parse(bValue);
            return dateB.compareTo(dateA);
          } catch (_) {
            // Si no son fechas, comparar como strings
            return bValue.compareTo(aValue);
          }
        }

        return 0;
      });
      print('🔽 Registros ordenados descendente por: $column');
    }
  }

  // ===========================================================================
  // MÉTODOS MOCK (RESTAURADOS)
  // ===========================================================================

  Future<DatabaseMetadataModel> getMockMetadata() async {
    await Future.delayed(const Duration(seconds: 1));
    const mockJson = {
      "database_name": "MockDB",
      "tables": [
        {"schema": "dbo", "table": "Usuarios", "row_count": 25, "table_type": "USER_TABLE"},
        {"schema": "dbo", "table": "Tareas", "row_count": 50, "table_type": "USER_TABLE"},
      ],
      "columns": [
        {"schema": "dbo", "table": "Usuarios", "name": "id", "type": "int", "is_identity": true},
        {"schema": "dbo", "table": "Usuarios", "name": "nombre", "type": "varchar", "is_identity": false},
        {"schema": "dbo", "table": "Tareas", "name": "id", "type": "int", "is_identity": true},
        {"schema": "dbo", "table": "Tareas", "name": "descripcion", "type": "varchar", "is_identity": false},
      ],
      "pk_info": [
        {"schema": "dbo", "table": "Usuarios", "column": "id"},
        {"schema": "dbo", "table": "Tareas", "column": "id"},
      ],
    };
    return DatabaseMetadataModel.fromJson(mockJson);
  }

  Future<List<Map<String, dynamic>>> getMockTableRecords(String tableName) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.generate(10, (index) => {
      'id': index + 1,
      'nombre': 'Dato Mock ${index + 1} ($tableName)',
      'created_at': DateTime.now().subtract(Duration(days: index)).toIso8601String(),
    });
  }

  Future<Map<String, dynamic>> getMockTableRecordsPaginated({
    required String tableName,
    required int page,
    required int pageSize,
    String? searchTerm,
  }) async {
    final all = await getMockTableRecords(tableName);
    return {
      'records': all,
      'totalRecords': all.length,
    };
  }

  Future<List<DropdownItemModel>> getMockDropdownData(String tableName) async {
    return [
      DropdownItemModel(id: 1, displayValue: 'Opción Mock 1'),
      DropdownItemModel(id: 2, displayValue: 'Opción Mock 2'),
    ];
  }

  // ===========================================================================
  // 8. DROPDOWN (Actualizado para seguir usando V1)
  // ===========================================================================

=======
  /// Ordena los registros en orden descendente (más nuevos primero)
  /// Intenta ordenar por: id, ID, created_at, createdAt, updated_at, o el primer campo numérico encontrado
  void _sortRecordsDescending(List<Map<String, dynamic>> records) {
    if (records.isEmpty) return;

    // Buscar la columna de ordenamiento (priorizar id o columnas de fecha)
    String? sortColumn;
    final firstRecord = records.first;

    // Prioridad 1: Buscar columnas de fecha de creación
    for (var key in firstRecord.keys) {
      final lowerKey = key.toLowerCase();
      if (lowerKey.contains('created') || lowerKey.contains('fecha_creacion')) {
        sortColumn = key;
        break;
      }
    }

    // Prioridad 2: Buscar columnas de ID
    if (sortColumn == null) {
      for (var key in firstRecord.keys) {
        final lowerKey = key.toLowerCase();
        if (lowerKey == 'id' || lowerKey.endsWith('id')) {
          sortColumn = key;
          break;
        }
      }
    }

    // Prioridad 3: Primer campo numérico encontrado
    if (sortColumn == null) {
      for (var key in firstRecord.keys) {
        if (firstRecord[key] is num) {
          sortColumn = key;
          break;
        }
      }
    }

    // Si encontramos una columna para ordenar, ordenamos descendente
    if (sortColumn != null) {
      final column = sortColumn;
      records.sort((a, b) {
        final aValue = a[column];
        final bValue = b[column];

        // Manejo de valores null
        if (aValue == null && bValue == null) return 0;
        if (aValue == null) return 1;
        if (bValue == null) return -1;

        // Comparación descendente (más nuevo primero)
        if (aValue is num && bValue is num) {
          return bValue.compareTo(aValue);
        }

        if (aValue is String && bValue is String) {
          // Intentar parsear como fecha
          try {
            final dateA = DateTime.parse(aValue);
            final dateB = DateTime.parse(bValue);
            return dateB.compareTo(dateA);
          } catch (_) {
            // Si no son fechas, comparar como strings
            return bValue.compareTo(aValue);
          }
        }

        return 0;
      });
      print('🔽 Registros ordenados descendente por: $column');
    }
  }


>>>>>>> dynamic
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

      print('📋 Cargando dropdown desde: $endpoint');
      print('🗄️  Header X-DbName: $dbHeaderValue');

      final response = await client.get(
        Uri.parse('${ApiEndpoints.baseUrl}$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'X-DbName': dbHeaderValue,
        },
      ).timeout(_timeout);

      print('📡 Status Code: ${response.statusCode}');
      print('📄 Response body completo: ${response.body}');

      if (response.statusCode == 200) {
        // Verificar si la respuesta está vacía
        if (response.body.isEmpty) {
          print('⚠️ Respuesta vacía del servidor');
          return [];
        }

        // Intentar parsear como JSON
        try {
          final dynamic jsonData = jsonDecode(response.body);

          // Si es un array directamente
          if (jsonData is List) {
            print('✅ Opciones de dropdown obtenidas: ${jsonData.length}');
            print('📦 Primer elemento: ${jsonData.isNotEmpty ? jsonData[0] : "vacío"}');
            return jsonData.map((json) => DropdownItemModel.fromJson(
              json as Map<String, dynamic>,
              displayColumns: displayColumns,
            )).toList();
          }

          // Si viene como ApiResponse
          if (jsonData is Map && jsonData.containsKey('success')) {
            final apiResponse = ApiResponse.fromJson(jsonData as Map<String, dynamic>, null);
            if (apiResponse.success) {
              final List<dynamic> data = apiResponse.data as List<dynamic>;
              print('✅ Opciones de dropdown obtenidas: ${data.length}');
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
          // Si falla el parseo JSON, el backend podría estar devolviendo texto plano o un error
          if (e is FormatException) {
            print('❌ El backend devolvió texto plano en lugar de JSON: ${response.body}');
            throw Exception('El endpoint $endpoint devolvió texto plano en lugar de JSON. Respuesta: ${response.body}');
          }
          rethrow;
        }
      } else if (response.statusCode == 404) {
        // El endpoint no existe en el backend
        print('⚠️ Endpoint no encontrado (404): $endpoint');
        print('💡 Consejo: La tabla "$tableName" no tiene endpoint en el backend.');
        print('   Si el campo es opcional (nullable), el formulario lo permitirá vacío.');
        print('   Si el campo es obligatorio, contacta al equipo backend para implementar el endpoint.');

        // Retornar lista vacía en lugar de lanzar excepción
        // Esto permite que el formulario se muestre, y el campo quedará vacío/opcional
        return [];
      } else {
<<<<<<< HEAD
        return []; 
=======
        throw Exception('Error ${response.statusCode} al cargar dropdown desde $endpoint: ${response.body}');
>>>>>>> dynamic
      }
    } catch (e) {
      print('❌ Error cargando dropdown: $e');
      throw Exception('Error fetching dropdown data: $e');
    }
  }
<<<<<<< HEAD
  
  bool lowerKeyMatchesId(String key) => key.toLowerCase() == 'id' || key.toLowerCase().endsWith('id');
=======

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
>>>>>>> dynamic

    return [];
  }

  // Mock table records with pagination
  Future<Map<String, dynamic>> getMockTableRecordsPaginated({
    required String tableName,
    required int page,
    required int pageSize,
    String? searchTerm,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // Get all mock records
    final allRecords = await getMockTableRecords(tableName);

    // Filter by search term if provided
    var filteredRecords = allRecords;
    if (searchTerm != null && searchTerm.isNotEmpty) {
      filteredRecords = allRecords.where((record) {
        return record.values.any((value) =>
            value.toString().toLowerCase().contains(searchTerm.toLowerCase()));
      }).toList();
    }

    // Apply pagination
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

  /// Genera un mensaje de error específico según la tabla que se intenta eliminar
  String _getDeleteErrorMessage(String tableName) {
    final lowerTable = tableName.toLowerCase();
<<<<<<< HEAD
    final Map<String, String> tableMessages = {
      'categorias': 'Tiene productos asociados.',
      'medicos': 'Tiene citas registradas.',
      'pacientes': 'Tiene citas o historiales médicos.',
      'proveedores': 'Tiene productos asociados.',
      'cursos': 'Tiene estudiantes inscritos.',
      'profesores': 'Tiene cursos asignados.',
      'citas': 'Tiene historiales clínicos asociados.',
    };

    for (var entry in tableMessages.entries) {
      if (lowerTable.contains(entry.key)) {
        return 'No se puede eliminar: ${entry.value}';
      }
    }

    return 'No se puede eliminar el registro por dependencias en otras tablas.';
  }
}
=======

    // Mensajes específicos por tabla
    final Map<String, String> tableMessages = {
      'categorias': 'No se puede eliminar esta categoría porque tiene productos asociados.\n\n'
          '💡 Solución:\n'
          '1. Primero cambie los productos a otra categoría, o\n'
          '2. Elimine los productos de esta categoría\n'
          '3. Luego intente eliminar la categoría nuevamente',

      'medicos': 'No se puede eliminar este médico porque tiene citas registradas.\n\n'
          '💡 Solución:\n'
          '1. Primero elimine o reasigne las citas del médico, o\n'
          '2. Considere marcarlo como "Inactivo" en lugar de eliminarlo',

      'pacientes': 'No se puede eliminar este paciente porque tiene citas o historiales médicos.\n\n'
          '💡 Solución:\n'
          '1. Primero elimine las citas y registros del paciente, o\n'
          '2. Considere marcarlo como "Inactivo" en lugar de eliminarlo',

      'proveedores': 'No se puede eliminar este proveedor porque tiene productos asociados.\n\n'
          '💡 Solución:\n'
          '1. Primero cambie los productos a otro proveedor, o\n'
          '2. Elimine los productos de este proveedor\n'
          '3. Luego intente eliminar el proveedor',

      'cursos': 'No se puede eliminar este curso porque tiene estudiantes inscritos.\n\n'
          '💡 Solución:\n'
          '1. Primero elimine las inscripciones del curso, o\n'
          '2. Considere marcarlo como "Inactivo"',

      'profesores': 'No se puede eliminar este profesor porque tiene cursos asignados.\n\n'
          '💡 Solución:\n'
          '1. Primero reasigne los cursos a otro profesor, o\n'
          '2. Considere marcarlo como "Inactivo"',

      'citas': 'No se puede eliminar esta cita porque tiene historiales clínicos asociados.\n\n'
          '💡 Solución:\n'
          '1. Primero elimine los historiales clínicos de esta cita, o\n'
          '2. Contacte al administrador del sistema',
    };

    // Buscar mensaje específico
    for (var entry in tableMessages.entries) {
      if (lowerTable.contains(entry.key)) {
        return entry.value;
      }
    }

    // Mensaje genérico si no se encuentra la tabla
    return 'No se puede eliminar el registro porque tiene datos relacionados en otras tablas.\n\n'
        '💡 Solución:\n'
        '1. Primero elimine o reasigne los registros relacionados\n'
        '2. Luego intente eliminar este registro nuevamente\n'
        '3. O considere marcarlo como "Inactivo" en lugar de eliminarlo\n\n'
        '📞 Si el problema persiste, contacte al administrador del sistema.';
  }
}
>>>>>>> dynamic
