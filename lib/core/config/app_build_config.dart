class AppBuildConfig {
  // TRUCO DE SEGURIDAD:
  // Partimos el string en pedazos ("{{" + ... + "}}") para que el script de C#
  // NO lo reemplace aquí (en la variable _placeholderPattern), solo abajo.
  static const String _placeholderPattern = "{{" + "DB_NAME_PLACEHOLDER" + "}}";

  /// 🚨 IMPORTANTE: Esta línea debe tener EXACTAMENTE este texto.
  /// C# buscará "{{DB_NAME_PLACEHOLDER}}" y pondrá aquí el nombre (ej: "Medicos").
  /// Si tu compañera puso "Productos" o "", cámbialo a esto:
  static const String defaultDatabaseName = "{{DB_NAME_PLACEHOLDER}}";

  /// LÓGICA DEL INTERRUPTOR:
  /// Compara si el valor actual es diferente al patrón original.
  /// Si C# inyectó "Medicos", entonces "Medicos" != "{{...}}" -> TRUE (Es Dinámica)
  /// Si nadie inyectó nada, "{{...}}" == "{{...}}" -> FALSE (Es Genérica)
  static bool get isPreConfigured =>
      defaultDatabaseName != _placeholderPattern &&
      defaultDatabaseName.isNotEmpty;

  static String? get configuredDatabase =>
      isPreConfigured ? defaultDatabaseName : null;

  AppBuildConfig._();
}