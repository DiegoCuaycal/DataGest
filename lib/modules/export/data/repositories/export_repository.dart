import 'dart:io';
import 'package:herramienta_case/modules/dynamic_crud/data/datasources/dynamic_remote_datasource.dart';
import 'package:herramienta_case/modules/dynamic_crud/data/models/table_info_model.dart';
// IMPORTANTE: Necesitamos importar el modelo de metadata
import 'package:herramienta_case/modules/dynamic_crud/data/models/database_metadata_model.dart'; 
import 'package:herramienta_case/modules/export/domain/models/export_config.dart';
import 'package:herramienta_case/modules/export/domain/models/export_result.dart';
import 'package:herramienta_case/modules/export/domain/services/export_service.dart';

/// Repositorio para gestionar la exportación de datos
class ExportRepository {
  final DynamicRemoteDataSource remoteDataSource;
  final ExportService exportService;

  ExportRepository({
    required this.remoteDataSource,
    required this.exportService,
  });

  /// Exporta datos de una tabla específica
  Future<ExportResult> exportTable({
    required DatabaseMetadataModel metadata, // <--- NUEVO REQUISITO V2
    required String databaseName,
    required String tableName,
    required ExportConfig config,
    required String token,
    bool useMockData = false,
  }) async {
    try {
      List<Map<String, dynamic>> data;

      if (useMockData) {
        // Usar datos de prueba (Ahora sí funcionará porque agregamos el método al datasource)
        print('⚠️ Usando datos de prueba para tabla: $tableName');
        data = await remoteDataSource.getMockTableRecords(tableName);

        if (data.isEmpty) {
          data = [
            {'id': 1, 'nombre': 'Dato 1', 'descripcion': 'Ejemplo'},
            {'id': 2, 'nombre': 'Dato 2', 'descripcion': 'Ejemplo'},
          ];
        }
      } else {
        // Obtener los datos reales de la tabla usando la Lógica V2
        // Nótese que ahora pasamos 'metadata' y quitamos 'databaseName' del llamado
        data = await remoteDataSource.getTableRecords(
          metadata: metadata, // <--- Pasamos la metadata aquí
          tableName: tableName,
          token: token,
        );
      }

      if (data.isEmpty) {
        throw Exception('La tabla $tableName no contiene datos para exportar');
      }

      // Exportar usando el servicio
      return await exportService.exportData(
        data: data,
        config: config,
      );
    } catch (e) {
      throw Exception('Error al exportar la tabla $tableName: $e');
    }
  }

  /// Exporta datos de múltiples tablas
  Future<List<ExportResult>> exportMultipleTables({
    required DatabaseMetadataModel metadata, // <--- NUEVO REQUISITO V2
    required String databaseName,
    required List<TableInfoModel> tables,
    required ExportConfig baseConfig,
    required String token,
    bool useMockData = false,
  }) async {
    final results = <ExportResult>[];
    final errors = <String>[];

    if (useMockData) {
      print('⚠️⚠️⚠️ MODO DE PRUEBA ACTIVADO ⚠️⚠️⚠️');
    }

    print('🔄 Iniciando exportación de ${tables.length} tablas...');

    for (final table in tables) {
      try {
        print('📊 Procesando tabla: ${table.table}');

        final config = baseConfig.copyWith(tableName: table.table);

        // Exportar la tabla pasando la metadata
        final result = await exportTable(
          metadata: metadata, // <--- Pasamos la metadata
          databaseName: databaseName,
          tableName: table.table,
          config: config,
          token: token,
          useMockData: useMockData,
        );

        results.add(result);
        print('✅ Tabla ${table.table} exportada exitosamente');
      } catch (e) {
        final errorMsg = 'Tabla ${table.table}: ${_extractErrorMessage(e.toString())}';
        errors.add(errorMsg);
        print('❌ Error en tabla ${table.table}: $e');
      }
    }

    print('\n📈 Resumen de exportación:');
    print('   ✅ Exitosas: ${results.length}');
    print('   ❌ Fallidas: ${errors.length}');

    if (errors.isNotEmpty) {
      print('\n⚠️ Errores encontrados:');
      for (final error in errors) {
        print('   - $error');
      }
    }

    if (results.isEmpty) {
      throw Exception(
        'No se pudo exportar ninguna tabla.\nErrors:\n${errors.join('\n')}'
      );
    }

    return results;
  }

  /// Extrae el mensaje de error más relevante
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

  /// Exporta todas las tablas de la base de datos
  Future<List<ExportResult>> exportAllTables({
    required DatabaseMetadataModel metadata, // <--- NUEVO REQUISITO V2
    required String databaseName,
    required List<TableInfoModel> allTables,
    required ExportConfig config,
    required String token,
  }) async {
    return await exportMultipleTables(
      metadata: metadata, // <--- Pasamos la metadata
      databaseName: databaseName,
      tables: allTables,
      baseConfig: config,
      token: token,
    );
  }

  /// Obtiene el directorio de exportaciones
  Future<String> getExportsDirectory() async {
    return await exportService.getExportsDirectory();
  }

  /// Lista los archivos exportados
  Future<List<FileSystemEntity>> listExportedFiles() async {
    return await exportService.listExportedFiles();
  }

  /// Elimina un archivo exportado
  Future<void> deleteExportedFile(String filePath) async {
    return await exportService.deleteExportedFile(filePath);
  }

  /// Limpia todas las exportaciones
  Future<void> clearExports() async {
    return await exportService.clearExports();
  }
}