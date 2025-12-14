import 'package:herramienta_case/modules/auth/domain/entities/user_entity.dart';

/// Modelo de usuario (capa de datos)
class UserModel extends UserEntity {
  UserModel({
    super.id,
    super.email,
    super.nombre,
    required super.token,
  });

  /// Crea una instancia desde JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'] ?? json['usuario'] ?? 'admin',
      nombre: json['nombre'] ?? json['name'] ?? 'Administrador',
      token: json['token'] as String,
    );
  }

  /// Convierte la instancia a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nombre': nombre,
      'token': token,
    };
  }

  /// Crea una copia con valores opcionales actualizados
  UserModel copyWith({
    int? id,
    String? email,
    String? nombre,
    String? token,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      nombre: nombre ?? this.nombre,
      token: token ?? this.token,
    );
  }

  /// Convierte a entidad de dominio
  UserEntity toEntity() {
    return UserEntity(
      id: id,
      email: email,
      nombre: nombre,
      token: token,
    );
  }

  /// Crea desde una entidad de dominio
  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      nombre: entity.nombre,
      token: entity.token,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, nombre: $nombre)';
  }
}
