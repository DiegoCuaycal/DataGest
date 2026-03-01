import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:herramienta_case/modules/export/domain/models/export_config.dart';
import 'package:herramienta_case/modules/export/domain/models/export_format.dart';
import 'package:herramienta_case/modules/export/domain/models/export_result.dart';

/// Service responsible for serializing table data to CSV or JSON files
/// and persisting them in the application's documents directory under
/// an `exports/` subdirectory.
class ExportService {
  /// Exports [data] according to [config] and returns an [ExportResult]
  /// describing the generated file.
  ///
  /// Throws an [Exception] if [data] is empty.
  Future<ExportResult> exportData({
    required List<Map<String, dynamic>> data,
    required ExportConfig config,
  }) async {
    if (data.isEmpty) {
      throw Exception('No hay datos para exportar');
    }

    switch (config.format) {
      case ExportFormat.csv:
        return await _exportToCsv(data, config);
      case ExportFormat.json:
        return await _exportToJson(data, config);
    }
  }

  /// Serializes [data] to a CSV file using [config] and returns the result.
  Future<ExportResult> _exportToCsv(
    List<Map<String, dynamic>> data,
    ExportConfig config,
  ) async {
    final filteredData = _filterColumns(data, config.columns);

    final limitedData = config.limit != null
        ? filteredData.take(config.limit!).toList()
        : filteredData;

    final columns = limitedData.first.keys.toList();

    final List<List<dynamic>> rows = [];

    if (config.includeHeaders) {
      rows.add(columns);
    }

    for (final row in limitedData) {
      rows.add(columns.map((col) => _formatValue(row[col])).toList());
    }

    final csvData = const ListToCsvConverter().convert(rows);

    final file = await _saveFile(
      content: csvData,
      extension: 'csv',
      tableName: config.tableName,
    );

    return ExportResult(
      filePath: file.path,
      fileName: _getFileName(file.path),
      recordsCount: limitedData.length,
      fileSize: await file.length(),
      message: 'Datos exportados exitosamente a CSV',
    );
  }

  /// Serializes [data] to a JSON file using [config] and returns the result.
  Future<ExportResult> _exportToJson(
    List<Map<String, dynamic>> data,
    ExportConfig config,
  ) async {
    final filteredData = _filterColumns(data, config.columns);

    final limitedData = config.limit != null
        ? filteredData.take(config.limit!).toList()
        : filteredData;

    final jsonData = const JsonEncoder.withIndent('  ').convert(limitedData);

    final file = await _saveFile(
      content: jsonData,
      extension: 'json',
      tableName: config.tableName,
    );

    return ExportResult(
      filePath: file.path,
      fileName: _getFileName(file.path),
      recordsCount: limitedData.length,
      fileSize: await file.length(),
      message: 'Datos exportados exitosamente a JSON',
    );
  }

  /// Returns a copy of [data] with only the specified [columns] retained.
  ///
  /// Returns [data] unchanged if [columns] is null or empty.
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

  /// Converts [value] to an export-safe representation.
  ///
  /// `DateTime` values are formatted as `yyyy-MM-dd HH:mm:ss`.
  /// `bool` values become the strings `'true'` or `'false'`.
  /// `null` becomes an empty string.
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

  /// Writes [content] to a timestamped file with the given [extension] inside
  /// the `exports/` subdirectory of the application documents directory.
  Future<File> _saveFile({
    required String content,
    required String extension,
    String? tableName,
  }) async {
    final directory = await getApplicationDocumentsDirectory();

    final exportDir = Directory('${directory.path}/exports');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final prefix = tableName ?? 'all_tables';
    final fileName = '${prefix}_$timestamp.$extension';

    final file = File('${exportDir.path}/$fileName');
    await file.writeAsString(content);

    return file;
  }

  /// Returns the file name component of the given [path].
  String _getFileName(String path) {
    return path.split(Platform.pathSeparator).last;
  }

  /// Returns the absolute path to the `exports/` directory,
  /// creating it if it does not yet exist.
  Future<String> getExportsDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${directory.path}/exports');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    return exportDir.path;
  }

  /// Returns all files currently in the `exports/` directory.
  Future<List<FileSystemEntity>> listExportedFiles() async {
    final exportDir = await getExportsDirectory();
    final directory = Directory(exportDir);
    return directory.listSync();
  }

  /// Deletes the exported file at [filePath] if it exists.
  Future<void> deleteExportedFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Deletes all files in the `exports/` directory.
  Future<void> clearExports() async {
    final files = await listExportedFiles();
    for (final file in files) {
      await file.delete();
    }
  }
}
