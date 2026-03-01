/// Configuración centralizada de mapeo de Foreign Keys
///
/// El backend .NET no devuelve información de FKs en los metadatos,
/// por lo que necesitamos mapearlas manualmente basándonos en las convenciones de nombres
class ForeignKeyConfig {
  /// Mapa de configuración de Foreign Keys
  /// Estructura: {
  ///   'NombreTabla': {
  ///     'nombre_columna_fk': {
  ///       'referenceTable': 'TablReferenciada',
  ///       'referenceColumn': 'Id',
  ///       'displayColumns': ['Columna1', 'Columna2'] // Columnas a mostrar en dropdown
  ///     }
  ///   }
  /// }
  static const Map<String, Map<String, Map<String, dynamic>>> _fkConfig = {
    'Cursos': {
      'Profesor_Id': {
        'referenceTable': 'Profesores',
        'referenceColumn': 'Id',
        'displayColumns': ['Nombres', 'Apellidos'],
      },
    },
    'Inscripciones': {
      'Estudiante_Id': {
        'referenceTable': 'Estudiantes',
        'referenceColumn': 'Id',
        'displayColumns': ['Nombres', 'Apellidos', 'Legajo'],
      },
      'Curso_Id': {
        'referenceTable': 'Cursos',
        'referenceColumn': 'Id',
        'displayColumns': ['Codigo', 'Nombre'],
      },
    },

    'Categorias': {
      'Padre_Id': {
        'referenceTable': 'Categorias',
        'referenceColumn': 'Id',
        'displayColumns': ['Nombre'],
      },
    },
    'Productos': {
      'Categoria_Id': {
        'referenceTable': 'Categorias',
        'referenceColumn': 'Id',
        'displayColumns': ['Nombre'],
      },
      'Proveedor_Id': {
        'referenceTable': 'Proveedores',
        'referenceColumn': 'Id',
        'displayColumns': ['Nombre', 'Contacto'],
      },
    },
    'Inventario': {
      'Producto_Id': {
        'referenceTable': 'Productos',
        'referenceColumn': 'Id',
        'displayColumns': ['Sku', 'Nombre'],
      },
    },

    'Citas': {
      'Paciente_Id': {
        'referenceTable': 'Pacientes',
        'referenceColumn': 'Id',
        'displayColumns': ['Nombres', 'Apellidos', 'NumeroHistoria'],
      },
      'Medico_Id': {
        'referenceTable': 'Medicos',
        'referenceColumn': 'Id',
        'displayColumns': ['Nombres', 'Apellidos', 'Especialidad'],
      },
    },
    'Diagnosticos': {
      'Cita_Id': {
        'referenceTable': 'Citas',
        'referenceColumn': 'Id',
        'displayColumns': ['Fecha_Hora', 'Motivo_Consulta'],
      },
    },
  };

  /// Detecta si una columna es una Foreign Key basándose en convenciones
  /// Convenciones soportadas:
  /// 1. Termina en '_Id' o '_id' (ej: Profesor_Id, Estudiante_Id)
  /// 2. Coincide exactamente con '{NombreTabla}Id' (ej: ProfesorId, EstudianteId)
  /// 3. Está configurada explícitamente en _fkConfig
  static bool isForeignKey(String tableName, String columnName) {
    // Normalizar nombres (convertir a PascalCase para comparación)
    final normalizedTable = _toPascalCase(tableName);
    final normalizedColumn = _toPascalCase(columnName);

    // 1. Verificar si está en la configuración explícita
    if (_fkConfig.containsKey(normalizedTable)) {
      if (_fkConfig[normalizedTable]!.containsKey(normalizedColumn)) {
        return true;
      }
    }

    // 2. Detectar por convención: termina en '_Id' o '_id'
    if (columnName.endsWith('_Id') || columnName.endsWith('_id')) {
      return true;
    }

    // 3. Detectar por convención: coincide con '{Tabla}Id'
    if (columnName.toLowerCase().endsWith('id') &&
        columnName.toLowerCase() != 'id') {
      return true;
    }

    return false;
  }

  /// Obtiene la información de referencia de una Foreign Key
  /// Retorna un Map con: referenceTable, referenceColumn, displayColumns
  static Map<String, dynamic>? getForeignKeyReference({
    required String tableName,
    required String columnName,
  }) {
    // Normalizar nombres
    final normalizedTable = _toPascalCase(tableName);
    final normalizedColumn = _toPascalCase(columnName);

    // 1. Buscar en configuración explícita
    if (_fkConfig.containsKey(normalizedTable)) {
      final tableConfig = _fkConfig[normalizedTable]!;
      if (tableConfig.containsKey(normalizedColumn)) {
        return tableConfig[normalizedColumn];
      }
    }

    // 2. Inferir basándose en convenciones
    return _inferForeignKeyReference(columnName);
  }

  /// Infiere la tabla referenciada basándose en el nombre de la columna FK
  static Map<String, dynamic>? _inferForeignKeyReference(String columnName) {
    // Caso 1: Formato "NombreTabla_Id" → tabla referenciada es "NombreTabla"
    if (columnName.endsWith('_Id') || columnName.endsWith('_id')) {
      final tableName = columnName.replaceAll(RegExp(r'_[Ii]d$'), '');

      // Pluralizar el nombre de la tabla (convención común en .NET)
      final pluralizedTable = _pluralize(tableName);

      return {
        'referenceTable': pluralizedTable,
        'referenceColumn': 'Id',
        'displayColumns': ['Nombre', 'Nombres'], // Columnas por defecto
      };
    }

    // Caso 2: Formato "NombreTablaId" → tabla referenciada es "NombreTabla"
    if (columnName.toLowerCase().endsWith('id') &&
        columnName.toLowerCase() != 'id') {
      final tableName = columnName.substring(0, columnName.length - 2);

      // Pluralizar el nombre de la tabla
      final pluralizedTable = _pluralize(tableName);

      return {
        'referenceTable': pluralizedTable,
        'referenceColumn': 'Id',
        'displayColumns': ['Nombre', 'Nombres'],
      };
    }

    return null;
  }

  /// Pluraliza un nombre de tabla siguiendo convenciones comunes en español
  static String _pluralize(String singular) {
    // Reglas de pluralización en español

    // Ya está en plural (termina en 's')
    if (singular.endsWith('s')) {
      return singular;
    }

    // Casos especiales
    final specialCases = {
      'Categoria': 'Categorias',
      'Producto': 'Productos',
      'Inventario': 'Inventarios',
      'Estudiante': 'Estudiantes',
      'Profesor': 'Profesores',
      'Curso': 'Cursos',
      'Inscripcion': 'Inscripciones',
      'Paciente': 'Pacientes',
      'Medico': 'Medicos',
      'Cita': 'Citas',
      'Diagnostico': 'Diagnosticos',
      'Proveedor': 'Proveedores',
      'Usuario': 'Usuarios',
    };

    if (specialCases.containsKey(singular)) {
      return specialCases[singular]!;
    }

    // Regla general: agregar 's' al final
    if (singular.endsWith('r') ||
        singular.endsWith('n') ||
        singular.endsWith('l') ||
        singular.endsWith('d') ||
        singular.endsWith('j')) {
      return '${singular}es';
    }

    // Por defecto, agregar 's'
    return '${singular}s';
  }

  /// Convierte un string a PascalCase (primera letra mayúscula, sin guiones bajos)
  static String _toPascalCase(String str) {
    if (str.isEmpty) return str;

    // Si ya está en PascalCase, retornar tal cual
    if (!str.contains('_') && str[0] == str[0].toUpperCase()) {
      return str;
    }

    // Convertir snake_case a PascalCase
    return str.split('_').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join('');
  }

  /// Obtiene las columnas a mostrar en el dropdown para una FK
  static List<String> getDisplayColumns({
    required String tableName,
    required String columnName,
  }) {
    final reference = getForeignKeyReference(
      tableName: tableName,
      columnName: columnName,
    );

    if (reference != null && reference.containsKey('displayColumns')) {
      return List<String>.from(reference['displayColumns']);
    }

    // Columnas por defecto
    return ['Nombre', 'Nombres', 'Descripcion'];
  }

  /// Obtiene la tabla referenciada para una FK
  static String? getReferenceTable({
    required String tableName,
    required String columnName,
  }) {
    final reference = getForeignKeyReference(
      tableName: tableName,
      columnName: columnName,
    );

    return reference?['referenceTable'] as String?;
  }

  /// Obtiene la columna referenciada para una FK (generalmente 'Id')
  static String? getReferenceColumn({
    required String tableName,
    required String columnName,
  }) {
    final reference = getForeignKeyReference(
      tableName: tableName,
      columnName: columnName,
    );

    return reference?['referenceColumn'] as String?;
  }

  /// Verifica si una tabla tiene Foreign Keys configuradas
  static bool hasConfiguredForeignKeys(String tableName) {
    final normalizedTable = _toPascalCase(tableName);
    return _fkConfig.containsKey(normalizedTable);
  }

  /// Obtiene todas las Foreign Keys de una tabla
  static List<String> getForeignKeysForTable(String tableName) {
    final normalizedTable = _toPascalCase(tableName);

    if (_fkConfig.containsKey(normalizedTable)) {
      return _fkConfig[normalizedTable]!.keys.toList();
    }

    return [];
  }
}
