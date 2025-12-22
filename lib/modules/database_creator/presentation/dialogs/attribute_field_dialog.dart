import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:herramienta_case/core/constants/app_colors.dart';
import 'package:herramienta_case/core/constants/app_styles.dart';
import '../../domain/models/attribute_field.dart';
import '../../domain/models/field_type.dart';

/// Diálogo para agregar o editar un atributo
class AttributeFieldDialog extends StatefulWidget {
  final AttributeField? attributeToEdit;

  const AttributeFieldDialog({
    super.key,
    this.attributeToEdit,
  });

  @override
  State<AttributeFieldDialog> createState() => _AttributeFieldDialogState();
}

class _AttributeFieldDialogState extends State<AttributeFieldDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _maxLengthController;
  late TextEditingController _defaultValueController;

  late FieldType _selectedType;
  bool _isRequired = false;
  bool _isPrimaryKey = false;
  bool _isUnique = false;

  @override
  void initState() {
    super.initState();

    final attribute = widget.attributeToEdit;
    _nameController = TextEditingController(text: attribute?.name ?? '');
    _maxLengthController = TextEditingController(
      text: attribute?.maxLength?.toString() ?? '',
    );
    _defaultValueController = TextEditingController(
      text: attribute?.defaultValue ?? '',
    );

    _selectedType = attribute?.type ?? FieldType.string;
    _isRequired = attribute?.isRequired ?? false;
    _isPrimaryKey = attribute?.isPrimaryKey ?? false;
    _isUnique = attribute?.isUnique ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _maxLengthController.dispose();
    _defaultValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.attributeToEdit != null;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppStyles.paddingLarge),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Text(
                    isEditing ? 'Editar Atributo' : 'Agregar Atributo',
                    style: AppStyles.heading3,
                  ),
                  const SizedBox(height: AppStyles.paddingLarge),

                  // Nombre del atributo
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del atributo',
                      hintText: 'ej: nombre, edad, precio',
                      prefixIcon: Icon(Icons.label),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El nombre es requerido';
                      }
                      if (!RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$').hasMatch(value)) {
                        return 'Nombre inválido (use solo letras, números y _)';
                      }
                      return null;
                    },
                    textCapitalization: TextCapitalization.none,
                  ),
                  const SizedBox(height: AppStyles.paddingMedium),

                  // Tipo de dato
                  DropdownButtonFormField<FieldType>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de dato',
                      prefixIcon: Icon(Icons.dataset),
                    ),
                    items: FieldType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Row(
                          children: [
                            Icon(
                              _getIconForType(type),
                              size: 20,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(type.displayName),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value!;
                      });
                    },
                  ),
                  const SizedBox(height: AppStyles.paddingMedium),

                  // Longitud máxima (solo para string)
                  if (_selectedType == FieldType.string ||
                      _selectedType == FieldType.text)
                    Column(
                      children: [
                        TextFormField(
                          controller: _maxLengthController,
                          decoration: const InputDecoration(
                            labelText: 'Longitud máxima (opcional)',
                            hintText: 'ej: 255',
                            prefixIcon: Icon(Icons.straighten),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final intValue = int.tryParse(value);
                              if (intValue == null || intValue <= 0) {
                                return 'Ingrese un número válido mayor a 0';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppStyles.paddingMedium),
                      ],
                    ),

                  // Valor por defecto
                  TextFormField(
                    controller: _defaultValueController,
                    decoration: const InputDecoration(
                      labelText: 'Valor por defecto (opcional)',
                      hintText: 'Valor inicial del campo',
                      prefixIcon: Icon(Icons.settings),
                    ),
                  ),
                  const SizedBox(height: AppStyles.paddingLarge),

                  // Opciones
                  Text(
                    'Opciones',
                    style: AppStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppStyles.paddingSmall),

                  CheckboxListTile(
                    value: _isPrimaryKey,
                    onChanged: (value) {
                      setState(() {
                        _isPrimaryKey = value!;
                        if (_isPrimaryKey) {
                          _isRequired = true;
                          _isUnique = true;
                        }
                      });
                    },
                    title: const Text('Clave primaria'),
                    subtitle: const Text('Este campo será el identificador único'),
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppColors.primary,
                  ),

                  CheckboxListTile(
                    value: _isRequired,
                    onChanged: _isPrimaryKey
                        ? null
                        : (value) {
                            setState(() {
                              _isRequired = value!;
                            });
                          },
                    title: const Text('Requerido'),
                    subtitle: const Text('El campo no puede estar vacío'),
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppColors.primary,
                  ),

                  CheckboxListTile(
                    value: _isUnique,
                    onChanged: _isPrimaryKey
                        ? null
                        : (value) {
                            setState(() {
                              _isUnique = value!;
                            });
                          },
                    title: const Text('Único'),
                    subtitle: const Text('No se permiten valores duplicados'),
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppColors.primary,
                  ),

                  const SizedBox(height: AppStyles.paddingLarge),

                  // Botones
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: AppStyles.paddingSmall),
                      ElevatedButton(
                        onPressed: _saveAttribute,
                        child: Text(isEditing ? 'Guardar' : 'Agregar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _saveAttribute() {
    if (_formKey.currentState!.validate()) {
      final attribute = AttributeField(
        id: widget.attributeToEdit?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        type: _selectedType,
        isRequired: _isRequired,
        isPrimaryKey: _isPrimaryKey,
        isUnique: _isUnique,
        maxLength: _maxLengthController.text.isNotEmpty
            ? int.parse(_maxLengthController.text)
            : null,
        defaultValue: _defaultValueController.text.isNotEmpty
            ? _defaultValueController.text
            : null,
      );

      Navigator.pop(context, attribute);
    }
  }

  IconData _getIconForType(FieldType type) {
    switch (type) {
      case FieldType.string:
        return Icons.text_fields;
      case FieldType.integer:
        return Icons.numbers;
      case FieldType.decimal:
        return Icons.money;
      case FieldType.boolean:
        return Icons.toggle_on;
      case FieldType.date:
        return Icons.calendar_today;
      case FieldType.datetime:
        return Icons.access_time;
      case FieldType.text:
        return Icons.notes;
    }
  }
}
