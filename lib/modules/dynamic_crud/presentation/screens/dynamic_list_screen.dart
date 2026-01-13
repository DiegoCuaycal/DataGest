import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:herramienta_case/core/constants/app_colors.dart';
import 'package:herramienta_case/core/constants/app_icons.dart';
import 'package:herramienta_case/core/constants/app_strings.dart';
import 'package:herramienta_case/core/constants/app_styles.dart';
import 'package:herramienta_case/core/services/loading_overlay_service.dart';
import 'package:herramienta_case/core/utils/notification_service.dart';
import 'package:herramienta_case/shared/widgets/search_filter_bar.dart';
import 'package:herramienta_case/shared/widgets/pagination_controls.dart';
import '../providers/dynamic_crud_provider.dart';
import '../providers/metadata_provider.dart';
import '../../../database_selector/presentation/providers/database_selector_provider.dart';
import '../../../home/presentation/providers/recent_activity_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class DynamicListScreen extends StatefulWidget {
  final String tableName;

  const DynamicListScreen({
    super.key,
    required this.tableName,
  });

  @override
  State<DynamicListScreen> createState() => _DynamicListScreenState();
}

class _DynamicListScreenState extends State<DynamicListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _registerActivity();
    });
  }

  void _registerActivity() {
    context.read<RecentActivityProvider>().addActivity(
          tableName: widget.tableName,
          action: 'view',
        );
  }

  void _loadData({int? page}) {
    final dbProvider = context.read<DatabaseSelectorProvider>();
    final crudProvider = context.read<DynamicCrudProvider>();
    final authProvider = context.read<AuthProvider>();
    final metadataProvider = context.read<MetadataProvider>(); // Importante: Leer Metadata

    // Validar que tengamos metadata antes de llamar (evita crash)
    if (metadataProvider.metadata == null) return;

    if (dbProvider.currentDatabaseName != null) {
      final token = authProvider.currentUser?.token ?? '';
      print('🔐 Token del usuario: ${token.isEmpty ? "VACÍO" : "${token.substring(0, 20)}..."}');

      crudProvider.loadTableRecords(
        metadata: metadataProvider.metadata!, // <--- NUEVO: Pasamos la metadata
        databaseName: dbProvider.currentDatabaseName!,
        tableName: widget.tableName,
        token: token,
        page: page,
        resetData: true,
      );
    }
  }

  void _handlePageChanged(int newPage) {
    _loadData(page: newPage);
  }

  void _handlePageSizeChanged(int newPageSize) {
    final crudProvider = context.read<DynamicCrudProvider>();
    crudProvider.setPageSize(newPageSize);
    _loadData(page: 1);
  }

  void _handleSearchChanged(String searchTerm) {
    final dbProvider = context.read<DatabaseSelectorProvider>();
    final crudProvider = context.read<DynamicCrudProvider>();
    final authProvider = context.read<AuthProvider>();
    final metadataProvider = context.read<MetadataProvider>();

    if (metadataProvider.metadata == null) return;

    if (dbProvider.currentDatabaseName != null) {
      crudProvider.setSearchTerm(searchTerm);
      crudProvider.loadTableRecords(
        metadata: metadataProvider.metadata!, // <--- NUEVO: Pasamos la metadata
        databaseName: dbProvider.currentDatabaseName!,
        tableName: widget.tableName,
        token: authProvider.currentUser?.token ?? '',
        resetData: true, // Resetear datos al buscar
      );
    }
  }

  /// 🚨 FUNCIÓN SABUESO 🚨
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

  String _getDisplayValue(Map<String, dynamic> record, String columnName) {
    final value = _getValueFuzzy(record, columnName);
    if (value == null || value.toString().trim().isEmpty) {
      return '';
    }

    final lowerColumnName = columnName.toLowerCase();
    if (lowerColumnName.endsWith('_id')) {
      final baseName = lowerColumnName.replaceAll('_id', '');
      final possibleFields = [
        '${baseName}_nombre',
        '${baseName}_nombres',
        '${baseName}Nombre',
        '${baseName}Nombres',
        '${baseName}nombre',
        '${baseName}nombres',
        '${baseName}nombre',
        '${baseName}Nombre',
        'nombre_$baseName',
        'nombres_$baseName',
        'Nombre_$baseName',
        'Nombres_$baseName',
        '${baseName}_especialidad',
        '${baseName}Especialidad',
        '${baseName}_descripcion',
        '${baseName}Descripcion',
      ];

      for (var field in possibleFields) {
        final descriptiveValue = _getValueFuzzy(record, field);
        if (descriptiveValue != null &&
            descriptiveValue.toString().trim().isNotEmpty &&
            descriptiveValue.toString() != '0' &&
            descriptiveValue.toString() != 'null') {
          String displayName = baseName.replaceAll('_', ' ');
          displayName = displayName[0].toUpperCase() + displayName.substring(1);
          return '$displayName: $descriptiveValue';
        }
      }

      String displayName = baseName.replaceAll('_', ' ');
      displayName = displayName[0].toUpperCase() + displayName.substring(1);
      return '$displayName: $value';
    }

    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final metadataProvider = context.watch<MetadataProvider>();
    final columns = metadataProvider.getColumnsForTable(widget.tableName);
    final pkInfo = metadataProvider.metadata?.getPrimaryKeysForTable(widget.tableName);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.tableName),
            Consumer<DynamicCrudProvider>(
              builder: (context, provider, child) {
                if (provider.totalRecords > 0) {
                  return Text(
                    '${provider.records.length} de ${provider.totalRecords}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(AppIcons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda compacta
          SearchFilterBar(
            onSearchChanged: _handleSearchChanged,
            onRefresh: _loadData,
            hintText: 'Buscar...',
          ),

          // Contenido principal
          Expanded(
            child: Consumer<DynamicCrudProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.records.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                        const SizedBox(height: AppStyles.paddingMedium),
                        Text(
                          AppStrings.loadingRecords,
                          style: AppStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.errorMessage != null && provider.records.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppStyles.paddingLarge),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppStyles.paddingLarge),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              AppIcons.error,
                              size: 64,
                              color: AppColors.error,
                            ),
                          ),
                          const SizedBox(height: AppStyles.paddingLarge),
                          Text(
                            AppStrings.errorLoadingRecords,
                            style: AppStyles.heading3,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppStyles.paddingSmall),
                          Text(
                            provider.errorMessage!,
                            textAlign: TextAlign.center,
                            style: AppStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppStyles.paddingLarge),
                          ElevatedButton.icon(
                            onPressed: _loadData,
                            icon: const Icon(AppIcons.refresh),
                            label: const Text(AppStrings.retry),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppStyles.paddingLarge,
                                vertical: AppStyles.paddingMedium,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (provider.records.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppStyles.paddingLarge),
                          decoration: BoxDecoration(
                            color: AppColors.textSecondary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            AppIcons.empty,
                            size: 64,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppStyles.paddingLarge),
                        Text(
                          provider.searchTerm.isEmpty
                              ? AppStrings.noRecords
                              : 'No se encontraron resultados',
                          style: AppStyles.heading3.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppStyles.paddingSmall),
                        Text(
                          provider.searchTerm.isEmpty
                              ? AppStrings.addNewRecord
                              : 'Intenta con otros términos de búsqueda',
                          style: AppStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Lista con paginación
                return Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          _loadData();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.only(
                            left: AppStyles.paddingMedium,
                            right: AppStyles.paddingMedium,
                            top: AppStyles.paddingSmall,
                            bottom: AppStyles.paddingMedium,
                          ),
                          itemCount: provider.records.length,
                          itemBuilder: (context, index) {
                            final record = provider.records[index];
                            final pk = pkInfo?.first.column;
                            final pkValue = pk != null ? _getValueFuzzy(record, pk) : null;

                            return Card(
                              margin: const EdgeInsets.only(bottom: AppStyles.paddingSmall),
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                              ),
                              child: Padding(
                                  padding: const EdgeInsets.all(AppStyles.paddingMedium),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ...columns
                                          .where((col) {
                                            final name = col.name.toLowerCase();
                                            return name != pk?.toLowerCase() &&
                                                !name.contains('created_at') &&
                                                !name.contains('updated_at') &&
                                                !name.contains('deleted_at');
                                          })
                                          .take(4) 
                                          .map((col) {
                                            final displayValue = _getDisplayValue(record, col.name);

                                            if (displayValue.isEmpty) {
                                              return const SizedBox.shrink();
                                            }

                                            final isForeignKey = col.name.toLowerCase().endsWith('_id');

                                            if (isForeignKey && displayValue.contains(':')) {
                                              return Padding(
                                                padding: const EdgeInsets.only(bottom: 6),
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Icon(
                                                      Icons.link,
                                                      size: 16,
                                                      color: AppColors.primary,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        displayValue,
                                                        style: AppStyles.bodyMedium.copyWith(
                                                          color: AppColors.primary,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }

                                            return Padding(
                                              padding: const EdgeInsets.only(bottom: 6),
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  SizedBox(
                                                    width: 100,
                                                    child: Text(
                                                      '${col.name}:',
                                                      style: AppStyles.bodySmall.copyWith(
                                                        fontWeight: FontWeight.w600,
                                                        color: AppColors.textSecondary,
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      displayValue,
                                                      style: AppStyles.bodyMedium,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }),

                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          TextButton.icon(
                                            onPressed: () {
                                              if (pkValue != null) {
                                                Navigator.pushNamed(
                                                  context,
                                                  '/table/${widget.tableName}/edit/$pkValue',
                                                ).then((_) => _loadData());
                                              }
                                            },
                                            icon: const Icon(AppIcons.edit, size: 18),
                                            label: const Text('Editar'),
                                            style: TextButton.styleFrom(
                                              foregroundColor: AppColors.primary,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          TextButton.icon(
                                            onPressed: () => _confirmDelete(record, pk),
                                            icon: const Icon(AppIcons.delete, size: 18),
                                            label: const Text('Eliminar'),
                                            style: TextButton.styleFrom(
                                              foregroundColor: AppColors.error,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                            );
                          },
                        ),
                      ),
                    ),
                    PaginationControls(
                      currentPage: provider.currentPage,
                      totalPages: provider.totalPages,
                      totalRecords: provider.totalRecords,
                      recordsPerPage: provider.records.length,
                      pageSize: provider.pageSize,
                      onPageChanged: _handlePageChanged,
                      onPageSizeChanged: _handlePageSizeChanged,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 140),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.pushNamed(context, '/table/${widget.tableName}/create')
                .then((_) => _loadData());
          },
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          icon: const Icon(AppIcons.add),
          label: const Text('Nuevo'),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> record, String? pkColumn) async {
    if (pkColumn == null) return;
    
    final pkValue = _getValueFuzzy(record, pkColumn);

    final confirmed = await NotificationService.showConfirmDialog(
      context,
      title: AppStrings.delete,
      message: AppStrings.confirmDeleteRecord,
      confirmText: AppStrings.delete,
      cancelText: AppStrings.cancel,
      confirmColor: AppColors.error,
    );

    if (confirmed && mounted && pkValue != null) {
      final dbProvider = context.read<DatabaseSelectorProvider>();
      final crudProvider = context.read<DynamicCrudProvider>();
      final authProvider = context.read<AuthProvider>();
      final metadataProvider = context.read<MetadataProvider>(); // Importante

      // Seguridad: Verificar metadata
      if (metadataProvider.metadata == null) return;

      LoadingOverlayService.show(context, text: 'Eliminando registro...');

      try {
        final success = await crudProvider.deleteRecord(
          metadata: metadataProvider.metadata!, // <--- NUEVO: Pasamos metadata
          databaseName: dbProvider.currentDatabaseName!,
          tableName: widget.tableName,
          id: pkValue,
          token: authProvider.currentUser?.token ?? '',
        );

        if (!mounted) return;

        LoadingOverlayService.hide();

        if (success) {
          NotificationService.showSuccess(
            context,
            AppStrings.successDelete,
          );
          _loadData();
        } else {
          NotificationService.showError(
            context,
            crudProvider.errorMessage ?? AppStrings.errorGeneric,
          );
        }
      } catch (e) {
        LoadingOverlayService.hide();
        if (mounted) {
          NotificationService.showError(
            context,
            'Error al eliminar el registro',
          );
        }
      }
    }
  }
}