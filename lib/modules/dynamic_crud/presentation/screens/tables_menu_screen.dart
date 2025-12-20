import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:herramienta_case/core/constants/app_colors.dart';
import 'package:herramienta_case/core/constants/app_styles.dart';
import 'package:herramienta_case/core/utils/notification_service.dart';
import '../providers/metadata_provider.dart';
import '../../../database_selector/presentation/providers/database_selector_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/table_menu_item.dart';

class TablesMenuScreen extends StatefulWidget {
  const TablesMenuScreen({super.key});

  @override
  State<TablesMenuScreen> createState() => _TablesMenuScreenState();
}

class _TablesMenuScreenState extends State<TablesMenuScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMetadata();
    });
  }

  void _loadMetadata() {
    final dbProvider = context.read<DatabaseSelectorProvider>();
    final metadataProvider = context.read<MetadataProvider>();
    final authProvider = context.read<AuthProvider>();

    if (dbProvider.currentDatabaseName != null) {
      metadataProvider.loadMetadata(
        databaseName: dbProvider.currentDatabaseName!,
        token: authProvider.currentUser?.token ?? '',
        useMock: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dbProvider = context.watch<DatabaseSelectorProvider>();
    final metadataProvider = context.watch<MetadataProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(dbProvider.currentDatabaseName ?? 'Base de Datos'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMetadata,
          ),
        ],
      ),
      body: metadataProvider.isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                  const SizedBox(height: AppStyles.paddingMedium),
                  Text(
                    'Cargando tablas...',
                    style: AppStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : metadataProvider.errorMessage != null
              ? Center(
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
                            Icons.error,
                            size: 64,
                            color: AppColors.error,
                          ),
                        ),
                        const SizedBox(height: AppStyles.paddingLarge),
                        Text(
                          'Error al cargar tablas',
                          style: AppStyles.heading3,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppStyles.paddingSmall),
                        Text(
                          metadataProvider.errorMessage!,
                          textAlign: TextAlign.center,
                          style: AppStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppStyles.paddingLarge),
                        ElevatedButton.icon(
                          onPressed: _loadMetadata,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
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
                )
              : metadataProvider.tables.isEmpty
                  ? Center(
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
                              Icons.table_chart_outlined,
                              size: 64,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppStyles.paddingLarge),
                          Text(
                            'No hay tablas disponibles',
                            style: AppStyles.heading3.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppStyles.paddingMedium),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: AppColors.primaryGradient,
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.storage,
                                color: AppColors.white,
                              ),
                              const SizedBox(width: AppStyles.paddingMedium),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Base de datos',
                                      style: AppStyles.caption.copyWith(
                                        color: AppColors.white.withValues(alpha: 0.8),
                                      ),
                                    ),
                                    Text(
                                      dbProvider.currentDatabaseName ?? "",
                                      style: AppStyles.bodyMedium.copyWith(
                                        color: AppColors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(AppStyles.paddingMedium),
                            itemCount: metadataProvider.tables.length,
                            itemBuilder: (context, index) {
                              final table = metadataProvider.tables[index];
                              return TableMenuItem(
                                table: table,
                                onTap: () {
                                  NotificationService.showInfo(
                                    context,
                                    'Abriendo tabla "${table.table}"',
                                  );
                                  Navigator.pushNamed(
                                    context,
                                    '/table/${table.table}',
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
    );
  }
}
