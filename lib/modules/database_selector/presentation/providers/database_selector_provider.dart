import 'package:flutter/foundation.dart';
import '../../data/models/database_info_model.dart';
import '../../data/repositories/database_repository.dart';
import 'package:file_picker/file_picker.dart';

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

  /// Selecciona una base de datos por su nombre (usado para pre-configuración)
  void selectDatabaseByName(String databaseName) {
    final database = _availableDatabases.firstWhere(
      (db) => db.name.toLowerCase() == databaseName.toLowerCase(),
      orElse: () => DatabaseInfoModel(
        id: 0,
        name: databaseName,
        description: 'Base de datos $databaseName',
      ),
    );
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

  Future<String?> pickDatabaseFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['sql', 'db', 'csv'],
      );

      if (result != null) {
        return result.files.single.path;
      } else {
        return null;
      }
    } catch (e) {
      _errorMessage = 'Error picking file: $e';
      notifyListeners();
      return null;
    }
  }
}
