import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config/env_config.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/endpoint_mapper.dart';
import '../models/database_metadata_model.dart';
import '../models/dropdown_item_model.dart';

class DynamicRemoteDataSource {
  final http.Client client;

  DynamicRemoteDataSource({required this.client});

  /// Timeout para todas las peticiones HTTP
  Duration get _timeout => Duration(seconds: EnvConfig.apiTimeout);

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
        print('🔗 URL completa: $url');
        print('🔑 Token: ${token.isNotEmpty && token.length > 20 ? token.substring(0, 20) : token}...');

        final response = await client.get(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(_timeout);

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
        print('❌ Error en getMetadata (intento $attempt/$maxRetries): $e');
        final errorMsg = e.toString().toLowerCase();

        // Detectar si es un error de timeout del backend SQL Server o timeout HTTP
        final isConnectionTimeout = errorMsg.contains('connection timeout') ||
            errorMsg.contains('timeout expired') ||
            errorMsg.contains('post-login') ||
            errorMsg.contains('timeoutexception');

        // Si no es el último intento y es un timeout (HTTP o SQL), esperar antes de reintentar
        if (attempt < maxRetries && isConnectionTimeout) {
          print('⏳ Timeout detectado. Esperando 3 segundos antes de reintentar...');
          await Future.delayed(const Duration(seconds: 3));
          continue;
        }

        // Si es el último intento, lanzar el error
        throw Exception('Error fetching metadata: $e');
      }
    }

    throw Exception('Error desconocido al cargar metadata');
  }

  Future<List<Map<String, dynamic>>> getTableRecords({
    required String databaseName,
    required String tableName,
    required String token,
  }) async {
    try {
      // Usar el mapper para obtener el endpoint correcto
      final endpoint = EndpointMapper.getListEndpoint(
        databaseName: databaseName,
        tableName: tableName,
      );
      final dbHeaderValue = EndpointMapper.getDatabaseHeaderValue(databaseName);

      final url = '${ApiEndpoints.baseUrl}$endpoint';
      print('🌐 URL completa: $url');
      print('🗄️  Header X-DbName: $dbHeaderValue');
      print('🔑 Token: ${token.length > 20 ? "${token.substring(0, 20)}..." : token}');

      final response = await client.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'X-DbName': dbHeaderValue,
        },
      ).timeout(_timeout);

      print('📡 Status Code: ${response.statusCode}');
      print('📄 Response body (primeros 200 chars): ${response.body.length > 200 ? response.body.substring(0, 200) : response.body}');

      if (response.statusCode == 200) {
        // El backend de .NET devuelve directamente un array, no un objeto ApiResponse
        final dynamic jsonData = jsonDecode(response.body);

        // Si es un array directamente
        if (jsonData is List) {
          print('✅ Registros obtenidos: ${jsonData.length}');
          return jsonData.cast<Map<String, dynamic>>();
        }

        // Si viene envuelto en ApiResponse
        final apiResponse = ApiResponse.fromJson(jsonData, null);
        if (apiResponse.success) {
          final List<dynamic> data = apiResponse.data as List<dynamic>;
          print('✅ Registros obtenidos: ${data.length}');
          return data.cast<Map<String, dynamic>>();
        } else {
          throw Exception(apiResponse.message);
        }
      } else if (response.statusCode == 404 || response.statusCode == 405) {
        // El endpoint no existe o el método no está permitido
        print('⚠️ Endpoint no disponible (${response.statusCode}): $endpoint');
        throw Exception(
          'La tabla "$tableName" no tiene soporte para listar registros en el backend. '
          'Código de error: ${response.statusCode}. '
          'Contacta al equipo backend para implementar GET $endpoint'
        );
      } else {
        throw Exception('Failed to load records: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error en getTableRecords: $e');
      throw Exception('Error fetching records: $e');
    }
  }

  /// Get table records with pagination and search
  Future<Map<String, dynamic>> getTableRecordsPaginated({
    required String databaseName,
    required String tableName,
    required String token,
    required int page,
    required int pageSize,
    String? searchTerm,
  }) async {
    // Primero intentar con paginación del backend
    try {
      final endpoint = EndpointMapper.getListEndpoint(
        databaseName: databaseName,
        tableName: tableName,
      );
      final dbHeaderValue = EndpointMapper.getDatabaseHeaderValue(databaseName);

      final queryParams = <String, String>{
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      };

      if (searchTerm != null && searchTerm.isNotEmpty) {
        queryParams['search'] = searchTerm;
      }

      final uri = Uri.parse('${ApiEndpoints.baseUrl}$endpoint')
          .replace(queryParameters: queryParams);

      final response = await client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'X-DbName': dbHeaderValue,
        },
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final dynamic jsonData = jsonDecode(response.body);

        // Si el backend devuelve la estructura con paginación
        if (jsonData is Map &&
            jsonData.containsKey('records') &&
            jsonData.containsKey('totalRecords')) {
          print('✅ Usando paginación del backend');
          final records = (jsonData['records'] as List).cast<Map<String, dynamic>>();
          // Ordenar registros más nuevos primero (descendente)
          _sortRecordsDescending(records);
          return {
            'records': records,
            'totalRecords': jsonData['totalRecords'] as int,
          };
        }

        // Si viene como ApiResponse
        if (jsonData is Map && jsonData.containsKey('success')) {
          final apiResponse = ApiResponse.fromJson(jsonData as Map<String, dynamic>, null);
          if (apiResponse.success && apiResponse.data is Map) {
            final data = apiResponse.data as Map<String, dynamic>;
            if (data.containsKey('records') && data.containsKey('totalRecords')) {
              print('✅ Usando paginación del backend (ApiResponse)');
              final records = (data['records'] as List).cast<Map<String, dynamic>>();
              // Ordenar registros más nuevos primero (descendente)
              _sortRecordsDescending(records);
              return {
                'records': records,
                'totalRecords': data['totalRecords'] as int,
              };
            }
          }
        }
      }
    } catch (e) {
      print('⚠️ Paginación del backend no disponible: $e');
    }

    // Fallback: Obtener todos los registros y paginar del lado del cliente
    try {
      print('📱 Usando paginación del lado del cliente');
      final allRecords = await getTableRecords(
        databaseName: databaseName,
        tableName: tableName,
        token: token,
      );

      // Ordenar registros más nuevos primero (descendente)
      _sortRecordsDescending(allRecords);

      // Aplicar búsqueda si existe
      var filteredRecords = allRecords;
      if (searchTerm != null && searchTerm.isNotEmpty) {
        filteredRecords = allRecords.where((record) {
          return record.values.any((value) =>
              value.toString().toLowerCase().contains(searchTerm.toLowerCase()));
        }).toList();
      }

      // Aplicar paginación del lado del cliente
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
      throw Exception('Error fetching records: $e');
    }
  }

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

  Future<Map<String, dynamic>> getTableRecord({
    required String databaseName,
    required String tableName,
    required dynamic id,
    required String token,
  }) async {
    try {
      final endpoint = EndpointMapper.getByIdEndpoint(
        databaseName: databaseName,
        tableName: tableName,
        id: id,
      );
      final dbHeaderValue = EndpointMapper.getDatabaseHeaderValue(databaseName);

      print('🔍 Obteniendo registro por ID desde: $endpoint');
      print('🗄️  Header X-DbName: $dbHeaderValue');
      print('🔑 Token: ${token.length > 20 ? "${token.substring(0, 20)}..." : token}');

      final response = await client.get(
        Uri.parse('${ApiEndpoints.baseUrl}$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'X-DbName': dbHeaderValue,
        },
      ).timeout(_timeout);

      print('📡 Status Code: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic jsonData = jsonDecode(response.body);

        // Si es un objeto directamente
        if (jsonData is Map<String, dynamic>) {
          print('✅ Registro obtenido: $jsonData');
          return jsonData;
        }

        // Si viene envuelto en ApiResponse
        final apiResponse = ApiResponse.fromJson(jsonData as Map<String, dynamic>, null);
        if (apiResponse.success) {
          print('✅ Registro obtenido (ApiResponse): ${apiResponse.data}');
          return apiResponse.data as Map<String, dynamic>;
        } else {
          throw Exception(apiResponse.message);
        }
      } else if (response.statusCode == 404) {
        // FALLBACK: Si el endpoint GET por ID no existe (404),
        // obtener todos los registros y buscar el que coincida con el ID
        print('⚠️ Endpoint GET por ID no implementado (404), usando fallback...');

        final allRecords = await getTableRecords(
          databaseName: databaseName,
          tableName: tableName,
          token: token,
        );

        // Buscar el registro con el ID específico
        try {
          final record = allRecords.firstWhere(
            (record) => record['id'].toString() == id.toString(),
          );
          print('✅ Registro encontrado usando fallback: $record');
          return record;
        } catch (e) {
          throw Exception('Registro con ID $id no encontrado');
        }
      } else {
        throw Exception('Failed to load record: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error obteniendo registro: $e');
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
      final endpoint = EndpointMapper.getCreateEndpoint(
        databaseName: databaseName,
        tableName: tableName,
      );
      final dbHeaderValue = EndpointMapper.getDatabaseHeaderValue(databaseName);

      print('📝 Creando registro en: $endpoint');
      print('📦 Datos: $data');

      final response = await client.post(
        Uri.parse('${ApiEndpoints.baseUrl}$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'X-DbName': dbHeaderValue,
        },
        body: jsonEncode(data),
      ).timeout(_timeout);

      print('📡 Status Code: ${response.statusCode}');
      print('📄 Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Verificar si la respuesta está vacía o es texto plano
        if (response.body.isEmpty) {
          print('✅ Registro creado (respuesta vacía)');
          return {'success': true, 'message': 'Registro creado exitosamente'};
        }

        // Intentar parsear como JSON
        try {
          final dynamic jsonData = jsonDecode(response.body);

          // Si es un objeto directamente
          if (jsonData is Map<String, dynamic>) {
            return jsonData;
          }

          // Si viene como ApiResponse
          final apiResponse = ApiResponse.fromJson(jsonData as Map<String, dynamic>, null);
          if (apiResponse.success) {
            return apiResponse.data as Map<String, dynamic>;
          } else {
            throw Exception(apiResponse.message);
          }
        } catch (e) {
          // Si falla el parseo JSON, es probable que sea texto plano
          if (e is FormatException) {
            print('✅ Registro creado (respuesta de texto plano): ${response.body}');
            return {'success': true, 'message': response.body};
          }
          rethrow;
        }
      } else if (response.statusCode == 400) {
        // Error 400: Probablemente legajo duplicado
        final errorMsg = response.body.isNotEmpty
          ? response.body
          : 'Error de validación. Verifica que el legajo no esté duplicado.';
        throw Exception('Error de validación: $errorMsg');
      } else if (response.statusCode == 500) {
        // Error 500: Error del servidor
        final errorMsg = response.body.isNotEmpty
          ? response.body
          : 'Error interno del servidor. Verifica:\n1. Que el legajo no esté duplicado\n2. Que todos los campos requeridos estén completos\n3. Que el formato de fecha sea válido';
        throw Exception('Error del servidor: $errorMsg');
      } else {
        throw Exception('Failed to create record: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error creando registro: $e');
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
      final endpoint = EndpointMapper.getUpdateEndpoint(
        databaseName: databaseName,
        tableName: tableName,
        id: id,
      );
      final dbHeaderValue = EndpointMapper.getDatabaseHeaderValue(databaseName);

      print('✏️ Actualizando registro en: $endpoint');
      print('📦 Datos a actualizar: $data');

      final response = await client.put(
        Uri.parse('${ApiEndpoints.baseUrl}$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'X-DbName': dbHeaderValue,
        },
        body: jsonEncode(data),
      ).timeout(_timeout);

      print('📡 Status Code: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        // Verificar si la respuesta está vacía o es texto plano
        if (response.body.isEmpty) {
          print('✅ Registro actualizado (respuesta vacía)');
          return {'success': true, 'message': 'Registro actualizado exitosamente'};
        }

        // Intentar parsear como JSON
        try {
          final dynamic jsonData = jsonDecode(response.body);

          // Si es un objeto directamente
          if (jsonData is Map<String, dynamic>) {
            return jsonData;
          }

          // Si viene como ApiResponse
          final apiResponse = ApiResponse.fromJson(jsonData as Map<String, dynamic>, null);
          if (apiResponse.success) {
            return apiResponse.data as Map<String, dynamic>;
          } else {
            throw Exception(apiResponse.message);
          }
        } catch (e) {
          // Si falla el parseo JSON, es probable que sea texto plano
          if (e is FormatException) {
            print('✅ Registro actualizado (respuesta de texto plano): ${response.body}');
            return {'success': true, 'message': response.body};
          }
          rethrow;
        }
      } else if (response.statusCode == 404 || response.statusCode == 405) {
        // FALLBACK: Si el endpoint PUT no está implementado (404/405 Method Not Allowed)
        print('⚠️ Endpoint PUT no implementado (${response.statusCode}), intentando fallback...');

        // Opción 1: Intentar con POST en el endpoint base (algunos backends aceptan POST para update)
        final createEndpoint = EndpointMapper.getCreateEndpoint(
          databaseName: databaseName,
          tableName: tableName,
        );

        print('🔄 Intentando actualización vía POST en: $createEndpoint');

        // Agregar el ID a los datos para el POST
        final dataWithId = {...data, 'id': id};

        final fallbackResponse = await client.post(
          Uri.parse('${ApiEndpoints.baseUrl}$createEndpoint'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
            'X-DbName': dbHeaderValue,
          },
          body: jsonEncode(dataWithId),
        ).timeout(_timeout);

        print('📡 Fallback Status Code: ${fallbackResponse.statusCode}');
        print('📄 Fallback Response: ${fallbackResponse.body}');

        if (fallbackResponse.statusCode == 200 || fallbackResponse.statusCode == 201) {
          print('✅ Actualización exitosa usando fallback POST');
          return {'success': true, 'message': 'Registro actualizado'};
        } else {
          throw Exception(
            'El backend no tiene implementado el endpoint de actualización (PUT) '
            'para la tabla $tableName. Código de error: ${response.statusCode}. '
            'Contacte al equipo de backend para implementar este endpoint.'
          );
        }
      } else {
        throw Exception('Failed to update record: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error actualizando registro: $e');
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
      final endpoint = EndpointMapper.getDeleteEndpoint(
        databaseName: databaseName,
        tableName: tableName,
        id: id,
      );
      final dbHeaderValue = EndpointMapper.getDatabaseHeaderValue(databaseName);

      print('🗑️ Eliminando registro en: $endpoint');

      final response = await client.delete(
        Uri.parse('${ApiEndpoints.baseUrl}$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'X-DbName': dbHeaderValue,
        },
      ).timeout(_timeout);

      print('📡 Status Code: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Algunos endpoints devuelven solo un mensaje de texto o respuesta vacía
        if (response.body.isEmpty) {
          print('✅ Registro eliminado (respuesta vacía)');
          return true;
        }

        // Intentar parsear como JSON
        try {
          final dynamic jsonData = jsonDecode(response.body);

          // Si viene como ApiResponse
          if (jsonData is Map && jsonData.containsKey('success')) {
            final apiResponse = ApiResponse.fromJson(jsonData as Map<String, dynamic>, null);
            return apiResponse.success;
          }

          // Si es cualquier otra respuesta exitosa
          return true;
        } catch (e) {
          // Si falla el parseo JSON, es probable que sea texto plano
          if (e is FormatException) {
            print('✅ Registro eliminado (respuesta de texto plano): ${response.body}');
            return true;
          }
          rethrow;
        }
      } else {
        throw Exception('Failed to delete record: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error eliminando registro: $e');
      throw Exception('Error deleting record: $e');
    }
  }

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
        throw Exception('Error ${response.statusCode} al cargar dropdown desde $endpoint: ${response.body}');
      }
    } catch (e) {
      print('❌ Error cargando dropdown: $e');
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
}
