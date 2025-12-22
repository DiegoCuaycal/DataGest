import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:herramienta_case/core/config/app_config.dart';
import 'package:herramienta_case/core/config/env_config.dart';
import 'package:herramienta_case/core/config/routes.dart';
import 'package:herramienta_case/core/constants/app_colors.dart';
import 'package:herramienta_case/core/network/api_client.dart';
import 'package:herramienta_case/modules/auth/data/datasources/auth_remote_datasource.dart';
import 'package:herramienta_case/modules/auth/data/repositories/auth_repository.dart';
import 'package:herramienta_case/modules/auth/presentation/providers/auth_provider.dart';
import 'package:herramienta_case/modules/database_selector/data/datasources/database_remote_datasource.dart';
import 'package:herramienta_case/modules/database_selector/data/repositories/database_repository.dart';
import 'package:herramienta_case/modules/database_selector/presentation/providers/database_selector_provider.dart';
import 'package:herramienta_case/modules/database_creator/data/datasources/database_creator_remote_datasource.dart';
import 'package:herramienta_case/modules/database_creator/data/repositories/database_creator_repository.dart';
import 'package:herramienta_case/modules/database_creator/presentation/providers/database_creator_provider.dart';
import 'package:herramienta_case/modules/dynamic_crud/data/datasources/dynamic_remote_datasource.dart';
import 'package:herramienta_case/modules/dynamic_crud/data/repositories/dynamic_crud_repository.dart';
import 'package:herramienta_case/modules/dynamic_crud/presentation/providers/metadata_provider.dart';
import 'package:herramienta_case/modules/dynamic_crud/presentation/providers/dynamic_crud_provider.dart';
import 'package:herramienta_case/modules/home/presentation/providers/recent_activity_provider.dart';
import 'package:herramienta_case/modules/notifications/presentation/providers/notification_provider.dart';
import 'package:herramienta_case/modules/export/presentation/providers/export_provider.dart';
import 'package:herramienta_case/modules/export/data/repositories/export_repository.dart';
import 'package:herramienta_case/modules/export/domain/services/export_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar variables de entorno
  await EnvConfig.init();

  // Inicializar SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  // Inicializar ApiClient
  final apiClient = ApiClient();
  await apiClient.init();

  // Inicializar HTTP client
  final httpClient = http.Client();

  // Inicializar repositorios
  final authRemoteDataSource = AuthRemoteDataSource(apiClient: apiClient);
  final authRepository = AuthRepository(
    remoteDataSource: authRemoteDataSource,
    sharedPreferences: sharedPreferences,
  );

  final databaseRemoteDataSource = DatabaseRemoteDataSource(client: httpClient);
  final databaseRepository = DatabaseRepository(
    remoteDataSource: databaseRemoteDataSource,
  );

  final databaseCreatorRemoteDataSource = DatabaseCreatorRemoteDataSource(client: httpClient);
  final databaseCreatorRepository = DatabaseCreatorRepository(
    remoteDataSource: databaseCreatorRemoteDataSource,
  );

  final dynamicRemoteDataSource = DynamicRemoteDataSource(client: httpClient);
  final dynamicCrudRepository = DynamicCrudRepository(
    remoteDataSource: dynamicRemoteDataSource,
  );

  final exportService = ExportService();
  final exportRepository = ExportRepository(
    remoteDataSource: dynamicRemoteDataSource,
    exportService: exportService,
  );

  runApp(MyApp(
    authRepository: authRepository,
    databaseRepository: databaseRepository,
    databaseCreatorRepository: databaseCreatorRepository,
    dynamicCrudRepository: dynamicCrudRepository,
    exportRepository: exportRepository,
  ));
}

class MyApp extends StatelessWidget {
  final AuthRepository authRepository;
  final DatabaseRepository databaseRepository;
  final DatabaseCreatorRepository databaseCreatorRepository;
  final DynamicCrudRepository dynamicCrudRepository;
  final ExportRepository exportRepository;

  const MyApp({
    super.key,
    required this.authRepository,
    required this.databaseRepository,
    required this.databaseCreatorRepository,
    required this.dynamicCrudRepository,
    required this.exportRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => DatabaseSelectorProvider(
            repository: databaseRepository,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => DatabaseCreatorProvider(
            repository: databaseCreatorRepository,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authRepository: authRepository)..init(),
        ),
        ChangeNotifierProvider(
          create: (_) => MetadataProvider(
            repository: dynamicCrudRepository,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => DynamicCrudProvider(
            repository: dynamicCrudRepository,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => RecentActivityProvider()..init(),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider()..init(),
        ),
        ChangeNotifierProvider(
          create: (_) => ExportProvider(
            repository: exportRepository,
          ),
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp(
            title: AppConfig.appName,
            debugShowCheckedModeBanner: false,
            theme: _buildTheme(),

            // Ruta inicial: DatabaseSelector (sin autenticación)
            initialRoute: AppRoutes.selectDatabase,

            // Rutas de la aplicación
            routes: AppRoutes.getRoutes(),
            onGenerateRoute: AppRoutes.onGenerateRoute,
          );
        },
      ),
    );
  }

  /// Construye el tema de la aplicación
  ThemeData _buildTheme() {
    return ThemeData(
      primaryColor: AppColors.primary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        error: AppColors.error,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 2),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
      ),
      useMaterial3: true,
    );
  }
}
