/// Tipos de datos disponibles para los atributos de las tablas
enum FieldType {
  string('String', 'NVARCHAR'),
  integer('Integer', 'INT'),
  decimal('Decimal', 'DECIMAL'),
  boolean('Boolean', 'BIT'),
  date('Date', 'DATE'),
  datetime('DateTime', 'DATETIME'),
  text('Text', 'NVARCHAR(MAX)');

  final String displayName;
  final String sqlType;

  const FieldType(this.displayName, this.sqlType);

  /// Convierte el enum a string para JSON
  String toJson() => name;

  /// Convierte un string a FieldType
  static FieldType fromJson(String value) {
    return FieldType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => FieldType.string,
    );
  }

  /// Obtiene el tipo por su display name
  static FieldType? fromDisplayName(String displayName) {
    try {
      return FieldType.values.firstWhere(
        (type) => type.displayName == displayName,
      );
    } catch (e) {
      return null;
    }
  }
}
