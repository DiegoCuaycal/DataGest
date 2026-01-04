import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:herramienta_case/core/constants/app_colors.dart';
import 'package:herramienta_case/core/constants/app_icons.dart';
import 'package:herramienta_case/core/constants/app_strings.dart';
import 'package:herramienta_case/core/constants/app_styles.dart';
import 'package:herramienta_case/core/network/foreign_key_config.dart';
import '../../data/models/dropdown_item_model.dart';
import '../providers/dynamic_crud_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ForeignKeyDropdown extends StatefulWidget {
  final String label;
  final String databaseName;
  final String referenceTable;
  final String referenceColumn;
  final bool isRequired;
  final dynamic initialValue;
  final Function(dynamic) onChanged;

  const ForeignKeyDropdown({
    super.key,
    required this.label,
    required this.databaseName,
    required this.referenceTable,
    required this.referenceColumn,
    this.isRequired = false,
    this.initialValue,
    required this.onChanged,
  });

  @override
  State<ForeignKeyDropdown> createState() => _ForeignKeyDropdownState();
}

class _ForeignKeyDropdownState extends State<ForeignKeyDropdown> {
  List<DropdownItemModel> _items = [];
  bool _isLoading = true;
  String? _errorMessage;
  dynamic _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue;
    print('🎬 ForeignKeyDropdown INIT ${widget.label}: initialValue = $_selectedValue (${_selectedValue?.runtimeType})');
    _loadDropdownData();
  }

  @override
  void didUpdateWidget(ForeignKeyDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      setState(() {
        _selectedValue = widget.initialValue;
      });
    }
  }

  Future<void> _loadDropdownData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final provider = context.read<DynamicCrudProvider>();
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.currentUser?.token ?? '';

      print('📋 Cargando dropdown para ${widget.referenceTable}');
      print('🔑 Token: ${token.isEmpty ? "VACÍO" : "${token.substring(0, 20)}..."}');

      // Obtener las columnas a mostrar de la configuración
      final displayColumns = ForeignKeyConfig.getDisplayColumns(
        tableName: '', // No necesario para getDisplayColumns
        columnName: widget.referenceColumn,
      );

      print('🎨 Columnas para mostrar: $displayColumns');

      final items = await provider.getDropdownData(
        databaseName: widget.databaseName,
        tableName: widget.referenceTable,
        token: token,
        displayColumns: displayColumns,
      );

      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;

          // Normalizar el valor seleccionado después de cargar los items
          if (_selectedValue != null) {
            // Convertir a int si es necesario
            if (_selectedValue is String) {
              _selectedValue = int.tryParse(_selectedValue) ?? _selectedValue;
            }

            // Verificar que el valor existe en los items
            final valueExists = _items.any((item) => item.id == _selectedValue);
            if (!valueExists) {
              print('⚠️ ForeignKeyDropdown: Valor inicial $_selectedValue no encontrado en items, estableciendo a null');
              _selectedValue = null;
            } else {
              print('✅ ForeignKeyDropdown: Valor inicial $_selectedValue encontrado y establecido');
            }
          }
        });
      }
    } catch (e) {
      print('❌ Error cargando dropdown: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return InputDecorator(
        decoration: AppStyles.inputDecoration(
          labelText: widget.label,
        ),
        child: const Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      // Si hay error pero el campo no es requerido, mostrar el campo vacío
      if (!widget.isRequired) {
        return InputDecorator(
          decoration: AppStyles.inputDecoration(
            labelText: '${widget.label} (opcional - endpoint no disponible)',
            helperText: 'Este campo es opcional. El backend no tiene datos disponibles.',
          ),
          child: Text(
            'No disponible',
            style: AppStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        );
      }

      // Si el campo es requerido, mostrar el error con opción de reintentar
      return InputDecorator(
        decoration: AppStyles.inputDecoration(
          labelText: widget.label,
          errorText: AppStrings.errorLoadingData,
        ),
        child: Row(
          children: [
            const Icon(
              AppIcons.error,
              color: AppColors.error,
              size: 20,
            ),
            const SizedBox(width: AppStyles.paddingSmall),
            Expanded(
              child: Text(
                _errorMessage!,
                style: AppStyles.bodySmall.copyWith(
                  color: AppColors.error,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(AppIcons.refresh, size: 20),
              onPressed: _loadDropdownData,
              color: AppColors.primary,
            ),
          ],
        ),
      );
    }

    // Si no hay items disponibles
    if (_items.isEmpty) {
      // Si el campo no es requerido, mostrar como opcional
      if (!widget.isRequired) {
        return InputDecorator(
          decoration: AppStyles.inputDecoration(
            labelText: '${widget.label} (opcional)',
            helperText: 'No hay opciones disponibles en el backend.',
          ),
          child: Text(
            'Sin datos disponibles',
            style: AppStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        );
      }

      // Si el campo es requerido pero no hay opciones, mostrar advertencia
      return InputDecorator(
        decoration: AppStyles.inputDecoration(
          labelText: widget.label,
          errorText: 'No hay opciones disponibles',
          helperText: 'Debe configurarse en el backend primero.',
        ),
        child: Text(
          'Sin datos',
          style: AppStyles.bodySmall.copyWith(
            color: AppColors.error,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return DropdownButtonFormField<dynamic>(
      decoration: AppStyles.inputDecoration(
        labelText: widget.label,
      ),
      value: _selectedValue,
      items: _items.map((item) {
        return DropdownMenuItem<dynamic>(
          value: item.id,
          child: Text(
            item.displayValue,
            style: AppStyles.bodyMedium,
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedValue = value;
        });
        widget.onChanged(value);
      },
      validator: widget.isRequired
          ? (value) => value == null ? AppStrings.requiredFieldMessage : null
          : null,
    );
  }
}
