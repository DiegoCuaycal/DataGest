import '../datasources/dynamic_remote_datasource.dart';
import '../models/database_metadata_model.dart';
import '../models/dropdown_item_model.dart';

/// Repository that mediates between the dynamic CRUD feature and its remote
/// data source.
///
/// Exposes a unified interface for all CRUD operations, supporting both live
/// API calls and mock data for development and testing. All V2 operations
/// (read, create, update) require a [DatabaseMetadataModel] so the data
/// source can build the request schema dynamically. Delete and dropdown
/// operations use the legacy V1 endpoints via [DynamicRemoteDataSource].
class DynamicCrudRepository {
  final DynamicRemoteDataSource remoteDataSource;

  DynamicCrudRepository({required this.remoteDataSource});

  /// Fetches the full database schema metadata for [databaseName].
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

  /// Returns all records for [tableName] from the V2 API.
  Future<List<Map<String, dynamic>>> getTableRecords({
    required DatabaseMetadataModel metadata,
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
        metadata: metadata,
        tableName: tableName,
        token: token,
      );
    } catch (e) {
      throw Exception('Repository error: $e');
    }
  }

  /// Returns a paginated and optionally filtered page of records for [tableName].
  Future<Map<String, dynamic>> getTableRecordsPaginated({
    required DatabaseMetadataModel metadata,
    required String databaseName,
    required String tableName,
    required String token,
    required int page,
    required int pageSize,
    String? searchTerm,
    bool useMock = false,
  }) async {
    try {
      if (useMock) {
        return await remoteDataSource.getMockTableRecordsPaginated(
          tableName: tableName,
          page: page,
          pageSize: pageSize,
          searchTerm: searchTerm,
        );
      }
      return await remoteDataSource.getTableRecordsPaginated(
        metadata: metadata,
        tableName: tableName,
        token: token,
        page: page,
        pageSize: pageSize,
        searchTerm: searchTerm,
      );
    } catch (e) {
      throw Exception('Repository error: $e');
    }
  }

  /// Fetches a single record by [id] from [tableName].
  Future<Map<String, dynamic>> getTableRecord({
    required DatabaseMetadataModel metadata,
    required String databaseName,
    required String tableName,
    required dynamic id,
    required String token,
  }) async {
    try {
      return await remoteDataSource.getTableRecord(
        metadata: metadata,
        tableName: tableName,
        id: id,
        token: token,
      );
    } catch (e) {
      throw Exception('Repository error: $e');
    }
  }

  /// Creates a new record in [tableName] with the provided [data].
  Future<Map<String, dynamic>> createTableRecord({
    required DatabaseMetadataModel metadata,
    required String databaseName,
    required String tableName,
    required Map<String, dynamic> data,
    required String token,
  }) async {
    try {
      return await remoteDataSource.createTableRecord(
        metadata: metadata,
        tableName: tableName,
        data: data,
        token: token,
      );
    } catch (e) {
      throw Exception('Repository error: $e');
    }
  }

  /// Updates the record identified by [id] in [tableName] with [data].
  Future<Map<String, dynamic>> updateTableRecord({
    required DatabaseMetadataModel metadata,
    required String databaseName,
    required String tableName,
    required dynamic id,
    required Map<String, dynamic> data,
    required String token,
  }) async {
    try {
      return await remoteDataSource.updateTableRecord(
        metadata: metadata,
        tableName: tableName,
        id: id,
        data: data,
        token: token,
      );
    } catch (e) {
      throw Exception('Repository error: $e');
    }
  }

  /// Deletes the record identified by [id] from [tableName].
  ///
  /// Delegates to the legacy V1 delete endpoint. The [metadata] parameter
  /// is accepted for interface consistency with the other methods but is
  /// not forwarded to the data source.
  Future<bool> deleteTableRecord({
    required DatabaseMetadataModel metadata,
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

  /// Returns the list of items for a foreign key dropdown for [tableName].
  ///
  /// Uses the legacy V1 endpoints. Supports mock data for UI development.
  Future<List<DropdownItemModel>> getDropdownData({
    required String databaseName,
    required String tableName,
    required String token,
    List<String>? displayColumns,
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
        displayColumns: displayColumns,
      );
    } catch (e) {
      throw Exception('Repository error: $e');
    }
  }
}
