import 'package:flutter/foundation.dart';
import '../../data/models/dropdown_item_model.dart';
import '../../data/models/database_metadata_model.dart';
import '../../data/repositories/dynamic_crud_repository.dart';

/// State manager for dynamic CRUD operations on a database table.
///
/// Maintains paginated record lists, search state, loading flags, and error
/// messages. Supports both page-based navigation and infinite scroll via
/// [loadMoreRecords].
class DynamicCrudProvider extends ChangeNotifier {
  final DynamicCrudRepository repository;

  DynamicCrudProvider({required this.repository});

  List<Map<String, dynamic>> _records = [];
  Map<String, dynamic>? _currentRecord;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  bool _useMock = false;

  // Pagination state
  int _currentPage = 1;
  int _pageSize = 20;
  int _totalRecords = 0;
  int _totalPages = 0;
  bool _hasMoreData = true;

  // Search state
  String _searchTerm = '';

  List<Map<String, dynamic>> get records => _records;
  Map<String, dynamic>? get currentRecord => _currentRecord;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;

  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  int get totalRecords => _totalRecords;
  int get totalPages => _totalPages;
  bool get hasMoreData => _hasMoreData;

  String get searchTerm => _searchTerm;

  void setUseMock(bool value) {
    _useMock = value;
    notifyListeners();
  }

  /// Updates the page size and resets to the first page.
  void setPageSize(int newPageSize) {
    _pageSize = newPageSize;
    _currentPage = 1;
    notifyListeners();
  }

  /// Navigates to a specific [page] if it is within the valid range.
  void setPage(int page) {
    if (page >= 1 && page <= _totalPages) {
      _currentPage = page;
      notifyListeners();
    }
  }

  /// Updates the active search term and resets to the first page.
  void setSearchTerm(String term) {
    _searchTerm = term;
    _currentPage = 1;
    notifyListeners();
  }

  /// Clears the active search term and resets to the first page.
  void clearSearch() {
    _searchTerm = '';
    _currentPage = 1;
    notifyListeners();
  }

  void _updatePagination(int total) {
    _totalRecords = total;
    _totalPages = (_totalRecords / _pageSize).ceil();
    if (_totalPages == 0) _totalPages = 1;
    _hasMoreData = _currentPage < _totalPages;
  }

  /// Resets pagination state before a fresh data load.
  void resetPagination() {
    _currentPage = 1;
    _records = [];
    _hasMoreData = true;
    _totalRecords = 0;
    _totalPages = 0;
  }

  /// Loads a paginated page of records for [tableName].
  ///
  /// When [resetData] is `true` (default), existing records are replaced.
  /// When `false`, new records are appended for infinite scroll.
  Future<void> loadTableRecords({
    required DatabaseMetadataModel metadata,
    required String databaseName,
    required String tableName,
    required String token,
    int? page,
    int? pageSize,
    String? searchTerm,
    bool resetData = true,
  }) async {
    _isLoading = true;
    _errorMessage = null;

    if (resetData) {
      resetPagination();
    }

    notifyListeners();

    if (page != null) _currentPage = page;
    if (pageSize != null) _pageSize = pageSize;
    if (searchTerm != null) _searchTerm = searchTerm;

    try {
      final result = await repository.getTableRecordsPaginated(
        metadata: metadata,
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

  /// Appends the next page of records for infinite scroll.
  ///
  /// Does nothing if a load is already in progress or there are no more pages.
  Future<void> loadMoreRecords({
    required DatabaseMetadataModel metadata,
    required String databaseName,
    required String tableName,
    required String token,
  }) async {
    if (_isLoadingMore || !_hasMoreData || _isLoading) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      _currentPage++;

      final result = await repository.getTableRecordsPaginated(
        metadata: metadata,
        databaseName: databaseName,
        tableName: tableName,
        token: token,
        page: _currentPage,
        pageSize: _pageSize,
        searchTerm: _searchTerm.isEmpty ? null : _searchTerm,
        useMock: _useMock,
      );

      final newRecords = result['records'] as List<Map<String, dynamic>>;
      _records.addAll(newRecords);

      _updatePagination(result['totalRecords'] as int);

      _isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e.toString());
      _isLoadingMore = false;
      _currentPage--;
      notifyListeners();
    }
  }

  /// Loads all records for [tableName] without pagination.
  Future<void> loadAllTableRecords({
    required DatabaseMetadataModel metadata,
    required String databaseName,
    required String tableName,
    required String token,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _records = await repository.getTableRecords(
        metadata: metadata,
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

  /// Fetches a single record by [id] and stores it in [currentRecord].
  Future<void> loadTableRecord({
    required DatabaseMetadataModel metadata,
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
        metadata: metadata,
        databaseName: databaseName,
        tableName: tableName,
        id: id,
        token: token,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e.toString());
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Creates a new record in [tableName]. Returns `true` on success.
  Future<bool> createRecord({
    required DatabaseMetadataModel metadata,
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
        metadata: metadata,
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

  /// Updates the record identified by [id] in [tableName]. Returns `true` on success.
  Future<bool> updateRecord({
    required DatabaseMetadataModel metadata,
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
        metadata: metadata,
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

  /// Deletes the record identified by [id] from [tableName]. Returns `true` on success.
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
        metadata: DatabaseMetadataModel(
          databaseName: databaseName,
          tables: [],
          columns: [],
          pkInfo: [],
          fkInfo: [],
          indexes: [],
          views: [],
        ),
      );
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Returns the dropdown items for a foreign key field pointing to [tableName].
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

  /// Clears the current record list and resets state.
  void clearRecords() {
    _records = [];
    _currentRecord = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Clears the current error message.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _cleanErrorMessage(String errorMessage) {
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
}
