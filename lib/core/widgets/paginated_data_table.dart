import 'package:flutter/material.dart';
import 'package:herramienta_case/core/constants/app_colors.dart';
import 'package:herramienta_case/core/constants/app_styles.dart';
import 'package:herramienta_case/core/widgets/paginated_list_view.dart';

/// Widget reutilizable para mostrar tablas de datos con paginación
/// ```
class PaginatedDataTable<T> extends StatelessWidget {
  /// Lista completa de items a mostrar
  final List<T> items;

  /// Títulos de las columnas
  final List<String> columns;

  /// Constructor de las celdas para cada item
  /// Debe retornar una lista de Widgets, uno por cada columna
  final List<Widget> Function(T item) itemBuilder;

  /// Número de items por página
  final int itemsPerPage;

  /// Mensaje a mostrar cuando no hay datos
  final String emptyMessage;

  /// Acciones adicionales para cada fila (ej: editar, eliminar)
  final List<Widget> Function(T item)? rowActions;

  /// Callback cuando se hace clic en una fila
  final void Function(T item)? onRowTap;

  /// Si true, muestra el índice de la fila
  final bool showRowIndex;

  /// Color de fondo alterno para las filas
  final bool alternateRowColors;

  const PaginatedDataTable({
    super.key,
    required this.items,
    required this.columns,
    required this.itemBuilder,
    this.itemsPerPage = 10,
    this.emptyMessage = 'No hay datos para mostrar',
    this.rowActions,
    this.onRowTap,
    this.showRowIndex = false,
    this.alternateRowColors = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Encabezados de la tabla
        _buildTableHeader(),

        // Contenido de la tabla con paginación
        PaginatedListView<T>(
          items: items,
          itemsPerPage: itemsPerPage,
          itemBuilder: (context, item, index) {
            return _buildTableRow(context, item, index);
          },
          emptyMessage: emptyMessage,
          showPageInfo: true,
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(AppStyles.radiusMedium),
              bottomRight: Radius.circular(AppStyles.radiusMedium),
            ),
          ),
        ),
      ],
    );
  }

  /// Construye el encabezado de la tabla
  Widget _buildTableHeader() {
    final effectiveColumns = <String>[
      if (showRowIndex) '#',
      ...columns,
      if (rowActions != null) 'Acciones',
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        border: Border.all(color: AppColors.border),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppStyles.radiusMedium),
          topRight: Radius.circular(AppStyles.radiusMedium),
        ),
      ),
      child: Row(
        children: effectiveColumns.map((column) {
          final isIndex = column == '#';
          final isActions = column == 'Acciones';

          return Expanded(
            flex: isIndex ? 1 : (isActions ? 2 : 3),
            child: Padding(
              padding: const EdgeInsets.all(AppStyles.paddingMedium),
              child: Text(
                column,
                style: AppStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: isActions ? TextAlign.center : TextAlign.start,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Construye una fila de la tabla
  Widget _buildTableRow(BuildContext context, T item, int index) {
    final cells = itemBuilder(item);
    final actions = rowActions?.call(item) ?? [];

    final effectiveCells = <Widget>[
      if (showRowIndex)
        Text(
          '${index + 1}',
          style: AppStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ...cells,
      if (rowActions != null)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: actions,
        ),
    ];

    final backgroundColor = alternateRowColors && index.isOdd
        ? AppColors.background
        : AppColors.surface;

    return InkWell(
      onTap: onRowTap != null ? () => onRowTap!(item) : null,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          border: const Border(
            bottom: BorderSide(
              color: AppColors.border,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: effectiveCells.asMap().entries.map((entry) {
            final cellIndex = entry.key;
            final cell = entry.value;
            final isIndex = showRowIndex && cellIndex == 0;
            final isActions = rowActions != null &&
                              cellIndex == effectiveCells.length - 1;

            return Expanded(
              flex: isIndex ? 1 : (isActions ? 2 : 3),
              child: Padding(
                padding: const EdgeInsets.all(AppStyles.paddingMedium),
                child: cell,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Ejemplo de uso del widget PaginatedDataTable
///
/// Este es un ejemplo completo que muestra cómo usar el widget con un modelo de datos
class PaginatedDataTableExample extends StatelessWidget {
  const PaginatedDataTableExample({super.key});

  @override
  Widget build(BuildContext context) {
    // Datos de ejemplo
    final users = List.generate(
      50,
      (index) => _ExampleUser(
        id: index + 1,
        name: 'Usuario ${index + 1}',
        email: 'user${index + 1}@example.com',
        role: index % 3 == 0 ? 'Admin' : 'Usuario',
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ejemplo de Tabla Paginada'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppStyles.paddingMedium),
        child: PaginatedDataTable<_ExampleUser>(
          items: users,
          columns: const ['ID', 'Nombre', 'Email', 'Rol'],
          itemBuilder: (user) => [
            Text(
              user.id.toString(),
              style: AppStyles.bodySmall,
            ),
            Text(
              user.name,
              style: AppStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              user.email,
              style: AppStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: user.role == 'Admin'
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                user.role,
                style: AppStyles.caption.copyWith(
                  color: user.role == 'Admin'
                      ? AppColors.primary
                      : AppColors.info,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          rowActions: (user) => [
            IconButton(
              icon: const Icon(Icons.edit, size: 18),
              color: AppColors.primary,
              onPressed: () {},
              tooltip: 'Editar',
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 18),
              color: AppColors.error,
              onPressed: () {},
              tooltip: 'Eliminar',
            ),
          ],
          onRowTap: (user) {},
          itemsPerPage: 10,
          showRowIndex: true,
          alternateRowColors: true,
          emptyMessage: 'No hay usuarios registrados',
        ),
      ),
    );
  }
}

/// Modelo de ejemplo para la demostración
class _ExampleUser {
  final int id;
  final String name;
  final String email;
  final String role;

  _ExampleUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });
}
