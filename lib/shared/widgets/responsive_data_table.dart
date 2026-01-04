import 'package:flutter/material.dart';
import 'package:herramienta_case/core/constants/app_colors.dart';
import 'package:herramienta_case/core/constants/app_icons.dart';
import 'package:herramienta_case/modules/dynamic_crud/data/models/column_info_model.dart';

class ResponsiveDataTable extends StatelessWidget {
  final List<ColumnInfoModel> columns;
  final List<Map<String, dynamic>> records;
  final String? primaryKey;
  final Function(Map<String, dynamic>)? onEdit;
  final Function(Map<String, dynamic>)? onDelete;

  const ResponsiveDataTable({
    super.key,
    required this.columns,
    required this.records,
    this.primaryKey,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      return _buildMobileView();
    } else {
      return _buildDesktopView();
    }
  }

  Widget _buildMobileView() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Campos del registro
                ...columns.map((col) {
                  final value = record[col.name]?.toString() ?? '';
                  if (value.isEmpty) return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            col.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            value,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const Divider(height: 16),

                // Botones de acción
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onEdit != null)
                      OutlinedButton.icon(
                        onPressed: () => onEdit!(record),
                        icon: const Icon(AppIcons.edit, size: 16),
                        label: const Text('Editar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    if (onEdit != null && onDelete != null) const SizedBox(width: 8),
                    if (onDelete != null)
                      OutlinedButton.icon(
                        onPressed: () => onDelete!(record),
                        icon: const Icon(AppIcons.delete, size: 16),
                        label: const Text('Eliminar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopView() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            AppColors.primary.withValues(alpha: 0.1),
          ),
          columns: columns.map((col) {
            return DataColumn(
              label: Text(
                col.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            );
          }).toList()
            ..add(
              const DataColumn(
                label: Text(
                  'Acciones',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          rows: records.map((record) {
            return DataRow(
              cells: columns.map((col) {
                return DataCell(
                  Text(
                    record[col.name]?.toString() ?? '',
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList()
                ..add(
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (onEdit != null)
                          IconButton(
                            icon: const Icon(
                              AppIcons.edit,
                              size: 20,
                              color: AppColors.primary,
                            ),
                            onPressed: () => onEdit!(record),
                            tooltip: 'Editar',
                          ),
                        if (onDelete != null)
                          IconButton(
                            icon: const Icon(
                              AppIcons.delete,
                              size: 20,
                              color: AppColors.error,
                            ),
                            onPressed: () => onDelete!(record),
                            tooltip: 'Eliminar',
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
  }
}
