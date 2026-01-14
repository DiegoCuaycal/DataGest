import '../datasources/dynamic_remote_datasource.dart';
import '../models/database_metadata_model.dart';
import '../models/dropdown_item_model.dart';

class DynamicCrudRepository {
  final DynamicRemoteDataSource remoteDataSource;

  DynamicCrudRepository({required this.remoteDataSource});

  // 1. GET METADATA
  // Este NO cambia, porque es el encargado de OBTENER la metadata inicial.
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

  // 2. GET TABLE RECORDS (Lista Completa - V2)
  // Cambio: Agregamos 'metadata'
  Future<List<Map<String, dynamic>>> getTableRecords({
    required DatabaseMetadataModel metadata, // <--- NUEVO REQUERIDO
    required String databaseName, 
    required String tableName,
    required String token,
    bool useMock = false,
  }) async {
    try {
      if (useMock) {
        return await remoteDataSource.getMockTableRecords(tableName);
      }
      // Pasamos la metadata al datasource V2
      return await remoteDataSource.getTableRecords(
        metadata: metadata, 
        tableName: tableName,
        token: token,
      );
    } catch (e) {
      throw Exception('Repository error: $e');
    }
  }

  // 3. GET PAGINATED (V2)
  // Cambio: Agregamos 'metadata'
  Future<Map<String, dynamic>> getTableRecordsPaginated({
    required DatabaseMetadataModel metadata, // <--- NUEVO REQUERIDO
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
        metadata: metadata, // Pasamos la metadata
        tableName: tableName, // El datasource ya no pide databaseName aquí explícitamente si usa V2
        token: token,
        page: page,
        pageSize: pageSize,
        searchTerm: searchTerm,
      );
    } catch (e) {
      throw Exception('Repository error: $e');
    }
  }

  // 4. GET BY ID (V2)
  // Cambio: Agregamos 'metadata'
  Future<Map<String, dynamic>> getTableRecord({
    required DatabaseMetadataModel metadata, // <--- NUEVO REQUERIDO
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

  // 5. CREATE (V2)
  // Cambio: Agregamos 'metadata'
  Future<Map<String, dynamic>> createTableRecord({
    required DatabaseMetadataModel metadata, // <--- NUEVO REQUERIDO
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

  // 6. UPDATE (V2)
  // Cambio: Agregamos 'metadata'
  Future<Map<String, dynamic>> updateTableRecord({
    required DatabaseMetadataModel metadata, // <--- NUEVO REQUERIDO
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

  // 7. DELETE (Legacy/V1)
  // Nota: Mantenemos la firma con 'metadata' por consistencia en el Provider,
  // aunque el datasource use la lógica legacy (V1) que pide databaseName.
  Future<bool> deleteTableRecord({
    required DatabaseMetadataModel metadata, // <--- NUEVO (Por consistencia)
    required String databaseName,
    required String tableName,
    required dynamic id,
    required String token,
  }) async {
    try {
      return await remoteDataSource.deleteTableRecord(
        databaseName: databaseName, // Delete sigue usando V1
        tableName: tableName,
        id: id,
        token: token,
      );
    } catch (e) {
      throw Exception('Repository error: $e');
    }
  }

  // 8. DROPDOWN (Legacy/V1)
  // Este se queda IGUAL porque los dropdowns suelen usar endpoints V1
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
