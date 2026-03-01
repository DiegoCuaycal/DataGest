import 'package:flutter/material.dart';
import '../../data/models/column_info_model.dart';
import '../../data/models/database_metadata_model.dart';
import '../../../../shared/widgets/dynamic_fields/dynamic_text_field.dart';
import '../../../../shared/widgets/dynamic_fields/dynamic_number_field.dart';
import '../../../../shared/widgets/dynamic_fields/dynamic_date_picker.dart';
import '../../../../shared/widgets/dynamic_fields/dynamic_checkbox.dart';
import '../../../../shared/widgets/dynamic_fields/dynamic_readonly_field.dart';
import '../../../../shared/widgets/dynamic_fields/dynamic_dropdown.dart';
import '../../presentation/widgets/foreign_key_dropdown.dart';
import '../../../../core/network/column_name_mapper.dart';
import 'field_type_mapper.dart';

/// Service responsible for dynamically generating form fields and preparing
/// form data for submission, based on database table metadata.
///
/// It handles field type detection, naming convention translation between
/// the frontend and the backend (C# API), and initial value resolution
/// across multiple naming strategies (camelCase, PascalCase, snake_case).
class FormGeneratorService {
  /// Returns a descriptive hint text for a form field based on its column
  /// name and data type.
  String _generateHintForField(String columnName, String dataType) {
    final lowerName = columnName.toLowerCase();

    if (lowerName.contains('codigo') || lowerName.contains('sku')) {
      return 'Ingrese código alfanumérico (ej: ABC123)';
    }
    if (lowerName.contains('nombre')) {
      return 'Ingrese nombre completo';
    }
    if (lowerName.contains('email') || lowerName.contains('correo')) {
      return 'Ingrese email válido (ej: usuario@ejemplo.com)';
    }
    if (lowerName.contains('telefono') || lowerName.contains('celular')) {
      return 'Ingrese número telefónico (ej: 0981234567)';
    }
    if (lowerName.contains('cedula') || lowerName.contains('dni') || lowerName.contains('legajo')) {
      return 'Ingrese número de documento';
    }
    if (lowerName.contains('direccion')) {
      return 'Ingrese dirección completa';
    }
    if (lowerName.contains('descripcion')) {
      return 'Ingrese descripción detallada';
    }
    if (lowerName.contains('precio') || lowerName.contains('costo') || lowerName.contains('venta')) {
      return 'Ingrese precio (ej: 15000.50)';
    }
    if (lowerName.contains('stock') || lowerName.contains('cantidad')) {
      return 'Ingrese cantidad numérica';
    }
    if (lowerName.contains('calificacion') || lowerName.contains('nota')) {
      return 'Ingrese calificación numérica';
    }
    if (lowerName.contains('edad')) {
      return 'Ingrese edad en años';
    }
    if (lowerName.contains('especificacion')) {
      return 'Ingrese especificaciones técnicas';
    }
    if (lowerName.contains('motivo')) {
      return 'Ingrese motivo o razón';
    }
    if (lowerName.contains('tratamiento')) {
      return 'Ingrese detalles del tratamiento';
    }
    if (lowerName.contains('diagnostico')) {
      return 'Ingrese diagnóstico médico';
    }
    if (lowerName.contains('especialidad')) {
      return 'Ingrese área de especialidad';
    }
    if (lowerName.contains('consultorio')) {
      return 'Ingrese número o nombre del consultorio';
    }
    if (lowerName.contains('licencia')) {
      return 'Ingrese número de licencia profesional';
    }
    if (lowerName.contains('ubicacion') || lowerName.contains('almacen')) {
      return 'Ingrese ubicación o almacén';
    }
    if (lowerName.contains('genero')) {
      return 'Ingrese género (M/F/Otro)';
    }
    if (lowerName.contains('grupo') && lowerName.contains('sanguineo')) {
      return 'Ingrese grupo sanguíneo (ej: O+, A-, AB+)';
    }
    if (lowerName.contains('apellido')) {
      return 'Ingrese apellido(s) completo(s)';
    }

    if (dataType.toLowerCase().contains('int') || dataType.toLowerCase().contains('number')) {
      return 'Ingrese número entero';
    }
    if (dataType.toLowerCase().contains('decimal') || dataType.toLowerCase().contains('float')) {
      return 'Ingrese número decimal';
    }

    return 'Ingrese texto';
  }

  /// Generates a single form field widget for a given [column].
  ///
  /// The widget type is determined by evaluating, in order:
  /// 1. Identity / auto-increment columns → read-only or hidden.
  /// 2. Auto-generated timestamp columns → read-only or hidden.
  /// 3. Hidden system columns (e.g. `usuario_id`).
  /// 4. Foreign key columns → [ForeignKeyDropdown].
  /// 5. Predefined enum columns (`estado`, `genero`) → [DynamicDropdown].
  /// 6. SQL data type → text, number, date, or checkbox widget.
  Widget generateField({
    required ColumnInfoModel column,
    required DatabaseMetadataModel metadata,
    required String currentDatabase,
    dynamic initialValue,
    required Function(String, dynamic) onChanged,
  }) {
    // 1. Identity / PK
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
      return const SizedBox.shrink();
    }

    // 2. Auto-generated timestamp columns
    final autoGeneratedFields = [
      'created_at', 'updated_at', 'deleted_at',
      'createdat', 'updatedat', 'deletedat',
    ];

    if (autoGeneratedFields.contains(column.name.toLowerCase())) {
      if (initialValue != null) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: DynamicReadonlyField(
            label: column.name,
            value: initialValue.toString(),
          ),
        );
      }
      return const SizedBox.shrink();
    }

    // 3. Hide internal user reference column
    if (column.name.toLowerCase() == 'usuario_id') {
      return const SizedBox.shrink();
    }

    // 4. FK Dropdown
    final fk = metadata.getForeignKeyForColumn(column.table, column.name);

    if (fk != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: ForeignKeyDropdown(
          label: column.name,
          databaseName: currentDatabase,
          referenceTable: fk.referenceTable,
          referenceColumn: fk.referenceColumn,
          isRequired: true,
          initialValue: initialValue,
          onChanged: (value) => onChanged(column.name, value),
        ),
      );
    }

    // 5. Predefined dropdown fields (estado, genero, etc.)
    final lowerName = column.name.toLowerCase();

    if (lowerName == 'estado') {
      List<DropdownMenuItem<String>> estadoItems;
      String defaultValue;

      if (column.table.toLowerCase() == 'citas') {
        estadoItems = [
          DropdownMenuItem(value: 'programada', child: Text('Programada')),
          DropdownMenuItem(value: 'completada', child: Text('Completada')),
          DropdownMenuItem(value: 'cancelada', child: Text('Cancelada')),
        ];
        defaultValue = 'programada';
      } else {
        estadoItems = [
          DropdownMenuItem(value: 'Activo', child: Text('Activo')),
          DropdownMenuItem(value: 'Inactivo', child: Text('Inactivo')),
        ];
        defaultValue = 'Activo';
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: DynamicDropdown(
          label: column.name,
          items: estadoItems,
          value: initialValue?.toString() ?? defaultValue,
          onChanged: (value) => onChanged(column.name, value),
          isRequired: true,
        ),
      );
    }

    if (lowerName == 'genero') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: DynamicDropdown(
          label: column.name,
          items: [
            DropdownMenuItem(value: 'M', child: Text('Masculino')),
            DropdownMenuItem(value: 'F', child: Text('Femenino')),
            DropdownMenuItem(value: 'Otro', child: Text('Otro')),
          ],
          value: initialValue?.toString(),
          onChanged: (value) => onChanged(column.name, value),
          isRequired: true,
        ),
      );
    }

    // 6. Data type-based field selection
    final type = column.type.toLowerCase();

    if (FieldTypeMapper.isStringType(type) || FieldTypeMapper.isTextType(type)) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: DynamicTextField(
          label: column.name,
          maxLength: column.maxLength,
          isRequired: true,
          initialValue: initialValue?.toString(),
          onChanged: (value) => onChanged(column.name, value),
          multiline: FieldTypeMapper.isTextType(type),
          hintText: _generateHintForField(column.name, type),
        ),
      );
    }

    if (FieldTypeMapper.isIntegerType(type)) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: DynamicNumberField(
          label: column.name,
          allowDecimal: false,
          isRequired: true,
          initialValue: initialValue?.toString(),
          onChanged: (value) => onChanged(column.name, value),
          hintText: _generateHintForField(column.name, type),
        ),
      );
    }

    if (FieldTypeMapper.isDecimalType(type)) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: DynamicNumberField(
          label: column.name,
          allowDecimal: true,
          isRequired: true,
          initialValue: initialValue?.toString(),
          onChanged: (value) => onChanged(column.name, value),
          hintText: _generateHintForField(column.name, type),
        ),
      );
    }

    if (FieldTypeMapper.isDateTimeType(type)) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: DynamicDatePicker(
          label: column.name,
          includeTime: type.contains('time') && type != 'time',
          isRequired: true,
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

    // Default fallback
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DynamicTextField(
        label: column.name,
        isRequired: true,
        initialValue: initialValue?.toString(),
        onChanged: (value) => onChanged(column.name, value),
        hintText: _generateHintForField(column.name, type),
      ),
    );
  }

  /// Resolves the initial value for a column from [initialData], applying
  /// multiple naming strategy fallbacks to handle inconsistencies between
  /// frontend column names and backend response keys.
  ///
  /// Resolution order:
  /// 1. Special-case aliases (e.g. `legajo` → `Cedula` for Estudiantes).
  /// 2. Fuzzy match (strips underscores, case-insensitive).
  /// 3. Exact key match.
  /// 4. Backend-mapped name via [ColumnNameMapper].
  /// 5. PascalCase variant.
  /// 6. camelCase variant.
  /// 7. Case-insensitive scan.
  /// 8. snake_case variant.
  dynamic _getInitialValue(
    Map<String, dynamic>? initialData,
    String columnName,
    String tableName,
  ) {
    if (initialData == null || initialData.isEmpty) return null;

    // 1. Special-case alias: Estudiantes uses 'Cedula' as the display key for 'legajo'
    if (columnName.toLowerCase() == 'legajo') {
      if (initialData.containsKey('Cedula')) return initialData['Cedula'];
      if (initialData.containsKey('cedula')) return initialData['cedula'];
    }

    // 2. Fuzzy match — strips underscores and normalizes case
    final cleanColumnName = columnName.replaceAll('_', '').toLowerCase();
    for (var key in initialData.keys) {
      final cleanKey = key.replaceAll('_', '').toLowerCase();
      if (cleanKey == cleanColumnName) return initialData[key];
    }

    // 3. Exact key match
    if (initialData.containsKey(columnName)) return initialData[columnName];

    // 4. Backend-mapped name
    final backendName = ColumnNameMapper.getBackendName(tableName, columnName);
    if (backendName != columnName && initialData.containsKey(backendName)) {
      return initialData[backendName];
    }

    // 5. PascalCase variant
    final pascalCaseName = _toPascalCase(columnName);
    if (initialData.containsKey(pascalCaseName)) return initialData[pascalCaseName];

    // 6. camelCase variant
    final camelCaseName = _toCamelCase(columnName);
    if (initialData.containsKey(camelCaseName)) return initialData[camelCaseName];

    // 7. Case-insensitive scan
    final lowerColumnName = columnName.toLowerCase();
    for (var entry in initialData.entries) {
      if (entry.key.toLowerCase() == lowerColumnName) return entry.value;
    }

    // 8. snake_case variant
    final snakeCaseName = _toSnakeCase(columnName);
    if (snakeCaseName != columnName && initialData.containsKey(snakeCaseName)) {
      return initialData[snakeCaseName];
    }

    return null;
  }

  /// Generates the complete list of form field widgets for a given [tableName].
  ///
  /// Uses [metadata] to retrieve all columns for the table and delegates
  /// individual field rendering to [generateField].
  List<Widget> generateForm({
    required String tableName,
    required DatabaseMetadataModel metadata,
    required String currentDatabase,
    Map<String, dynamic>? initialData,
    required Function(String, dynamic) onFieldChanged,
  }) {
    final columns = metadata.getColumnsForTable(tableName);

    return columns.map((column) {
      final initialValue = _getInitialValue(initialData, column.name, tableName);

      return generateField(
        column: column,
        metadata: metadata,
        currentDatabase: currentDatabase,
        initialValue: initialValue,
        onChanged: onFieldChanged,
      );
    }).toList();
  }

  /// Converts a camelCase or PascalCase string to snake_case.
  String _toSnakeCase(String str) {
    return str.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    );
  }

  /// Converts a snake_case string to camelCase.
  String _toCamelCase(String str) {
    return str.replaceAllMapped(
      RegExp(r'_([a-z])'),
      (match) => match.group(1)!.toUpperCase(),
    );
  }

  /// Converts a snake_case string to PascalCase.
  String _toPascalCase(String str) {
    final camel = _toCamelCase(str);
    if (camel.isEmpty) return camel;
    return camel[0].toUpperCase() + camel.substring(1);
  }

  /// Translates a frontend column name to the exact key format expected by
  /// the backend API for a given [tableName].
  ///
  /// The backend uses mixed naming conventions depending on the domain:
  /// - Simple fields: lowercase as-is.
  /// - Compound fields: `snake_PascalSecond` (e.g. `fecha_Inscripcion`).
  /// - Product fields: `PascalCase_PascalCase` (e.g. `Precio_Costo`).
  /// - General fallback: PascalCase.
  String _toBackendCase(String str, String tableName) {
    final String lowerStr = str.toLowerCase();

    // Profesores table uses specific field conventions
    if (tableName.toLowerCase() == 'profesores') {
      if (lowerStr == 'usuario_id') return 'usuarioId';
      if (lowerStr == 'email') return 'email';
      if (lowerStr == 'nombres') return 'nombres';
      if (lowerStr == 'especialidad') return 'especialidad';
    }

    // Simple single-word fields — pass through as-is
    if (lowerStr == 'id') return 'id';
    if (lowerStr == 'nombres' || lowerStr == 'nombre') return lowerStr;
    if (lowerStr == 'apellidos') return 'apellidos';
    if (lowerStr == 'activo') return 'activo';
    if (lowerStr == 'sku') return 'sku';
    if (lowerStr == 'descripcion') return 'descripcion';
    if (lowerStr == 'estado') return 'estado';
    if (lowerStr == 'especificaciones') return 'especificaciones';
    if (lowerStr == 'cedula' || lowerStr == 'legajo') return 'cedula';
    if (lowerStr == 'dni') return 'dni';

    // Compound fields requiring exact snake_Pascal format (defined by the API contract)
    final columnasPascalGuionStrict = [
      'cita_id', 'descripcion_diagnostico', 'tratamiento_recetado', 'proxima_visita',
      'producto_id', 'stock_actual', 'stock_minimo', 'ubicacion_almacen',
      'estudiante_id', 'curso_id', 'fecha_inscripcion', 'padre_id',
      'paciente_id', 'medico_id', 'fecha_hora', 'motivo_consulta',
      'fecha_nacimiento', 'grupo_sanguineo', 'numero_licencia', 'created_at',
      'profesor_id',
    ];

    if (columnasPascalGuionStrict.contains(lowerStr)) {
      if (lowerStr == 'cita_id') return 'cita_Id';
      if (lowerStr == 'descripcion_diagnostico') return 'descripcion_Diagnostico';
      if (lowerStr == 'tratamiento_recetado') return 'tratamiento_Recetado';
      if (lowerStr == 'proxima_visita') return 'proxima_Visita';
      if (lowerStr == 'producto_id') return 'producto_Id';
      if (lowerStr == 'stock_actual') return 'stock_Actual';
      if (lowerStr == 'stock_minimo') return 'stock_Minimo';
      if (lowerStr == 'ubicacion_almacen') return 'ubicacion_Almacen';
      if (lowerStr == 'estudiante_id') return 'estudiante_Id';
      if (lowerStr == 'curso_id') return 'curso_Id';
      if (lowerStr == 'fecha_inscripcion') return 'fecha_Inscripcion';
      if (lowerStr == 'padre_id') return 'padre_Id';
      if (lowerStr == 'paciente_id') return 'paciente_Id';
      if (lowerStr == 'medico_id') return 'medico_Id';
      if (lowerStr == 'fecha_hora') return 'fecha_Hora';
      if (lowerStr == 'motivo_consulta') return 'motivo_Consulta';
      if (lowerStr == 'fecha_nacimiento') return 'fecha_Nacimiento';
      if (lowerStr == 'grupo_sanguineo') return 'grupo_Sanguineo';
      if (lowerStr == 'numero_licencia') return 'numero_Licencia';
      if (lowerStr == 'created_at') return 'created_At';
      if (lowerStr == 'profesor_id') return 'profesor_Id';
    }

    // Product pricing and relation fields use PascalCase_PascalCase format
    final productosPascalGuion = [
      'precio_costo', 'precio_venta', 'categoria_id', 'proveedor_id'
    ];

    if (productosPascalGuion.contains(lowerStr)) {
      return str.split('_').map((part) {
        if (part.isEmpty) return '';
        return part[0].toUpperCase() + part.substring(1);
      }).join('_');
    }

    // Domain-specific single-word fields
    if (lowerStr == 'usuario_id') return 'usuario_Id';
    if (lowerStr == 'genero') return 'genero';
    if (lowerStr == 'direccion') return 'direccion';
    if (lowerStr == 'telefono') return 'telefono';
    if (lowerStr == 'especialidad') return 'especialidad';
    if (lowerStr == 'consultorio') return 'consultorio';
    if (lowerStr == 'calificacion') return 'calificacion';

    // General fallback: PascalCase
    return _toPascalCase(str);
  }

  /// Transforms the raw [formData] map into the payload structure expected
  /// by the backend API.
  ///
  /// - Excludes identity, auto-generated, and system columns.
  /// - Translates each key to the backend naming convention via [_toBackendCase].
  /// - Parses values to the correct type via [FieldTypeMapper.parseValue].
  /// - Auto-injects `usuario_id` and `created_at` when the table schema
  ///   includes those columns.
  Map<String, dynamic> prepareDataForSubmit({
    required Map<String, dynamic> formData,
    required List<ColumnInfoModel> columns,
    required String tableName,
    int? currentUserId,
    bool isEditing = false,
    int? existingId,
  }) {
    final Map<String, dynamic> preparedData = {};

    preparedData['id'] = isEditing ? existingId : 0;

    for (var entry in formData.entries) {
      ColumnInfoModel? column = columns.where((col) => col.name == entry.key).firstOrNull;

      if (column == null) {
        final snakeKey = _toSnakeCase(entry.key);
        column = columns.where((col) => col.name == snakeKey).firstOrNull;
      }

      if (column == null) {
        final camelKey = _toCamelCase(entry.key);
        column = columns.where((col) => col.name == camelKey).firstOrNull;
      }

      if (column == null || column.isIdentity || column.name.toLowerCase() == 'id') continue;

      final autoGeneratedFields = ['updated_at', 'deleted_at', 'updatedat', 'deletedat'];
      if (autoGeneratedFields.contains(column.name.toLowerCase())) continue;
      if (column.name.toLowerCase() == 'usuario_id') continue;

      final parsedValue = FieldTypeMapper.parseValue(column.type, entry.value);
      final backendName = _toBackendCase(column.name, tableName);
      preparedData[backendName] = parsedValue;
    }

    // Auto-inject authenticated user reference if the table requires it
    final hasUsuarioIdColumn = columns.any((c) => c.name.toLowerCase() == 'usuario_id');
    if (hasUsuarioIdColumn && currentUserId != null) {
      final userIdKey = _toBackendCase('usuario_id', tableName);
      preparedData[userIdKey] = currentUserId;
    }

    // Auto-inject creation timestamp for C# backend compatibility
    final hasCreatedAt = columns.any((c) => c.name.toLowerCase() == 'created_at');
    if (hasCreatedAt && !preparedData.containsKey('CreatedAt')) {
      final createdAtKey = _toBackendCase('created_at', tableName);
      preparedData[createdAtKey] = DateTime.now().toIso8601String();
    }

    return preparedData;
  }
}
