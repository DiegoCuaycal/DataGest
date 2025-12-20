import 'package:flutter/material.dart';

/// Modelo para representar un elemento de configuración
class SettingItem {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Widget? trailing;
  final Color? iconColor;

  const SettingItem({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.onTap,
    this.trailing,
    this.iconColor,
  });
}

/// Modelo para representar una sección de configuración
class SettingSection {
  final String title;
  final List<SettingItem> items;

  const SettingSection({
    required this.title,
    required this.items,
  });
}
