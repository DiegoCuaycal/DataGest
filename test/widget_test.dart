
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:herramienta_case/core/network/api_client.dart';
import 'package:herramienta_case/modules/auth/data/datasources/auth_remote_datasource.dart';
import 'package:herramienta_case/modules/auth/data/repositories/auth_repository.dart';
import 'package:herramienta_case/modules/database_selector/data/datasources/database_remote_datasource.dart';
import 'package:herramienta_case/modules/database_selector/data/repositories/database_repository.dart';
import 'package:herramienta_case/modules/database_creator/data/datasources/database_creator_remote_datasource.dart';
import 'package:herramienta_case/modules/database_creator/data/repositories/database_creator_repository.dart';
import 'package:herramienta_case/modules/dynamic_crud/data/datasources/dynamic_remote_datasource.dart';
import 'package:herramienta_case/modules/dynamic_crud/data/repositories/dynamic_crud_repository.dart';
import 'package:herramienta_case/modules/export/data/repositories/export_repository.dart';
import 'package:herramienta_case/modules/export/domain/services/export_service.dart';
import 'package:herramienta_case/main.dart';

void main() {
  testWidgets('App initialization test', (WidgetTester tester) async {
    // Inicializar SharedPreferences con valores mock
    SharedPreferences.setMockInitialValues({});
    final sharedPreferences = await SharedPreferences.getInstance();

    // Crear instancias necesarias para el test
    final apiClient = ApiClient();
    final httpClient = http.Client();

    // Auth repository
    final authRemoteDataSource = AuthRemoteDataSource(apiClient: apiClient);
    final authRepository = AuthRepository(
      remoteDataSource: authRemoteDataSource,
      sharedPreferences: sharedPreferences,
    );

    // Database repository
    final databaseRemoteDataSource = DatabaseRemoteDataSource(client: httpClient);
    final databaseRepository = DatabaseRepository(
      remoteDataSource: databaseRemoteDataSource,
    );

    // Database creator repository
    final databaseCreatorRemoteDataSource = DatabaseCreatorRemoteDataSource(client: httpClient);
    final databaseCreatorRepository = DatabaseCreatorRepository(
      remoteDataSource: databaseCreatorRemoteDataSource,
    );

    // Dynamic CRUD repository
    final dynamicRemoteDataSource = DynamicRemoteDataSource(client: httpClient);
    final dynamicCrudRepository = DynamicCrudRepository(
      remoteDataSource: dynamicRemoteDataSource,
    );

    // Export repository
    final exportService = ExportService();
    final exportRepository = ExportRepository(
      remoteDataSource: dynamicRemoteDataSource,
      exportService: exportService,
    );

    // Construir la app con las dependencias necesarias
    await tester.pumpWidget(MyApp(
      authRepository: authRepository,
      databaseRepository: databaseRepository,
      databaseCreatorRepository: databaseCreatorRepository,
      dynamicCrudRepository: dynamicCrudRepository,
      exportRepository: exportRepository,
    ));

    // Verificar que la app se inicializa correctamente
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
