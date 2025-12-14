/// Entidad de usuario (capa de dominio)
class UserEntity {
  final int? id;
  final String? email;
  final String? nombre;
  final String token;

  UserEntity({
    this.id,
    this.email,
    this.nombre,
    required this.token,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserEntity &&
        other.id == id &&
        other.email == email &&
        other.nombre == nombre &&
        other.token == token;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        email.hashCode ^
        nombre.hashCode ^
        token.hashCode;
  }

  @override
  String toString() {
    return 'UserEntity(id: $id, email: $email, nombre: $nombre)';
  }
}
