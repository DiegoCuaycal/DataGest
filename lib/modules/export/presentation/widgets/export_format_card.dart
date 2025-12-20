import 'package:flutter/material.dart';
import 'package:herramienta_case/core/constants/app_colors.dart';
import 'package:herramienta_case/core/constants/app_styles.dart';
import 'package:herramienta_case/modules/export/domain/models/export_format.dart';

/// Widget para seleccionar un formato de exportación
class ExportFormatCard extends StatelessWidget {
  final ExportFormat format;
  final bool isSelected;
  final VoidCallback onTap;

  const ExportFormatCard({
    super.key,
    required this.format,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppStyles.paddingSmall),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
        child: Container(
          padding: const EdgeInsets.all(AppStyles.paddingMedium),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Radio button
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: 2,
                  ),
                  color: isSelected ? AppColors.primary : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        size: 16,
                        color: AppColors.white,
                      )
                    : null,
              ),
              const SizedBox(width: AppStyles.paddingMedium),

              // Icono del formato
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getFormatIcon(format),
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppStyles.paddingMedium),

              // Información del formato
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      format.displayName,
                      style: AppStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      format.description,
                      style: AppStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '.${format.extension}',
                        style: AppStyles.bodySmall.copyWith(
                          fontFamily: 'monospace',
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getFormatIcon(ExportFormat format) {
    switch (format) {
      case ExportFormat.csv:
        return Icons.table_chart;
      case ExportFormat.json:
        return Icons.code;
    }
  }
}
