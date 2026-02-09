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
        // La API ahora devuelve un array de objetos: [{"name": "...", "type": "..."}]
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;

        // Convertir cada objeto a un DatabaseInfoModel
        return data.asMap().entries.map((entry) {
          final dynamic item = entry.value;
          
          if (item is String) {
            // Caso 1: API devuelve lista de strings ["DB1", "DB2", ...]
            return DatabaseInfoModel(
              id: entry.key + 1,
              name: item,
              description: 'Base de datos $item',
              type: 'SQL Server', // Tipo por defecto al no tener info
            );
          } else if (item is Map) {
            // Caso 2: API devuelve lista de objetos [{"Name": "DB1", "Type": "SQL Server"}, ...]
            final dbInfo = item as Map<String, dynamic>;
            return DatabaseInfoModel(
              id: entry.key + 1,
              name: dbInfo['Name'] as String? ?? dbInfo['name'] as String? ?? 'Base de Datos ${entry.key + 1}',
              description: 'Base de datos ${dbInfo['Name'] ?? dbInfo['name']}',
              type: dbInfo['Type'] as String? ?? dbInfo['type'] as String? ?? 'SQL Server',
            );
          } else {
             // Fallback para otros tipos inesperados
             return DatabaseInfoModel(
              id: entry.key + 1,
              name: 'Unknown DB ${entry.key + 1}',
              description: 'Base de datos desconocida',
              type: 'SQL Server',
            );
          }
        }).toList();
      } else {
        throw Exception('Failed to load databases: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching databases: $e');
    }
  }

  /// Mock data for testing without backend (SOLO PARA DEBUG)
  /// NOTA: Este método solo se usa si falla la conexión con el API
  Future<List<DatabaseInfoModel>> getMockDatabases() async {
    // Simular delay de red
    await Future.delayed(const Duration(seconds: 1));

    // IMPORTANTE: Esta lista es solo para desarrollo/debug
    // En producción, SIEMPRE se debe usar getAvailableDatabases()
    return [];
  }
}
