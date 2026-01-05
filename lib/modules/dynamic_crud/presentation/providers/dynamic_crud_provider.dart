import 'package:flutter/foundation.dart';
import '../../data/models/dropdown_item_model.dart';
import '../../data/repositories/dynamic_crud_repository.dart';

class DynamicCrudProvider extends ChangeNotifier {
  final DynamicCrudRepository repository;

  DynamicCrudProvider({required this.repository});

  List<Map<String, dynamic>> _records = [];
  Map<String, dynamic>? _currentRecord;
  bool _isLoading = false;
  bool _isLoadingMore = false; // Para infinite scroll
  String? _errorMessage;
  bool _useMock = false; // Use real API by default

  // Pagination state
  int _currentPage = 1;
  int _pageSize = 20; // Cambiado a 20 para infinite scroll
  int _totalRecords = 0;
  int _totalPages = 0;
  bool _hasMoreData = true; // Para saber si hay más datos

  // Search state
  String _searchTerm = '';

  List<Map<String, dynamic>> get records => _records;
  Map<String, dynamic>? get currentRecord => _currentRecord;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;

  // Pagination getters
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  int get totalRecords => _totalRecords;
  int get totalPages => _totalPages;
  bool get hasMoreData => _hasMoreData;

  // Search getter
  String get searchTerm => _searchTerm;

  void setUseMock(bool value) {
    _useMock = value;
    notifyListeners();
  }

  /// Set the page size and reload data
  void setPageSize(int newPageSize) {
    _pageSize = newPageSize;
    _currentPage = 1; // Reset to first page when changing page size
    notifyListeners();
  }

  /// Set the current page
  void setPage(int page) {
    if (page >= 1 && page <= _totalPages) {
      _currentPage = page;
      notifyListeners();
    }
  }

  /// Set search term
  void setSearchTerm(String term) {
    _searchTerm = term;
    _currentPage = 1; // Reset to first page when searching
    notifyListeners();
  }

  /// Clear search
  void clearSearch() {
    _searchTerm = '';
    _currentPage = 1;
    notifyListeners();
  }

  /// Calculate total pages based on total records and page size
  void _updatePagination(int total) {
    _totalRecords = total;
    _totalPages = (_totalRecords / _pageSize).ceil();
    if (_totalPages == 0) _totalPages = 1;

    // Actualizar hasMoreData
    _hasMoreData = _currentPage < _totalPages;
  }

  /// Reset pagination state (call before fresh load)
  void resetPagination() {
    _currentPage = 1;
    _records = [];
    _hasMoreData = true;
    _totalRecords = 0;
    _totalPages = 0;
  }

  Future<void> loadTableRecords({
    required String databaseName,
    required String tableName,
    required String token,
    int? page,
    int? pageSize,
    String? searchTerm,
    bool resetData = true, // Por defecto resetea los datos
  }) async {
    _isLoading = true;
    _errorMessage = null;

    if (resetData) {
      resetPagination();
    }

    notifyListeners();

    // Update pagination parameters if provided
    if (page != null) _currentPage = page;
    if (pageSize != null) _pageSize = pageSize;
    if (searchTerm != null) _searchTerm = searchTerm;

    try {
      final result = await repository.getTableRecordsPaginated(
        databaseName: databaseName,
        tableName: tableName,
        token: token,
        page: _currentPage,
        pageSize: _pageSize,
        searchTerm: _searchTerm.isEmpty ? null : _searchTerm,
        useMock: _useMock,
      );

      if (resetData) {
        _records = result['records'] as List<Map<String, dynamic>>;
      } else {
        // Append para infinite scroll
        _records.addAll(result['records'] as List<Map<String, dynamic>>);
      }

      _updatePagination(result['totalRecords'] as int);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e.toString());
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cargar más registros (infinite scroll)
  Future<void> loadMoreRecords({
    required String databaseName,
    required String tableName,
    required String token,
  }) async {
    // No cargar si ya estamos cargando o no hay más datos
    if (_isLoadingMore || !_hasMoreData || _isLoading) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      // Incrementar página
      _currentPage++;

      final result = await repository.getTableRecordsPaginated(
        databaseName: databaseName,
        tableName: tableName,
        token: token,
        page: _currentPage,
        pageSize: _pageSize,
        searchTerm: _searchTerm.isEmpty ? null : _searchTerm,
        useMock: _useMock,
      );

      // Agregar nuevos registros al final
      final newRecords = result['records'] as List<Map<String, dynamic>>;
      _records.addAll(newRecords);

      _updatePagination(result['totalRecords'] as int);

      _isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e.toString());
      _isLoadingMore = false;
      _currentPage--; // Revertir el incremento en caso de error
      notifyListeners();
    }
  }

  /// Load all records without pagination (for backwards compatibility)
  Future<void> loadAllTableRecords({
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
      _updatePagination(_records.length);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e.toString());
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
      print('📝 Registro cargado para editar ($tableName #$id):');
      print('   Keys: ${_currentRecord?.keys.toList()}');
      print('   Data: $_currentRecord');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e.toString());
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
      _errorMessage = _cleanErrorMessage(e.toString());
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
      _errorMessage = _cleanErrorMessage(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Limpia mensajes de error técnicos para mostrar solo información útil al usuario
  String _cleanErrorMessage(String errorMessage) {
    // Remover prefijos técnicos como "Exception:", "Repository error:", etc.
    String cleaned = errorMessage
        .replaceAll('Exception: Repository error: Exception: ', '')
        .replaceAll('Exception: Error deleting record: Exception: ', '')
        .replaceAll('Exception: ', '')
        .replaceAll('Repository error: ', '')
        .replaceAll('Error deleting record: ', '')
        .replaceAll('Error del servidor: ', '')
        .trim();

    return cleaned;
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
      // Limpiar mensaje de error antes de mostrarlo al usuario
      _errorMessage = _cleanErrorMessage(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<List<DropdownItemModel>> getDropdownData({
    required String databaseName,
    required String tableName,
    required String token,
    List<String>? displayColumns,
  }) async {
    try {
      return await repository.getDropdownData(
        databaseName: databaseName,
        tableName: tableName,
        token: token,
        displayColumns: displayColumns,
        useMock: _useMock,
      );
    } catch (e) {
      throw Exception(_cleanErrorMessage(e.toString()));
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
