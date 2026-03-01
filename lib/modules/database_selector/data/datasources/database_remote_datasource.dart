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
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;

        return data.asMap().entries.map((entry) {
          return DatabaseInfoModel(
            id: entry.key + 1,
            name: entry.value as String,
            description: 'Base de datos ${entry.value}',
          );
        }).toList();
      } else {
        throw Exception('Failed to load databases: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching databases: $e');
    }
  }

  /// Returns an empty list; reserved as a local fallback when the backend is unavailable.
  Future<List<DatabaseInfoModel>> getMockDatabases() async {
    await Future.delayed(const Duration(seconds: 1));
    return [];
  }
}
