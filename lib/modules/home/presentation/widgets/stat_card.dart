import 'package:flutter/material.dart';
import 'package:herramienta_case/core/constants/app_colors.dart';
import 'package:herramienta_case/core/constants/app_styles.dart';

/// Widget para mostrar una estadística en formato de card
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Ajustar tamaños basándose en el ancho disponible
        final isSmallCard = constraints.maxWidth < 150;
        final iconSize = isSmallCard ? 32.0 : 38.0;
        final iconInnerSize = isSmallCard ? 16.0 : 20.0;
        final valueFontSize = isSmallCard ? 16.0 : 18.0;
        final labelFontSize = isSmallCard ? 10.0 : 11.0;
        final horizontalPadding = isSmallCard ? 8.0 : 10.0;
        final verticalPadding = isSmallCard ? 8.0 : 10.0;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
            border: Border.all(
              color: AppColors.border,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icono con fondo de color
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: iconInnerSize,
                ),
              ),
              SizedBox(width: isSmallCard ? 8 : 10),

              // Texto - usando Flexible en lugar de Expanded para mejor control
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: valueFontSize,
                          height: 1.0,
                        ),
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      label,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: labelFontSize,
                        height: 1.0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
