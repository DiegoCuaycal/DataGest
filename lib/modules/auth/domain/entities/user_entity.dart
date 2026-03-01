class UserEntity {
  final int? id;
  final String? username;
  final String? email;
  final String? nombre;
  final String? role;
  final int? roleId;
  final String token;
  final String? moduloOrigen;

  UserEntity({
    this.id,
    this.username,
    this.email,
    this.nombre,
    this.role,
    this.roleId,
    required this.token,
    this.moduloOrigen,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserEntity &&
        other.id == id &&
        other.username == username &&
        other.email == email &&
        other.nombre == nombre &&
        other.role == role &&
        other.roleId == roleId &&
        other.token == token &&
        other.moduloOrigen == moduloOrigen;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        username.hashCode ^
        email.hashCode ^
        nombre.hashCode ^
        role.hashCode ^
        roleId.hashCode ^
        token.hashCode ^
        moduloOrigen.hashCode;
  }
}
