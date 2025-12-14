import 'package:flutter/material.dart';

class DynamicTextField extends StatelessWidget {
  final String label;
  final int? maxLength;
  final bool isRequired;
  final String? initialValue;
  final Function(String) onChanged;
  final bool multiline;
  final TextEditingController? controller;

  const DynamicTextField({
    super.key,
    required this.label,
    this.maxLength,
    this.isRequired = false,
    this.initialValue,
    required this.onChanged,
    this.multiline = false,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        counterText: maxLength != null ? '' : null,
      ),
      maxLength: maxLength,
      maxLines: multiline ? 5 : 1,
      onChanged: onChanged,
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return 'Campo requerido';
        }
        if (maxLength != null && value != null && value.length > maxLength!) {
          return 'Máximo $maxLength caracteres';
        }
        return null;
      },
    );
  }
}
