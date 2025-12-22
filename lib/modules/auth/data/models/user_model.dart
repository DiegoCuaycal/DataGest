import 'package:herramienta_case/modules/auth/domain/entities/user_entity.dart';

/// Modelo de usuario (capa de datos)
class UserModel extends UserEntity {
  UserModel({
    super.id,
    super.username,
    super.email,
    super.nombre,
    super.role,
    super.roleId,
    required super.token,
  });

  /// Crea una instancia desde JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      username: json['username'] ?? json['usuario'],
      email: json['email'] ?? json['usuario'] ?? 'admin',
      nombre: json['nombre'] ?? json['name'] ?? 'Administrador',
      role: json['role'] ?? json['rol'],
      roleId: json['roleId'] ?? json['rol_id'],
      token: json['token'] as String,
    );
  }

  /// Convierte la instancia a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'nombre': nombre,
      'role': role,
      'roleId': roleId,
      'token': token,
    };
  }

  /// Crea una copia con valores opcionales actualizados
  UserModel copyWith({
    int? id,
    String? username,
    String? email,
    String? nombre,
    String? role,
    int? roleId,
    String? token,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      nombre: nombre ?? this.nombre,
      role: role ?? this.role,
      roleId: roleId ?? this.roleId,
      token: token ?? this.token,
    );
  }

  /// Convierte a entidad de dominio
  UserEntity toEntity() {
    return UserEntity(
      id: id,
      username: username,
      email: email,
      nombre: nombre,
      role: role,
      roleId: roleId,
      token: token,
    );
  }

  /// Crea desde una entidad de dominio
  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      username: entity.username,
      email: entity.email,
      nombre: entity.nombre,
      role: entity.role,
      roleId: entity.roleId,
      token: entity.token,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, nombre: $nombre)';
  }
}
