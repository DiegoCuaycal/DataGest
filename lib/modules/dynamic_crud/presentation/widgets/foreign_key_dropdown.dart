import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:herramienta_case/core/constants/app_colors.dart';
import 'package:herramienta_case/core/constants/app_icons.dart';
import 'package:herramienta_case/core/constants/app_strings.dart';
import 'package:herramienta_case/core/constants/app_styles.dart';
import '../../data/models/dropdown_item_model.dart';
import '../providers/dynamic_crud_provider.dart';

class ForeignKeyDropdown extends StatefulWidget {
  final String label;
  final String databaseName;
  final String referenceTable;
  final String referenceColumn;
  final bool isRequired;
  final dynamic initialValue;
  final Function(dynamic) onChanged;

  const ForeignKeyDropdown({
    super.key,
    required this.label,
    required this.databaseName,
    required this.referenceTable,
    required this.referenceColumn,
    this.isRequired = false,
    this.initialValue,
    required this.onChanged,
  });

  @override
  State<ForeignKeyDropdown> createState() => _ForeignKeyDropdownState();
}

class _ForeignKeyDropdownState extends State<ForeignKeyDropdown> {
  List<DropdownItemModel> _items = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDropdownData();
  }

  Future<void> _loadDropdownData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final provider = context.read<DynamicCrudProvider>();
      final items = await provider.getDropdownData(
        databaseName: widget.databaseName,
        tableName: widget.referenceTable,
      );

      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return InputDecorator(
        decoration: AppStyles.inputDecoration(
          labelText: widget.label,
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

    if (_errorMessage != null) {
      return InputDecorator(
        decoration: AppStyles.inputDecoration(
          labelText: widget.label,
          errorText: AppStrings.errorLoadingData,
        ),
        child: Row(
          children: [
            const Icon(
              AppIcons.error,
              color: AppColors.error,
              size: 20,
            ),
            const SizedBox(width: AppStyles.paddingSmall),
            Expanded(
              child: Text(
                _errorMessage!,
                style: AppStyles.bodySmall.copyWith(
                  color: AppColors.error,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(AppIcons.refresh, size: 20),
              onPressed: _loadDropdownData,
              color: AppColors.primary,
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<dynamic>(
      decoration: AppStyles.inputDecoration(
        labelText: widget.label,
      ),
      initialValue: widget.initialValue,
      items: _items.map((item) {
        return DropdownMenuItem<dynamic>(
          value: item.id,
          child: Text(
            item.displayValue,
            style: AppStyles.bodyMedium,
          ),
        );
      }).toList(),
      onChanged: widget.onChanged,
      validator: widget.isRequired
          ? (value) => value == null ? AppStrings.requiredFieldMessage : null
          : null,
    );
  }
}
