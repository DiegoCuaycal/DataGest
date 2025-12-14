import 'package:flutter/foundation.dart';
import '../../data/models/dropdown_item_model.dart';
import '../../data/repositories/dynamic_crud_repository.dart';

class DynamicCrudProvider extends ChangeNotifier {
  final DynamicCrudRepository repository;

  DynamicCrudProvider({required this.repository});

  List<Map<String, dynamic>> _records = [];
  Map<String, dynamic>? _currentRecord;
  bool _isLoading = false;
  String? _errorMessage;
  bool _useMock = false; // Use real API by default

  List<Map<String, dynamic>> get records => _records;
  Map<String, dynamic>? get currentRecord => _currentRecord;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setUseMock(bool value) {
    _useMock = value;
    notifyListeners();
  }

  Future<void> loadTableRecords({
    required String databaseName,
    required String tableName,
    required String token,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _records = await repository.getTableRecords(
        databaseName: databaseName,
        tableName: tableName,
        token: token,
        useMock: _useMock,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTableRecord({
    required String databaseName,
    required String tableName,
    required dynamic id,
    required String token,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentRecord = await repository.getTableRecord(
        databaseName: databaseName,
        tableName: tableName,
        id: id,
        token: token,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createRecord({
    required String databaseName,
    required String tableName,
    required Map<String, dynamic> data,
    required String token,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await repository.createTableRecord(
        databaseName: databaseName,
        tableName: tableName,
        data: data,
        token: token,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateRecord({
    required String databaseName,
    required String tableName,
    required dynamic id,
    required Map<String, dynamic> data,
    required String token,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await repository.updateTableRecord(
        databaseName: databaseName,
        tableName: tableName,
        id: id,
        data: data,
        token: token,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteRecord({
    required String databaseName,
    required String tableName,
    required dynamic id,
    required String token,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await repository.deleteTableRecord(
        databaseName: databaseName,
        tableName: tableName,
        id: id,
        token: token,
      );
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<List<DropdownItemModel>> getDropdownData({
    required String databaseName,
    required String tableName,
  }) async {
    try {
      return await repository.getDropdownData(
        databaseName: databaseName,
        tableName: tableName,
        token: 'mock_token',
        useMock: _useMock,
      );
    } catch (e) {
      throw Exception('Error loading dropdown data: $e');
    }
  }

  void clearRecords() {
    _records = [];
    _currentRecord = null;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
