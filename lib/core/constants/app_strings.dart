/// Textos y mensajes de la aplicación
class AppStrings {
  // General
  static const String appName = 'Herramientas CASE';
  static const String ok = 'Aceptar';
  static const String cancel = 'Cancelar';
  static const String save = 'Guardar';
  static const String delete = 'Eliminar';
  static const String edit = 'Editar';
  static const String close = 'Cerrar';
  static const String loading = 'Cargando...';
  static const String retry = 'Reintentar';
  static const String back = 'Volver';

  // Autenticación
  static const String login = 'Iniciar Sesión';
  static const String logout = 'Cerrar Sesión';
  static const String email = 'Correo Electrónico';
  static const String password = 'Contraseña';
  static const String rememberMe = 'Recordarme';
  static const String forgotPassword = '¿Olvidaste tu contraseña?';
  static const String welcomeBack = '¡Bienvenido de nuevo!';
  static const String loginToContinue = 'Inicia sesión para continuar';

  // Mensajes de validación
  static const String requiredField = 'Este campo es requerido';
  static const String invalidEmail = 'Correo electrónico inválido';
  static const String invalidPassword = 'La contraseña debe tener al menos 6 caracteres';
  static const String passwordsDoNotMatch = 'Las contraseñas no coinciden';

  // Mensajes de error
  static const String errorGeneric = 'Ha ocurrido un error. Por favor, intenta de nuevo.';
  static const String errorNetwork = 'Error de conexión. Verifica tu conexión a internet.';
  static const String errorServer = 'Error del servidor. Intenta más tarde.';
  static const String errorUnauthorized = 'No tienes autorización para esta acción.';
  static const String errorNotFound = 'Recurso no encontrado.';
  static const String errorTimeout = 'Tiempo de espera agotado.';
  static const String errorInvalidCredentials = 'Credenciales incorrectas';

  // Mensajes de éxito
  static const String successLogin = 'Inicio de sesión exitoso';
  static const String successLogout = 'Sesión cerrada exitosamente';
  static const String successSave = 'Guardado exitosamente';
  static const String successDelete = 'Eliminado exitosamente';
  static const String successUpdate = 'Actualizado exitosamente';

  // Home
  static const String home = 'Inicio';
  static const String welcome = 'Bienvenido';
  static const String dashboard = 'Panel de Control';

  // Herramientas CASE
  static const String tools = 'Herramientas';
  static const String toolsList = 'Lista de Herramientas';
  static const String toolDetail = 'Detalle de Herramienta';
  static const String addTool = 'Agregar Herramienta';
  static const String editTool = 'Editar Herramienta';
  static const String deleteTool = 'Eliminar Herramienta';
  static const String toolName = 'Nombre de la Herramienta';
  static const String toolDescription = 'Descripción';
  static const String toolCategory = 'Categoría';
  static const String noToolsFound = 'No se encontraron herramientas';

  // Confirmaciones
  static const String confirmDelete = '¿Estás seguro de eliminar este elemento?';
  static const String confirmLogout = '¿Estás seguro de cerrar sesión?';

  /// Constructor privado para evitar instanciación
  AppStrings._();
}
