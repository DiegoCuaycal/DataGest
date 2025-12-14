class DatabaseInfoModel {
  final int id;
  final String name;
  final String description;

  DatabaseInfoModel({
    required this.id,
    required this.name,
    required this.description,
  });

  factory DatabaseInfoModel.fromJson(Map<String, dynamic> json) {
    return DatabaseInfoModel(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }

  @override
  String toString() => 'DatabaseInfoModel(id: $id, name: $name, description: $description)';
}
