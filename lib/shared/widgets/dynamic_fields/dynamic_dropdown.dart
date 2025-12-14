import 'package:flutter/material.dart';

class DynamicDropdown extends StatelessWidget {
  final String label;
  final List<DropdownMenuItem> items;
  final dynamic value;
  final Function(dynamic) onChanged;
  final bool isRequired;
  final bool isLoading;

  const DynamicDropdown({
    super.key,
    required this.label,
    required this.items,
    this.value,
    required this.onChanged,
    this.isRequired = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: const Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return DropdownButtonFormField(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      initialValue: value,
      items: items,
      onChanged: onChanged,
      validator: (value) {
        if (isRequired && value == null) {
          return 'Campo requerido';
        }
        return null;
      },
    );
  }
}
