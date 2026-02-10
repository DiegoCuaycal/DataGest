import 'package:flutter/material.dart';
import 'package:herramienta_case/modules/splash/presentation/screens/splash_screen.dart';
import 'package:herramienta_case/modules/auth/presentation/screens/login_screen.dart';
import 'package:herramienta_case/modules/home/presentation/screens/new_home_screen.dart';
import 'package:herramienta_case/modules/case_tools/presentation/screens/tools_list_screen.dart';
import 'package:herramienta_case/modules/case_tools/presentation/screens/tool_detail_screen.dart';
import 'package:herramienta_case/modules/database_selector/presentation/screens/database_selector_screen.dart';
import 'package:herramienta_case/modules/database_creator/presentation/screens/database_creator_screen.dart';
import 'package:herramienta_case/modules/dynamic_crud/presentation/screens/tables_menu_screen.dart';
import 'package:herramienta_case/modules/dynamic_crud/presentation/screens/dynamic_list_screen.dart';
import 'package:herramienta_case/modules/dynamic_crud/presentation/screens/dynamic_form_screen.dart';
import 'package:herramienta_case/modules/notifications/presentation/screens/notifications_screen.dart';
import 'package:herramienta_case/modules/export/presentation/screens/export_options_screen.dart';
import 'package:herramienta_case/modules/settings/presentation/screens/settings_screen.dart';
import 'package:herramienta_case/modules/help/presentation/screens/help_screen.dart';


class AppRoutes {
  static const String splash = '/';
  static const String selectDatabase = '/select-database';
  static const String createDatabase = '/create-database';
  static const String login = '/login';
  static const String home = '/home';
  static const String tablesMenu = '/tables';
  static const String toolsList = '/tools';
  static const String toolDetail = '/tools/detail';
  static const String notifications = '/notifications';
  static const String exportData = '/export';
  static const String settings = '/settings';
  static const String help = '/help';

  /// Mapa de rutas de la aplicación
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      splash: (context) => const SplashScreen(),
      selectDatabase: (context) => const DatabaseSelectorScreen(),
      createDatabase: (context) => const DatabaseCreatorScreen(),
      login: (context) => const LoginScreen(),
      home: (context) => const NewHomeScreen(),
      tablesMenu: (context) => const TablesMenuScreen(),
      toolsList: (context) => const ToolsListScreen(),
      notifications: (context) => const NotificationsScreen(),
      exportData: (context) => const ExportOptionsScreen(),
      settings: (context) => const SettingsScreen(),
      help: (context) => const HelpScreen(),
    };
  }

  /// Generador de rutas dinámicas para pasar argumentos
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? '');

    if (uri.pathSegments.length == 2 && uri.pathSegments[0] == 'table') {
      final tableName = uri.pathSegments[1];
      return MaterialPageRoute(
        builder: (context) => DynamicListScreen(tableName: tableName),
      );
    }

    // Create route: /table/:tableName/create
    if (uri.pathSegments.length == 3 &&
        uri.pathSegments[0] == 'table' &&
        uri.pathSegments[2] == 'create') {
      final tableName = uri.pathSegments[1];
      return MaterialPageRoute(
        builder: (context) => DynamicFormScreen(
          tableName: tableName,
          isEdit: false,
        ),
      );
    }

    // Edit route: /table/:tableName/edit/:id
    if (uri.pathSegments.length == 4 &&
        uri.pathSegments[0] == 'table' &&
        uri.pathSegments[2] == 'edit') {
      final tableName = uri.pathSegments[1];
      final recordId = uri.pathSegments[3];
      return MaterialPageRoute(
        builder: (context) => DynamicFormScreen(
          tableName: tableName,
          recordId: recordId,
          isEdit: true,
        ),
      );
    }

    switch (settings.name) {
      case toolDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (context) => ToolDetailScreen(
            toolId: args?['toolId'] ?? 0,
          ),
        );
      default:
        return null;
    }
  }

  /// Navegar a una ruta y limpiar el historial
  static void navigateAndRemoveUntil(
    BuildContext context,
    String routeName,
  ) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
    );
  }

  /// Navegar a una ruta
  static Future<T?> navigateTo<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.of(context).pushNamed<T>(
      routeName,
      arguments: arguments,
    );
  }

  /// Retroceder a la pantalla anterior
  static void goBack(BuildContext context, {Object? result}) {
    Navigator.of(context).pop(result);
  }
}
