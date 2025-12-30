import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:herramienta_case/core/constants/app_colors.dart';
import 'package:herramienta_case/core/constants/app_styles.dart';
import 'package:herramienta_case/core/services/loading_overlay_service.dart';
import 'package:herramienta_case/core/utils/notification_service.dart';
import 'package:herramienta_case/modules/auth/presentation/providers/auth_provider.dart';
import 'package:herramienta_case/modules/database_selector/presentation/providers/database_selector_provider.dart';
import 'package:herramienta_case/modules/dynamic_crud/data/models/table_info_model.dart';
import 'package:herramienta_case/modules/dynamic_crud/presentation/providers/metadata_provider.dart';
import 'package:herramienta_case/modules/export/domain/models/export_config.dart';
import 'package:herramienta_case/modules/export/domain/models/export_format.dart';
import 'package:herramienta_case/modules/export/presentation/providers/export_provider.dart';
import 'package:herramienta_case/modules/export/presentation/widgets/export_format_card.dart';
import 'package:herramienta_case/modules/export/presentation/widgets/table_selection_list.dart';

/// Pantalla para seleccionar opciones de exportación
class ExportOptionsScreen extends StatefulWidget {
  const ExportOptionsScreen({super.key});

  @override
  State<ExportOptionsScreen> createState() => _ExportOptionsScreenState();
}

class _ExportOptionsScreenState extends State<ExportOptionsScreen> {
  ExportFormat _selectedFormat = ExportFormat.csv;
  bool _includeHeaders = true;
  bool _exportAll = true;
  final Set<String> _selectedTables = {};

  @override
  Widget build(BuildContext context) {
    final metadataProvider = context.watch<MetadataProvider>();
    final exportProvider = context.watch<ExportProvider>();
    final allTables = metadataProvider.tables;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Exportar datos'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: exportProvider.isExporting
          ? _buildExportingState(exportProvider)
          : _buildOptionsForm(allTables),
      bottomNavigationBar: exportProvider.isExporting
          ? null
          : _buildBottomBar(context, allTables),
    );
  }

  Widget _buildExportingState(ExportProvider exportProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppStyles.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            const SizedBox(height: AppStyles.paddingLarge),
            Text(
              exportProvider.statusMessage ?? 'Exportando...',
              style: AppStyles.bodyLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (exportProvider.progress > 0) ...[
              const SizedBox(height: AppStyles.paddingMedium),
              LinearProgressIndicator(
                value: exportProvider.progress,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              const SizedBox(height: AppStyles.paddingSmall),
              Text(
                '${(exportProvider.progress * 100).toStringAsFixed(0)}%',
                style: AppStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsForm(List<TableInfoModel> allTables) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppStyles.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selección de formato
          Text(
            'Formato de exportación',
            style: AppStyles.heading3,
          ),
          const SizedBox(height: AppStyles.paddingMedium),
          _buildFormatSelection(),

          const SizedBox(height: AppStyles.paddingLarge),

          // Opciones adicionales
          Text(
            'Opciones',
            style: AppStyles.heading3,
          ),
          const SizedBox(height: AppStyles.paddingMedium),
          _buildOptionsSection(),

          const SizedBox(height: AppStyles.paddingLarge),

          // Selección de tablas
          Text(
            'Tablas a exportar',
            style: AppStyles.heading3,
          ),
          const SizedBox(height: AppStyles.paddingMedium),
          _buildTableSelection(allTables),
        ],
      ),
    );
  }

  Widget _buildFormatSelection() {
    return Column(
      children: ExportFormat.values.map((format) {
        return ExportFormatCard(
          format: format,
          isSelected: _selectedFormat == format,
          onTap: () {
            setState(() {
              _selectedFormat = format;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildOptionsSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Incluir cabeceras'),
            subtitle: const Text('Agregar nombres de columnas en la primera fila'),
            value: _includeHeaders,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
            activeThumbColor: AppColors.primary,
            onChanged: (value) {
              setState(() {
                _includeHeaders = value;
              });
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Exportar todas las tablas'),
            subtitle: const Text('Exportar todas las tablas de la base de datos'),
            value: _exportAll,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
            activeThumbColor: AppColors.primary,
            onChanged: (value) {
              setState(() {
                _exportAll = value;
                if (value) {
                  _selectedTables.clear();
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTableSelection(List<TableInfoModel> allTables) {
    if (_exportAll) {
      return Container(
        padding: const EdgeInsets.all(AppStyles.paddingMedium),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: AppStyles.paddingSmall),
            Expanded(
              child: Text(
                'Se exportarán todas las ${allTables.length} tablas de la base de datos',
                style: AppStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return TableSelectionList(
      tables: allTables,
      selectedTables: _selectedTables,
      onSelectionChanged: (selected) {
        setState(() {
          _selectedTables.clear();
          _selectedTables.addAll(selected);
        });
      },
    );
  }

  Widget _buildBottomBar(BuildContext context, List<TableInfoModel> allTables) {
    return Container(
      padding: const EdgeInsets.all(AppStyles.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.divider),
        ),
      ),
      child: SafeArea(
        child: ElevatedButton.icon(
          onPressed: () => _handleExport(context, allTables),
          icon: const Icon(Icons.download),
          label: Text(
            _exportAll
                ? 'Exportar ${allTables.length} tablas'
                : _selectedTables.isEmpty
                    ? 'Seleccione al menos una tabla'
                    : 'Exportar ${_selectedTables.length} tabla${_selectedTables.length > 1 ? 's' : ''}',
          ),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            backgroundColor: _canExport() ? AppColors.primary : AppColors.border,
          ),
        ),
      ),
    );
  }

  bool _canExport() {
    return _exportAll || _selectedTables.isNotEmpty;
  }

  Future<void> _handleExport(
    BuildContext context,
    List<TableInfoModel> allTables,
  ) async {
    if (!_canExport()) {
      NotificationService.showWarning(
        context,
        'Por favor seleccione al menos una tabla para exportar',
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final dbProvider = context.read<DatabaseSelectorProvider>();
    final exportProvider = context.read<ExportProvider>();

    final token = authProvider.currentUser?.token ?? '';
    final databaseName = dbProvider.currentDatabaseName ?? '';

    if (token.isEmpty || databaseName.isEmpty) {
      if (context.mounted) {
        NotificationService.showError(
          context,
          'Error: No se pudo obtener la información de autenticación',
        );
      }
      return;
    }

    // Crear configuración de exportación
    final config = ExportConfig(
      format: _selectedFormat,
      includeHeaders: _includeHeaders,
    );

    // Obtener las tablas a exportar
    final tablesToExport = _exportAll
        ? allTables
        : allTables.where((t) => _selectedTables.contains(t.table)).toList();

    // Mostrar loading overlay durante la exportación
    LoadingOverlayService.show(
      context,
      text: 'Exportando ${tablesToExport.length} tabla${tablesToExport.length > 1 ? 's' : ''}...',
    );

    try {
      // Exportar
      // TEMPORAL: Activar modo de prueba por defecto hasta que se arregle el backend
      final results = await exportProvider.exportMultipleTables(
        databaseName: databaseName,
        tables: tablesToExport,
        baseConfig: config,
        token: token,
        useMockData: true, // CAMBIAR A false cuando el backend funcione
      );

      if (!context.mounted) return;

      // Ocultar loading
      LoadingOverlayService.hide();

      if (results != null && results.isNotEmpty) {
        final totalRecords = results.fold<int>(
          0,
          (sum, result) => sum + result.recordsCount,
        );

        NotificationService.showSuccess(
          context,
          'Exportación completada:\n'
          '${results.length} tabla${results.length > 1 ? 's' : ''} '
          '($totalRecords registros)',
        );

        // Mostrar diálogo con ubicación de archivos
        _showExportSuccessDialog(context, results);
      } else if (exportProvider.errorMessage != null) {
        NotificationService.showError(
          context,
          exportProvider.errorMessage!,
        );
      }
    } catch (e) {
      // Ocultar loading en caso de error
      LoadingOverlayService.hide();
      if (context.mounted) {
        NotificationService.showError(
          context,
          'Error durante la exportación: ${e.toString()}',
        );
      }
    }
  }

  void _showExportSuccessDialog(
    BuildContext context,
    List results,
  ) async {
    // Obtener la ubicación de los archivos
    final exportProvider = context.read<ExportProvider>();
    final exportPath = await exportProvider.getExportsDirectory();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success),
            const SizedBox(width: 8),
            const Text('Exportación exitosa'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Resumen
              Text(
                'Se han exportado ${results.length} archivo${results.length > 1 ? 's' : ''}:',
                style: AppStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppStyles.paddingMedium),

              // Lista de archivos
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: results.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final result = results[index];
                    final sizeKB = (result.fileSize / 1024).toStringAsFixed(1);
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        Icons.insert_drive_file,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      title: Text(
                        result.fileName,
                        style: AppStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        '$sizeKB KB • ${result.recordsCount} registro${result.recordsCount != 1 ? 's' : ''}',
                        style: AppStyles.bodySmall.copyWith(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: AppStyles.paddingMedium),

              // Ubicación de archivos
              Container(
                padding: const EdgeInsets.all(AppStyles.paddingMedium),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.folder_open,
                          size: 16,
                          color: AppColors.info,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Ubicación de archivos:',
                          style: AppStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.info,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      exportPath,
                      style: AppStyles.bodySmall.copyWith(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Puedes encontrar tus archivos en esta carpeta usando un explorador de archivos.',
                      style: AppStyles.bodySmall.copyWith(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.check),
            label: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }
}
