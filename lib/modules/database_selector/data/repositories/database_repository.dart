import '../datasources/database_remote_datasource.dart';
import '../models/database_info_model.dart';

class DatabaseRepository {
  final DatabaseRemoteDataSource remoteDataSource;

  DatabaseRepository({required this.remoteDataSource});

  Future<List<DatabaseInfoModel>> getAvailableDatabases({bool useMock = false}) async {
    try {
      if (useMock) {
        return await remoteDataSource.getMockDatabases();
      }
      return await remoteDataSource.getAvailableDatabases();
    } catch (e) {
      throw Exception('Repository error: $e');
    }
  }
}
