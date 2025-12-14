import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
      appBar: AppBar(
        title: const Text('Seleccionar Base de Datos'),
        centerTitle: true,
      ),
      body: Consumer<DatabaseSelectorProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar bases de datos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      provider.loadAvailableDatabases(useMock: false);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (provider.availableDatabases.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.dns,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay bases de datos disponibles',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Selecciona una base de datos para comenzar',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: provider.availableDatabases.length,
                  itemBuilder: (context, index) {
                    final database = provider.availableDatabases[index];
                    return DatabaseCard(
                      database: database,
                      onTap: () {
                        provider.selectDatabase(database);
                        // Navigate to login screen
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
    );
  }
}
