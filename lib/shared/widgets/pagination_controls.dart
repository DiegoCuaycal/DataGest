import 'package:flutter/material.dart';
import 'package:herramienta_case/core/constants/app_colors.dart';

class PaginationControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int totalRecords;
  final int recordsPerPage;
  final int pageSize;
  final Function(int) onPageChanged;
  final Function(int) onPageSizeChanged;
  final List<int> pageSizeOptions;

  const PaginationControls({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.totalRecords,
    required this.recordsPerPage,
    required this.pageSize,
    required this.onPageChanged,
    required this.onPageSizeChanged,
    this.pageSizeOptions = const [10, 20, 50, 100],
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (totalRecords == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.divider),
        ),
      ),
      child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Información de registros
        _buildRecordsInfo(),
        const SizedBox(height: 8),
        // Selector de tamaño de página
        _buildPageSizeSelector(),
        const SizedBox(height: 8),
        // Controles de navegación en su propia fila
        _buildNavigationButtons(),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Selector de tamaño de página
        _buildPageSizeSelector(),
        // Información de registros
        _buildRecordsInfo(),
        // Controles de navegación
        _buildNavigationButtons(),
      ],
    );
  }

  Widget _buildPageSizeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      children: [
        const Text(
          'Mostrar:',
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButton<int>(
            value: pageSize,
            underline: const SizedBox(),
            isDense: true,
            items: pageSizeOptions.map((size) {
              return DropdownMenuItem<int>(
                value: size,
                child: Text('$size'),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                onPageSizeChanged(value);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecordsInfo() {
    final startRecord = totalRecords == 0 ? 0 : (currentPage - 1) * pageSize + 1;
    final endRecord = (currentPage * pageSize > totalRecords)
        ? totalRecords
        : currentPage * pageSize;

    return Text(
      'Mostrando $startRecord-$endRecord de $totalRecords registros',
      style: const TextStyle(
        fontSize: 14,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      children: [
        // Botón primera página
        IconButton(
          icon: const Icon(Icons.first_page),
          onPressed: currentPage > 1 ? () => onPageChanged(1) : null,
          tooltip: 'Primera página',
          color: AppColors.primary,
          disabledColor: AppColors.textDisabled,
          visualDensity: VisualDensity.compact,
        ),
        // Botón página anterior
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
          tooltip: 'Página anterior',
          color: AppColors.primary,
          disabledColor: AppColors.textDisabled,
          visualDensity: VisualDensity.compact,
        ),
        // Indicador de página
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Pág $currentPage de $totalPages',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        // Botón página siguiente
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed:
              currentPage < totalPages ? () => onPageChanged(currentPage + 1) : null,
          tooltip: 'Página siguiente',
          color: AppColors.primary,
          disabledColor: AppColors.textDisabled,
          visualDensity: VisualDensity.compact,
        ),
        // Botón última página
        IconButton(
          icon: const Icon(Icons.last_page),
          onPressed:
              currentPage < totalPages ? () => onPageChanged(totalPages) : null,
          tooltip: 'Última página',
          color: AppColors.primary,
          disabledColor: AppColors.textDisabled,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}
