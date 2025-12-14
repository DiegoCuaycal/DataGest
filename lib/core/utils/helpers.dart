import 'package:flutter/material.dart';
import 'package:herramienta_case/core/constants/app_colors.dart';
import 'package:herramienta_case/core/config/app_config.dart';

/// Funciones de ayuda y utilidades generales
class Helpers {
  /// Muestra un SnackBar con un mensaje
  static void showSnackBar(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Duration? duration,
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration ??
            Duration(seconds: AppConfig.snackbarDuration),
        action: action,
      ),
    );
  }

  /// Muestra un SnackBar de éxito
  static void showSuccessSnackBar(
    BuildContext context,
    String message,
  ) {
    showSnackBar(
      context,
      message,
      backgroundColor: AppColors.success,
    );
  }

  /// Muestra un SnackBar de error
  static void showErrorSnackBar(
    BuildContext context,
    String message,
  ) {
    showSnackBar(
      context,
      message,
      backgroundColor: AppColors.error,
    );
  }

  /// Muestra un SnackBar de información
  static void showInfoSnackBar(
    BuildContext context,
    String message,
  ) {
    showSnackBar(
      context,
      message,
      backgroundColor: AppColors.info,
    );
  }

  /// Muestra un SnackBar de advertencia
  static void showWarningSnackBar(
    BuildContext context,
    String message,
  ) {
    showSnackBar(
      context,
      message,
      backgroundColor: AppColors.warning,
    );
  }

  /// Muestra un diálogo de confirmación
  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Aceptar',
    String cancelText = 'Cancelar',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Muestra un diálogo de alerta simple
  static Future<void> showAlertDialog(
    BuildContext context, {
    required String title,
    required String message,
    String buttonText = 'Aceptar',
  }) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  /// Muestra un diálogo de carga
  static void showLoadingDialog(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 20),
                Text(message ?? 'Cargando...'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Cierra el diálogo de carga
  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }

  /// Formatea una fecha a string legible
  static String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  /// Formatea una fecha con hora a string legible
  static String formatDateTime(DateTime date) {
    return '${formatDate(date)} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  /// Capitaliza la primera letra de un string
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  /// Capitaliza cada palabra de un string
  static String capitalizeWords(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) => capitalize(word)).join(' ');
  }

  /// Trunca un texto a una longitud máxima
  static String truncate(String text, int maxLength, {String suffix = '...'}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - suffix.length)}$suffix';
  }

  /// Oculta el teclado
  static void hideKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  /// Verifica si el teclado está visible
  static bool isKeyboardVisible(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom > 0;
  }

  /// Obtiene el tamaño de la pantalla
  static Size getScreenSize(BuildContext context) {
    return MediaQuery.of(context).size;
  }

  /// Verifica si es una pantalla pequeña (móvil)
  static bool isSmallScreen(BuildContext context) {
    return getScreenSize(context).width < 600;
  }

  /// Verifica si es una pantalla mediana (tablet)
  static bool isMediumScreen(BuildContext context) {
    final width = getScreenSize(context).width;
    return width >= 600 && width < 1024;
  }

  /// Verifica si es una pantalla grande (desktop)
  static bool isLargeScreen(BuildContext context) {
    return getScreenSize(context).width >= 1024;
  }

  /// Delay asíncrono
  static Future<void> delay(int milliseconds) async {
    await Future.delayed(Duration(milliseconds: milliseconds));
  }

  /// Constructor privado para evitar instanciación
  Helpers._();
}
