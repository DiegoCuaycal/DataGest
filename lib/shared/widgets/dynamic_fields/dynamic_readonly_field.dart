import 'package:flutter/material.dart';

class DynamicReadonlyField extends StatelessWidget {
  final String label;
  final String value;

  const DynamicReadonlyField({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey[200],
      ),
      readOnly: true,
      enabled: false,
    );
  }
}
