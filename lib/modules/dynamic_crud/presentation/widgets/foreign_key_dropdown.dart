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
    print('🎬 ForeignKeyDropdown INIT ${widget.label}:');
    print('   📥 initialValue = $_selectedValue');
    print('   📦 Type = ${_selectedValue?.runtimeType}');
    print('   📋 Table = ${widget.referenceTable}');
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
      
      // --- 🚨 PARCHE DE COLUMNAS (SOLUCIÓN 1) 🚨 ---
      List<String> displayColumns;

      // 1. Si la tabla es CITAS
      if (widget.referenceTable.toLowerCase() == 'citas') {
        print('🚑 Aplicando parche de columnas para Citas');
        displayColumns = ['fecha_hora', 'motivo_consulta'];
      } 
      // 2. Si la tabla es DIAGNOSTICOS
      else if (widget.referenceTable.toLowerCase() == 'diagnosticos') {
         displayColumns = ['descripcion_diagnostico', 'tratamiento_recetado'];
      }
      // 3. 🚨 NUEVO: Si la tabla es MEDICOS (Para que se vea bonito)
      else if (widget.referenceTable.toLowerCase() == 'medicos') {
         print('🚑 Aplicando parche de columnas para Medicos');
         displayColumns = ['nombres', 'especialidad', 'consultorio'];
      }
      // 4. Configuración normal
      else {
        displayColumns = ForeignKeyConfig.getDisplayColumns(
          tableName: widget.referenceTable, 
          columnName: widget.referenceColumn,
        );
      }
      // -----------------------------------------------

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

          print('📊 Items cargados: ${items.length}');
          if (items.isNotEmpty) {
            print('   Primer item: id=${items.first.id}, display=${items.first.displayValue}');
          }

          // Normalizar el valor seleccionado
          if (_selectedValue != null) {
            print('🔍 Normalizando valor seleccionado: $_selectedValue (${_selectedValue.runtimeType})');

            if (_selectedValue is String) {
              _selectedValue = int.tryParse(_selectedValue) ?? _selectedValue;
              print('   Convertido a: $_selectedValue (${_selectedValue.runtimeType})');
            }

            final valueExists = _items.any((item) {
              print('   Comparando: item.id=${item.id} (${item.id.runtimeType}) con _selectedValue=$_selectedValue (${_selectedValue.runtimeType})');
              return item.id == _selectedValue;
            });

            if (!valueExists) {
              print('⚠️ Valor inicial $_selectedValue NO encontrado en items');
              print('   IDs disponibles: ${_items.map((e) => e.id).toList()}');
            } else {
              print('✅ Valor inicial $_selectedValue SÍ encontrado');
            }
          } else {
            print('⚠️ No hay valor inicial seleccionado');
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
        decoration: AppStyles.inputDecoration(labelText: widget.label),
        child: const Center(
          child: SizedBox(
            height: 20, width: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      if (!widget.isRequired) {
        return InputDecorator(
          decoration: AppStyles.inputDecoration(
            labelText: '${widget.label} (opcional - error)',
          ),
          child: const Text('No disponible', style: TextStyle(fontStyle: FontStyle.italic)),
        );
      }
      return InputDecorator(
        decoration: AppStyles.inputDecoration(
          labelText: widget.label,
          errorText: 'Error de carga',
        ),
        child: Row(
          children: [
            const Icon(Icons.error, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(_errorMessage ?? 'Error')),
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: _loadDropdownData,
            ),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return InputDecorator(
        decoration: AppStyles.inputDecoration(
          labelText: widget.label,
          helperText: 'No hay datos disponibles',
        ),
        child: const Text('Sin datos', style: TextStyle(fontStyle: FontStyle.italic)),
      );
    }

    return DropdownButtonFormField<dynamic>(
      decoration: AppStyles.inputDecoration(
        labelText: '${widget.label}${widget.isRequired ? ' *' : ''}',
      ).copyWith(
        helperText: widget.isRequired
            ? 'Campo obligatorio - Selecciona una opción'
            : 'Selecciona una opción',
        helperStyle: const TextStyle(fontSize: 11, color: Colors.grey),
      ),
      value: _selectedValue,
      isExpanded: true,
      items: _items.map((item) {
        return DropdownMenuItem<dynamic>(
          value: item.id,
          child: Text(
            item.displayValue,
            style: AppStyles.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedValue = value;
        });
        widget.onChanged(value);
      },
      validator: (value) {
        if (widget.isRequired) {
          if (value == null) {
            return '${AppStrings.requiredFieldMessage} - Debe seleccionar una opción en ${widget.label}';
          }
        }
        return null;
      },
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }
}