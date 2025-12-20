import 'package:flutter/material.dart';
import 'package:herramienta_case/core/constants/app_colors.dart';
import 'package:herramienta_case/core/constants/app_styles.dart';
import 'package:herramienta_case/modules/dynamic_crud/data/models/table_info_model.dart';

/// Widget para seleccionar tablas a exportar
class TableSelectionList extends StatefulWidget {
  final List<TableInfoModel> tables;
  final Set<String> selectedTables;
  final ValueChanged<Set<String>> onSelectionChanged;

  const TableSelectionList({
    super.key,
    required this.tables,
    required this.selectedTables,
    required this.onSelectionChanged,
  });

  @override
  State<TableSelectionList> createState() => _TableSelectionListState();
}

class _TableSelectionListState extends State<TableSelectionList> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TableInfoModel> get _filteredTables {
    if (_searchQuery.isEmpty) {
      return widget.tables;
    }
    return widget.tables.where((table) {
      return table.table.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _toggleTable(String tableName) {
    final newSelection = Set<String>.from(widget.selectedTables);
    if (newSelection.contains(tableName)) {
      newSelection.remove(tableName);
    } else {
      newSelection.add(tableName);
    }
    widget.onSelectionChanged(newSelection);
  }

  void _selectAll() {
    final allTableNames = _filteredTables.map((t) => t.table).toSet();
    widget.onSelectionChanged(allTableNames);
  }

  void _deselectAll() {
    widget.onSelectionChanged({});
  }

  @override
  Widget build(BuildContext context) {
    final filteredTables = _filteredTables;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Búsqueda
          Padding(
            padding: const EdgeInsets.all(AppStyles.paddingMedium),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar tabla...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Botones de selección
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppStyles.paddingMedium,
            ),
            child: Row(
              children: [
                Text(
                  '${widget.selectedTables.length} de ${widget.tables.length} seleccionadas',
                  style: AppStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _selectAll,
                  child: const Text('Seleccionar todas'),
                ),
                TextButton(
                  onPressed: _deselectAll,
                  child: const Text('Deseleccionar todas'),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Lista de tablas
          if (filteredTables.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppStyles.paddingLarge),
              child: Column(
                children: [
                  Icon(
                    Icons.search_off,
                    size: 48,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: AppStyles.paddingSmall),
                  Text(
                    'No se encontraron tablas',
                    style: AppStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              constraints: const BoxConstraints(maxHeight: 400),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: filteredTables.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final table = filteredTables[index];
                  final isSelected = widget.selectedTables.contains(table.table);

                  return CheckboxListTile(
                    title: Text(
                      table.table,
                      style: AppStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      '${table.rowCount} registro${table.rowCount != 1 ? 's' : ''}',
                      style: AppStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    value: isSelected,
                    activeColor: AppColors.primary,
                    onChanged: (value) => _toggleTable(table.table),
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.table_chart,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
