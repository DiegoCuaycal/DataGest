import 'package:flutter/material.dart';
import 'package:herramienta_case/core/constants/app_colors.dart';
import 'package:herramienta_case/core/constants/app_styles.dart';

/// Widget reutilizable para mostrar listas paginadas
///
/// ```
class PaginatedListView<T> extends StatefulWidget {
  /// Lista completa de items a paginar
  final List<T> items;

  /// Número de items por página (por defecto 10)
  final int itemsPerPage;

  /// Constructor del widget para cada item
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  /// Separador entre items (opcional)
  final Widget Function(BuildContext context, int index)? separatorBuilder;

  /// Mensaje a mostrar cuando la lista está vacía
  final String emptyMessage;

  /// Widget a mostrar cuando la lista está vacía (opcional, tiene prioridad sobre emptyMessage)
  final Widget? emptyWidget;

  /// Si true, reduce el espacio vertical del widget
  final bool shrinkWrap;

  /// ScrollPhysics para el ListView
  final ScrollPhysics? physics;

  /// Padding del contenedor
  final EdgeInsetsGeometry? padding;

  /// Decoración del contenedor (opcional)
  final BoxDecoration? decoration;

  /// Si true, muestra información del número total de páginas y elementos
  final bool showPageInfo;

  const PaginatedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.itemsPerPage = 10,
    this.separatorBuilder,
    this.emptyMessage = 'No hay elementos para mostrar',
    this.emptyWidget,
    this.shrinkWrap = true,
    this.physics = const NeverScrollableScrollPhysics(),
    this.padding,
    this.decoration,
    this.showPageInfo = true,
  });

  @override
  State<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  int _currentPage = 0;

  /// Calcula el número total de páginas
  int get _totalPages => (widget.items.length / widget.itemsPerPage).ceil();

  /// Obtiene los items de la página actual
  List<T> get _currentPageItems {
    final startIndex = _currentPage * widget.itemsPerPage;
    final endIndex = (startIndex + widget.itemsPerPage).clamp(0, widget.items.length);
    return widget.items.sublist(startIndex, endIndex);
  }

  /// Navega a la página anterior
  void _goToPreviousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
    }
  }

  /// Navega a la página siguiente
  void _goToNextPage() {
    if (_currentPage < _totalPages - 1) {
      setState(() {
        _currentPage++;
      });
    }
  }

  /// Navega a una página específica
  void _goToPage(int page) {
    if (page >= 0 && page < _totalPages) {
      setState(() {
        _currentPage = page;
      });
    }
  }

  @override
  void didUpdateWidget(PaginatedListView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Si la lista cambió y la página actual ya no es válida, volver a la primera página
    if (widget.items.length != oldWidget.items.length) {
      if (_currentPage >= _totalPages && _totalPages > 0) {
        setState(() {
          _currentPage = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si no hay items, mostrar mensaje vacío
    if (widget.items.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Información de la página (si está habilitada)
        if (widget.showPageInfo && _totalPages > 1)
          _buildPageInfo(),

        // Lista de items
        _buildItemsList(),

        // Controles de paginación (solo si hay más de una página)
        if (_totalPages > 1)
          _buildPaginationControls(),
      ],
    );
  }

  /// Construye el widget de estado vacío
  Widget _buildEmptyState() {
    if (widget.emptyWidget != null) {
      return widget.emptyWidget!;
    }

    return Container(
      padding: const EdgeInsets.all(AppStyles.paddingLarge),
      decoration: widget.decoration,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppStyles.paddingMedium),
            Text(
              widget.emptyMessage,
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Construye la información de la página
  Widget _buildPageInfo() {
    final startItem = _currentPage * widget.itemsPerPage + 1;
    final endItem = (startItem + _currentPageItems.length - 1).clamp(0, widget.items.length);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppStyles.paddingSmall),
      child: Text(
        'Mostrando $startItem-$endItem de ${widget.items.length}',
        style: AppStyles.caption.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  /// Construye la lista de items
  Widget _buildItemsList() {
    final listView = widget.separatorBuilder != null
        ? ListView.separated(
            shrinkWrap: widget.shrinkWrap,
            physics: widget.physics,
            itemCount: _currentPageItems.length,
            separatorBuilder: widget.separatorBuilder!,
            itemBuilder: (context, index) {
              final item = _currentPageItems[index];
              final globalIndex = _currentPage * widget.itemsPerPage + index;
              return widget.itemBuilder(context, item, globalIndex);
            },
          )
        : ListView.builder(
            shrinkWrap: widget.shrinkWrap,
            physics: widget.physics,
            itemCount: _currentPageItems.length,
            itemBuilder: (context, index) {
              final item = _currentPageItems[index];
              final globalIndex = _currentPage * widget.itemsPerPage + index;
              return widget.itemBuilder(context, item, globalIndex);
            },
          );

    if (widget.decoration != null) {
      return Container(
        decoration: widget.decoration,
        padding: widget.padding,
        child: listView,
      );
    }

    return Padding(
      padding: widget.padding ?? EdgeInsets.zero,
      child: listView,
    );
  }

  /// Construye los controles de paginación
  Widget _buildPaginationControls() {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppStyles.paddingMedium,
        horizontal: AppStyles.paddingSmall,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Botón "Primera página"
          IconButton(
            icon: const Icon(Icons.first_page),
            onPressed: _currentPage > 0 ? () => _goToPage(0) : null,
            tooltip: 'Primera página',
            iconSize: 20,
          ),

          // Botón "Anterior"
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 0 ? _goToPreviousPage : null,
            tooltip: 'Página anterior',
            iconSize: 20,
          ),

          const SizedBox(width: AppStyles.paddingSmall),

          // Indicadores de página
          _buildPageIndicators(),

          const SizedBox(width: AppStyles.paddingSmall),

          // Botón "Siguiente"
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < _totalPages - 1 ? _goToNextPage : null,
            tooltip: 'Página siguiente',
            iconSize: 20,
          ),

          // Botón "Última página"
          IconButton(
            icon: const Icon(Icons.last_page),
            onPressed: _currentPage < _totalPages - 1
                ? () => _goToPage(_totalPages - 1)
                : null,
            tooltip: 'Última página',
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  /// Construye los indicadores de página (puntos o números)
  Widget _buildPageIndicators() {
    // Si hay muchas páginas, mostrar solo algunas
    final maxVisiblePages = 5;

    if (_totalPages <= maxVisiblePages) {
      // Mostrar todas las páginas
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(_totalPages, (index) {
          return _buildPageButton(index);
        }),
      );
    } else {
      // Mostrar páginas seleccionadas con "..."
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: _buildCondensedPageButtons(),
      );
    }
  }

  /// Construye botones de página condensados para muchas páginas
  List<Widget> _buildCondensedPageButtons() {
    final buttons = <Widget>[];

    // Siempre mostrar primera página
    buttons.add(_buildPageButton(0));

    // Mostrar "..." si es necesario
    if (_currentPage > 2) {
      buttons.add(_buildEllipsis());
    }

    // Mostrar páginas alrededor de la actual
    for (int i = (_currentPage - 1).clamp(1, _totalPages - 1);
         i <= (_currentPage + 1).clamp(1, _totalPages - 1);
         i++) {
      if (i > 0 && i < _totalPages - 1) {
        buttons.add(_buildPageButton(i));
      }
    }

    // Mostrar "..." si es necesario
    if (_currentPage < _totalPages - 3) {
      buttons.add(_buildEllipsis());
    }

    // Siempre mostrar última página
    if (_totalPages > 1) {
      buttons.add(_buildPageButton(_totalPages - 1));
    }

    return buttons;
  }

  /// Construye un botón de página individual
  Widget _buildPageButton(int pageIndex) {
    final isCurrentPage = pageIndex == _currentPage;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: () => _goToPage(pageIndex),
        borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCurrentPage
                ? AppColors.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
            border: Border.all(
              color: isCurrentPage
                  ? AppColors.primary
                  : AppColors.border,
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '${pageIndex + 1}',
            style: AppStyles.caption.copyWith(
              color: isCurrentPage
                  ? AppColors.white
                  : AppColors.textPrimary,
              fontWeight: isCurrentPage
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  /// Construye el indicador de elipsis "..."
  Widget _buildEllipsis() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        '...',
        style: AppStyles.caption.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
