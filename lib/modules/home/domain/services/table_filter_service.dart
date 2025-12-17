import '../../../dynamic_crud/data/models/table_info_model.dart';

/// Servicio para filtrar y categorizar tablas de forma inteligente
class TableFilterService {
  /// Lista de prefijos/patrones de tablas del sistema que deben ser excluidas
  static const List<String> _systemTablePatterns = [
    'sys_',
    'system_',
    'information_schema',
    'mysql.',
    'performance_schema',
    '__',
    'flyway_',
    'databasechangelog',
    'schema_',
    'migrations',
    'django_',
    'auth_',
    'sqlalchemy_',
  ];

  /// Tablas técnicas comunes que no son de negocio
  static const List<String> _technicalTables = [
    'sessions',
    'cache',
    'jobs',
    'failed_jobs',
    'password_resets',
    'personal_access_tokens',
    'oauth_',
    'log',
    'logs',
    'audit',
    'audits',
  ];

  /// Obtiene las tablas más importantes de forma automática
  ///
  /// Criterios de importancia:
  /// 1. No son tablas del sistema
  /// 2. No son tablas técnicas
  /// 3. Tienen nombres cortos y significativos
  /// 4. Preferiblemente sin prefijos técnicos
  static List<TableInfoModel> getImportantTables(
    List<TableInfoModel> allTables, {
    int maxTables = 8,
  }) {
    // Filtrar tablas del sistema y técnicas
    final filteredTables = allTables.where((table) {
      final tableName = table.table.toLowerCase();

      // Excluir tablas del sistema
      for (final pattern in _systemTablePatterns) {
        if (tableName.startsWith(pattern)) return false;
      }

      // Excluir tablas técnicas
      for (final technical in _technicalTables) {
        if (tableName.contains(technical)) return false;
      }

      return true;
    }).toList();

    // Ordenar por "importancia" usando heurísticas
    filteredTables.sort((a, b) {
      final scoreA = _calculateImportanceScore(a);
      final scoreB = _calculateImportanceScore(b);
      return scoreB.compareTo(scoreA); // Descendente
    });

    // Retornar máximo N tablas
    return filteredTables.take(maxTables).toList();
  }

  /// Calcula un puntaje de importancia para una tabla
  /// Mayor puntaje = más importante
  static int _calculateImportanceScore(TableInfoModel table) {
    int score = 100; // Puntaje base
    final tableName = table.table.toLowerCase();

    // Preferir tablas con nombres cortos (más genéricas)
    if (tableName.length <= 10) {
      score += 30;
    } else if (tableName.length <= 15) {
      score += 15;
    }

    // Penalizar tablas con guiones bajos múltiples (probablemente técnicas)
    final underscoreCount = '_'.allMatches(tableName).length;
    score -= (underscoreCount * 5);

    // Bonificar tablas con nombres comunes de negocio
    final businessKeywords = [
      'user', 'cliente', 'customer', 'product', 'producto',
      'order', 'pedido', 'venta', 'sale', 'compra', 'purchase',
      'categoria', 'category', 'item', 'articulo',
      'empleado', 'employee', 'factura', 'invoice',
      'pago', 'payment', 'proveedor', 'supplier',
    ];

    for (final keyword in businessKeywords) {
      if (tableName.contains(keyword)) {
        score += 50;
        break;
      }
    }

    // Penalizar tablas que terminan con sufijos técnicos
    final technicalSuffixes = ['_log', '_history', '_backup', '_temp', '_tmp'];
    for (final suffix in technicalSuffixes) {
      if (tableName.endsWith(suffix)) {
        score -= 40;
        break;
      }
    }

    return score;
  }

  /// Agrupa tablas por categorías basadas en prefijos comunes
  static Map<String, List<TableInfoModel>> groupTablesByPrefix(
    List<TableInfoModel> tables,
  ) {
    final Map<String, List<TableInfoModel>> groups = {
      'General': [],
    };

    for (final table in tables) {
      final tableName = table.table;
      final parts = tableName.split('_');

      if (parts.length > 1) {
        // Tiene prefijo
        final prefix = parts[0];
        final capitalizedPrefix = _capitalize(prefix);

        groups.putIfAbsent(capitalizedPrefix, () => []);
        groups[capitalizedPrefix]!.add(table);
      } else {
        // Sin prefijo, va a General
        groups['General']!.add(table);
      }
    }

    // Eliminar categorías vacías
    groups.removeWhere((key, value) => value.isEmpty);

    return groups;
  }

  /// Capitaliza una cadena
  static String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  /// Obtiene un icono sugerido para una tabla basado en su nombre
  static String getTableIcon(String tableName) {
    final name = tableName.toLowerCase();

    if (name.contains('user') || name.contains('usuario') || name.contains('cliente') || name.contains('customer')) {
      return '👥';
    } else if (name.contains('product') || name.contains('producto') || name.contains('item') || name.contains('articulo')) {
      return '📦';
    } else if (name.contains('order') || name.contains('pedido') || name.contains('venta') || name.contains('sale')) {
      return '🛒';
    } else if (name.contains('category') || name.contains('categoria')) {
      return '📁';
    } else if (name.contains('payment') || name.contains('pago') || name.contains('factura') || name.contains('invoice')) {
      return '💳';
    } else if (name.contains('employee') || name.contains('empleado') || name.contains('staff')) {
      return '👔';
    } else if (name.contains('config') || name.contains('setting')) {
      return '⚙️';
    } else if (name.contains('report') || name.contains('reporte')) {
      return '📊';
    } else {
      return '📄';
    }
  }

  /// Obtiene un color sugerido basado en el índice
  static int getColorIndex(int index) {
    final colors = [0, 1, 2, 3, 4, 5]; // Índices de colores predefinidos
    return colors[index % colors.length];
  }
}
