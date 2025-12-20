import 'package:flutter/material.dart';
import 'package:herramienta_case/core/constants/app_colors.dart';
import 'package:herramienta_case/modules/settings/domain/models/setting_item.dart';

/// Widget reutilizable para mostrar una sección de configuración
class SettingSectionWidget extends StatelessWidget {
  final SettingSection section;

  const SettingSectionWidget({
    super.key,
    required this.section,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            section.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          child: Column(
            children: section.items
                .map((item) => _buildSettingItem(context, item))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem(BuildContext context, SettingItem item) {
    return ListTile(
      leading: Icon(
        item.icon,
        color: item.iconColor ?? AppColors.primary,
      ),
      title: Text(item.title),
      subtitle: item.subtitle != null ? Text(item.subtitle!) : null,
      trailing: item.trailing ?? const Icon(Icons.chevron_right),
      onTap: item.onTap,
    );
  }
}
