import '../datasources/dynamic_remote_datasource.dart';
import '../models/database_metadata_model.dart';
import '../models/dropdown_item_model.dart';

class DynamicCrudRepository {
  final DynamicRemoteDataSource remoteDataSource;

  DynamicCrudRepository({required this.remoteDataSource});

  Future<DatabaseMetadataModel> getMetadata({
    required String databaseName,
    required String token,
    bool useMock = false,
  }) async {
    try {
      if (useMock) {
        return await remoteDataSource.getMockMetadata();
      }
      return await remoteDataSource.getMetadata(
        databaseName: databaseName,
        token: token,
      );
    } catch (e) {
      throw Exception('Repository error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getTableRecords({
    required String databaseName,
    required String tableName,
    required String token,
    bool useMock = false,
  }) async {
    try {
      if (useMock) {
        return await remoteDataSource.getMockTableRecords(tableName);
      }
      return await remoteDataSource.getTableRecords(
        databaseName: databaseName,
        tableName: tableName,
        token: token,
      );
    } catch (e) {
      throw Exception('Repository error: $e');
    }
  }

  Future<Map<String, dynamic>> getTableRecord({
    required String databaseName,
    required String tableName,
    required dynamic id,
    required String token,
  }) async {
    try {
      return await remoteDataSource.getTableRecord(
        databaseName: databaseName,
        tableName: tableName,
        id: id,
        token: token,
      );
    } catch (e) {
      throw Exception('Repository error: $e');
    }
  }

  Future<Map<String, dynamic>> createTableRecord({
    required String databaseName,
    required String tableName,
    required Map<String, dynamic> data,
    required String token,
  }) async {
    try {
      return await remoteDataSource.createTableRecord(
        databaseName: databaseName,
        tableName: tableName,
        data: data,
        token: token,
      );
    } catch (e) {
      throw Exception('Repository error: $e');
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
      return await remoteDataSource.updateTableRecord(
        databaseName: databaseName,
        tableName: tableName,
        id: id,
        data: data,
        token: token,
      );
    } catch (e) {
      throw Exception('Repository error: $e');
    }
  }

  Future<bool> deleteTableRecord({
    required String databaseName,
    required String tableName,
    required dynamic id,
    required String token,
  }) async {
    try {
      return await remoteDataSource.deleteTableRecord(
        databaseName: databaseName,
        tableName: tableName,
        id: id,
        token: token,
      );
    } catch (e) {
      throw Exception('Repository error: $e');
    }
  }

  Future<List<DropdownItemModel>> getDropdownData({
    required String databaseName,
    required String tableName,
    required String token,
    bool useMock = false,
  }) async {
    try {
      if (useMock) {
        return await remoteDataSource.getMockDropdownData(tableName);
      }
      return await remoteDataSource.getDropdownData(
        databaseName: databaseName,
        tableName: tableName,
        token: token,
      );
    } catch (e) {
      throw Exception('Repository error: $e');
    }
  }
}
