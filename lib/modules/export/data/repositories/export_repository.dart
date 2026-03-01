import 'dart:io';
import 'package:herramienta_case/modules/dynamic_crud/data/datasources/dynamic_remote_datasource.dart';
import 'package:herramienta_case/modules/dynamic_crud/data/models/table_info_model.dart';
import 'package:herramienta_case/modules/dynamic_crud/data/models/database_metadata_model.dart';
import 'package:herramienta_case/modules/export/domain/models/export_config.dart';
import 'package:herramienta_case/modules/export/domain/models/export_result.dart';
import 'package:herramienta_case/modules/export/domain/services/export_service.dart';

/// Repository that coordinates data fetching and file export for the export
/// feature.
///
/// Delegates record retrieval to [DynamicRemoteDataSource] and file
/// serialization to [ExportService].
class ExportRepository {
  final DynamicRemoteDataSource remoteDataSource;
  final ExportService exportService;

  ExportRepository({
    required this.remoteDataSource,
    required this.exportService,
  });

  /// Fetches all records from [tableName] and exports them according to
  /// [config].
  ///
  /// When [useMockData] is `true`, returns synthetic records instead of
  /// calling the remote API.
  Future<ExportResult> exportTable({
    required DatabaseMetadataModel metadata,
    required String databaseName,
    required String tableName,
    required ExportConfig config,
    required String token,
    bool useMockData = false,
  }) async {
    try {
      List<Map<String, dynamic>> data;

      if (useMockData) {
        data = await remoteDataSource.getMockTableRecords(tableName);

        if (data.isEmpty) {
          data = [
            {'id': 1, 'nombre': 'Dato 1', 'descripcion': 'Ejemplo'},
            {'id': 2, 'nombre': 'Dato 2', 'descripcion': 'Ejemplo'},
          ];
        }
      } else {
        data = await remoteDataSource.getTableRecords(
          metadata: metadata,
          tableName: tableName,
          token: token,
        );
      }

      if (data.isEmpty) {
        throw Exception('La tabla $tableName no contiene datos para exportar');
      }

      return await exportService.exportData(
        data: data,
        config: config,
      );
    } catch (e) {
      throw Exception('Error al exportar la tabla $tableName: $e');
    }
  }

  /// Exports each table in [tables] and returns one [ExportResult] per
  /// successfully exported table.
  ///
  /// Tables that fail are silently skipped; if every table fails an
  /// [Exception] is thrown summarising all errors.
  Future<List<ExportResult>> exportMultipleTables({
    required DatabaseMetadataModel metadata,
    required String databaseName,
    required List<TableInfoModel> tables,
    required ExportConfig baseConfig,
    required String token,
    bool useMockData = false,
  }) async {
    final results = <ExportResult>[];
    final errors = <String>[];

    for (final table in tables) {
      try {
        final config = baseConfig.copyWith(tableName: table.table);

        final result = await exportTable(
          metadata: metadata,
          databaseName: databaseName,
          tableName: table.table,
          config: config,
          token: token,
          useMockData: useMockData,
        );

        results.add(result);
      } catch (e) {
        final errorMsg = 'Tabla ${table.table}: ${_extractErrorMessage(e.toString())}';
        errors.add(errorMsg);
      }
    }

    if (results.isEmpty) {
      throw Exception(
        'No se pudo exportar ninguna tabla.\n\n'
        'Errores:\n${errors.join('\n')}'
      );
    }

    return results;
  }

  String _extractErrorMessage(String fullError) {
    if (fullError.contains('404')) {
      return 'No se encontró el endpoint (404)';
    } else if (fullError.contains('no contiene datos')) {
      return 'Tabla vacía';
    } else if (fullError.contains('Failed to load records')) {
      return 'Error al cargar registros del servidor';
    }
    return 'Error desconocido';
  }

  /// Exports every table in [allTables].
  ///
  /// Delegates to [exportMultipleTables].
  Future<List<ExportResult>> exportAllTables({
    required DatabaseMetadataModel metadata,
    required String databaseName,
    required List<TableInfoModel> allTables,
    required ExportConfig config,
    required String token,
  }) async {
    return await exportMultipleTables(
      metadata: metadata,
      databaseName: databaseName,
      tables: allTables,
      baseConfig: config,
      token: token,
    );
  }

  Future<String> getExportsDirectory() async {
    return await exportService.getExportsDirectory();
  }

  Future<List<FileSystemEntity>> listExportedFiles() async {
    return await exportService.listExportedFiles();
  }

  Future<void> deleteExportedFile(String filePath) async {
    return await exportService.deleteExportedFile(filePath);
  }

  Future<void> clearExports() async {
    return await exportService.clearExports();
  }
}
