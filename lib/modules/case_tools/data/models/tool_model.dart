import 'package:herramienta_case/modules/case_tools/domain/entities/tool_entity.dart';

/// Modelo de herramienta CASE (capa de datos)
class ToolModel extends ToolEntity {
  ToolModel({
    required super.id,
    required super.nombre,
    required super.descripcion,
    required super.categoria,
    super.url,
    super.fechaCreacion,
  });

  /// Crea una instancia desde JSON
  factory ToolModel.fromJson(Map<String, dynamic> json) {
    return ToolModel(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'] ?? '',
      categoria: json['categoria'] ?? '',
      url: json['url'],
      fechaCreacion: json['fechaCreacion'] != null
          ? DateTime.parse(json['fechaCreacion'])
          : null,
    );
  }

  /// Convierte la instancia a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'categoria': categoria,
      'url': url,
      'fechaCreacion': fechaCreacion?.toIso8601String(),
    };
  }

  /// Crea una copia con valores opcionales actualizados
  ToolModel copyWith({
    int? id,
    String? nombre,
    String? descripcion,
    String? categoria,
    String? url,
    DateTime? fechaCreacion,
  }) {
    return ToolModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      categoria: categoria ?? this.categoria,
      url: url ?? this.url,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }

  /// Convierte a entidad de dominio
  ToolEntity toEntity() {
    return ToolEntity(
      id: id,
      nombre: nombre,
      descripcion: descripcion,
      categoria: categoria,
      url: url,
      fechaCreacion: fechaCreacion,
    );
  }

  /// Crea desde una entidad de dominio
  factory ToolModel.fromEntity(ToolEntity entity) {
    return ToolModel(
      id: entity.id,
      nombre: entity.nombre,
      descripcion: entity.descripcion,
      categoria: entity.categoria,
      url: entity.url,
      fechaCreacion: entity.fechaCreacion,
    );
  }

  @override
  String toString() {
    return 'ToolModel(id: $id, nombre: $nombre, categoria: $categoria)';
  }
}
