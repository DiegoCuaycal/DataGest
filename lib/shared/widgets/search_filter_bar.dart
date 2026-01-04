import 'package:flutter/material.dart';
import 'package:herramienta_case/core/constants/app_colors.dart';

class SearchFilterBar extends StatefulWidget {
  final String? initialSearchTerm;
  final Function(String) onSearchChanged;
  final VoidCallback? onClearSearch;
  final VoidCallback? onRefresh;
  final String? hintText;
  final bool showRefreshButton;

  const SearchFilterBar({
    super.key,
    this.initialSearchTerm,
    required this.onSearchChanged,
    this.onClearSearch,
    this.onRefresh,
    this.hintText,
    this.showRefreshButton = true,
  });

  @override
  State<SearchFilterBar> createState() => _SearchFilterBarState();
}

class _SearchFilterBarState extends State<SearchFilterBar> {
  late TextEditingController _searchController;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialSearchTerm ?? '');
    _isSearching = (widget.initialSearchTerm?.isNotEmpty ?? false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
    });
    widget.onSearchChanged('');
    if (widget.onClearSearch != null) {
      widget.onClearSearch!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Row(
        children: [
          // Campo de búsqueda
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: widget.hintText ?? 'Buscar...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                suffixIcon: _isSearching
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                        onPressed: _clearSearch,
                        tooltip: 'Limpiar búsqueda',
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
                filled: true,
                fillColor: AppColors.white,
              ),
              onChanged: (value) {
                setState(() {
                  _isSearching = value.isNotEmpty;
                });
                widget.onSearchChanged(value);
              },
              onSubmitted: (value) {
                widget.onSearchChanged(value);
              },
            ),
          ),
          // Botón de refresh
          if (widget.showRefreshButton && widget.onRefresh != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: widget.onRefresh,
              tooltip: 'Actualizar',
              color: AppColors.primary,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
