import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Estilos de texto y temas de la aplicación
class AppStyles {
  // Estilos de texto - Headings
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading4 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // Estilos de texto - Body
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  // Estilos de texto - Buttons
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  // Estilos de texto - Caption
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 1.5,
  );

  // Espaciado
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  // Border Radius
  static const double radiusSmall = 4.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 12.0;
  static const double radiusXLarge = 16.0;
  static const double radiusCircular = 100.0;

  // Elevación
  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;

  // Decoración de Input
  static InputDecoration inputDecoration({
    required String labelText,
    String? hintText,
    String? errorText,
    String? helperText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool enabled = true,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      errorText: errorText,
      helperText: helperText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      enabled: enabled,
      filled: true,
      fillColor: enabled ? AppColors.surface : AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: paddingMedium,
        vertical: paddingMedium,
      ),
    );
  }

  // Decoración de Card
  static BoxDecoration cardDecoration({
    Color? color,
    double? borderRadius,
    bool withShadow = true,
  }) {
    return BoxDecoration(
      color: color ?? AppColors.surface,
      borderRadius: BorderRadius.circular(borderRadius ?? radiusMedium),
      boxShadow: withShadow
          ? [
              BoxShadow(
                color: AppColors.black.withOpacity(0.1),
                blurRadius: elevationMedium,
                offset: const Offset(0, 2),
              ),
            ]
          : null,
    );
  }

  // Decoración de Card con gradiente
  static BoxDecoration cardGradientDecoration({
    required List<Color> colors,
    double? borderRadius,
    bool withShadow = true,
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: colors,
        begin: begin,
        end: end,
      ),
      borderRadius: BorderRadius.circular(borderRadius ?? radiusMedium),
      boxShadow: withShadow
          ? [
              BoxShadow(
                color: colors.first.withValues(alpha: 0.3),
                blurRadius: elevationMedium,
                offset: const Offset(0, 4),
              ),
            ]
          : null,
    );
  }

  // Decoración de Card elevada moderna
  static BoxDecoration modernCardDecoration({
    Color? color,
    double? borderRadius,
    bool withBorder = false,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: color ?? AppColors.surface,
      borderRadius: BorderRadius.circular(borderRadius ?? radiusLarge),
      border: withBorder
          ? Border.all(color: borderColor ?? AppColors.divider, width: 1)
          : null,
      boxShadow: const [
        BoxShadow(
          color: AppColors.shadowLight,
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
        BoxShadow(
          color: AppColors.shadowLight,
          blurRadius: 4,
          offset: Offset(0, 1),
        ),
      ],
    );
  }

  // Decoración de Card con efecto hover
  static BoxDecoration hoverCardDecoration({
    Color? color,
    double? borderRadius,
    bool isHovered = false,
  }) {
    return BoxDecoration(
      color: color ?? AppColors.surface,
      borderRadius: BorderRadius.circular(borderRadius ?? radiusLarge),
      boxShadow: [
        BoxShadow(
          color: isHovered ? AppColors.shadowMedium : AppColors.shadowLight,
          blurRadius: isHovered ? 12 : 8,
          offset: Offset(0, isHovered ? 6 : 2),
        ),
      ],
    );
  }

  /// Constructor privado para evitar instanciación
  AppStyles._();
}
