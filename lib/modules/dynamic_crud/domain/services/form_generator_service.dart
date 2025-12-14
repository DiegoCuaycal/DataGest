import 'package:flutter/material.dart';
import '../../data/models/column_info_model.dart';
import '../../data/models/foreign_key_model.dart';
import '../../data/models/database_metadata_model.dart';
import '../../../../shared/widgets/dynamic_fields/dynamic_text_field.dart';
import '../../../../shared/widgets/dynamic_fields/dynamic_number_field.dart';
import '../../../../shared/widgets/dynamic_fields/dynamic_date_picker.dart';
import '../../../../shared/widgets/dynamic_fields/dynamic_checkbox.dart';
import '../../../../shared/widgets/dynamic_fields/dynamic_readonly_field.dart';
import '../../presentation/widgets/foreign_key_dropdown.dart';
import 'field_type_mapper.dart';

class FormGeneratorService {
  Widget generateField({
    required ColumnInfoModel column,
    required DatabaseMetadataModel metadata,
    required String currentDatabase,
    dynamic initialValue,
    required Function(String, dynamic) onChanged,
  }) {
    // 1. If it's PK with identity → Read-only field or hidden
    if (column.isIdentity) {
      if (initialValue != null) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: DynamicReadonlyField(
            label: column.name,
            value: initialValue.toString(),
          ),
        );
      }
      return const SizedBox.shrink(); // Hide in create mode
    }

    // 2. If it's FK → Dropdown with data from referenced table
    final fk = metadata.getForeignKeyForColumn(column.table, column.name);

    if (fk != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: ForeignKeyDropdown(
          label: column.name,
          databaseName: currentDatabase,
          referenceTable: fk.referenceTable,
          referenceColumn: fk.referenceColumn,
          isRequired: !column.nullable,
          initialValue: initialValue,
          onChanged: (value) => onChanged(column.name, value),
        ),
      );
    }

    // 3. According to data type → Corresponding widget
    final type = column.type.toLowerCase();

    if (FieldTypeMapper.isStringType(type) || FieldTypeMapper.isTextType(type)) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: DynamicTextField(
          label: column.name,
          maxLength: column.maxLength,
          isRequired: !column.nullable,
          initialValue: initialValue?.toString(),
          onChanged: (value) => onChanged(column.name, value),
          multiline: FieldTypeMapper.isTextType(type),
        ),
      );
    }

    if (FieldTypeMapper.isIntegerType(type)) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: DynamicNumberField(
          label: column.name,
          allowDecimal: false,
          isRequired: !column.nullable,
          initialValue: initialValue,
          onChanged: (value) => onChanged(column.name, value),
        ),
      );
    }

    if (FieldTypeMapper.isDecimalType(type)) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: DynamicNumberField(
          label: column.name,
          allowDecimal: true,
          isRequired: !column.nullable,
          initialValue: initialValue,
          onChanged: (value) => onChanged(column.name, value),
        ),
      );
    }

    if (FieldTypeMapper.isDateTimeType(type)) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: DynamicDatePicker(
          label: column.name,
          includeTime: type.contains('time') && type != 'time',
          isRequired: !column.nullable,
          initialValue: initialValue,
          onChanged: (value) => onChanged(column.name, value),
        ),
      );
    }

    if (FieldTypeMapper.isBooleanType(type)) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: DynamicCheckbox(
          label: column.name,
          initialValue: initialValue ?? false,
          onChanged: (value) => onChanged(column.name, value),
        ),
      );
    }

    // Default to text field
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DynamicTextField(
        label: column.name,
        isRequired: !column.nullable,
        initialValue: initialValue?.toString(),
        onChanged: (value) => onChanged(column.name, value),
      ),
    );
  }

  List<Widget> generateForm({
    required String tableName,
    required DatabaseMetadataModel metadata,
    required String currentDatabase,
    Map<String, dynamic>? initialData,
    required Function(String, dynamic) onFieldChanged,
  }) {
    final columns = metadata.getColumnsForTable(tableName);

    return columns.map((column) {
      return generateField(
        column: column,
        metadata: metadata,
        currentDatabase: currentDatabase,
        initialValue: initialData?[column.name],
        onChanged: onFieldChanged,
      );
    }).toList();
  }

  Map<String, dynamic> prepareDataForSubmit({
    required Map<String, dynamic> formData,
    required List<ColumnInfoModel> columns,
  }) {
    final Map<String, dynamic> preparedData = {};

    for (var entry in formData.entries) {
      final column = columns.firstWhere(
        (col) => col.name == entry.key,
        orElse: () => throw Exception('Column ${entry.key} not found'),
      );

      // Skip identity columns
      if (column.isIdentity && entry.value == null) {
        continue;
      }

      // Parse value according to type
      preparedData[entry.key] = FieldTypeMapper.parseValue(
        column.type,
        entry.value,
      );
    }

    return preparedData;
  }
}
