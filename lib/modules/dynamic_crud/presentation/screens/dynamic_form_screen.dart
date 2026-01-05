import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:herramienta_case/core/services/loading_overlay_service.dart';
import '../providers/dynamic_crud_provider.dart';
import '../providers/metadata_provider.dart';
import '../../../database_selector/presentation/providers/database_selector_provider.dart';
import '../../../home/presentation/providers/recent_activity_provider.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/services/form_generator_service.dart';
import '../../data/models/column_info_model.dart'; 

class DynamicFormScreen extends StatefulWidget {
  final String tableName;
  final String? recordId;
  final bool isEdit;

  const DynamicFormScreen({
    super.key,
    required this.tableName,
    this.recordId,
    this.isEdit = false,
  });

  @override
  State<DynamicFormScreen> createState() => _DynamicFormScreenState();
}

class _DynamicFormScreenState extends State<DynamicFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _formData = {};
  final FormGeneratorService _formGenerator = FormGeneratorService();
  bool _isLoading = false;
  bool _isLoadingRecord = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.recordId != null) {
      _isLoadingRecord = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadRecord();
      });
    }
  }

  dynamic _getValueFuzzy(Map<String, dynamic> record, String columnName) {
    if (record.containsKey(columnName)) return record[columnName];
    final cleanCol = columnName.replaceAll('_', '').toLowerCase();
    for (var key in record.keys) {
      final cleanKey = key.replaceAll('_', '').toLowerCase();
      if (cleanKey == cleanCol) {
        return record[key];
      }
    }
    return null;
  }

  Future<void> _loadRecord() async {
    final dbProvider = context.read<DatabaseSelectorProvider>();
    final crudProvider = context.read<DynamicCrudProvider>();
    final authProvider = context.read<AuthProvider>();
    final metadataProvider = context.read<MetadataProvider>();
    final token = authProvider.currentUser?.token ?? '';

    if (dbProvider.currentDatabaseName != null && widget.recordId != null) {
      await crudProvider.loadTableRecord(
        databaseName: dbProvider.currentDatabaseName!,
        tableName: widget.tableName,
        id: widget.recordId!,
        token: token,
      );

      if (mounted) {
        setState(() {
          _isLoadingRecord = false;
          if (crudProvider.currentRecord != null) {
            final columns = metadataProvider.getColumnsForTable(widget.tableName);
            _populateFormData(columns, crudProvider.currentRecord!);
          }
        });
      }
    }
  }

  void _populateFormData(List<ColumnInfoModel> columns, Map<String, dynamic> initialData) {
    _formData.clear();
    for (var col in columns) {
      final val = _getValueFuzzy(initialData, col.name);
      if (val != null && !col.isIdentity) {
        _formData[col.name] = val;
      }
    }
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();

    LoadingOverlayService.show(
      context,
      text: widget.isEdit ? 'Actualizando registro...' : 'Guardando registro...',
    );

    final dbProvider = context.read<DatabaseSelectorProvider>();
    final crudProvider = context.read<DynamicCrudProvider>();
    final metadataProvider = context.read<MetadataProvider>();
    final authProvider = context.read<AuthProvider>();
    final token = authProvider.currentUser?.token ?? '';

    final columns = metadataProvider.getColumnsForTable(widget.tableName);
    
    final preparedData = _formGenerator.prepareDataForSubmit(
  formData: _formData,
  columns: columns,
  tableName: widget.tableName, 
  currentUserId: authProvider.currentUser?.id,
  isEditing: widget.isEdit,
  existingId: widget.recordId != null ? int.tryParse(widget.recordId!) : null,
);

    bool success;
    try {
      if (widget.isEdit && widget.recordId != null) {
        success = await crudProvider.updateRecord(
          databaseName: dbProvider.currentDatabaseName!,
          tableName: widget.tableName,
          id: widget.recordId!,
          data: preparedData,
          token: token,
        );
      } else {
        success = await crudProvider.createRecord(
          databaseName: dbProvider.currentDatabaseName!,
          tableName: widget.tableName,
          data: preparedData,
          token: token,
        );
      }
    } finally {
      LoadingOverlayService.hide();
    }

    if (mounted) {
      if (success) {
        context.read<RecentActivityProvider>().addActivity(
              tableName: widget.tableName,
              action: widget.isEdit ? 'update' : 'create',
            );

        final notificationProvider = context.read<NotificationProvider>();
        if (widget.isEdit) {
          await notificationProvider.notifySuccess(
            'Registro actualizado',
            'El registro en la tabla ${widget.tableName} fue actualizado exitosamente',
            actionRoute: '/table/${widget.tableName}',
          );
        } else {
          await notificationProvider.notifySuccess(
            'Registro creado',
            'Se creó un nuevo registro en la tabla ${widget.tableName}',
            actionRoute: '/table/${widget.tableName}',
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.isEdit ? 'Registro actualizado' : 'Registro creado'),
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        await context.read<NotificationProvider>().notifyError(
          'Error al guardar',
          crudProvider.errorMessage ?? 'Ocurrió un error al intentar guardar el registro',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(crudProvider.errorMessage ?? 'Error al guardar')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final metadataProvider = context.watch<MetadataProvider>();
    final dbProvider = context.watch<DatabaseSelectorProvider>();
    final crudProvider = context.watch<DynamicCrudProvider>();

    if (widget.isEdit && (_isLoadingRecord || crudProvider.isLoading)) {
      return Scaffold(
        appBar: AppBar(
          title: Text('${widget.isEdit ? 'Editar' : 'Crear'} ${widget.tableName}'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final metadata = metadataProvider.metadata;
    if (metadata == null || dbProvider.currentDatabaseName == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('${widget.isEdit ? 'Editar' : 'Crear'} ${widget.tableName}'),
        ),
        body: const Center(child: Text('No se pudo cargar la metadata')),
      );
    }

    final formFields = _formGenerator.generateForm(
      tableName: widget.tableName,
      metadata: metadata,
      currentDatabase: dbProvider.currentDatabaseName!,
      initialData: widget.isEdit ? _formData : null, 
      onFieldChanged: (fieldName, value) {
        setState(() {
          _formData[fieldName] = value;
        });
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.isEdit ? 'Editar' : 'Crear'} ${widget.tableName}'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...formFields,
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveRecord,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.isEdit ? 'Actualizar' : 'Crear'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}