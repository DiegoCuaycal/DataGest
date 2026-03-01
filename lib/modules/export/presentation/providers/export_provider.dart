import 'package:flutter/foundation.dart';
import 'package:herramienta_case/modules/dynamic_crud/data/models/table_info_model.dart';
import 'package:herramienta_case/modules/dynamic_crud/data/models/database_metadata_model.dart';
import 'package:herramienta_case/modules/export/data/repositories/export_repository.dart';
import 'package:herramienta_case/modules/export/domain/models/export_config.dart';
import 'package:herramienta_case/modules/export/domain/models/export_result.dart';

/// ChangeNotifier that manages the state of the export feature.
///
/// Delegates to [ExportRepository] for all I/O operations and exposes
/// progress, status, and error information to the presentation layer.
class ExportProvider extends ChangeNotifier {
  final ExportRepository repository;

  ExportProvider({required this.repository});

  bool _isExporting = false;
  bool get isExporting => _isExporting;

  double _progress = 0.0;
  double get progress => _progress;

  String? _statusMessage;
  String? get statusMessage => _statusMessage;

  ExportResult? _lastResult;
  ExportResult? get lastResult => _lastResult;

  List<ExportResult>? _lastResults;
  List<ExportResult>? get lastResults => _lastResults;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Exports a single [tableName] using [config] and returns the result,
  /// or `null` on failure.
  Future<ExportResult?> exportTable({
    required DatabaseMetadataModel metadata,
    required String databaseName,
    required String tableName,
    required ExportConfig config,
    required String token,
  }) async {
    try {
      _setLoading(true, 'Exportando tabla $tableName...');
      _clearError();

      final result = await repository.exportTable(
        metadata: metadata,
        databaseName: databaseName,
        tableName: tableName,
        config: config,
        token: token,
      );

      _lastResult = result;
      _setLoading(false, 'Exportación completada');
      return result;
    } catch (e) {
      _setError('Error al exportar la tabla: $e');
      _setLoading(false);
      return null;
    }
  }

  /// Exports each table in [tables] and returns all successful results,
  /// or `null` if the entire operation fails.
  Future<List<ExportResult>?> exportMultipleTables({
    required DatabaseMetadataModel metadata,
    required String databaseName,
    required List<TableInfoModel> tables,
    required ExportConfig baseConfig,
    required String token,
    bool useMockData = false,
  }) async {
    try {
      _setLoading(true, 'Exportando ${tables.length} tablas...');
      _clearError();
      _progress = 0.0;

      final results = await repository.exportMultipleTables(
        metadata: metadata,
        databaseName: databaseName,
        tables: tables,
        baseConfig: baseConfig,
        token: token,
        useMockData: useMockData,
      );

      _lastResults = results;
      _setLoading(false, 'Exportación completada: ${results.length} tablas');
      return results;
    } catch (e) {
      _setError('Error al exportar tablas: $e');
      _setLoading(false);
      return null;
    }
  }

  /// Exports every table in [allTables].
  ///
  /// Delegates to [exportMultipleTables].
  Future<List<ExportResult>?> exportAllTables({
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
    return await repository.getExportsDirectory();
  }

  void clearState() {
    _lastResult = null;
    _lastResults = null;
    _errorMessage = null;
    _statusMessage = null;
    _progress = 0.0;
    notifyListeners();
  }

  void _setLoading(bool loading, [String? message]) {
    _isExporting = loading;
    _statusMessage = message;
    if (!loading) {
      _progress = 0.0;
    }
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
