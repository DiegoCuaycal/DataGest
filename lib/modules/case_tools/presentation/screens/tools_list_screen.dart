import 'package:flutter/material.dart';
import 'package:herramienta_case/core/constants/app_colors.dart';
import 'package:herramienta_case/core/constants/app_strings.dart';
import 'package:herramienta_case/core/constants/app_styles.dart';
import 'package:herramienta_case/core/config/routes.dart';
import 'package:herramienta_case/modules/case_tools/data/repositories/tool_repository.dart';
import 'package:herramienta_case/modules/case_tools/domain/entities/tool_entity.dart';
import 'package:herramienta_case/shared/widgets/loading_indicator.dart';

/// Pantalla de lista de herramientas CASE
class ToolsListScreen extends StatefulWidget {
  const ToolsListScreen({Key? key}) : super(key: key);

  @override
  State<ToolsListScreen> createState() => _ToolsListScreenState();
}

class _ToolsListScreenState extends State<ToolsListScreen> {
  final _toolRepository = ToolRepository();
  List<ToolEntity> _tools = [];
  List<ToolEntity> _filteredTools = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadTools();
  }

  Future<void> _loadTools() async {
    setState(() => _isLoading = true);

    try {
      final tools = await _toolRepository.getAllTools();
      setState(() {
        _tools = tools;
        _filteredTools = tools;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar herramientas: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _filterTools(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredTools = _tools;
      } else {
        _filteredTools = _tools
            .where((tool) =>
                tool.nombre.toLowerCase().contains(query.toLowerCase()) ||
                tool.descripcion.toLowerCase().contains(query.toLowerCase()) ||
                tool.categoria.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.toolsList),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.all(AppStyles.paddingMedium),
            child: TextField(
              onChanged: _filterTools,
              decoration: InputDecoration(
                hintText: 'Buscar herramientas...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _filterTools(''),
                      )
                    : null,
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppStyles.radiusMedium),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Lista de herramientas
          Expanded(
            child: _isLoading
                ? const LoadingIndicator(
                    message: 'Cargando herramientas...',
                  )
                : _filteredTools.isEmpty
                    ? EmptyStateWidget(
                        message: _searchQuery.isEmpty
                            ? AppStrings.noToolsFound
                            : 'No se encontraron herramientas que coincidan con "$_searchQuery"',
                        icon: Icons.build_outlined,
                      )
                    : RefreshIndicator(
                        onRefresh: _loadTools,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(
                              AppStyles.paddingMedium),
                          itemCount: _filteredTools.length,
                          itemBuilder: (context, index) {
                            final tool = _filteredTools[index];
                            return _buildToolCard(tool);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolCard(ToolEntity tool) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppStyles.paddingMedium),
      elevation: AppStyles.elevationMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
      ),
      child: InkWell(
        onTap: () {
          AppRoutes.navigateTo(
            context,
            AppRoutes.toolDetail,
            arguments: {'toolId': tool.id},
          );
        },
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppStyles.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Icono
                  Container(
                    padding: const EdgeInsets.all(AppStyles.paddingSmall),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                          AppStyles.radiusSmall),
                    ),
                    child: const Icon(
                      Icons.build_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppStyles.paddingMedium),

                  // Nombre y categoría
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tool.nombre,
                          style: AppStyles.heading4,
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppStyles.paddingSmall,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                                AppStyles.radiusSmall),
                          ),
                          child: Text(
                            tool.categoria,
                            style: AppStyles.caption.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Icono de flecha
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: AppStyles.paddingSmall),

              // Descripción
              Text(
                tool.descripcion,
                style: AppStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // URL (si existe)
              if (tool.url != null) ...[
                const SizedBox(height: AppStyles.paddingSmall),
                Row(
                  children: [
                    const Icon(
                      Icons.link,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        tool.url!,
                        style: AppStyles.caption.copyWith(
                          color: AppColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
