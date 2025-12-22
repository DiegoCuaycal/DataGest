import 'package:flutter/material.dart';
import 'package:herramienta_case/core/constants/app_colors.dart';
import 'package:herramienta_case/core/constants/app_styles.dart';
import '../../domain/models/attribute_field.dart';
import '../../domain/models/field_type.dart';

/// Widget que muestra un atributo en una tarjeta con opciones de edición y eliminación
class AttributeFieldCard extends StatelessWidget {
  final AttributeField attribute;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AttributeFieldCard({
    super.key,
    required this.attribute,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppStyles.paddingSmall),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(AppStyles.paddingMedium),
        child: Row(
          children: [
            // Icono del tipo de dato
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
              ),
              child: Icon(
                _getIconForType(),
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppStyles.paddingMedium),

            // Información del campo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          attribute.name,
                          style: AppStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
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
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        attribute.type.displayName,
                        style: AppStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (attribute.maxLength != null) ...[
                        Text(
                          ' (${attribute.maxLength})',
                          style: AppStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      if (attribute.isRequired) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Requerido',
                            style: AppStyles.caption.copyWith(
                              color: AppColors.warning,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                      if (attribute.isUnique) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.info.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Único',
                            style: AppStyles.caption.copyWith(
                              color: AppColors.info,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Botones de acción
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: onEdit,
                  color: AppColors.primary,
                  tooltip: 'Editar',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  onPressed: onDelete,
                  color: AppColors.error,
                  tooltip: 'Eliminar',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType() {
    switch (attribute.type) {
      case FieldType.string:
        return Icons.text_fields;
      case FieldType.integer:
        return Icons.numbers;
      case FieldType.decimal:
        return Icons.money;
      case FieldType.boolean:
        return Icons.toggle_on;
      case FieldType.date:
        return Icons.calendar_today;
      case FieldType.datetime:
        return Icons.access_time;
      case FieldType.text:
        return Icons.notes;
    }
  }
}
