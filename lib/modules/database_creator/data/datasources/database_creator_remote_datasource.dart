import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_endpoints.dart';
import '../../domain/models/database_schema.dart';

/// Datasource para manejar la comunicación con el backend para crear bases de datos
class DatabaseCreatorRemoteDataSource {
  final http.Client client;

  DatabaseCreatorRemoteDataSource({required this.client});

  /// Envía el esquema de la base de datos al backend usando /api/Auth/crear-modulo
  Future<void> createDatabase(DatabaseSchema schema) async {
    try {
      // El backend espera dos campos:
      // - nombreDb: nombre de la base de datos
      // - jsonTablas: JSON string con las tablas
      final tablesJson = schema.toJson();

      // Convertir el array de tablas a string JSON
      final tablesJsonString = jsonEncode(tablesJson);

      // Crear el objeto que espera el backend
      final requestBody = {
        'nombreDb': schema.name,
        'jsonTablas': tablesJsonString,
      };

      // Debug: Imprimir lo que se está enviando
      print('\n=== CREANDO BASE DE DATOS ===');
      print('Nombre de BD: ${schema.name}');
      print('Número de tablas: ${schema.tables.length}');
      print('\n--- JSON TABLAS ---');
      print(tablesJsonString);
      print('\n--- REQUEST BODY COMPLETO ---');
      print(jsonEncode(requestBody));
      print('--- FIN ---\n');

      // Endpoint del backend para crear módulo/base de datos
      final url = '${ApiEndpoints.baseUrl}/api/Auth/crear-modulo';

      print('📤 Enviando a: $url');

      final response = await client.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}\n');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Base de datos "${schema.name}" creada exitosamente en el backend\n');
        return;
      } else if (response.statusCode == 400) {
        // Error de validación del backend
        try {
          final errorData = jsonDecode(response.body);
          final errorMessage = errorData['message'] ??
                              errorData['error'] ??
                              'Error de validación en el servidor';
          throw Exception(errorMessage);
        } catch (e) {
          throw Exception('Error de validación: ${response.body}');
        }
      } else if (response.statusCode == 409) {
        // Conflicto - la base de datos ya existe
        throw Exception('Ya existe una base de datos con ese nombre');
      } else {
        throw Exception(
          'Error al crear la base de datos: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Error: $e\n');
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Error de conexión al crear la base de datos: $e');
    }
  }

  /// Valida el esquema en el backend sin crearlo
  Future<Map<String, dynamic>> validateSchema(DatabaseSchema schema) async {
    try {
      final jsonData = schema.toJson();

      final response = await client.post(
        Uri.parse('${ApiEndpoints.baseUrl}/api/Schema/validate'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(jsonData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Error al validar el esquema: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión al validar el esquema: $e');
    }
  }
}
