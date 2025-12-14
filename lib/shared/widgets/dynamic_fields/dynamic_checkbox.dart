import 'package:flutter/material.dart';

class DynamicCheckbox extends StatefulWidget {
  final String label;
  final bool initialValue;
  final Function(bool) onChanged;

  const DynamicCheckbox({
    super.key,
    required this.label,
    this.initialValue = false,
    required this.onChanged,
  });

  @override
  State<DynamicCheckbox> createState() => _DynamicCheckboxState();
}

class _DynamicCheckboxState extends State<DynamicCheckbox> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return FormField<bool>(
      initialValue: _value,
      builder: (FormFieldState<bool> state) {
        return InputDecorator(
          decoration: InputDecoration(
            labelText: widget.label,
            border: const OutlineInputBorder(),
          ),
          child: SwitchListTile(
            title: Text(_value ? 'Sí' : 'No'),
            value: _value,
            onChanged: (bool newValue) {
              setState(() {
                _value = newValue;
              });
              state.didChange(newValue);
              widget.onChanged(newValue);
            },
            contentPadding: EdgeInsets.zero,
          ),
        );
      },
    );
  }
}
