import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:herramienta_case/core/constants/app_colors.dart';
import 'package:herramienta_case/core/constants/app_icons.dart';
import 'package:herramienta_case/core/constants/app_strings.dart';
import 'package:herramienta_case/core/constants/app_styles.dart';
import 'package:herramienta_case/core/config/routes.dart';
import 'package:herramienta_case/core/utils/notification_service.dart';
import 'package:herramienta_case/modules/auth/presentation/providers/auth_provider.dart';
import 'package:herramienta_case/modules/database_selector/presentation/providers/database_selector_provider.dart';
import 'package:herramienta_case/modules/dynamic_crud/presentation/providers/metadata_provider.dart';
import 'package:herramienta_case/modules/home/presentation/providers/recent_activity_provider.dart';
import 'package:herramienta_case/modules/home/domain/services/table_filter_service.dart';
import 'package:herramienta_case/modules/home/domain/models/database_stats_model.dart';
import 'package:herramienta_case/modules/home/presentation/widgets/home_drawer.dart';
import 'package:herramienta_case/modules/home/presentation/widgets/stat_card.dart';
import 'package:herramienta_case/modules/home/presentation/widgets/quick_action_button.dart';
import 'package:herramienta_case/modules/home/presentation/widgets/featured_table_card.dart';
import 'package:herramienta_case/modules/home/presentation/widgets/recent_activity_item.dart';
import 'package:herramienta_case/modules/notifications/presentation/providers/notification_provider.dart';

/// Pantalla principal (Home) rediseñada profesionalmente
class NewHomeScreen extends StatefulWidget {
  const NewHomeScreen({super.key});

  @override
  State<NewHomeScreen> createState() => _NewHomeScreenState();
}

class _NewHomeScreenState extends State<NewHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMetadata();
      _initRecentActivity();
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

  void _initRecentActivity() {
    final activityProvider = context.read<RecentActivityProvider>();
    activityProvider.init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      drawer: const HomeDrawer(),
      body: Consumer3<AuthProvider, DatabaseSelectorProvider, MetadataProvider>(
        builder: (context, authProvider, dbProvider, metadataProvider, child) {
          if (metadataProvider.isLoading) {
            return _buildLoadingState();
          }

          if (metadataProvider.errorMessage != null) {
            return _buildErrorState(metadataProvider.errorMessage!);
          }

          return RefreshIndicator(
            onRefresh: () async => _loadMetadata(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con info del usuario y BD
                  _buildHeader(authProvider, dbProvider),

                  // Estadísticas de la BD
                  _buildStatsSection(metadataProvider),

                  // Accesos rápidos
                  _buildQuickActionsSection(context),

                  // Tablas destacadas
                  _buildFeaturedTablesSection(metadataProvider),

                  // Actividad reciente
                  _buildRecentActivitySection(),

                  const SizedBox(height: AppStyles.paddingLarge),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Dashboard'),
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadMetadata,
          tooltip: 'Actualizar',
        ),
        Consumer<NotificationProvider>(
          builder: (context, notificationProvider, _) {
            final hasUnread = notificationProvider.hasUnread;
            final unreadCount = notificationProvider.unreadCount;

            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    AppRoutes.navigateTo(context, AppRoutes.notifications);
                  },
                  tooltip: 'Notificaciones',
                ),
                if (hasUnread)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.white,
                          width: 2,
                        ),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildHeader(AuthProvider authProvider, DatabaseSelectorProvider dbProvider) {
    final userName = authProvider.currentUser?.nombre ?? 'Usuario';
    final databaseName = dbProvider.currentDatabaseName ?? 'Base de Datos';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppStyles.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.divider,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.primaryGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  AppIcons.person,
                  size: 28,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(width: AppStyles.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${AppStrings.welcome},',
                      style: AppStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userName,
                      style: AppStyles.heading2.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppStyles.paddingSmall),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.storage,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    databaseName,
                    style: AppStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(MetadataProvider metadataProvider) {
    final stats = DatabaseStatsModel.fromMetadata(
      databaseName: metadataProvider.databaseName ?? '',
      tablesCount: metadataProvider.tables.length,
      columnsCount: metadataProvider.metadata?.columns.length ?? 0,
      foreignKeysCount: metadataProvider.metadata?.fkInfo.length ?? 0,
      indexesCount: metadataProvider.metadata?.indexes.length ?? 0,
      viewsCount: metadataProvider.metadata?.views.length ?? 0,
    );

    return Padding(
      padding: const EdgeInsets.all(AppStyles.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estadísticas',
            style: AppStyles.heading3,
          ),
          const SizedBox(height: AppStyles.paddingMedium),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppStyles.paddingSmall,
            crossAxisSpacing: AppStyles.paddingSmall,
            childAspectRatio: 3.2,
            children: [
              StatCard(
                label: 'Tablas',
                value: '${stats.totalTables}',
                icon: Icons.table_chart,
                color: AppColors.primary,
              ),
              StatCard(
                label: 'Columnas',
                value: '${stats.totalColumns}',
                icon: Icons.view_column,
                color: AppColors.secondary,
              ),
              StatCard(
                label: 'Relaciones',
                value: '${stats.totalForeignKeys}',
                icon: Icons.link,
                color: AppColors.success,
              ),
              StatCard(
                label: 'Vistas',
                value: '${stats.totalViews}',
                icon: Icons.visibility,
                color: AppColors.warning,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppStyles.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Accesos rápidos',
            style: AppStyles.heading3,
          ),
          const SizedBox(height: AppStyles.paddingMedium),
          Wrap(
            spacing: AppStyles.paddingSmall,
            runSpacing: AppStyles.paddingSmall,
            children: [
              QuickActionButton(
                label: 'Ver todas las tablas',
                icon: Icons.table_rows,
                color: AppColors.primary,
                onTap: () {
                  AppRoutes.navigateTo(context, AppRoutes.tablesMenu);
                },
              ),
              QuickActionButton(
                label: 'Exportar datos',
                icon: Icons.download,
                color: AppColors.success,
                onTap: () {
                  AppRoutes.navigateTo(context, AppRoutes.exportData);
                },
              ),
              QuickActionButton(
                label: 'Estadísticas',
                icon: Icons.bar_chart,
                color: AppColors.warning,
                onTap: () {
                  NotificationService.showInfo(context, AppStrings.featureInDevelopment);
                },
              ),
              QuickActionButton(
                label: 'Configuración',
                icon: Icons.settings,
                color: AppColors.textSecondary,
                onTap: () {
                  NotificationService.showInfo(context, AppStrings.featureInDevelopment);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedTablesSection(MetadataProvider metadataProvider) {
    final importantTables = TableFilterService.getImportantTables(
      metadataProvider.tables,
      maxTables: 8,
    );

    if (importantTables.isEmpty) {
      return const SizedBox.shrink();
    }

    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.success,
      AppColors.warning,
      AppColors.info,
      AppColors.accent,
    ];

    return Padding(
      padding: const EdgeInsets.all(AppStyles.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tablas principales',
                style: AppStyles.heading3,
              ),
              TextButton(
                onPressed: () {
                  AppRoutes.navigateTo(context, AppRoutes.tablesMenu);
                },
                child: const Text('Ver todas'),
              ),
            ],
          ),
          const SizedBox(height: AppStyles.paddingMedium),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _getCrossAxisCount(context),
              mainAxisSpacing: AppStyles.paddingMedium,
              crossAxisSpacing: AppStyles.paddingMedium,
              childAspectRatio: 0.95,
            ),
            itemCount: importantTables.length,
            itemBuilder: (context, index) {
              final table = importantTables[index];
              final color = colors[index % colors.length];
              final emoji = TableFilterService.getTableIcon(table.table);

              return FeaturedTableCard(
                table: table,
                emoji: emoji,
                color: color,
                onTap: () {
                  // Registrar actividad
                  context.read<RecentActivityProvider>().addActivity(
                        tableName: table.table,
                        action: 'view',
                      );

                  // Navegar a la tabla
                  Navigator.pushNamed(context, '/table/${table.table}');
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Consumer<RecentActivityProvider>(
      builder: (context, activityProvider, child) {
        if (activityProvider.activities.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.all(AppStyles.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Actividad reciente',
                    style: AppStyles.heading3,
                  ),
                  TextButton(
                    onPressed: () async {
                      final confirmed = await NotificationService.showConfirmDialog(
                        context,
                        title: 'Limpiar actividad',
                        message: '¿Desea limpiar toda la actividad reciente?',
                        confirmText: 'Limpiar',
                        cancelText: 'Cancelar',
                        confirmColor: AppColors.error,
                      );
                      if (confirmed && context.mounted) {
                        context.read<RecentActivityProvider>().clearActivities();
                      }
                    },
                    child: const Text('Limpiar'),
                  ),
                ],
              ),
              const SizedBox(height: AppStyles.paddingSmall),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                  border: Border.all(color: AppColors.border),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: activityProvider.activities.take(5).length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final activity = activityProvider.activities[index];
                    return RecentActivityItem(activity: activity);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: AppStyles.paddingMedium),
          Text(
            'Cargando información...',
            style: AppStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String errorMessage) {
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
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppStyles.paddingLarge),
            Text(
              'Error al cargar',
              style: AppStyles.heading3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppStyles.paddingSmall),
            Text(
              errorMessage,
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
            ),
          ],
        ),
      ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) {
      return 2; // Móvil
    } else if (width < 1024) {
      return 3; // Tablet
    } else {
      return 4; // Desktop
    }
  }
}
