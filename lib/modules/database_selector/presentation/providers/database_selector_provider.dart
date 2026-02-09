import 'package:flutter/foundation.dart';
import '../../data/models/database_info_model.dart';
import '../../data/repositories/database_repository.dart';
import 'package:file_picker/file_picker.dart';

class DatabaseSelectorProvider extends ChangeNotifier {
  final DatabaseRepository repository;

  DatabaseSelectorProvider({required this.repository});

  DatabaseInfoModel? _selectedDatabase;
  List<DatabaseInfoModel> _availableDatabases = [];
  final List<DatabaseInfoModel> _importedDatabases = [];
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
      final remoteDatabases = await repository.getAvailableDatabases(useMock: useMock);
      _availableDatabases = [..._importedDatabases, ...remoteDatabases];
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      if (_importedDatabases.isNotEmpty) {
        _availableDatabases = [..._importedDatabases];
        _errorMessage = null;
      } else {
        _errorMessage = e.toString();
      }
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
        type: 'SQL Server', // Tipo por defecto
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

  DatabaseInfoModel addImportedDatabase(PickedDatabaseFile file) {
    final importedDatabase = DatabaseInfoModel(
      id: _generateTemporaryId(),
      name: _deriveNameFromFile(file.name),
      description: 'Importada desde ${file.name}',
      type: file.detectedType,
      isImported: true,
      localPath: file.path,
    );

    _importedDatabases.insert(0, importedDatabase);
    _availableDatabases = [importedDatabase, ..._availableDatabases];
    _selectedDatabase = importedDatabase;
    notifyListeners();
    return importedDatabase;
  }

  Future<PickedDatabaseFile?> pickDatabaseFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['sql', 'db', 'csv', 'bak', 'sqlite', 'sqlite3', 'dump'],
      );

      if (result != null) {
        final selectedFile = result.files.single;
        final filePath = selectedFile.path ?? selectedFile.name;
        final detectedType = _detectDatabaseType(selectedFile.name);

        return PickedDatabaseFile(
          path: filePath,
          name: selectedFile.name,
          detectedType: detectedType,
        );
      } else {
        return null;
      }
    } catch (e) {
      _errorMessage = 'Error picking file: $e';
      notifyListeners();
      return null;
    }
  }

  String _detectDatabaseType(String fileName) {
    final normalizedName = fileName.toLowerCase();
    final extension = _extractExtension(normalizedName);

    if (normalizedName.contains('postgres') || normalizedName.contains('pgsql') || extension == 'dump') {
      return 'PostgreSQL';
    }

    if (normalizedName.contains('maria')) {
      return 'MariaDB';
    }

    if (normalizedName.contains('mysql')) {
      return 'MySQL';
    }

    if (normalizedName.contains('mssql') || normalizedName.contains('sqlserver') || extension == 'bak') {
      return 'SQL Server';
    }

    if (extension == 'db' || extension == 'sqlite' || extension == 'sqlite3') {
      return 'SQLite';
    }

    if (extension == 'csv') {
      return 'CSV (Datos tabulares)';
    }

    if (extension == 'sql') {
      return 'Script SQL';
    }

    return 'Tipo desconocido';
  }

  String _extractExtension(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == fileName.length - 1) {
      return '';
    }
    return fileName.substring(dotIndex + 1);
  }

  int _generateTemporaryId() => DateTime.now().millisecondsSinceEpoch * -1;

  String _deriveNameFromFile(String fileName) {
    final sanitized = fileName.split(RegExp(r'[\\/]')).last;
    final dotIndex = sanitized.lastIndexOf('.');
    if (dotIndex > 0) {
      return sanitized.substring(0, dotIndex);
    }
    return sanitized;
  }
}

class PickedDatabaseFile {
  final String path;
  final String name;
  final String detectedType;

  const PickedDatabaseFile({
    required this.path,
    required this.name,
    required this.detectedType,
  });
}
