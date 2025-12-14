import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DynamicNumberField extends StatelessWidget {
  final String label;
  final bool allowDecimal;
  final bool isRequired;
  final dynamic initialValue;
  final Function(dynamic) onChanged;
  final TextEditingController? controller;

  const DynamicNumberField({
    super.key,
    required this.label,
    this.allowDecimal = false,
    this.isRequired = false,
    this.initialValue,
    required this.onChanged,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue?.toString() : null,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
      inputFormatters: [
        if (!allowDecimal) FilteringTextInputFormatter.digitsOnly,
        if (allowDecimal) FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      onChanged: (value) {
        if (value.isEmpty) {
          onChanged(null);
          return;
        }
        if (allowDecimal) {
          onChanged(double.tryParse(value));
        } else {
          onChanged(int.tryParse(value));
        }
      },
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return 'Campo requerido';
        }
        if (value != null && value.isNotEmpty) {
          if (allowDecimal) {
            if (double.tryParse(value) == null) {
              return 'Debe ser un número válido';
            }
          } else {
            if (int.tryParse(value) == null) {
              return 'Debe ser un número entero';
            }
          }
        }
        return null;
      },
    );
  }
}
