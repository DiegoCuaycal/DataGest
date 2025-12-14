class DropdownItemModel {
  final dynamic id;
  final String displayValue;

  DropdownItemModel({
    required this.id,
    required this.displayValue,
  });

  factory DropdownItemModel.fromJson(Map<String, dynamic> json) {
    return DropdownItemModel(
      id: json['id'],
      displayValue: json['displayValue'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayValue': displayValue,
    };
  }

  @override
  String toString() => 'DropdownItemModel(id: $id, displayValue: $displayValue)';
}
