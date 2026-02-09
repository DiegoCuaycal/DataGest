class DatabaseInfoModel {
  final int id;
  final String name;
  final String description;
  final String type; // Tipo de base de datos: "SQL Server", "PostgreSQL", "MariaDB", "MySQL"
  final bool isImported;
  final String? localPath;

  DatabaseInfoModel({
    required this.id,
    required this.name,
    required this.description,
    this.type = 'SQL Server', // Valor por defecto para compatibilidad
    this.isImported = false,
    this.localPath,
  });

  factory DatabaseInfoModel.fromJson(Map<String, dynamic> json) {
    return DatabaseInfoModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String,
      description: json['description'] as String? ?? 'Base de datos ${json['name']}',
      type: json['type'] as String? ?? 'SQL Server',
      isImported: json['isImported'] as bool? ?? false,
      localPath: json['localPath'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type,
      'isImported': isImported,
      'localPath': localPath,
    };
  }

  @override
  String toString() =>
      'DatabaseInfoModel(id: $id, name: $name, description: $description, type: $type, isImported: $isImported, localPath: $localPath)';
}
