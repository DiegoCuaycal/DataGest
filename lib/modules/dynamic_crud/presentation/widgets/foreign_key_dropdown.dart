import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/dropdown_item_model.dart';
import '../providers/dynamic_crud_provider.dart';

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

  @override
  void initState() {
    super.initState();
    _loadDropdownData();
  }

  Future<void> _loadDropdownData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final provider = context.read<DynamicCrudProvider>();
      final items = await provider.getDropdownData(
        databaseName: widget.databaseName,
        tableName: widget.referenceTable,
      );

      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
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
        decoration: InputDecoration(
          labelText: widget.label,
          border: const OutlineInputBorder(),
        ),
        child: const Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return InputDecorator(
        decoration: InputDecoration(
          labelText: widget.label,
          border: const OutlineInputBorder(),
          errorText: 'Error al cargar datos',
        ),
        child: Row(
          children: [
            const Icon(Icons.error, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 12, color: Colors.red),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: _loadDropdownData,
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<dynamic>(
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
      ),
      initialValue: widget.initialValue,
      items: _items.map((item) {
        return DropdownMenuItem<dynamic>(
          value: item.id,
          child: Text(item.displayValue),
        );
      }).toList(),
      onChanged: widget.onChanged,
      validator: widget.isRequired
          ? (value) => value == null ? 'Campo requerido' : null
          : null,
    );
  }
}
