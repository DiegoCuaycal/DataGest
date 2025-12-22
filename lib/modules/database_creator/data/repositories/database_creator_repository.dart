import '../../domain/models/database_schema.dart';
import '../datasources/database_creator_remote_datasource.dart';

/// Repository para manejar la creación de bases de datos
class DatabaseCreatorRepository {
  final DatabaseCreatorRemoteDataSource remoteDataSource;

  DatabaseCreatorRepository({required this.remoteDataSource});

  /// Crea una nueva base de datos en el backend
  Future<void> createDatabase(DatabaseSchema schema) async {
    try {
      await remoteDataSource.createDatabase(schema);
    } catch (e) {
      // Podríamos agregar logging aquí
      rethrow;
    }
  }

  /// Valida un esquema de base de datos sin crearlo
  Future<Map<String, dynamic>> validateSchema(DatabaseSchema schema) async {
    try {
      return await remoteDataSource.validateSchema(schema);
    } catch (e) {
      rethrow;
    }
  }
}
