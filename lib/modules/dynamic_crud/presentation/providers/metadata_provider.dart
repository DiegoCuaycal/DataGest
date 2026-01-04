import 'package:flutter/foundation.dart';
import '../../data/models/database_metadata_model.dart';
import '../../data/models/table_info_model.dart';
import '../../data/models/column_info_model.dart';
import '../../data/models/foreign_key_model.dart';
import '../../data/repositories/dynamic_crud_repository.dart';

class MetadataProvider extends ChangeNotifier {
  final DynamicCrudRepository repository;

  MetadataProvider({required this.repository});

  DatabaseMetadataModel? _metadata;
  bool _isLoading = false;
  String? _errorMessage;

  DatabaseMetadataModel? get metadata => _metadata;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Tablas con CRUD habilitado por base de datos
  static const Map<String, List<String>> _allowedTables = {
    'Estudiantes': ['cursos', 'estudiantes', 'inscripciones', 'profesores', 'usuarios'],
    'Medicos': ['pacientes', 'medicos', 'citas', 'diagnosticos'],
    'Salud': ['pacientes', 'medicos', 'citas', 'diagnosticos'],
    'Productos': ['productos', 'categorias', 'proveedores', 'inventario'],
  };

  List<TableInfoModel> get tables {
    if (_metadata == null) return [];

    final dbName = _metadata!.databaseName;
    final allowed = _allowedTables[dbName];

    // Si no hay configuración específica, mostrar todas las tablas
    if (allowed == null) return _metadata!.tables;

    // Filtrar solo las tablas permitidas
    return _metadata!.tables.where((table) {
      return allowed.contains(table.table.toLowerCase());
    }).toList();
  }

  String? get databaseName => _metadata?.databaseName;

  Future<void> loadMetadata({
    required String databaseName,
    required String token,
    bool useMock = false,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _metadata = await repository.getMetadata(
        databaseName: databaseName,
        token: token,
        useMock: useMock,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  List<ColumnInfoModel> getColumnsForTable(String tableName) {
    return _metadata?.getColumnsForTable(tableName) ?? [];
  }

  List<ForeignKeyModel> getForeignKeysForTable(String tableName) {
    return _metadata?.getForeignKeysForTable(tableName) ?? [];
  }

  ForeignKeyModel? getForeignKeyForColumn(String tableName, String columnName) {
    return _metadata?.getForeignKeyForColumn(tableName, columnName);
  }

  bool isPrimaryKey(String tableName, String columnName) {
    return _metadata?.isPrimaryKey(tableName, columnName) ?? false;
  }

  void clearMetadata() {
    _metadata = null;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
