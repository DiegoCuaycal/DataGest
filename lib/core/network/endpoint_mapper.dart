/// Maps database names and table names to the corresponding REST API endpoints
/// defined in the backend.
///
/// The backend organizes resources by domain (`educacion`, `salud`, `productos`),
/// and each domain has its own set of endpoints. This mapper centralizes that
/// routing logic so the rest of the application remains decoupled from specific
/// URL patterns.
class EndpointMapper {
  /// Resolves the API domain prefix for a given [databaseName].
  ///
  /// Returns `'educacion'`, `'salud'`, or `'productos'` based on keywords
  /// found in [databaseName]. Falls back to the lowercased database name
  /// if no known domain keyword is matched.
  static String _getApiPrefix(String databaseName) {
    final dbLower = databaseName.toLowerCase();

    if (dbLower.contains('estudiante') || dbLower.contains('educacion')) {
      return 'educacion';
    } else if (dbLower.contains('producto')) {
      return 'productos';
    } else if (dbLower.contains('medico') || dbLower.contains('médico') || dbLower.contains('salud')) {
      return 'salud';
    }

    return databaseName.toLowerCase();
  }

  /// Returns the GET (list) endpoint for [tableName] in [databaseName].
  ///
  /// Applies explicit table-to-endpoint mappings for each supported domain.
  /// Falls back to the pattern `/api/{domain}/{table}` for unmapped tables.
  static String getListEndpoint({
    required String databaseName,
    required String tableName,
  }) {
    final apiPrefix = _getApiPrefix(databaseName);
    final tableLower = tableName.toLowerCase();

    if (apiPrefix == 'educacion') {
      switch (tableLower) {
        case 'estudiantes':
          return '/api/educacion/estudiantes';
        case 'profesores':
          return '/api/educacion/profesores';
        case 'cursos':
          return '/api/educacion/cursos';
        case 'inscripciones':
          // The backend only exposes POST /api/educacion/inscribir for writes;
          // the GET endpoint follows the standard pattern.
          return '/api/educacion/inscripciones';
        case 'usuarios':
          return '/api/usuarios';
      }
    }

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
          return '/api/usuarios';
      }
    }

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

    if (tableLower == 'usuarios') {
      return '/api/usuarios';
    }

    return '/api/$apiPrefix/$tableLower';
  }

  /// Returns the endpoint for fetching a single record by [id].
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

  /// Returns the POST endpoint for creating a new record in [tableName].
  ///
  /// Uses a dedicated endpoint for the `inscripciones` table in the education
  /// domain; all other tables reuse the list endpoint.
  static String getCreateEndpoint({
    required String databaseName,
    required String tableName,
  }) {
    final apiPrefix = _getApiPrefix(databaseName);
    final tableLower = tableName.toLowerCase();

    if (apiPrefix == 'educacion' && tableLower == 'inscripciones') {
      return '/api/educacion/inscribir';
    }

    return getListEndpoint(databaseName: databaseName, tableName: tableName);
  }

  /// Returns the PUT endpoint for updating a record identified by [id].
  static String getUpdateEndpoint({
    required String databaseName,
    required String tableName,
    required dynamic id,
  }) {
    return getByIdEndpoint(
      databaseName: databaseName,
      tableName: tableName,
      id: id,
    );
  }

  /// Returns the DELETE endpoint for removing a record identified by [id].
  static String getDeleteEndpoint({
    required String databaseName,
    required String tableName,
    required dynamic id,
  }) {
    return getByIdEndpoint(
      databaseName: databaseName,
      tableName: tableName,
      id: id,
    );
  }

  /// Returns the endpoint used to populate a foreign key dropdown for [tableName].
  ///
  /// Delegates to [getListEndpoint] since dropdowns are populated from the
  /// full record list, with display value extraction handled client-side.
  static String getDropdownEndpoint({
    required String databaseName,
    required String tableName,
  }) {
    return getListEndpoint(
      databaseName: databaseName,
      tableName: tableName,
    );
  }

  /// Returns `true` if a valid API prefix can be resolved for [databaseName],
  /// indicating that CRUD operations are supported for that database.
  static bool isCrudSupported({
    required String databaseName,
    required String tableName,
  }) {
    final apiPrefix = _getApiPrefix(databaseName);
    return apiPrefix.isNotEmpty && tableName.isNotEmpty;
  }

  /// Returns the value for the `X-DbName` header expected by the backend for
  /// a given [databaseName].
  ///
  /// The backend uses this header to route the request to the correct SQL
  /// Server database instance.
  static String getDatabaseHeaderValue(String databaseName) {
    final dbLower = databaseName.toLowerCase();

    if (dbLower.contains('estudiante') || dbLower.contains('educacion')) {
      return 'Estudiantes';
    } else if (dbLower.contains('producto')) {
      return 'Productos';
    } else if (dbLower.contains('medico') || dbLower.contains('médico') || dbLower.contains('salud')) {
      return 'Medicos';
    }

    return databaseName;
  }
}
