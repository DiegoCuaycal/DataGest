import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:herramienta_case/modules/export/domain/models/export_config.dart';
import 'package:herramienta_case/modules/export/domain/models/export_format.dart';
import 'package:herramienta_case/modules/export/domain/models/export_result.dart';

/// Servicio para exportar datos a diferentes formatos
class ExportService {
  /// Exporta datos según la configuración proporcionada
  Future<ExportResult> exportData({
    required List<Map<String, dynamic>> data,
    required ExportConfig config,
  }) async {
    // Validar que hay datos
    if (data.isEmpty) {
      throw Exception('No hay datos para exportar');
    }

    // Log de inicio de exportación
    print('📤 Iniciando exportación:');
    print('   - Formato: ${config.format.displayName}');
    print('   - Tabla: ${config.tableName ?? "Todas"}');
    print('   - Registros: ${data.length}');
    print('   - Incluir cabeceras: ${config.includeHeaders}');

    switch (config.format) {
      case ExportFormat.csv:
        return await _exportToCsv(data, config);
      case ExportFormat.json:
        return await _exportToJson(data, config);
    }
  }

  /// Exporta datos a formato CSV
  Future<ExportResult> _exportToCsv(
    List<Map<String, dynamic>> data,
    ExportConfig config,
  ) async {
    print('📊 Exportando a CSV...');

    // Filtrar columnas si se especificaron
    final filteredData = _filterColumns(data, config.columns);
    print('   ✓ Datos filtrados: ${filteredData.length} registros');

    // Aplicar límite si se especificó
    final limitedData = config.limit != null
        ? filteredData.take(config.limit!).toList()
        : filteredData;
    print('   ✓ Límite aplicado: ${limitedData.length} registros');

    // Obtener las columnas
    final columns = limitedData.first.keys.toList();
    print('   ✓ Columnas detectadas: ${columns.length} (${columns.join(", ")})');

    // Crear las filas para el CSV
    final List<List<dynamic>> rows = [];

    // Agregar cabeceras si se requieren
    if (config.includeHeaders) {
      rows.add(columns);
      print('   ✓ Cabeceras agregadas');
    } else {
      print('   ⊗ Sin cabeceras');
    }

    // Agregar datos
    for (final row in limitedData) {
      rows.add(columns.map((col) => _formatValue(row[col])).toList());
    }
    print('   ✓ ${rows.length} filas preparadas');

    // Convertir a CSV
    final csvData = const ListToCsvConverter().convert(rows);
    print('   ✓ CSV generado: ${csvData.length} caracteres');

    // Guardar archivo
    final file = await _saveFile(
      content: csvData,
      extension: 'csv',
      tableName: config.tableName,
    );
    print('   ✓ Archivo guardado: ${file.path}');

    final result = ExportResult(
      filePath: file.path,
      fileName: _getFileName(file.path),
      recordsCount: limitedData.length,
      fileSize: await file.length(),
      message: 'Datos exportados exitosamente a CSV',
    );

    print('✅ Exportación CSV completada: ${result.fileName} (${result.fileSize} bytes)');
    return result;
  }

  /// Exporta datos a formato JSON
  Future<ExportResult> _exportToJson(
    List<Map<String, dynamic>> data,
    ExportConfig config,
  ) async {
    print('📋 Exportando a JSON...');

    // Filtrar columnas si se especificaron
    final filteredData = _filterColumns(data, config.columns);
    print('   ✓ Datos filtrados: ${filteredData.length} registros');

    // Aplicar límite si se especificó
    final limitedData = config.limit != null
        ? filteredData.take(config.limit!).toList()
        : filteredData;
    print('   ✓ Límite aplicado: ${limitedData.length} registros');

    // Nota: JSON no tiene el concepto de "cabeceras" como CSV
    // Los nombres de las columnas están incluidos en cada objeto JSON
    if (config.includeHeaders) {
      print('   ✓ JSON incluye nombres de campos automáticamente');
    }

    // Convertir a JSON con formato legible
    final jsonData = const JsonEncoder.withIndent('  ').convert(limitedData);
    print('   ✓ JSON generado: ${jsonData.length} caracteres');

    // Guardar archivo
    final file = await _saveFile(
      content: jsonData,
      extension: 'json',
      tableName: config.tableName,
    );
    print('   ✓ Archivo guardado: ${file.path}');

    final result = ExportResult(
      filePath: file.path,
      fileName: _getFileName(file.path),
      recordsCount: limitedData.length,
      fileSize: await file.length(),
      message: 'Datos exportados exitosamente a JSON',
    );

    print('✅ Exportación JSON completada: ${result.fileName} (${result.fileSize} bytes)');
    return result;
  }

  /// Filtra las columnas de los datos según la configuración
  List<Map<String, dynamic>> _filterColumns(
    List<Map<String, dynamic>> data,
    List<String>? columns,
  ) {
    if (columns == null || columns.isEmpty) {
      return data;
    }

    return data.map((row) {
      final filteredRow = <String, dynamic>{};
      for (final column in columns) {
        if (row.containsKey(column)) {
          filteredRow[column] = row[column];
        }
      }
      return filteredRow;
    }).toList();
  }

  /// Formatea un valor para exportación
  dynamic _formatValue(dynamic value) {
    if (value == null) {
      return '';
    }
    if (value is DateTime) {
      return DateFormat('yyyy-MM-dd HH:mm:ss').format(value);
    }
    if (value is bool) {
      return value ? 'true' : 'false';
    }
    return value.toString();
  }

  /// Guarda el contenido en un archivo
  Future<File> _saveFile({
    required String content,
    required String extension,
    String? tableName,
  }) async {
    // Obtener el directorio de documentos
    final directory = await getApplicationDocumentsDirectory();
    print('📁 Directorio base: ${directory.path}');

    // Crear carpeta de exportaciones si no existe
    final exportDir = Directory('${directory.path}/exports');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
      print('   ✓ Carpeta exports creada');
    }

    print('📂 Ruta de exportaciones: ${exportDir.path}');

    // Generar nombre de archivo con timestamp
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final prefix = tableName ?? 'all_tables';
    final fileName = '${prefix}_$timestamp.$extension';

    // Crear y escribir archivo
    final file = File('${exportDir.path}/$fileName');
    await file.writeAsString(content);

    print('💾 Archivo guardado en:');
    print('   ${file.path}');

    return file;
  }

  /// Obtiene el nombre del archivo de una ruta completa
  String _getFileName(String path) {
    return path.split(Platform.pathSeparator).last;
  }

  /// Obtiene el directorio de exportaciones
  Future<String> getExportsDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${directory.path}/exports');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    return exportDir.path;
  }

  /// Lista todos los archivos exportados
  Future<List<FileSystemEntity>> listExportedFiles() async {
    final exportDir = await getExportsDirectory();
    final directory = Directory(exportDir);
    return directory.listSync();
  }

  /// Elimina un archivo exportado
  Future<void> deleteExportedFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Elimina todos los archivos exportados
  Future<void> clearExports() async {
    final files = await listExportedFiles();
    for (final file in files) {
      await file.delete();
    }
  }
}
