/// Mapper que traduce nombres de tablas y bases de datos a los endpoints específicos del backend
class EndpointMapper {
  /// Obtiene el prefijo de API según la base de datos
  static String _getApiPrefix(String databaseName) {
    final dbLower = databaseName.toLowerCase();

    if (dbLower.contains('estudiante') || dbLower.contains('educacion')) {
      return 'educacion';
    } else if (dbLower.contains('producto')) {
      return 'productos';
    } else if (dbLower.contains('medico') || dbLower.contains('médico') || dbLower.contains('salud')) {
      return 'salud';
    }

    // Fallback: usar el nombre de la base de datos
    return databaseName.toLowerCase();
  }

  /// Mapea el endpoint correcto para listar registros de una tabla
  static String getListEndpoint({
    required String databaseName,
    required String tableName,
  }) {
    final apiPrefix = _getApiPrefix(databaseName);
    final tableLower = tableName.toLowerCase();

    // ========== MAPEO DE ENDPOINTS SEGÚN EL BACKEND ==========
    // Basado en la estructura real del backend en BackFabrica

    // ENDPOINTS DE EDUCACIÓN
    if (apiPrefix == 'educacion') {
      switch (tableLower) {
        case 'estudiantes':
          return '/api/educacion/estudiantes';
        case 'profesores':
          return '/api/educacion/profesores';
        case 'cursos':
          return '/api/educacion/cursos';
        case 'inscripciones':
          // IMPORTANTE: El backend solo tiene POST /api/educacion/inscribir
          // Para GET, intentar con endpoint estándar (puede no existir)
          return '/api/educacion/inscripciones';
        case 'usuarios':
          // Los usuarios están integrados en Estudiantes/Profesores
          return '/api/usuarios';
      }
    }

    // ENDPOINTS DE SALUD
    if (apiPrefix == 'salud') {
      switch (tableLower) {
        case 'pacientes':
          return '/api/salud/pacientes';
        case 'medicos':
        case 'médicos':
          return '/api/salud/medicos';
        case 'citas':
          return '/api/salud/citas';
        case 'diagnosticos':
        case 'diagnósticos':
          return '/api/salud/diagnosticos';
        case 'usuarios':
          // Los usuarios están integrados en Médicos
          return '/api/usuarios';
      }
    }

    // ENDPOINTS DE PRODUCTOS
    if (apiPrefix == 'productos') {
      switch (tableLower) {
        case 'productos':
          return '/api/productos';
        case 'categorias':
        case 'categorías':
          return '/api/productos/categorias';
        case 'proveedores':
          return '/api/productos/proveedores';
        case 'inventario':
        case 'inventarios':
          return '/api/productos/inventario';
      }
    }

    // CASO ESPECIAL: tabla "usuarios" sin prefijo específico
    if (tableLower == 'usuarios') {
      // Los usuarios son parte de otras entidades (Estudiantes, Profesores, Médicos)
      return '/api/usuarios';
    }

    // PATRÓN GENERAL (fallback): /api/{apiPrefix}/{tabla}
    return '/api/$apiPrefix/$tableLower';
  }

  /// Mapea el endpoint para obtener un registro específico por ID
  static String getByIdEndpoint({
    required String databaseName,
    required String tableName,
    required dynamic id,
  }) {
    final baseEndpoint = getListEndpoint(
      databaseName: databaseName,
      tableName: tableName,
    );
    return '$baseEndpoint/$id';
  }

  /// Mapea el endpoint para crear un nuevo registro
  static String getCreateEndpoint({
    required String databaseName,
    required String tableName,
  }) {
    final apiPrefix = _getApiPrefix(databaseName);
    final tableLower = tableName.toLowerCase();

    // Casos especiales para CREATE (POST)
    if (apiPrefix == 'educacion' && tableLower == 'inscripciones') {
      // Inscripciones usa un endpoint especial para POST
      return '/api/educacion/inscribir';
    }

    // Para POST, usar el mismo endpoint que el listado
    return getListEndpoint(databaseName: databaseName, tableName: tableName);
  }

  /// Mapea el endpoint para actualizar un registro
  static String getUpdateEndpoint({
    required String databaseName,
    required String tableName,
    required dynamic id,
  }) {
    // Usar el mismo patrón que getByIdEndpoint
    return getByIdEndpoint(
      databaseName: databaseName,
      tableName: tableName,
      id: id,
    );
  }

  /// Mapea el endpoint para eliminar un registro
  static String getDeleteEndpoint({
    required String databaseName,
    required String tableName,
    required dynamic id,
  }) {
    // Usar el mismo patrón que getByIdEndpoint
    return getByIdEndpoint(
      databaseName: databaseName,
      tableName: tableName,
      id: id,
    );
  }

  /// Mapea el endpoint para obtener opciones de dropdown (foreign keys)
  static String getDropdownEndpoint({
    required String databaseName,
    required String tableName,
  }) {
    // Para dropdowns, usar el mismo endpoint que para listar la tabla
    // El backend devuelve todos los registros y el frontend filtra lo necesario
    return getListEndpoint(
      databaseName: databaseName,
      tableName: tableName,
    );
  }

  /// Verifica si una tabla tiene soporte completo de CRUD en el backend
  /// Ahora simplificado: si podemos determinar un prefijo de API válido,
  /// asumimos que la tabla tiene soporte CRUD siguiendo el patrón del backend
  static bool isCrudSupported({
    required String databaseName,
    required String tableName,
  }) {
    // Si podemos obtener un prefijo de API válido, la tabla es soportada
    final apiPrefix = _getApiPrefix(databaseName);

    // Verificar que tengamos un prefijo válido (no vacío)
    return apiPrefix.isNotEmpty && tableName.isNotEmpty;
  }

  /// Obtiene el nombre del header X-DbName que espera el backend
  static String getDatabaseHeaderValue(String databaseName) {
    final dbLower = databaseName.toLowerCase();

    if (dbLower.contains('estudiante') || dbLower.contains('educacion')) {
      return 'Estudiantes';
    } else if (dbLower.contains('producto')) {
      return 'Productos';
    } else if (dbLower.contains('medico') || dbLower.contains('médico') || dbLower.contains('salud')) {
      return 'Medicos';
    }

    // Fallback: usar el nombre original
    return databaseName;
  }
}
