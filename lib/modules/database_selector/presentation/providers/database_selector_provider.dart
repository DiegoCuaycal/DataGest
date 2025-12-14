import 'package:flutter/foundation.dart';
import '../../data/models/database_info_model.dart';
import '../../data/repositories/database_repository.dart';

class DatabaseSelectorProvider extends ChangeNotifier {
  final DatabaseRepository repository;

  DatabaseSelectorProvider({required this.repository});

  DatabaseInfoModel? _selectedDatabase;
  List<DatabaseInfoModel> _availableDatabases = [];
  bool _isLoading = false;
  String? _errorMessage;

  DatabaseInfoModel? get selectedDatabase => _selectedDatabase;
  List<DatabaseInfoModel> get availableDatabases => _availableDatabases;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get currentDatabaseName => _selectedDatabase?.name;

  Future<void> loadAvailableDatabases({bool useMock = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _availableDatabases = await repository.getAvailableDatabases(useMock: useMock);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectDatabase(DatabaseInfoModel database) {
    _selectedDatabase = database;
    notifyListeners();
  }

  void clearSelection() {
    _selectedDatabase = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
