import 'table_info_model.dart';
import 'column_info_model.dart';
import 'primary_key_model.dart';
import 'foreign_key_model.dart';
import '../../../../core/network/foreign_key_config.dart';

class DatabaseMetadataModel {
  final String databaseName;
  final List<TableInfoModel> tables;
  final List<ColumnInfoModel> columns;
  final List<PrimaryKeyModel> pkInfo;
  final List<ForeignKeyModel> fkInfo;
  final List<dynamic> indexes;
  final List<dynamic> views;

  DatabaseMetadataModel({
    required this.databaseName,
    required this.tables,
    required this.columns,
    required this.pkInfo,
    required this.fkInfo,
    required this.indexes,
    required this.views,
  });

  factory DatabaseMetadataModel.fromJson(Map<String, dynamic> json) {
    return DatabaseMetadataModel(
      databaseName: json['database_name'] as String,
      tables: (json['tables'] as List<dynamic>)
          .map((e) => TableInfoModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      columns: (json['columns'] as List<dynamic>)
          .map((e) => ColumnInfoModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      pkInfo: (json['pk_info'] as List<dynamic>)
          .map((e) => PrimaryKeyModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      fkInfo: (json['fk_info'] as List<dynamic>)
          .map((e) => ForeignKeyModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      indexes: json['indexes'] as List<dynamic>,
      views: json['views'] as List<dynamic>,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'database_name': databaseName,
      'tables': tables.map((e) => e.toJson()).toList(),
      'columns': columns.map((e) => e.toJson()).toList(),
      'pk_info': pkInfo.map((e) => e.toJson()).toList(),
      'fk_info': fkInfo.map((e) => e.toJson()).toList(),
      'indexes': indexes,
      'views': views,
    };
  }

  List<ColumnInfoModel> getColumnsForTable(String tableName) {
    return columns.where((col) => col.table == tableName).toList()
      ..sort((a, b) => a.ordinalPosition.compareTo(b.ordinalPosition));
  }

  List<ForeignKeyModel> getForeignKeysForTable(String tableName) {
    return fkInfo.where((fk) => fk.table == tableName).toList();
  }

  ForeignKeyModel? getForeignKeyForColumn(String tableName, String columnName) {
    // 1. Primero intentar buscar en fkInfo (si el backend devuelve FKs)
    try {
      final fk = fkInfo.firstWhere(
        (fk) => fk.table == tableName && fk.column == columnName,
      );
      return fk;
    } catch (e) {
      // No se encontró en fkInfo, continuar con detección automática
    }

    // 2. Si no está en fkInfo, usar detección automática basada en convenciones
    if (ForeignKeyConfig.isForeignKey(tableName, columnName)) {
      final reference = ForeignKeyConfig.getForeignKeyReference(
        tableName: tableName,
        columnName: columnName,
      );

      if (reference != null) {
        // Crear un ForeignKeyModel virtual basado en la convención
        return ForeignKeyModel(
          schema: 'dbo', // Schema por defecto
          table: tableName,
          column: columnName,
          foreignKeyName: 'FK_${tableName}_$columnName', // Nombre sintético
          referenceSchema: 'dbo',
          referenceTable: reference['referenceTable'] as String,
          referenceColumn: reference['referenceColumn'] as String,
        );
      }
    }

    return null;
  }

  List<PrimaryKeyModel> getPrimaryKeysForTable(String tableName) {
    return pkInfo.where((pk) => pk.table == tableName).toList();
  }

  bool isPrimaryKey(String tableName, String columnName) {
    return pkInfo.any((pk) => pk.table == tableName && pk.column == columnName);
  }

  @override
  String toString() => 'DatabaseMetadataModel(databaseName: $databaseName, tables: ${tables.length}, columns: ${columns.length})';
}
