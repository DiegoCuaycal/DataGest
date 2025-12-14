import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dynamic_crud_provider.dart';
import '../providers/metadata_provider.dart';
import '../../../database_selector/presentation/providers/database_selector_provider.dart';

class DynamicListScreen extends StatefulWidget {
  final String tableName;

  const DynamicListScreen({
    super.key,
    required this.tableName,
  });

  @override
  State<DynamicListScreen> createState() => _DynamicListScreenState();
}

class _DynamicListScreenState extends State<DynamicListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final dbProvider = context.read<DatabaseSelectorProvider>();
    final crudProvider = context.read<DynamicCrudProvider>();

    if (dbProvider.currentDatabaseName != null) {
      crudProvider.loadTableRecords(
        databaseName: dbProvider.currentDatabaseName!,
        tableName: widget.tableName,
        token: 'mock_token',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final metadataProvider = context.watch<MetadataProvider>();

    final columns = metadataProvider.getColumnsForTable(widget.tableName);
    final pkInfo = metadataProvider.metadata?.getPrimaryKeysForTable(widget.tableName);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tableName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Consumer<DynamicCrudProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(provider.errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (provider.records.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No hay registros',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                columns: columns.map((col) {
                  return DataColumn(
                    label: Text(
                      col.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList()
                  ..add(const DataColumn(label: Text('Acciones'))),
                rows: provider.records.map((record) {
                  return DataRow(
                    cells: columns.map((col) {
                      return DataCell(
                        Text(record[col.name]?.toString() ?? ''),
                      );
                    }).toList()
                      ..add(
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () {
                                  final pk = pkInfo?.first.column;
                                  if (pk != null) {
                                    Navigator.pushNamed(
                                      context,
                                      '/table/${widget.tableName}/edit/${record[pk]}',
                                    );
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                onPressed: () => _confirmDelete(record, pkInfo?.first.column),
                              ),
                            ],
                          ),
                        ),
                      ),
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/table/${widget.tableName}/create');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> record, String? pkColumn) async {
    if (pkColumn == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Está seguro de eliminar este registro?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final dbProvider = context.read<DatabaseSelectorProvider>();
      final crudProvider = context.read<DynamicCrudProvider>();

      final success = await crudProvider.deleteRecord(
        databaseName: dbProvider.currentDatabaseName!,
        tableName: widget.tableName,
        id: record[pkColumn],
        token: 'mock_token',
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registro eliminado exitosamente')),
          );
          _loadData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(crudProvider.errorMessage ?? 'Error al eliminar')),
          );
        }
      }
    }
  }
}
