class AppBuildConfig {
  // TRUCO DE SEGURIDAD:
  // Partimos el string en pedazos ("{{" + ... + "}}") para que el script de C#
  // NO lo reemplace aquí (en la variable _placeholderPattern), solo abajo.
  static const String _placeholderPattern = "{{" + "DB_NAME_PLACEHOLDER" + "}}";
  static const String _serverPlaceholderPattern = "{{" + "SERVER_PROFILE_PLACEHOLDER" + "}}";

  /// C# buscará "{{DB_NAME_PLACEHOLDER}}" y pondrá aquí el nombre (ej: "Medicos").
  static const String defaultDatabaseName = "{{DB_NAME_PLACEHOLDER}}";

  /// C# buscará "{{SERVER_PROFILE_PLACEHOLDER}}" y pondrá aquí el perfil (ej: "Produccion").
  static const String defaultServerProfile = "{{SERVER_PROFILE_PLACEHOLDER}}";

  /// LÓGICA DEL INTERRUPTOR (Base de datos):
  static bool get isPreConfigured =>
      defaultDatabaseName != _placeholderPattern &&
      defaultDatabaseName.isNotEmpty;

  static String? get configuredDatabase =>
      isPreConfigured ? defaultDatabaseName : null;

  /// LÓGICA DEL INTERRUPTOR (Servidor):
  static bool get isServerPreConfigured =>
      defaultServerProfile != _serverPlaceholderPattern &&
      defaultServerProfile.isNotEmpty;

  static String? get configuredServerProfile =>
      isServerPreConfigured ? defaultServerProfile : null;

  AppBuildConfig._();
}