import 'package:flutter/foundation.dart';
import 'package:herramienta_case/modules/dynamic_crud/data/models/table_info_model.dart';
// 1. IMPORTANTE: Importar el modelo de metadata
import 'package:herramienta_case/modules/dynamic_crud/data/models/database_metadata_model.dart'; 
import 'package:herramienta_case/modules/export/data/repositories/export_repository.dart';
import 'package:herramienta_case/modules/export/domain/models/export_config.dart';
import 'package:herramienta_case/modules/export/domain/models/export_result.dart';

/// Provider para gestionar el estado de la exportación de datos
class ExportProvider extends ChangeNotifier {
  final ExportRepository repository;

  ExportProvider({required this.repository});

  // Estado de carga
  bool _isExporting = false;
  bool get isExporting => _isExporting;

  // Progreso de exportación (0.0 - 1.0)
  double _progress = 0.0;
  double get progress => _progress;

  // Mensaje de estado
  String? _statusMessage;
  String? get statusMessage => _statusMessage;

  // Último resultado de exportación
  ExportResult? _lastResult;
  ExportResult? get lastResult => _lastResult;

  // Últimos resultados de exportación múltiple
  List<ExportResult>? _lastResults;
  List<ExportResult>? get lastResults => _lastResults;

  // Mensaje de error
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Exporta datos de una tabla específica
  Future<ExportResult?> exportTable({
    required DatabaseMetadataModel metadata, // <--- 2. NUEVO REQUISITO
    required String databaseName,
    required String tableName,
    required ExportConfig config,
    required String token,
  }) async {
    try {
      _setLoading(true, 'Exportando tabla $tableName...');
      _clearError();

      final result = await repository.exportTable(
        metadata: metadata, // <--- 3. PASAMOS METADATA AL REPO
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

  /// Exporta datos de múltiples tablas
  Future<List<ExportResult>?> exportMultipleTables({
    required DatabaseMetadataModel metadata, // <--- 2. NUEVO REQUISITO
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

      // Usar el método del repositorio que maneja todo el proceso
      final results = await repository.exportMultipleTables(
        metadata: metadata, // <--- 3. PASAMOS METADATA AL REPO
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

  /// Exporta todas las tablas de la base de datos
  Future<List<ExportResult>?> exportAllTables({
    required DatabaseMetadataModel metadata, // <--- 2. NUEVO REQUISITO
    required String databaseName,
    required List<TableInfoModel> allTables,
    required ExportConfig config,
    required String token,
  }) async {
    return await exportMultipleTables(
      metadata: metadata, // <--- 3. PASAMOS METADATA
      databaseName: databaseName,
      tables: allTables,
      baseConfig: config,
      token: token,
    );
  }

  /// Obtiene el directorio de exportaciones
  Future<String> getExportsDirectory() async {
    return await repository.getExportsDirectory();
  }

  /// Limpia el estado
  void clearState() {
    _lastResult = null;
    _lastResults = null;
    _errorMessage = null;
    _statusMessage = null;
    _progress = 0.0;
    notifyListeners();
  }

  /// Establece el estado de carga
  void _setLoading(bool loading, [String? message]) {
    _isExporting = loading;
    _statusMessage = message;
    if (!loading) {
      _progress = 0.0;
    }
    notifyListeners();
  }

  /// Establece un error
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Limpia el error
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
