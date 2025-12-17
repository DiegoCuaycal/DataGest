import 'package:flutter/material.dart';
import 'package:herramienta_case/core/constants/app_colors.dart';
import 'package:herramienta_case/core/constants/app_styles.dart';
import 'package:herramienta_case/core/utils/helpers.dart';
import 'package:herramienta_case/core/utils/notification_service.dart';
import 'package:herramienta_case/modules/case_tools/data/repositories/tool_repository.dart';
import 'package:herramienta_case/modules/case_tools/domain/entities/tool_entity.dart';
import 'package:herramienta_case/shared/widgets/loading_indicator.dart';

/// Pantalla de detalle de herramienta CASE
class ToolDetailScreen extends StatefulWidget {
  final int toolId;

  const ToolDetailScreen({
    Key? key,
    required this.toolId,
  }) : super(key: key);

  @override
  State<ToolDetailScreen> createState() => _ToolDetailScreenState();
}

class _ToolDetailScreenState extends State<ToolDetailScreen> {
  final _toolRepository = ToolRepository();
  ToolEntity? _tool;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTool();
  }

  Future<void> _loadTool() async {
    setState(() => _isLoading = true);

    try {
      final tool = await _toolRepository.getToolById(widget.toolId);
      setState(() {
        _tool = tool;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        NotificationService.showError(
          context,
          'Error al cargar la herramienta',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_tool?.nombre ?? 'Detalle'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : _tool == null
              ? const ErrorStateWidget(
                  message: 'No se encontró la herramienta',
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header con icono grande
                      Container(
                        width: double.infinity,
                        color: AppColors.primary,
                        padding: const EdgeInsets.all(AppStyles.paddingLarge),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(
                                  AppStyles.paddingLarge),
                              decoration: const BoxDecoration(
                                color: AppColors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.build_outlined,
                                size: 60,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: AppStyles.paddingMedium),
                            Text(
                              _tool!.nombre,
                              style: AppStyles.heading2.copyWith(
                                color: AppColors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppStyles.paddingSmall),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppStyles.paddingMedium,
                                vertical: AppStyles.paddingSmall,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(
                                    AppStyles.radiusCircular),
                              ),
                              child: Text(
                                _tool!.categoria,
                                style: AppStyles.bodyMedium.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Contenido
                      Padding(
                        padding: const EdgeInsets.all(AppStyles.paddingLarge),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Descripción
                            _buildSection(
                              title: 'Descripción',
                              icon: Icons.description_outlined,
                              child: Text(
                                _tool!.descripcion,
                                style: AppStyles.bodyLarge,
                              ),
                            ),

                            // URL
                            if (_tool!.url != null) ...[
                              const SizedBox(height: AppStyles.paddingLarge),
                              _buildSection(
                                title: 'Sitio Web',
                                icon: Icons.link,
                                child: InkWell(
                                  onTap: () {
                                    NotificationService.showInfo(
                                      context,
                                      'Abriendo ${_tool!.url}',
                                    );
                                    // TODO: Abrir URL en navegador
                                  },
                                  child: Text(
                                    _tool!.url!,
                                    style: AppStyles.bodyMedium.copyWith(
                                      color: AppColors.primary,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                            ],

                            // Fecha de creación
                            if (_tool!.fechaCreacion != null) ...[
                              const SizedBox(height: AppStyles.paddingLarge),
                              _buildSection(
                                title: 'Fecha de Registro',
                                icon: Icons.calendar_today_outlined,
                                child: Text(
                                  Helpers.formatDate(_tool!.fechaCreacion!),
                                  style: AppStyles.bodyMedium,
                                ),
                              ),
                            ],

                            // Acciones
                            const SizedBox(height: AppStyles.paddingXLarge),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      NotificationService.showInfo(
                                        context,
                                        'Funcionalidad en desarrollo',
                                      );
                                    },
                                    icon: const Icon(Icons.edit_outlined),
                                    label: const Text('Editar'),
                                  ),
                                ),
                                const SizedBox(width: AppStyles.paddingMedium),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      NotificationService.showInfo(
                                        context,
                                        'Funcionalidad en desarrollo',
                                      );
                                    },
                                    icon: const Icon(Icons.delete_outline),
                                    label: const Text('Eliminar'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: AppStyles.paddingSmall),
            Text(
              title,
              style: AppStyles.heading4.copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppStyles.paddingSmall),
        child,
      ],
    );
  }
}
