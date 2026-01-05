import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:herramienta_case/core/constants/app_strings.dart';
import 'package:herramienta_case/core/constants/app_styles.dart';

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
      decoration: AppStyles.inputDecoration(
        labelText: '$label${isRequired ? ' *' : ''}',
      ).copyWith(
        helperText: isRequired
            ? 'Campo obligatorio - ${allowDecimal ? 'Número decimal' : 'Número entero'}'
            : allowDecimal ? 'Número decimal' : 'Número entero',
        helperStyle: const TextStyle(fontSize: 11, color: Colors.grey),
      ),
      keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
      inputFormatters: [
        if (!allowDecimal) FilteringTextInputFormatter.digitsOnly,
        if (allowDecimal) FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
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
        // Validar campo requerido
        if (isRequired) {
          if (value == null || value.trim().isEmpty) {
            return '${AppStrings.requiredFieldMessage} - El campo $label no puede estar vacío';
          }
        }

        // Validar formato numérico
        if (value != null && value.isNotEmpty) {
          if (allowDecimal) {
            final parsedValue = double.tryParse(value);
            if (parsedValue == null) {
              return 'Debe ser un número decimal válido (ej: 10.5)';
            }
            // Validar rangos razonables
            if (parsedValue.abs() > 999999999) {
              return 'El número es demasiado grande';
            }
          } else {
            final parsedValue = int.tryParse(value);
            if (parsedValue == null) {
              return 'Debe ser un número entero válido (ej: 42)';
            }
            // Validar rangos razonables
            if (parsedValue.abs() > 2147483647) {
              return 'El número es demasiado grande';
            }
          }
        }

        // Si no es requerido y está vacío, es válido
        if (!isRequired && (value == null || value.trim().isEmpty)) {
          return null;
        }

        return null;
      },
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }
}
