import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:herramienta_case/core/constants/app_colors.dart';
import 'package:herramienta_case/core/constants/app_styles.dart';
import 'package:herramienta_case/core/utils/notification_service.dart';
import '../providers/database_selector_provider.dart';
import '../widgets/database_card.dart';
import 'package:herramienta_case/modules/dynamic_crud/domain/services/sql_parser_service.dart';
import 'package:herramienta_case/modules/auth/presentation/providers/auth_provider.dart';

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
      context.read<DatabaseSelectorProvider>().loadAvailableDatabases(useMock: false);
    });
  }

  /// Prompts the user to pick a `.sql` or `.txt` file, parses it into the
  /// backend schema format, and sends it to the API to provision a new
  /// database module.
  ///
  /// Compatible with both local files and cloud-sourced files (e.g. Google
  /// Drive) by reading raw bytes when a file path is unavailable.
  Future<void> _handleImportDatabase() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final pickedFile = result.files.single;

        final fileName = pickedFile.name.toLowerCase();
        final validExtensions = ['.sql', '.txt'];
        final hasValidExtension = validExtensions.any((ext) => fileName.endsWith(ext));

        if (!hasValidExtension) {
          if (mounted) {
            NotificationService.showError(
              context,
              'Solo se permiten archivos .sql o .txt\nSeleccionaste: ${pickedFile.name}',
            );
          }
          return;
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Procesando y enviando archivo...'),
            backgroundColor: AppColors.primary,
          ),
        );

        String content;

        if (pickedFile.bytes != null) {
          content = utf8.decode(pickedFile.bytes!, allowMalformed: true);
        } else if (pickedFile.path != null) {
          final file = File(pickedFile.path!);
          content = await file.readAsString();
        } else {
          throw Exception('No se pudo leer el archivo (bytes y path nulos)');
        }

        final dbName = pickedFile.name.split('.').first;

        final schemaMap = SqlParserService.parseSqlToSchemaMap(content, dbName);
        final jsonTablasString = jsonEncode(schemaMap);

        if (!mounted) return;

        final authProvider = context.read<AuthProvider>();

        final success = await authProvider.createModule(
          dbName: dbName,
          jsonTables: jsonTablasString,
        );

        if (!mounted) return;

        if (success) {
          NotificationService.showSuccess(
            context,
            'Base de datos "$dbName" creada exitosamente',
          );
          context.read<DatabaseSelectorProvider>().loadAvailableDatabases(useMock: false);
        } else {
          NotificationService.showError(
            context,
            'Error al crear la base de datos',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(
          context,
          'Error al procesar el archivo: ${e.toString()}',
        );
      }
    }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
               context.read<DatabaseSelectorProvider>().loadAvailableDatabases(useMock: false);
            },
          )
        ],
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
        children: [
          FloatingActionButton.extended(
            heroTag: 'importar_bd',
            onPressed: _handleImportDatabase,
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            icon: const Icon(Icons.upload_file),
            label: const Text('Importar BD'),
            tooltip: 'Importar archivo SQL o TXT',
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'crear_bd',
            onPressed: () {
              Navigator.pushNamed(context, '/create-database');
            },
            backgroundColor: AppColors.success,
            foregroundColor: AppColors.white,
            icon: const Icon(Icons.add),
            label: const Text('Crear BD'),
            tooltip: 'Crear nueva base de datos',
          ),
        ],
      ),
    );
  }
}