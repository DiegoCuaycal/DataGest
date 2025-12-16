import 'package:flutter/material.dart';
import 'package:herramienta_case/core/constants/app_colors.dart';
import 'package:herramienta_case/core/constants/app_strings.dart';
import 'package:herramienta_case/core/constants/app_styles.dart';

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
        decoration: AppStyles.inputDecoration(
          labelText: label,
        ),
        child: const Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ),
      );
    }

    return DropdownButtonFormField(
      decoration: AppStyles.inputDecoration(
        labelText: label,
      ),
      initialValue: value,
      items: items,
      onChanged: onChanged,
      validator: (value) {
        if (isRequired && value == null) {
          return AppStrings.requiredFieldMessage;
        }
        return null;
      },
    );
  }
}
