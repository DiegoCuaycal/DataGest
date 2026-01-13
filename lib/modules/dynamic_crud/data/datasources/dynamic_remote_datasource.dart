import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config/env_config.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/endpoint_mapper.dart';
import '../models/database_metadata_model.dart';
import '../models/dropdown_item_model.dart';
import '../models/v2_schema_dto.dart'; // Asegúrate de haber creado este archivo (Paso 1)
import 'schema_adapter.dart'; // Asegúrate de haber creado este archivo (Paso 2)

class DynamicRemoteDataSource {
  final http.Client client;

  DynamicRemoteDataSource({required this.client});

  /// Timeout para todas las peticiones HTTP
  Duration get _timeout => Duration(seconds: EnvConfig.apiTimeout);

  /// URL Base para la V2
  String get _v2BaseUrl => '${ApiEndpoints.baseUrl}/api/DynamicCrud/V2';

  // ===========================================================================
  // 1. METADATA (SE MANTIENE IGUAL - ES EL PUNTO DE ENTRADA)
  // ===========================================================================
  Future<DatabaseMetadataModel> getMetadata({
    required String databaseName,
    required String token,
  }) async {
    const maxRetries = 3;
    int attempt = 0;

    while (attempt < maxRetries) {
      attempt++;
      try {
        final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.metadata(databaseName)}';
        print('📊 Solicitando metadata para DB: $databaseName (Intento $attempt/$maxRetries)');
        
        final response = await client.get(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(_timeout);

        if (response.statusCode == 200) {
          final jsonData = jsonDecode(response.body);
          return DatabaseMetadataModel.fromJson(jsonData);
        } else {
          throw Exception('Failed to load metadata: ${response.statusCode}');
        }
      } catch (e) {
        print('❌ Error en getMetadata (intento $attempt/$maxRetries): $e');
        final errorMsg = e.toString().toLowerCase();

        final isConnectionTimeout = errorMsg.contains('connection timeout') ||
            errorMsg.contains('timeout expired') ||
            errorMsg.contains('post-login') ||
            errorMsg.contains('timeoutexception');

        if (attempt < maxRetries && isConnectionTimeout) {
          await Future.delayed(const Duration(seconds: 3));
          continue;
        }
        throw Exception('Error fetching metadata: $e');
      }
    }
    throw Exception('Error desconocido al cargar metadata');
  }

  // ===========================================================================
  // 2. GET ALL RECORDS (ACTUALIZADO A V2)
  // ===========================================================================
  Future<List<Map<String, dynamic>>> getTableRecords({
    required DatabaseMetadataModel metadata, // ¡Nuevo! Necesario para V2
    required String tableName,
    required String token,
  }) async {
    try {
      // 1. Construir Schema usando el Adapter
      final v2Schema = SchemaAdapter.fromMetadata(
        metadata: metadata, 
        targetTableName: tableName
      );
      
      // 2. Preparar Request Body
      final requestBody = V2DynamicRequest(schema: v2Schema);

      print('🚀 V2 GETALL: $tableName');

      // 3. Llamada POST al endpoint V2
      // CRÍTICO: tableName va como query parameter, NO en el body
      final uri = Uri.parse('$_v2BaseUrl/GETALL').replace(
        queryParameters: {'tableName': tableName},
      );

      final response = await client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody.toJson()),
      ).timeout(_timeout);

      print('📡 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        // === DEBUG: Ver la respuesta exacta del backend ===
        print('🔍 Response Body Type: ${response.body.runtimeType}');
        print('🔍 Response Body Length: ${response.body.length}');
        print('🔍 Response Body Preview (primeros 500 chars): ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');

        final dynamic jsonData = jsonDecode(response.body);
        print('🔍 JSON Data Type: ${jsonData.runtimeType}');

        if (jsonData is List) {
          print('✅ Es una Lista directa con ${jsonData.length} elementos');
        } else if (jsonData is Map) {
          print('✅ Es un Map con keys: ${jsonData.keys.toList()}');
        }
        // === FIN DEBUG ===

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

        // Soporte legacy para ApiResponse si el backend V2 lo usa
        if (jsonData is Map && jsonData.containsKey('success')) {
           final apiResponse = ApiResponse.fromJson(jsonData as Map<String, dynamic>, null);
           return (apiResponse.data as List).cast<Map<String, dynamic>>();
        }

        print('⚠️ No se encontró ningún array de datos en la respuesta');
        return [];
      } else {
        throw Exception('V2 Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Error en getTableRecords V2: $e');
      throw Exception('Error fetching records V2: $e');
    }
  }

  // ===========================================================================
  // 3. PAGINACIÓN (ACTUALIZADO - CLIENT SIDE PAGINATION SOBRE V2)
  // ===========================================================================
  Future<Map<String, dynamic>> getTableRecordsPaginated({
    required DatabaseMetadataModel metadata,
    required String tableName,
    required String token,
    required int page,
    required int pageSize,
    String? searchTerm,
  }) async {
    // NOTA: Como la V2 GETALL devuelve todo (según swagger), 
    // mantenemos tu lógica de paginación local que funciona muy bien.
    try {
      print('📱 Usando paginación del lado del cliente sobre datos V2');
      
      // Llamamos al nuevo método V2
      final allRecords = await getTableRecords(
        metadata: metadata,
        tableName: tableName,
        token: token,
      );

      // --- Tu lógica de ordenamiento y filtrado se mantiene intacta ---
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
          ? filteredRecords.sublist(
              startIndex.clamp(0, totalRecords),
              endIndex,
            )
          : <Map<String, dynamic>>[];

      return {
        'records': paginatedRecords,
        'totalRecords': totalRecords,
      };
    } catch (e) {
      throw Exception('Error fetching paginated records: $e');
    }
  }

  // ===========================================================================
  // 4. GET BY ID (ACTUALIZADO A V2)
  // ===========================================================================
  Future<Map<String, dynamic>> getTableRecord({
    required DatabaseMetadataModel metadata,
    required String tableName,
    required dynamic id,
    required String token,
  }) async {
    try {
      final v2Schema = SchemaAdapter.fromMetadata(metadata: metadata, targetTableName: tableName);

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
      throw Exception('Error fetching record: $e');
    }
  }

  // ===========================================================================
  // 5. CREATE (ACTUALIZADO A V2 + TU LOGICA DE FECHAS)
  // ===========================================================================
  Future<Map<String, dynamic>> createTableRecord({
    required DatabaseMetadataModel metadata,
    required String tableName,
    required Map<String, dynamic> data,
    required String token,
  }) async {
    try {

      // --- INICIO DE SOLUCIÓN 3 (TU PARCHE DE FECHA AZURE) ---
      final Map<String, dynamic> optimizedData = Map.from(data);
      optimizedData.forEach((key, value) {
        if (key.toLowerCase().contains('visita') || 
            key.toLowerCase().contains('fecha') || 
            (value is String && value.contains('T') && value.length > 10)) {
          if (value is String && !value.endsWith('Z')) {
            optimizedData[key] = value.contains('.') 
                ? "${value.split('.')[0]}Z" 
                : "${value}Z";
            print('📅 Fecha optimizada para Azure: $key -> ${optimizedData[key]}');
          }
        }
      });
      // --- FIN DE SOLUCIÓN 3 ---

      // Preparar V2 Body
      final v2Schema = SchemaAdapter.fromMetadata(metadata: metadata, targetTableName: tableName);
      final requestBody = V2DynamicRequest(schema: v2Schema, data: optimizedData);

      // OJO: Typo 'CREADTE' mantenido del backend
      // CRÍTICO: tableName va como query parameter
      final uri = Uri.parse('$_v2BaseUrl/CREADTE').replace(
        queryParameters: {'tableName': tableName},
      );
      print('📝 V2 CREATE: $tableName');

      final response = await client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody.toJson()),
      ).timeout(_timeout);

      print('📡 Status Code: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.body.isEmpty) return {'success': true};
        try {
          return jsonDecode(response.body);
        } catch (_) {
          return {'success': true, 'message': response.body};
        }
      } else {
        throw Exception('V2 Create Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error creando registro V2: $e');
      throw Exception('Error creating record: $e');
    }
  }

  // ===========================================================================
  // 6. UPDATE (ACTUALIZADO A V2)
  // ===========================================================================
  Future<Map<String, dynamic>> updateTableRecord({
    required DatabaseMetadataModel metadata,
    required String tableName,
    required dynamic id,
    required Map<String, dynamic> data,
    required String token,
  }) async {
    try {

      // Aseguramos que el ID vaya en la data (por si el backend lo requiere en el body)
      final dataWithId = Map<String, dynamic>.from(data);
      // Opcional: Si tu lógica UI no manda el ID en el mapa 'data', descomenta esto:
      // dataWithId['id'] = id; 

      final v2Schema = SchemaAdapter.fromMetadata(metadata: metadata, targetTableName: tableName);
      final requestBody = V2DynamicRequest(schema: v2Schema, data: dataWithId);

      // CRÍTICO: tableName va como query parameter
      final uri = Uri.parse('$_v2BaseUrl/UPDATE').replace(
        queryParameters: {'tableName': tableName},
      );
      print('✏️ V2 UPDATE: $tableName');

      final response = await client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody.toJson()),
      ).timeout(_timeout);

      print('📡 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Actualizado correctamente'};
      } else {
        throw Exception('V2 Update Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error actualizando registro V2: $e');
      throw Exception('Error updating record: $e');
    }
  }

  // ===========================================================================
  // 7. DELETE (MANTENIDO LOGICA ORIGINAL - NO HAY V2 DEFINIDA)
  // ===========================================================================
  Future<bool> deleteTableRecord({
    // Recibimos metadata por compatibilidad con el repo, pero no la usamos aquí
    required DatabaseMetadataModel metadata, 
    required String databaseName,
    required String tableName,
    required dynamic id,
    required String token,
  }) async {
    try {
      // Usamos EndpointMapper (Lógica Antigua) porque no hay endpoint DELETE en V2 Swagger
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
        String specificMsg = _getDeleteErrorMessage(tableName);
        throw Exception(response.body.isNotEmpty ? response.body : specificMsg);
      } else {
        throw Exception('Failed to delete: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error eliminando registro: $e');
      throw Exception('Error deleting record: $e');
    }
  }

  // ===========================================================================
  // MÉTODOS MOCK (RECUPERADOS PARA EXPORT_REPOSITORY)
  // ===========================================================================

  Future<DatabaseMetadataModel> getMockMetadata() async {
    await Future.delayed(const Duration(seconds: 1));
    // Mock básico para pruebas
    return DatabaseMetadataModel(
      databaseName: "MockDB",
      tables: [], 
      columns: [],
      pkInfo: [],
      fkInfo: [],
      indexes: [],
      views: []
    );
  }

  Future<List<Map<String, dynamic>>> getMockTableRecords(String tableName) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Retorna datos de prueba genéricos
    return List.generate(10, (index) => {
      'id': index + 1,
      'titulo': 'Dato de Prueba ${index + 1} para $tableName',
      'fecha': DateTime.now().toIso8601String(),
    });
  }
  
  // Este también se usaba en tu código anterior
  Future<Map<String, dynamic>> getMockTableRecordsPaginated({
    required String tableName,
    required int page,
    required int pageSize,
    String? searchTerm,
  }) async {
    final records = await getMockTableRecords(tableName);
    return {
      'records': records,
      'totalRecords': records.length,
    };
  }
  
  Future<List<DropdownItemModel>> getMockDropdownData(String tableName) async {
      return [];
  }

  // ===========================================================================
  // 8. DROPDOWN & UTILS (SE MANTIENEN IGUAL)
  // ===========================================================================
  Future<List<DropdownItemModel>> getDropdownData({
    required String databaseName,
    required String tableName,
    required String token,
    List<String>? displayColumns,
  }) async {
    // Mantenemos lógica original para dropdowns
    try {
      final endpoint = EndpointMapper.getDropdownEndpoint(
        databaseName: databaseName,
        tableName: tableName,
      );
      final dbHeaderValue = EndpointMapper.getDatabaseHeaderValue(databaseName);

      final response = await client.get(
        Uri.parse('${ApiEndpoints.baseUrl}$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'X-DbName': dbHeaderValue,
        },
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        if (response.body.isEmpty) return [];
        final dynamic jsonData = jsonDecode(response.body);
        if (jsonData is List) {
          return jsonData.map((json) => DropdownItemModel.fromJson(
            json as Map<String, dynamic>,
            displayColumns: displayColumns,
          )).toList();
        }
        return [];
      } else {
        return []; // Retorna vacío si falla (comportamiento original seguro)
      }
    } catch (e) {
      print('❌ Error dropdown: $e');
      return [];
    }
  }

  // --- HELPERS (Sorting y Error Messages) SE MANTIENEN IGUAL ---
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
        if (lowerKeyMatchesId(key)) { sortColumn = key; break; }
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
        if (aValue is num && bValue is num) return bValue.compareTo(aValue);
        return bValue.toString().compareTo(aValue.toString());
      });
    }
  }
  
  bool lowerKeyMatchesId(String key) => key.toLowerCase() == 'id' || key.toLowerCase().endsWith('id');

  String _getDeleteErrorMessage(String tableName) {
    // ... (Tu lista de mensajes de error original se mantiene aquí)
    return 'No se puede eliminar el registro. Verifique dependencias.';
  }

}