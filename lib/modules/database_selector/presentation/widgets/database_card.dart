import 'package:flutter/material.dart';
import 'package:herramienta_case/core/constants/app_colors.dart';
import 'package:herramienta_case/core/constants/app_styles.dart';
import '../../data/models/database_info_model.dart';

class DatabaseCard extends StatelessWidget {
  final DatabaseInfoModel database;
  final VoidCallback onTap;

  const DatabaseCard({
    super.key,
    required this.database,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppStyles.paddingMedium),
      decoration: AppStyles.modernCardDecoration(),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
        child: Padding(
          padding: const EdgeInsets.all(AppStyles.paddingLarge),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.primaryGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                ),
                child: const Icon(
                  Icons.storage_rounded,
                  size: 32,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(width: AppStyles.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      database.name,
                      style: AppStyles.heading4,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      database.description,
                      style: AppStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _DatabaseTypeChip(type: database.type),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(AppStyles.paddingSmall),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DatabaseTypeChip extends StatelessWidget {
  final String type;

  const _DatabaseTypeChip({required this.type});

  Color _backgroundColor() {
    final normalized = type.toLowerCase();
    if (normalized.contains('postgres')) return AppColors.secondary.withValues(alpha: 0.15);
    if (normalized.contains('maria')) return AppColors.success.withValues(alpha: 0.15);
    if (normalized.contains('mysql')) return AppColors.warning.withValues(alpha: 0.15);
    if (normalized.contains('sql server') || normalized.contains('sqlserver') || normalized.contains('mssql')) {
      return AppColors.primary.withValues(alpha: 0.15);
    }
    if (normalized.contains('sqlite')) return AppColors.info.withValues(alpha: 0.15);
    return AppColors.textSecondary.withValues(alpha: 0.1);
  }

  Color _textColor() {
    final normalized = type.toLowerCase();
    if (normalized.contains('postgres')) return AppColors.secondary;
    if (normalized.contains('maria')) return AppColors.success;
    if (normalized.contains('mysql')) return AppColors.warning;
    if (normalized.contains('sql server') || normalized.contains('sqlserver') || normalized.contains('mssql')) {
      return AppColors.primary;
    }
    if (normalized.contains('sqlite')) return AppColors.info;
    return AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppStyles.paddingMedium,
        vertical: AppStyles.paddingSmall / 2,
      ),
      decoration: BoxDecoration(
        color: _backgroundColor(),
        borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.data_object,
            size: 16,
            color: _textColor(),
          ),
          const SizedBox(width: 6),
          Text(
            type,
            style: AppStyles.bodySmall.copyWith(
              color: _textColor(),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
