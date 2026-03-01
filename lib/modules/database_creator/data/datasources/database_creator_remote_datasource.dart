import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_endpoints.dart';
import '../../domain/models/database_schema.dart';

/// Remote data source for database-creation operations.
///
/// Communicates directly with the `/api/Auth/crear-modulo` endpoint using
/// a plain [http.Client] (no auth token required at this stage).
class DatabaseCreatorRemoteDataSource {
  final http.Client client;

  DatabaseCreatorRemoteDataSource({required this.client});

  /// Sends [schema] to the backend to provision a new SQL Server database.
  ///
  /// The endpoint expects two fields:
  /// - `nombreDb`: the database name
  /// - `jsonTablas`: the table definitions serialised as a JSON string
  ///
  /// Throws an [Exception] on validation errors (400), name conflicts (409),
  /// or any other non-2xx response.
  Future<void> createDatabase(DatabaseSchema schema) async {
    try {
      final tablesJson = schema.toJson();
      final tablesJsonString = jsonEncode(tablesJson);

      final requestBody = {
        'nombreDb': schema.name,
        'jsonTablas': tablesJsonString,
      };

      final url = '${ApiEndpoints.baseUrl}/api/Auth/crear-modulo';

      final response = await client.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else if (response.statusCode == 400) {
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
        throw Exception('Ya existe una base de datos con ese nombre');
      } else {
        throw Exception(
          'Error al crear la base de datos: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Error de conexión al crear la base de datos: $e');
    }
  }

  /// Validates [schema] against the backend without creating anything.
  ///
  /// Returns the server's validation response on success, or throws an
  /// [Exception] if the request fails.
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
