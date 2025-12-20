/// Formatos de exportación disponibles
enum ExportFormat {
  csv('CSV', 'csv', 'Valores separados por comas'),
  json('JSON', 'json', 'JavaScript Object Notation');

  const ExportFormat(this.displayName, this.extension, this.description);

  final String displayName;
  final String extension;
  final String description;
}
