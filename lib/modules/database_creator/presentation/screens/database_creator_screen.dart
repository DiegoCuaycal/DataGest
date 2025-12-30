import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:herramienta_case/core/constants/app_colors.dart';
import 'package:herramienta_case/core/constants/app_styles.dart';
import 'package:herramienta_case/core/services/loading_overlay_service.dart';
import 'package:herramienta_case/core/utils/notification_service.dart';
import 'package:herramienta_case/modules/database_selector/presentation/providers/database_selector_provider.dart';
import '../../domain/models/table_entity.dart';
import '../../domain/models/attribute_field.dart';
import '../providers/database_creator_provider.dart';
import '../dialogs/table_entity_dialog.dart';
import '../dialogs/attribute_field_dialog.dart';
import '../widgets/table_entity_card.dart';

/// Pantalla principal para crear una base de datos personalizada
class DatabaseCreatorScreen extends StatefulWidget {
  const DatabaseCreatorScreen({super.key});

  @override
  State<DatabaseCreatorScreen> createState() => _DatabaseCreatorScreenState();
}

class _DatabaseCreatorScreenState extends State<DatabaseCreatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Crear Base de Datos'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        actions: [
          // Botón para previsualizar JSON
          IconButton(
            icon: const Icon(Icons.preview),
            tooltip: 'Previsualizar JSON',
            onPressed: _previewJson,
          ),
          // Botón para guardar
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Guardar y Enviar',
            onPressed: _saveAndSubmit,
          ),
        ],
      ),
      body: Consumer<DatabaseCreatorProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(AppStyles.paddingMedium),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Información general
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(AppStyles.paddingLarge),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: AppColors.primaryGradient,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.storage,
                                    color: AppColors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: AppStyles.paddingMedium),
                                Text(
                                  'Información General',
                                  style: AppStyles.heading3,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppStyles.paddingLarge),

                            // Nombre de la base de datos
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Nombre de la base de datos',
                                hintText: 'ej: mi_base_datos',
                                prefixIcon: Icon(Icons.storage),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'El nombre es requerido';
                                }
                                if (!RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$')
                                    .hasMatch(value)) {
                                  return 'Nombre inválido (use solo letras, números y _)';
                                }
                                return null;
                              },
                              onChanged: (value) {
                                provider.updateDatabaseName(value);
                              },
                            ),
                            const SizedBox(height: AppStyles.paddingMedium),

                            // Descripción
                            TextFormField(
                              controller: _descriptionController,
                              decoration: const InputDecoration(
                                labelText: 'Descripción (opcional)',
                                hintText: 'Describe el propósito de esta base de datos',
                                prefixIcon: Icon(Icons.description),
                              ),
                              maxLines: 3,
                              onChanged: (value) {
                                provider.updateDatabaseDescription(value);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppStyles.paddingLarge),

                    // Sección de tablas
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.table_chart,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: AppStyles.paddingSmall),
                            Text(
                              'Tablas',
                              style: AppStyles.heading3,
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: _addTable,
                          icon: const Icon(Icons.add),
                          label: const Text('Agregar Tabla'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppStyles.paddingMedium),

                    // Lista de tablas
                    if (provider.schema.tables.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppStyles.paddingLarge * 2),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.table_chart_outlined,
                                  size: 64,
                                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: AppStyles.paddingMedium),
                                Text(
                                  'No hay tablas agregadas',
                                  style: AppStyles.bodyLarge.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: AppStyles.paddingSmall),
                                Text(
                                  'Presiona "Agregar Tabla" para comenzar',
                                  style: AppStyles.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      ...provider.schema.tables.map((table) {
                        return TableEntityCard(
                          table: table,
                          onEdit: () => _editTable(table),
                          onDelete: () => _deleteTable(table.id),
                          onAddAttribute: () => _addAttributeToTable(table),
                        );
                      }),

                    const SizedBox(height: AppStyles.paddingLarge),

                    // Información adicional
                    if (provider.schema.tables.isNotEmpty)
                      Card(
                        color: AppColors.info.withValues(alpha: 0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(AppStyles.paddingMedium),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: AppColors.info,
                              ),
                              const SizedBox(width: AppStyles.paddingMedium),
                              Expanded(
                                child: Text(
                                  'Total: ${provider.schema.tables.length} tabla(s) con '
                                  '${provider.getTotalAttributes()} atributo(s)',
                                  style: AppStyles.bodyMedium.copyWith(
                                    color: AppColors.info,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Agregar nueva tabla
  Future<void> _addTable() async {
    final result = await showDialog<TableEntity>(
      context: context,
      builder: (context) => const TableEntityDialog(),
    );

    if (result != null && mounted) {
      context.read<DatabaseCreatorProvider>().addTable(result);
      NotificationService.showSuccess(
        context,
        'Tabla "${result.name}" agregada',
      );
    }
  }

  /// Editar tabla existente
  Future<void> _editTable(TableEntity table) async {
    final result = await showDialog<TableEntity>(
      context: context,
      builder: (context) => TableEntityDialog(tableToEdit: table),
    );

    if (result != null && mounted) {
      context.read<DatabaseCreatorProvider>().updateTable(table.id, result);
      NotificationService.showSuccess(
        context,
        'Tabla "${result.name}" actualizada',
      );
    }
  }

  /// Eliminar tabla
  Future<void> _deleteTable(String tableId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Está seguro de eliminar esta tabla?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.read<DatabaseCreatorProvider>().removeTable(tableId);
      NotificationService.showSuccess(context, 'Tabla eliminada');
    }
  }

  /// Agregar atributo a una tabla
  Future<void> _addAttributeToTable(TableEntity table) async {
    final result = await showDialog<AttributeField>(
      context: context,
      builder: (context) => const AttributeFieldDialog(),
    );

    if (result != null && mounted) {
      final provider = context.read<DatabaseCreatorProvider>();
      provider.addAttributeToTable(table.id, result);
      NotificationService.showSuccess(
        context,
        'Atributo "${result.name}" agregado a "${table.name}"',
      );
    }
  }

  /// Previsualizar JSON
  void _previewJson() {
    final provider = context.read<DatabaseCreatorProvider>();
    final schema = provider.schema.copyWith(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
    );

    // Validar antes de mostrar
    final errors = schema.getValidationErrors();
    if (errors.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Errores de Validación'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: errors.map((error) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error, color: AppColors.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(error)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
      return;
    }

    // Mostrar JSON
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(AppStyles.paddingLarge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Previsualización JSON', style: AppStyles.heading3),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: AppStyles.paddingMedium),
                Flexible(
                  child: SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.all(AppStyles.paddingMedium),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: SelectableText(
                        schema.toFormattedJson(),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Guardar y enviar al backend
  Future<void> _saveAndSubmit() async {
    if (!_formKey.currentState!.validate()) {
      NotificationService.showError(
        context,
        'Por favor complete los campos requeridos',
      );
      return;
    }

    final provider = context.read<DatabaseCreatorProvider>();
    final schema = provider.schema.copyWith(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
    );

    // Validar el esquema completo
    final errors = schema.getValidationErrors();
    if (errors.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Errores de Validación'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: errors.map((error) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error, color: AppColors.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(error)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
      return;
    }

    // Confirmar antes de enviar
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Creación'),
        content: Text(
          '¿Desea crear la base de datos "${schema.name}" con '
          '${schema.tables.length} tabla(s)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Crear'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Mostrar loading overlay durante la creación
    LoadingOverlayService.show(
      context,
      text: 'Creando base de datos "${schema.name}"...',
    );

    try {
      // Enviar al backend
      await provider.submitSchema(schema);

      if (!mounted) return;

      // Ocultar loading
      LoadingOverlayService.hide();

      if (provider.errorMessage != null) {
        NotificationService.showError(context, provider.errorMessage!);
      } else {
        NotificationService.showSuccess(
          context,
          'Base de datos "${schema.name}" creada exitosamente',
        );

        // Recargar la lista de bases de datos para mostrar la nueva
        final databaseSelectorProvider = context.read<DatabaseSelectorProvider>();
        await databaseSelectorProvider.loadAvailableDatabases(useMock: false);

        // Limpiar el estado del provider para la próxima creación
        provider.resetSchema();

        // Regresar a la pantalla de selección
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      // Ocultar loading en caso de error
      LoadingOverlayService.hide();
      if (mounted) {
        NotificationService.showError(
          context,
          'Error al crear la base de datos: ${e.toString()}',
        );
      }
    }
  }
}
