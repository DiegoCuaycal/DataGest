import 'package:flutter/material.dart';
import 'package:herramienta_case/core/constants/app_colors.dart';
import 'package:herramienta_case/core/constants/app_styles.dart';
import '../../domain/models/recent_activity_model.dart';

/// Widget para mostrar un item de actividad reciente
class RecentActivityItem extends StatelessWidget {
  final RecentActivityModel activity;

  const RecentActivityItem({
    super.key,
    required this.activity,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppStyles.paddingMedium,
        vertical: AppStyles.paddingSmall,
      ),
      child: Row(
        children: [
          // Icono según el tipo de acción
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getActionColor().withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
            ),
            child: Icon(
              _getActionIcon(),
              size: 20,
              color: _getActionColor(),
            ),
          ),
          const SizedBox(width: AppStyles.paddingMedium),

          // Información de la actividad
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${activity.actionLabel} ${activity.tableName}',
                  style: AppStyles.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  activity.timeAgo,
                  style: AppStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getActionIcon() {
    switch (activity.action) {
      case 'view':
        return Icons.visibility_outlined;
      case 'create':
        return Icons.add_circle_outline;
      case 'update':
        return Icons.edit_outlined;
      case 'delete':
        return Icons.delete_outline;
      default:
        return Icons.circle_outlined;
    }
  }

  Color _getActionColor() {
    switch (activity.action) {
      case 'view':
        return AppColors.primary;
      case 'create':
        return AppColors.success;
      case 'update':
        return AppColors.warning;
      case 'delete':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }
}
