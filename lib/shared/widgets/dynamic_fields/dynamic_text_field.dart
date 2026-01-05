import 'package:flutter/material.dart';
import 'package:herramienta_case/core/constants/app_strings.dart';
import 'package:herramienta_case/core/constants/app_styles.dart';

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
      decoration: AppStyles.inputDecoration(
        labelText: '$label${isRequired ? ' *' : ''}',
      ).copyWith(
        counterText: maxLength != null ? '' : null,
        helperText: isRequired ? 'Campo obligatorio' : null,
        helperStyle: const TextStyle(fontSize: 11, color: Colors.grey),
      ),
      maxLength: maxLength,
      maxLines: multiline ? 5 : 1,
      onChanged: onChanged,
      validator: (value) {
        // Validar campo requerido
        if (isRequired) {
          if (value == null || value.trim().isEmpty) {
            return '${AppStrings.requiredFieldMessage} - El campo $label no puede estar vacío';
          }
        }

        // Validar longitud máxima
        if (maxLength != null && value != null && value.length > maxLength!) {
          return 'Máximo $maxLength caracteres permitidos';
        }

        // Validar que no sea solo espacios en blanco
        if (value != null && value.trim().isEmpty && value.isNotEmpty) {
          return 'No se permiten solo espacios en blanco';
        }

        return null;
      },
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }
}
