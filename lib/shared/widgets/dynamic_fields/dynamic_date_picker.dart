import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:herramienta_case/core/constants/app_colors.dart';
import 'package:herramienta_case/core/constants/app_icons.dart';
import 'package:herramienta_case/core/constants/app_strings.dart';
import 'package:herramienta_case/core/constants/app_styles.dart';

class DynamicDatePicker extends StatefulWidget {
  final String label;
  final bool includeTime;
  final bool isRequired;
  final dynamic initialValue;
  final Function(DateTime?) onChanged;

  const DynamicDatePicker({
    super.key,
    required this.label,
    this.includeTime = false,
    this.isRequired = false,
    this.initialValue,
    required this.onChanged,
  });

  @override
  State<DynamicDatePicker> createState() => _DynamicDatePickerState();
}

class _DynamicDatePickerState extends State<DynamicDatePicker> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    print('🗓️ DatePicker - Inicializando para campo: ${widget.label}');
    print('   initialValue recibido: ${widget.initialValue} (tipo: ${widget.initialValue.runtimeType})');

    if (widget.initialValue != null) {
      if (widget.initialValue is DateTime) {
        final date = widget.initialValue as DateTime;
        print('   📅 Es DateTime: $date (año: ${date.year})');
        // Validar que la fecha no sea la fecha por defecto de C# (0001-01-01)
        // y que esté dentro del rango válido (1900-2100)
        if (date.year >= 1900 && date.year <= 2100) {
          _selectedDate = date;
          _selectedTime = TimeOfDay.fromDateTime(_selectedDate!);
          print('   ✅ Fecha válida, establecida: $_selectedDate');
        } else {
          print('   ❌ Fecha fuera del rango válido (${date.year} no está entre 1900-2100)');
        }
      } else if (widget.initialValue is String) {
        final dateStr = widget.initialValue as String;
        print('   📝 Es String: "$dateStr"');
        final date = DateTime.tryParse(dateStr);
        print('   🔄 Parseado a: $date');
        if (date != null && date.year >= 1900 && date.year <= 2100) {
          _selectedDate = date;
          _selectedTime = TimeOfDay.fromDateTime(_selectedDate!);
          print('   ✅ Fecha válida, establecida: $_selectedDate');
        } else {
          print('   ❌ Fecha inválida o fuera de rango');
        }
      }
    } else {
      print('   ⚠️ initialValue es null');
    }

    _controller = TextEditingController(text: _formatDateTime(_selectedDate));
    print('   📝 Texto del controlador: "${_controller.text}"');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return '';
    if (widget.includeTime) {
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    // Asegurar que initialDate esté dentro del rango válido
    DateTime initialDate;
    if (_selectedDate != null &&
        _selectedDate!.year >= 1900 &&
        _selectedDate!.year <= 2100) {
      initialDate = _selectedDate!;
    } else {
      initialDate = DateTime.now();
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });

      if (widget.includeTime) {
        await _selectTime(context);
      } else {
        _controller.text = _formatDateTime(_selectedDate);
        widget.onChanged(_selectedDate);
      }
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );

    if (picked != null && _selectedDate != null) {
      setState(() {
        _selectedTime = picked;
        _selectedDate = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          picked.hour,
          picked.minute,
        );
        _controller.text = _formatDateTime(_selectedDate);
      });
      widget.onChanged(_selectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      decoration: AppStyles.inputDecoration(
        labelText: '${widget.label}${widget.isRequired ? ' *' : ''}',
      ).copyWith(
        helperText: widget.isRequired
            ? 'Campo obligatorio - Selecciona una fecha'
            : 'Selecciona una fecha',
        helperStyle: const TextStyle(fontSize: 11, color: Colors.grey),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(
                AppIcons.calendar,
                color: AppColors.primary,
              ),
              onPressed: () => _selectDate(context),
            ),
            if (_selectedDate != null)
              IconButton(
                icon: const Icon(
                  AppIcons.clear,
                  color: AppColors.textSecondary,
                ),
                onPressed: () {
                  setState(() {
                    _selectedDate = null;
                    _selectedTime = null;
                    _controller.clear();
                  });
                  widget.onChanged(null);
                },
              ),
          ],
        ),
      ),
      readOnly: true,
      onTap: () => _selectDate(context),
      validator: (value) {
        if (widget.isRequired) {
          if (value == null || value.isEmpty) {
            return '${AppStrings.requiredFieldMessage} - Debe seleccionar una fecha para ${widget.label}';
          }
          if (_selectedDate == null) {
            return 'Por favor selecciona una fecha válida';
          }
        }
        return null;
      },
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }
}
