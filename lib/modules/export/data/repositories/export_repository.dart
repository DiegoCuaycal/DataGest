import 'dart:io';
import 'package:herramienta_case/modules/dynamic_crud/data/datasources/dynamic_remote_datasource.dart';
import 'package:herramienta_case/modules/dynamic_crud/data/models/table_info_model.dart';
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
    required String databaseName,
    required String tableName,
    required ExportConfig config,
    required String token,
    bool useMockData = false, // Nueva opción para usar datos de prueba
  }) async {
    try {
      List<Map<String, dynamic>> data;

      if (useMockData) {
        // Usar datos de prueba
        print('⚠️ Usando datos de prueba para tabla: $tableName');
        data = await remoteDataSource.getMockTableRecords(tableName);

        if (data.isEmpty) {
          // Si no hay mock para esta tabla, crear datos genéricos
          data = [
            {'id': 1, 'nombre': 'Dato 1', 'descripcion': 'Ejemplo'},
            {'id': 2, 'nombre': 'Dato 2', 'descripcion': 'Ejemplo'},
          ];
        }
      } else {
        // Obtener los datos reales de la tabla
        data = await remoteDataSource.getTableRecords(
          databaseName: databaseName,
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
    required String databaseName,
    required List<TableInfoModel> tables,
    required ExportConfig baseConfig,
    required String token,
    bool useMockData = false, // Opción para usar datos de prueba
  }) async {
    final results = <ExportResult>[];
    final errors = <String>[];

    if (useMockData) {
      print('⚠️⚠️⚠️ MODO DE PRUEBA ACTIVADO ⚠️⚠️⚠️');
      print('Se usarán datos de prueba en lugar de datos reales');
    }

    print('🔄 Iniciando exportación de ${tables.length} tablas...');

    for (final table in tables) {
      try {
        print('📊 Procesando tabla: ${table.table}');

        // Crear configuración específica para cada tabla
        final config = baseConfig.copyWith(tableName: table.table);

        // Exportar la tabla (con o sin datos mock)
        final result = await exportTable(
          databaseName: databaseName,
          tableName: table.table,
          config: config,
          token: token,
          useMockData: useMockData,
        );

        results.add(result);
        print('✅ Tabla ${table.table} exportada exitosamente');
      } catch (e) {
        // Guardar el error pero continuar con las demás tablas
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
        'No se pudo exportar ninguna tabla.\n\n'
        'Posibles causas:\n'
        '• El backend no está corriendo\n'
        '• Error 404: Los endpoints no existen\n'
        '• Las tablas están vacías\n\n'
        'Errores:\n${errors.join('\n')}\n\n'
        '💡 Sugerencia: Activa el modo de prueba para verificar la funcionalidad.'
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
    required String databaseName,
    required List<TableInfoModel> allTables,
    required ExportConfig config,
    required String token,
  }) async {
    return await exportMultipleTables(
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
