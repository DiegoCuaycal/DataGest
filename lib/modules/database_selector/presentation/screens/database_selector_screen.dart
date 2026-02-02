import 'dart:convert'; // Para jsonEncode
import 'dart:io'; // Para leer el archivo
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart'; // Para seleccionar el archivo
import 'package:provider/provider.dart';
import 'package:herramienta_case/core/constants/app_colors.dart';
import 'package:herramienta_case/core/constants/app_styles.dart';
import 'package:herramienta_case/core/utils/notification_service.dart';
import '../providers/database_selector_provider.dart';
import '../widgets/database_card.dart';

// --- IMPORTS NUEVOS DE TU LÓGICA ---
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
      // Cargar bases de datos desde la API al iniciar
      context.read<DatabaseSelectorProvider>().loadAvailableDatabases(useMock: false);
    });
  }

  // ===========================================================================
  // LÓGICA DE IMPORTACIÓN (EL CEREBRO NUEVO)
  // ===========================================================================
  Future<void> _handleImportDatabase() async {
    try {
      // 1. SELECCIONAR ARCHIVO (Lógica corregida para Drive/Android)
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,  // Permite seleccionar desde Drive
        withData: true,      // CRÍTICO: Obtiene los bytes en memoria
      );

      if (result != null && result.files.isNotEmpty) {
        final pickedFile = result.files.single;

        // Validar extensión manualmente (porque usamos FileType.any)
        final fileName = pickedFile.name.toLowerCase();
        final validExtensions = ['.sql', '.txt'];
        final hasValidExtension = validExtensions.any((ext) => fileName.endsWith(ext));

        if (!hasValidExtension) {
          if (mounted) {
            NotificationService.showError(
              context,
              '⚠️ Solo se permiten archivos .sql o .txt\nSeleccionaste: ${pickedFile.name}',
            );
          }
          return;
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📂 Procesando y enviando archivo...'),
            backgroundColor: AppColors.primary,
          ),
        );

        // 2. LEER CONTENIDO (Compatible con Drive)
        String content;

        if (pickedFile.bytes != null) {
          // Archivo de Drive/Cloud - decodificar bytes
          content = utf8.decode(pickedFile.bytes!, allowMalformed: true);
        } else if (pickedFile.path != null) {
          // Archivo local físico - leer desde path
          final file = File(pickedFile.path!);
          content = await file.readAsString();
        } else {
          throw Exception('No se pudo leer el archivo (bytes y path nulos)');
        }

        final dbName = pickedFile.name.split('.').first;

        // 3. EL TRADUCTOR (Parser)
        // Esto devuelve: { "database_name": "...", "tables": [...], "columns": [...], "pk_Info": [...] }
        final schemaMap = SqlParserService.parseSqlToSchemaMap(content, dbName);

        // ============================================================
        // 🔴 4. EMPAQUETADO (LA CORRECCIÓN ESTÁ AQUÍ)
        // ============================================================
        // NO extraigas ['tables']. Codifica el MAPA COMPLETO.
        final jsonTablasString = jsonEncode(schemaMap);

        // DEBUG: Debe empezar con llave { NO con corchete [
        debugPrint("📦 JSON COMPLETO A ENVIAR: $jsonTablasString");

        if (!mounted) return;

        // 5. EL ENVÍO
        final authProvider = context.read<AuthProvider>();

        final success = await authProvider.createModule(
          dbName: dbName,
          jsonTables: jsonTablasString // Enviamos el objeto completo
        );

        if (!mounted) return;

        // 6. RESULTADO
        if (success) {
          NotificationService.showSuccess(
            context,
            '✅ Base de datos "$dbName" creada exitosamente',
          );
          // Recargar lista
          context.read<DatabaseSelectorProvider>().loadAvailableDatabases(useMock: false);
        } else {
          NotificationService.showError(
            context,
            '❌ Error al crear la base de datos (Backend rechazó el formato)',
          );
        }
      }
    } catch (e) {
      debugPrint("Error importando: $e");
      if (mounted) {
        NotificationService.showError(
          context,
          'Error al procesar el archivo: ${e.toString()}',
        );
      }
    }
  }
  // ===========================================================================

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
      // --- DOS BOTONES FLOTANTES ---
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // BOTÓN IMPORTAR BD (nuevo)
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
          // BOTÓN CREAR BD (original - intocable)
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