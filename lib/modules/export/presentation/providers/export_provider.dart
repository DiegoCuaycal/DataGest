import 'package:flutter/foundation.dart';
import 'package:herramienta_case/modules/dynamic_crud/data/models/table_info_model.dart';
// 1. IMPORTAR EL MODELO DE METADATA
import 'package:herramienta_case/modules/dynamic_crud/data/models/database_metadata_model.dart'; 
import 'package:herramienta_case/modules/export/data/repositories/export_repository.dart';
import 'package:herramienta_case/modules/export/domain/models/export_config.dart';
import 'package:herramienta_case/modules/export/domain/models/export_result.dart';

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

  // --- MÉTODO 1: EXPORTAR UNA TABLA ---
  Future<ExportResult?> exportTable({
    required DatabaseMetadataModel metadata, // <--- NUEVO REQUERIDO
    required String databaseName,
    required String tableName,
    required ExportConfig config,
    required String token,
  }) async {
    try {
      _setLoading(true, 'Exportando tabla $tableName...');
      _clearError();

      final result = await repository.exportTable(
        metadata: metadata, // <--- PASAR METADATA
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

  // --- MÉTODO 2: EXPORTAR MÚLTIPLES TABLAS ---
  Future<List<ExportResult>?> exportMultipleTables({
    required DatabaseMetadataModel metadata, // <--- NUEVO REQUERIDO
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
        metadata: metadata, // <--- PASAR METADATA
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

  // --- MÉTODO 3: EXPORTAR TODO ---
  Future<List<ExportResult>?> exportAllTables({
    required DatabaseMetadataModel metadata, // <--- NUEVO REQUERIDO
    required String databaseName,
    required List<TableInfoModel> allTables,
    required ExportConfig config,
    required String token,
  }) async {
    return await exportMultipleTables(
      metadata: metadata, // <--- PASAR METADATA
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