import 'package:equatable/equatable.dart';

/// Resultado de una exportación
class ExportResult extends Equatable {
  /// Ruta del archivo exportado
  final String filePath;

  /// Nombre del archivo
  final String fileName;

  /// Número de registros exportados
  final int recordsCount;

  /// Tamaño del archivo en bytes
  final int fileSize;

  /// Mensaje de éxito
  final String message;

  const ExportResult({
    required this.filePath,
    required this.fileName,
    required this.recordsCount,
    required this.fileSize,
    required this.message,
  });

  @override
  List<Object?> get props => [filePath, fileName, recordsCount, fileSize, message];
}
