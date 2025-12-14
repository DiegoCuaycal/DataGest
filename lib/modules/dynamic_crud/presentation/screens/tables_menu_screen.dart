import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
      appBar: AppBar(
        title: Text(dbProvider.currentDatabaseName ?? 'Base de Datos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMetadata,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _handleLogout();
              } else if (value == 'change_db') {
                _handleChangeDatabase();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'change_db',
                child: Row(
                  children: [
                    Icon(Icons.swap_horiz),
                    SizedBox(width: 8),
                    Text('Cambiar BD'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Cerrar sesión'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: metadataProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : metadataProvider.errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(metadataProvider.errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadMetadata,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : metadataProvider.tables.isEmpty
                  ? const Center(
                      child: Text('No hay tablas disponibles'),
                    )
                  : Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Base de datos: ${dbProvider.currentDatabaseName ?? ""}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: metadataProvider.tables.length,
                            itemBuilder: (context, index) {
                              final table = metadataProvider.tables[index];
                              return TableMenuItem(
                                table: table,
                                onTap: () {
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

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Está seguro de cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AuthProvider>().logout();
              context.read<MetadataProvider>().clearMetadata();
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }

  void _handleChangeDatabase() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar base de datos'),
        content: const Text('¿Desea cambiar a otra base de datos? Esto cerrará su sesión actual.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AuthProvider>().logout();
              context.read<MetadataProvider>().clearMetadata();
              context.read<DatabaseSelectorProvider>().clearSelection();
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
            child: const Text('Cambiar'),
          ),
        ],
      ),
    );
  }
}
