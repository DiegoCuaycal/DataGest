/// Modelo para estadísticas de la base de datos
class DatabaseStatsModel {
  final String databaseName;
  final int totalTables;
  final int totalColumns;
  final int totalForeignKeys;
  final int totalIndexes;
  final int totalViews;

  DatabaseStatsModel({
    required this.databaseName,
    required this.totalTables,
    required this.totalColumns,
    required this.totalForeignKeys,
    required this.totalIndexes,
    required this.totalViews,
  });

  factory DatabaseStatsModel.fromMetadata({
    required String databaseName,
    required int tablesCount,
    required int columnsCount,
    required int foreignKeysCount,
    required int indexesCount,
    required int viewsCount,
  }) {
    return DatabaseStatsModel(
      databaseName: databaseName,
      totalTables: tablesCount,
      totalColumns: columnsCount,
      totalForeignKeys: foreignKeysCount,
      totalIndexes: indexesCount,
      totalViews: viewsCount,
    );
  }

  @override
  String toString() => 'DatabaseStatsModel(database: $databaseName, tables: $totalTables)';
}
