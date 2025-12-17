import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:herramienta_case/core/constants/app_colors.dart';
import 'package:herramienta_case/core/constants/app_icons.dart';
import 'package:herramienta_case/core/constants/app_strings.dart';
import 'package:herramienta_case/core/constants/app_styles.dart';
import 'package:herramienta_case/core/utils/notification_service.dart';
import '../providers/dynamic_crud_provider.dart';
import '../providers/metadata_provider.dart';
import '../../../database_selector/presentation/providers/database_selector_provider.dart';
import '../../../home/presentation/providers/recent_activity_provider.dart';

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

  void _loadData() {
    final dbProvider = context.read<DatabaseSelectorProvider>();
    final crudProvider = context.read<DynamicCrudProvider>();

    if (dbProvider.currentDatabaseName != null) {
      crudProvider.loadTableRecords(
        databaseName: dbProvider.currentDatabaseName!,
        tableName: widget.tableName,
        token: 'mock_token',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final metadataProvider = context.watch<MetadataProvider>();

    final columns = metadataProvider.getColumnsForTable(widget.tableName);
    final pkInfo = metadataProvider.metadata?.getPrimaryKeysForTable(widget.tableName);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.tableName),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(AppIcons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Consumer<DynamicCrudProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
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

          if (provider.errorMessage != null) {
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
                    AppStrings.noRecords,
                    style: AppStyles.heading3.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppStyles.paddingSmall),
                  Text(
                    AppStrings.addNewRecord,
                    style: AppStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                columns: columns.map((col) {
                  return DataColumn(
                    label: Text(
                      col.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList()
                  ..add(const DataColumn(label: Text('Acciones'))),
                rows: provider.records.map((record) {
                  return DataRow(
                    cells: columns.map((col) {
                      return DataCell(
                        Text(record[col.name]?.toString() ?? ''),
                      );
                    }).toList()
                      ..add(
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  AppIcons.edit,
                                  size: 20,
                                  color: AppColors.primary,
                                ),
                                onPressed: () {
                                  final pk = pkInfo?.first.column;
                                  if (pk != null) {
                                    Navigator.pushNamed(
                                      context,
                                      '/table/${widget.tableName}/edit/${record[pk]}',
                                    );
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  AppIcons.delete,
                                  size: 20,
                                  color: AppColors.error,
                                ),
                                onPressed: () => _confirmDelete(record, pkInfo?.first.column),
                              ),
                            ],
                          ),
                        ),
                      ),
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/table/${widget.tableName}/create');
        },
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        child: const Icon(AppIcons.add),
      ),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> record, String? pkColumn) async {
    if (pkColumn == null) return;

    final confirmed = await NotificationService.showConfirmDialog(
      context,
      title: AppStrings.delete,
      message: AppStrings.confirmDeleteRecord,
      confirmText: AppStrings.delete,
      cancelText: AppStrings.cancel,
      confirmColor: AppColors.error,
    );

    if (confirmed && mounted) {
      final dbProvider = context.read<DatabaseSelectorProvider>();
      final crudProvider = context.read<DynamicCrudProvider>();

      final success = await crudProvider.deleteRecord(
        databaseName: dbProvider.currentDatabaseName!,
        tableName: widget.tableName,
        id: record[pkColumn],
        token: 'mock_token',
      );

      if (mounted) {
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
      }
    }
  }
}
