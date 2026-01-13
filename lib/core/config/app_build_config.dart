/// Configuración de compilación de la aplicación
/// Este archivo contiene placeholders que son reemplazados por el generador de APK
class AppBuildConfig {
  /// Nombre de la base de datos pre-configurada
  /// Este placeholder será reemplazado por el script de C# antes de compilar
  /// Si el valor no es reemplazado, la app funcionará en "Modo Genérico"
  static const String defaultDatabaseName = "{{DB_NAME_PLACEHOLDER}}";

  /// Indica si la app fue pre-configurada para una base de datos específica
  /// Retorna true si el placeholder fue reemplazado con un nombre de BD válido
  /// Retorna false si la app está en "Modo Genérico" (sin pre-configuración)
  static bool get isPreConfigured =>
      defaultDatabaseName != "{{DB_NAME_PLACEHOLDER}}" &&
      defaultDatabaseName.isNotEmpty;

  /// Retorna el nombre de la base de datos configurada o null si no hay ninguna
  static String? get configuredDatabase =>
      isPreConfigured ? defaultDatabaseName : null;

  AppBuildConfig._();
}
