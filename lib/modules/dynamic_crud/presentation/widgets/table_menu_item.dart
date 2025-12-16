import 'package:flutter/material.dart';
import 'package:herramienta_case/core/constants/app_colors.dart';
import 'package:herramienta_case/core/constants/app_icons.dart';
import 'package:herramienta_case/core/constants/app_strings.dart';
import 'package:herramienta_case/core/constants/app_styles.dart';
import '../../data/models/table_info_model.dart';

class TableMenuItem extends StatelessWidget {
  final TableInfoModel table;
  final VoidCallback onTap;

  const TableMenuItem({
    super.key,
    required this.table,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppStyles.paddingMedium),
      elevation: AppStyles.elevationLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: const Icon(
            AppIcons.table,
            color: AppColors.primary,
          ),
        ),
        title: Text(
          table.table,
          style: AppStyles.heading4,
        ),
        subtitle: Text(
          '${table.rowCount} ${AppStrings.records}',
          style: AppStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        trailing: const Icon(
          AppIcons.forward,
          size: 16,
          color: AppColors.textSecondary,
        ),
        onTap: onTap,
      ),
    );
  }
}
