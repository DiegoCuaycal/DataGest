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

  List<TableInfoModel> get tables => _metadata?.tables ?? [];
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
