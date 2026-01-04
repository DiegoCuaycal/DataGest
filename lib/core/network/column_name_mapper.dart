/// Configuración de mapeo de nombres de columnas entre BD y Backend
///
/// El backend .NET puede usar nombres de propiedades diferentes a los nombres
/// de columnas en la base de datos. Este mapper maneja esas diferencias.
class ColumnNameMapper {
  /// Mapeo de nombres de columnas
  /// Estructura: {
  ///   'NombreTabla': {
  ///     'nombre_columna_bd': 'nombrePropiedadBackend'
  ///   }
  /// }
  static const Map<String, Map<String, String>> _columnMapping = {
    // ========== EDUCACIÓN ==========
    'estudiantes': {
      'legajo': 'cedula', // BD usa 'legajo', backend usa 'Cedula'
      'usuario_id': 'usuarioId',
      'fecha_nacimiento': 'fechaNacimiento',
      'created_at': 'createdAt',
    },
    'profesores': {
      'usuario_id': 'usuarioId',
    },
    'cursos': {
      'profesor_id': 'profesorId',
    },
    'inscripciones': {
      'estudiante_id': 'estudianteId',
      'curso_id': 'cursoId',
      'fecha_inscripcion': 'fechaInscripcion',
    },

    // ========== PRODUCTOS ==========
    'categorias': {
      'padre_id': 'padreId',
    },
    'productos': {
      'categoria_id': 'categoriaId',
      'proveedor_id': 'proveedorId',
      'precio_costo': 'precioCosto',
      'precio_venta': 'precioVenta',
      'created_at': 'createdAt',
    },
    'inventario': {
      'producto_id': 'productoId',
      'stock_actual': 'stockActual',
      'stock_minimo': 'stockMinimo',
      'ubicacion_almacen': 'ubicacionAlmacen',
    },

    // ========== SALUD ==========
    'pacientes': {
      'numero_historia': 'numeroHistoria',
      'fecha_nacimiento': 'fechaNacimiento',
      'grupo_sanguineo': 'grupoSanguineo',
      'created_at': 'createdAt',
    },
    'medicos': {
      'numero_licencia': 'numeroLicencia',
    },
    'citas': {
      'paciente_id': 'pacienteId',
      'medico_id': 'medicoId',
      'fecha_hora': 'fechaHora',
      'motivo_consulta': 'motivoConsulta',
      'created_at': 'createdAt',
    },
    'diagnosticos': {
      'cita_id': 'citaId',
      'descripcion_diagnostico': 'descripcionDiagnostico',
      'tratamiento_recetado': 'tratamientoRecetado',
      'proxima_visita': 'proximaVisita',
    },
  };

  /// Obtiene el nombre que usa el backend para una columna de la BD
  ///
  /// Ejemplo:
  /// - getBackendName('estudiantes', 'legajo') → 'cedula'
  /// - getBackendName('estudiantes', 'nombres') → 'nombres' (sin cambio)
  static String getBackendName(String tableName, String dbColumnName) {
    final normalizedTable = tableName.toLowerCase();
    final normalizedColumn = dbColumnName.toLowerCase();

    if (_columnMapping.containsKey(normalizedTable)) {
      final tableMapping = _columnMapping[normalizedTable]!;
      if (tableMapping.containsKey(normalizedColumn)) {
        return tableMapping[normalizedColumn]!;
      }
    }

    // Si no hay mapeo, retornar el nombre original
    return dbColumnName;
  }

  /// Obtiene el nombre de columna de la BD a partir del nombre del backend
  ///
  /// Ejemplo:
  /// - getDatabaseName('estudiantes', 'cedula') → 'legajo'
  /// - getDatabaseName('estudiantes', 'nombres') → 'nombres' (sin cambio)
  static String getDatabaseName(String tableName, String backendName) {
    final normalizedTable = tableName.toLowerCase();
    final normalizedBackendName = backendName.toLowerCase();

    if (_columnMapping.containsKey(normalizedTable)) {
      final tableMapping = _columnMapping[normalizedTable]!;

      // Buscar el valor invertido
      for (var entry in tableMapping.entries) {
        if (entry.value.toLowerCase() == normalizedBackendName) {
          return entry.key;
        }
      }
    }

    // Si no hay mapeo, retornar el nombre original
    return backendName;
  }

  /// Transforma un Map de datos del backend al formato de la BD
  ///
  /// Ejemplo:
  /// Input:  {'cedula': 'ABC123', 'nombres': 'Juan'}
  /// Output: {'legajo': 'ABC123', 'nombres': 'Juan'}
  static Map<String, dynamic> toDatabaseFormat(
    String tableName,
    Map<String, dynamic> backendData,
  ) {
    final result = <String, dynamic>{};

    for (var entry in backendData.entries) {
      final dbColumnName = getDatabaseName(tableName, entry.key);
      result[dbColumnName] = entry.value;
    }

    return result;
  }

  /// Transforma un Map de datos de la BD al formato del backend
  ///
  /// Ejemplo:
  /// Input:  {'legajo': 'ABC123', 'nombres': 'Juan'}
  /// Output: {'cedula': 'ABC123', 'nombres': 'Juan'}
  static Map<String, dynamic> toBackendFormat(
    String tableName,
    Map<String, dynamic> dbData,
  ) {
    final result = <String, dynamic>{};

    for (var entry in dbData.entries) {
      final backendName = getBackendName(tableName, entry.key);
      result[backendName] = entry.value;
    }

    return result;
  }
}
