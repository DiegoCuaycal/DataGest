import 'package:flutter/material.dart';
import 'package:herramienta_case/core/constants/app_colors.dart';
import 'package:herramienta_case/core/constants/app_styles.dart';
import '../../domain/models/table_entity.dart';

/// Widget que muestra una tabla en una tarjeta expandible
class TableEntityCard extends StatefulWidget {
  final TableEntity table;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAddAttribute;

  const TableEntityCard({
    super.key,
    required this.table,
    required this.onEdit,
    required this.onDelete,
    required this.onAddAttribute,
  });

  @override
  State<TableEntityCard> createState() => _TableEntityCardState();
}

class _TableEntityCardState extends State<TableEntityCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppStyles.paddingMedium),
      elevation: 2,
      child: Column(
        children: [
          // Encabezado de la tarjeta
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(AppStyles.paddingMedium),
              child: Row(
                children: [
                  // Icono de tabla
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: AppColors.primaryGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
                    ),
                    child: const Icon(
                      Icons.table_chart,
                      color: AppColors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppStyles.paddingMedium),

                  // Información de la tabla
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.table.name,
                          style: AppStyles.heading4,
                        ),
                        if (widget.table.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.table.description,
                            style: AppStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          '${widget.table.attributes.length} atributos',
                          style: AppStyles.caption.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Botones de acción
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: widget.onEdit,
                    color: AppColors.primary,
                    tooltip: 'Editar tabla',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    onPressed: widget.onDelete,
                    color: AppColors.error,
                    tooltip: 'Eliminar tabla',
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          // Contenido expandible
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppStyles.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Atributos',
                        style: AppStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: widget.onAddAttribute,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Agregar'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppStyles.paddingSmall),
                  if (widget.table.attributes.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppStyles.paddingLarge,
                        ),
                        child: Text(
                          'No hay atributos agregados',
                          style: AppStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.table.attributes.length,
                      itemBuilder: (context, index) {
                        final attribute = widget.table.attributes[index];
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            _getIconForType(attribute.type.name),
                            size: 20,
                            color: AppColors.primary,
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  attribute.name,
                                  style: AppStyles.bodyMedium,
                                ),
                              ),
                              if (attribute.isPrimaryKey)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'PK',
                                    style: AppStyles.caption.copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Text(
                            attribute.type.displayName +
                                (attribute.isRequired ? ' • Requerido' : ''),
                            style: AppStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getIconForType(String typeName) {
    switch (typeName) {
      case 'string':
        return Icons.text_fields;
      case 'integer':
        return Icons.numbers;
      case 'decimal':
        return Icons.money;
      case 'boolean':
        return Icons.toggle_on;
      case 'date':
        return Icons.calendar_today;
      case 'datetime':
        return Icons.access_time;
      case 'text':
        return Icons.notes;
      default:
        return Icons.help_outline;
    }
  }
}
