import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:herramienta_case/core/constants/app_colors.dart';
import 'package:herramienta_case/core/constants/app_icons.dart';
import 'package:herramienta_case/core/constants/app_strings.dart';
import 'package:herramienta_case/core/constants/app_styles.dart';
import 'package:herramienta_case/core/services/loading_overlay_service.dart';
import 'package:herramienta_case/core/utils/notification_service.dart';
import 'package:herramienta_case/shared/widgets/search_filter_bar.dart';
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
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _registerActivity();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      _loadMoreData();
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9); // Cargar cuando llegue al 90%
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
    final authProvider = context.read<AuthProvider>();

    if (dbProvider.currentDatabaseName != null) {
      final token = authProvider.currentUser?.token ?? '';
      print('🔐 Token del usuario: ${token.isEmpty ? "VACÍO" : "${token.substring(0, 20)}..."}');

      crudProvider.loadTableRecords(
        databaseName: dbProvider.currentDatabaseName!,
        tableName: widget.tableName,
        token: token,
        resetData: true, // Siempre resetear cuando se carga manualmente
      );
    }
  }

  void _loadMoreData() {
    final dbProvider = context.read<DatabaseSelectorProvider>();
    final crudProvider = context.read<DynamicCrudProvider>();
    final authProvider = context.read<AuthProvider>();

    if (dbProvider.currentDatabaseName != null && crudProvider.hasMoreData) {
      crudProvider.loadMoreRecords(
        databaseName: dbProvider.currentDatabaseName!,
        tableName: widget.tableName,
        token: authProvider.currentUser?.token ?? '',
      );
    }
  }

  void _handleSearchChanged(String searchTerm) {
    final dbProvider = context.read<DatabaseSelectorProvider>();
    final crudProvider = context.read<DynamicCrudProvider>();
    final authProvider = context.read<AuthProvider>();

    if (dbProvider.currentDatabaseName != null) {
      crudProvider.setSearchTerm(searchTerm);
      crudProvider.loadTableRecords(
        databaseName: dbProvider.currentDatabaseName!,
        tableName: widget.tableName,
        token: authProvider.currentUser?.token ?? '',
        resetData: true, // Resetear datos al buscar
      );
    }
  }

  /// 🚨 FUNCIÓN SABUESO 🚨
  /// Busca el valor de una columna aunque el nombre venga diferente (Mayúsculas/Minúsculas)
  dynamic _getValueFuzzy(Map<String, dynamic> record, String columnName) {
    // 1. Intento directo
    if (record.containsKey(columnName)) return record[columnName];

    // 2. Intento Fuzzy (limpiando guiones y case)
    final cleanCol = columnName.replaceAll('_', '').toLowerCase();
    
    for (var key in record.keys) {
      final cleanKey = key.replaceAll('_', '').toLowerCase();
      if (cleanKey == cleanCol) {
        return record[key];
      }
    }
    return null;
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

                // Lista con infinite scroll
                return RefreshIndicator(
                  onRefresh: () async {
                    _loadData();
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(
                      left: AppStyles.paddingMedium,
                      right: AppStyles.paddingMedium,
                      top: AppStyles.paddingSmall,
                      bottom: 80, // Espacio para el FAB
                    ),
                    itemCount: provider.records.length + (provider.hasMoreData ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Mostrar indicador de carga al final
                      if (index >= provider.records.length) {
                        if (provider.isLoadingMore) {
                          return const Padding(
                            padding: EdgeInsets.all(AppStyles.paddingMedium),
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }

                      final record = provider.records[index];
                      final pk = pkInfo?.first.column;
                      // Buscar el valor del ID usando Fuzzy por si acaso
                      final pkValue = pk != null ? _getValueFuzzy(record, pk) : null;

                      // Card para cada registro (diseño móvil)
                      return Card(
                        margin: const EdgeInsets.only(bottom: AppStyles.paddingSmall),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                          onTap: () {
                            if (pkValue != null) {
                              Navigator.pushNamed(
                                context,
                                '/table/${widget.tableName}/edit/$pkValue',
                              ).then((_) => _loadData());
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(AppStyles.paddingMedium),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Mostrar todas las columnas excepto el ID y columnas de auditoría
                                ...columns
                                    .where((col) {
                                      final name = col.name.toLowerCase();
                                      // Excluir columnas de auditoría y el ID principal
                                      return name != pk?.toLowerCase() &&
                                          !name.contains('created_at') &&
                                          !name.contains('updated_at') &&
                                          !name.contains('deleted_at');
                                    })
                                    .take(4) // Mostrar máximo 4 campos para no sobrecargar
                                    .map((col) {
                                      // ✅ USAMOS LA FUNCIÓN FUZZY AQUÍ
                                      final value = _getValueFuzzy(record, col.name);
                                      
                                      // Si el valor es null o vacío, no mostrarlo
                                      if (value == null || value.toString().trim().isEmpty) {
                                        return const SizedBox.shrink();
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
                                                value.toString(),
                                                style: AppStyles.bodyMedium,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),

                                // Botones de acción
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
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/table/${widget.tableName}/create')
              .then((_) => _loadData());
        },
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        icon: const Icon(AppIcons.add),
        label: const Text('Nuevo'),
      ),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> record, String? pkColumn) async {
    if (pkColumn == null) return;
    
    // Usar Fuzzy también para encontrar el ID al borrar
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

      LoadingOverlayService.show(context, text: 'Eliminando registro...');

      try {
        final success = await crudProvider.deleteRecord(
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