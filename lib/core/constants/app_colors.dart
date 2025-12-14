import 'package:flutter/material.dart';

/// Paleta de colores de la aplicación
class AppColors {
  // Colores primarios
  static const Color primary = Color(0xFF2196F3);
  static const Color primaryDark = Color(0xFF1976D2);
  static const Color primaryLight = Color(0xFF64B5F6);

  // Colores secundarios
  static const Color secondary = Color(0xFF00BCD4);
  static const Color secondaryDark = Color(0xFF0097A7);
  static const Color secondaryLight = Color(0xFF4DD0E1);

  // Colores de estado
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);

  // Colores de fondo
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color scaffoldBackground = Color(0xFFFAFAFA);

  // Colores de texto
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textDisabled = Color(0xFFBDBDBD);
  static const Color textHint = Color(0xFF9E9E9E);

  // Colores de bordes y divisores
  static const Color divider = Color(0xFFE0E0E0);
  static const Color border = Color(0xFFBDBDBD);

  // Otros colores
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Colors.transparent;

  // Colores de acento adicionales
  static const Color accent = Color(0xFFFF5722);
  static const Color accentLight = Color(0xFFFF8A65);

  // Colores para sombras
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowMedium = Color(0x33000000);
  static const Color shadowDark = Color(0x4D000000);

  // Gradientes predefinidos
  static const List<Color> primaryGradient = [primary, primaryLight];
  static const List<Color> secondaryGradient = [secondary, secondaryLight];
  static const List<Color> successGradient = [Color(0xFF66BB6A), Color(0xFF81C784)];
  static const List<Color> errorGradient = [error, Color(0xFFE57373)];
  static const List<Color> warningGradient = [warning, Color(0xFFFFB74D)];
  static const List<Color> infoGradient = [info, Color(0xFF64B5F6)];

  // Gradiente oscuro para fondos
  static const List<Color> darkGradient = [Color(0xFF1976D2), Color(0xFF1565C0)];

  // Gradiente de cards
  static const List<Color> cardGradient = [Color(0xFFFFFFFF), Color(0xFFF8F9FA)];

  /// Constructor privado para evitar instanciación
  AppColors._();
}
