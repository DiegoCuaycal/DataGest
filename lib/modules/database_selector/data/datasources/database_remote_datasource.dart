import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_endpoints.dart';
import '../models/database_info_model.dart';

class DatabaseRemoteDataSource {
  final http.Client client;

  DatabaseRemoteDataSource({required this.client});

  Future<List<DatabaseInfoModel>> getAvailableDatabases() async {
    try {
      final response = await client.get(
        Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.databases}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        // La API devuelve un array de strings: ["Estudiantes", "Médicos", "Productos"]
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;

        // Convertir cada string a un DatabaseInfoModel
        return data.asMap().entries.map((entry) {
          return DatabaseInfoModel(
            id: entry.key + 1, // Generar ID basado en el índice
            name: entry.value as String,
            description: 'Base de datos ${entry.value}', // Descripción generada
          );
        }).toList();
      } else {
        throw Exception('Failed to load databases: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching databases: $e');
    }
  }

  // Mock data for testing without backend
  Future<List<DatabaseInfoModel>> getMockDatabases() async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

    return [
      DatabaseInfoModel(
        id: 1,
        name: 'ToList',
        description: 'Gestión de tareas',
      ),
      DatabaseInfoModel(
        id: 2,
        name: 'Inventario',
        description: 'Control de inventario',
      ),
      DatabaseInfoModel(
        id: 3,
        name: 'Ventas',
        description: 'Sistema de ventas',
      ),
    ];
  }
}
