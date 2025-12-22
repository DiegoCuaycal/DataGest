import 'package:flutter/foundation.dart';
import '../../domain/models/database_schema.dart';
import '../../domain/models/table_entity.dart';
import '../../domain/models/attribute_field.dart';
import '../../data/repositories/database_creator_repository.dart';

/// Provider para manejar el estado de creación de bases de datos
class DatabaseCreatorProvider extends ChangeNotifier {
  final DatabaseCreatorRepository repository;

  DatabaseCreatorProvider({required this.repository});

  DatabaseSchema _schema = DatabaseSchema(name: '');
  bool _isSubmitting = false;
  String? _errorMessage;

  DatabaseSchema get schema => _schema;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  /// Actualiza el nombre de la base de datos
  void updateDatabaseName(String name) {
    _schema = _schema.copyWith(name: name);
    notifyListeners();
  }

  /// Actualiza la descripción de la base de datos
  void updateDatabaseDescription(String description) {
    _schema = _schema.copyWith(description: description);
    notifyListeners();
  }

  /// Agrega una nueva tabla al esquema
  void addTable(TableEntity table) {
    _schema = _schema.addTable(table);
    notifyListeners();
  }

  /// Actualiza una tabla existente
  void updateTable(String tableId, TableEntity updatedTable) {
    _schema = _schema.updateTable(tableId, updatedTable);
    notifyListeners();
  }

  /// Elimina una tabla del esquema
  void removeTable(String tableId) {
    _schema = _schema.removeTable(tableId);
    notifyListeners();
  }

  /// Agrega un atributo a una tabla específica
  void addAttributeToTable(String tableId, AttributeField attribute) {
    final table = _schema.tables.firstWhere((t) => t.id == tableId);
    final updatedTable = table.addAttribute(attribute);
    _schema = _schema.updateTable(tableId, updatedTable);
    notifyListeners();
  }

  /// Actualiza un atributo de una tabla específica
  void updateAttributeInTable(
    String tableId,
    String attributeId,
    AttributeField updatedAttribute,
  ) {
    final table = _schema.tables.firstWhere((t) => t.id == tableId);
    final updatedTable = table.updateAttribute(attributeId, updatedAttribute);
    _schema = _schema.updateTable(tableId, updatedTable);
    notifyListeners();
  }

  /// Elimina un atributo de una tabla específica
  void removeAttributeFromTable(String tableId, String attributeId) {
    final table = _schema.tables.firstWhere((t) => t.id == tableId);
    final updatedTable = table.removeAttribute(attributeId);
    _schema = _schema.updateTable(tableId, updatedTable);
    notifyListeners();
  }

  /// Obtiene el número total de atributos en todas las tablas
  int getTotalAttributes() {
    return _schema.tables.fold(
      0,
      (sum, table) => sum + table.attributes.length,
    );
  }

  /// Reinicia el esquema a su estado inicial
  void resetSchema() {
    _schema = DatabaseSchema(name: '');
    _errorMessage = null;
    notifyListeners();
  }

  /// Envía el esquema al backend
  Future<void> submitSchema(DatabaseSchema schema) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await repository.createDatabase(schema);
      _isSubmitting = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Limpia el mensaje de error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
