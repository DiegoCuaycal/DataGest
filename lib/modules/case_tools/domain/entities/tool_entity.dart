/// Entidad de herramienta CASE (capa de dominio)
class ToolEntity {
  final int id;
  final String nombre;
  final String descripcion;
  final String categoria;
  final String? url;
  final DateTime? fechaCreacion;

  ToolEntity({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.categoria,
    this.url,
    this.fechaCreacion,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ToolEntity &&
        other.id == id &&
        other.nombre == nombre &&
        other.descripcion == descripcion &&
        other.categoria == categoria &&
        other.url == url &&
        other.fechaCreacion == fechaCreacion;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        nombre.hashCode ^
        descripcion.hashCode ^
        categoria.hashCode ^
        url.hashCode ^
        fechaCreacion.hashCode;
  }

  @override
  String toString() {
    return 'ToolEntity(id: $id, nombre: $nombre, categoria: $categoria)';
  }
}
