class AppBuildConfig {
  // The placeholder string is split so the .NET build script does not replace
  // the sentinel variable itself—only the dedicated public constants below are substituted.
  static const String _placeholderPattern = "{{" + "DB_NAME_PLACEHOLDER" + "}}";
  static const String _serverPlaceholderPattern = "{{" + "SERVER_PROFILE_PLACEHOLDER" + "}}";

  /// Replaced by the .NET build script with the target database name (e.g. "Medicos").
  static const String defaultDatabaseName = "{{DB_NAME_PLACEHOLDER}}";

  /// Replaced by the .NET build script with the target server profile (e.g. "Produccion").
  static const String defaultServerProfile = "{{SERVER_PROFILE_PLACEHOLDER}}";

  /// Returns `true` when the .NET build script has substituted a real database
  /// name, indicating the app was compiled with a pre-configured connection target.
  static bool get isPreConfigured =>
      defaultDatabaseName != _placeholderPattern &&
      defaultDatabaseName.isNotEmpty;

  static String? get configuredDatabase =>
      isPreConfigured ? defaultDatabaseName : null;

  /// Returns `true` when the .NET build script has substituted a real server
  /// profile, indicating the app was compiled targeting a specific environment.
  static bool get isServerPreConfigured =>
      defaultServerProfile != _serverPlaceholderPattern &&
      defaultServerProfile.isNotEmpty;

  static String? get configuredServerProfile =>
      isServerPreConfigured ? defaultServerProfile : null;

  AppBuildConfig._();
}