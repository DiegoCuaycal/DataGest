import 'package:equatable/equatable.dart';
import 'package:herramienta_case/modules/export/domain/models/export_format.dart';

/// Configuración para la exportación de datos
class ExportConfig extends Equatable {
  /// Nombre de la tabla a exportar (null = todas las tablas)
  final String? tableName;

  /// Formato de exportación
  final ExportFormat format;

  /// Incluir cabeceras en la exportación
  final bool includeHeaders;

  /// Límite de registros a exportar (null = todos)
  final int? limit;

  /// Nombres de columnas específicas a exportar (null = todas)
  final List<String>? columns;

  const ExportConfig({
    this.tableName,
    required this.format,
    this.includeHeaders = true,
    this.limit,
    this.columns,
  });

  /// Constructor para exportar una tabla completa
  factory ExportConfig.table({
    required String tableName,
    required ExportFormat format,
    bool includeHeaders = true,
  }) {
    return ExportConfig(
      tableName: tableName,
      format: format,
      includeHeaders: includeHeaders,
    );
  }

  /// Constructor para exportar todas las tablas
  factory ExportConfig.allTables({
    required ExportFormat format,
    bool includeHeaders = true,
  }) {
    return ExportConfig(
      format: format,
      includeHeaders: includeHeaders,
    );
  }

  /// Copia con modificaciones
  ExportConfig copyWith({
    String? tableName,
    ExportFormat? format,
    bool? includeHeaders,
    int? limit,
    List<String>? columns,
  }) {
    return ExportConfig(
      tableName: tableName ?? this.tableName,
      format: format ?? this.format,
      includeHeaders: includeHeaders ?? this.includeHeaders,
      limit: limit ?? this.limit,
      columns: columns ?? this.columns,
    );
  }

  @override
  List<Object?> get props => [tableName, format, includeHeaders, limit, columns];
}
