import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:herramienta_case/core/constants/app_colors.dart';
import 'package:herramienta_case/core/constants/app_styles.dart';
import 'package:herramienta_case/core/utils/notification_service.dart';
import '../providers/database_selector_provider.dart';
import '../widgets/database_card.dart';

class DatabaseSelectorScreen extends StatefulWidget {
  const DatabaseSelectorScreen({super.key});

  @override
  State<DatabaseSelectorScreen> createState() => _DatabaseSelectorScreenState();
}

class _DatabaseSelectorScreenState extends State<DatabaseSelectorScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load databases from API
      context.read<DatabaseSelectorProvider>().loadAvailableDatabases(useMock: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Seleccionar Base de Datos'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: Consumer<DatabaseSelectorProvider>(
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
                    'Cargando bases de datos...',
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
                        Icons.error_outline,
                        size: 64,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: AppStyles.paddingLarge),
                    Text(
                      'Error al cargar bases de datos',
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
                      onPressed: () {
                        provider.loadAvailableDatabases(useMock: false);
                      },
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
            );
          }

          if (provider.availableDatabases.isEmpty) {
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
                      Icons.dns,
                      size: 64,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppStyles.paddingLarge),
                  Text(
                    'No hay bases de datos disponibles',
                    style: AppStyles.heading3.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
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
                      Icons.info_outline,
                      color: AppColors.white,
                    ),
                    const SizedBox(width: AppStyles.paddingMedium),
                    Expanded(
                      child: Text(
                        'Selecciona una base de datos para comenzar',
                        style: AppStyles.bodyMedium.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppStyles.paddingMedium),
                  itemCount: provider.availableDatabases.length,
                  itemBuilder: (context, index) {
                    final database = provider.availableDatabases[index];
                    return DatabaseCard(
                      database: database,
                      onTap: () {
                        provider.selectDatabase(database);
                        NotificationService.showSuccess(
                          context,
                          'Base de datos "${database.name}" seleccionada',
                        );
                        Navigator.pushNamed(context, '/login');
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'create_db_btn',
            onPressed: () {
              Navigator.pushNamed(context, '/create-database');
            },
            backgroundColor: AppColors.success,
            foregroundColor: AppColors.white,
            icon: const Icon(Icons.add),
            label: const Text('Crear BD'),
            tooltip: 'Crear nueva base de datos',
          ),
          const SizedBox(height: AppStyles.paddingMedium),
          FloatingActionButton.extended(
            heroTag: 'import_db_btn',
            onPressed: () async {
              final provider = context.read<DatabaseSelectorProvider>();
              final pickedFile = await provider.pickDatabaseFile();
              if (pickedFile != null && context.mounted) {
                final confirmed = await _showImportPreview(context, pickedFile);
                if (confirmed == true && context.mounted) {
                  final importedDatabase = provider.addImportedDatabase(pickedFile);
                  if (!context.mounted) return;
                  NotificationService.showSuccess(
                    context,
                    'Base de datos "${importedDatabase.name}" importada',
                  );
                  Navigator.pushNamed(context, '/login');
                }
              }
            },
            backgroundColor: AppColors.secondary,
            foregroundColor: AppColors.white,
            icon: const Icon(Icons.upload_file),
            label: const Text('Importar'),
            tooltip: 'Importar base de datos',
          ),
        ],
      ),
    );
  }

  Future<bool?> _showImportPreview(BuildContext context, PickedDatabaseFile file) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppStyles.radiusLarge),
        ),
      ),
      builder: (_) => _ImportPreviewSheet(file: file),
    );
  }
}

class _ImportPreviewSheet extends StatelessWidget {
  final PickedDatabaseFile file;

  const _ImportPreviewSheet({required this.file});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppStyles.paddingLarge,
        right: AppStyles.paddingLarge,
        top: AppStyles.paddingLarge,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppStyles.paddingLarge,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppStyles.paddingLarge),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppStyles.paddingMedium),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                ),
                child: const Icon(Icons.upload_file, color: AppColors.secondary, size: 32),
              ),
              const SizedBox(width: AppStyles.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Revisar archivo', style: AppStyles.heading4),
                    const SizedBox(height: 4),
                    Text('Confirma que corresponde al motor correcto antes de importar',
                        style: AppStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppStyles.paddingLarge),
          _InfoRow(label: 'Nombre', value: file.name),
          const SizedBox(height: AppStyles.paddingSmall),
          _InfoRow(label: 'Ruta', value: file.path),
          const SizedBox(height: AppStyles.paddingSmall),
          _InfoRow(label: 'Tipo detectado', value: file.detectedType),
          const SizedBox(height: AppStyles.paddingSmall),
          _InfoRow(
            label: 'Extensión',
            value: file.name.contains('.') ? file.name.split('.').last.toUpperCase() : 'N/A',
          ),
          const SizedBox(height: AppStyles.paddingLarge),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.3)),
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: AppStyles.paddingMedium),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: AppStyles.paddingMedium),
                  ),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Confirmar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        SelectableText(
          value,
          style: AppStyles.bodyMedium,
        ),
      ],
    );
  }
}
