import 'package:flutter/material.dart';
import 'package:herramienta_case/core/constants/app_styles.dart';
import '../../domain/models/table_entity.dart';

/// Diálogo para agregar o editar una tabla
class TableEntityDialog extends StatefulWidget {
  final TableEntity? tableToEdit;

  const TableEntityDialog({
    super.key,
    this.tableToEdit,
  });

  @override
  State<TableEntityDialog> createState() => _TableEntityDialogState();
}

class _TableEntityDialogState extends State<TableEntityDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();

    final table = widget.tableToEdit;
    _nameController = TextEditingController(text: table?.name ?? '');
    _descriptionController = TextEditingController(
      text: table?.description ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.tableToEdit != null;

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
                    isEditing ? 'Editar Tabla' : 'Agregar Tabla',
                    style: AppStyles.heading3,
                  ),
                  const SizedBox(height: AppStyles.paddingLarge),

                  // Nombre de la tabla
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la tabla',
                      hintText: 'ej: usuarios, productos, ventas',
                      prefixIcon: Icon(Icons.table_chart),
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

                  // Descripción
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Descripción (opcional)',
                      hintText: 'Descripción de la tabla',
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 3,
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
                        onPressed: _saveTable,
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

  void _saveTable() {
    if (_formKey.currentState!.validate()) {
      final table = TableEntity(
        id: widget.tableToEdit?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        attributes: widget.tableToEdit?.attributes ?? [],
      );

      Navigator.pop(context, table);
    }
  }
}
