import 'package:flutter/material.dart';
import '../../data/models/table_info_model.dart';

class TableMenuItem extends StatelessWidget {
  final TableInfoModel table;
  final VoidCallback onTap;

  const TableMenuItem({
    super.key,
    required this.table,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          child: Icon(
            Icons.table_chart,
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: Text(
          table.table,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text('${table.rowCount} registros'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
