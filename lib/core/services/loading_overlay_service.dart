import 'package:flutter/material.dart';
import 'package:herramienta_case/core/widgets/loading_indicator.dart';

/// Servicio global para mostrar/ocultar overlay de carga
///
/// Este servicio permite mostrar un indicador de carga en toda la aplicación
/// de manera centralizada y profesional.
/// ```
class LoadingOverlayService {
  static OverlayEntry? _overlayEntry;
  static bool _isShowing = false;

  /// Muestra el overlay de carga
  ///
  /// [context] - BuildContext requerido para obtener el Overlay
  /// [text] - Texto personalizado (opcional)
  /// [dismissible] - Si se puede cerrar tocando fuera (default: false)
  static void show(
    BuildContext context, {
    String? text,
    bool dismissible = false,
  }) {
    if (_isShowing) return;

    _isShowing = true;
    _overlayEntry = OverlayEntry(
      builder: (context) => _LoadingOverlay(
        text: text,
        dismissible: dismissible,
        onDismiss: hide,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  /// Oculta el overlay de carga
  static void hide() {
    if (!_isShowing) return;

    _overlayEntry?.remove();
    _overlayEntry = null;
    _isShowing = false;
  }

  /// Verifica si el overlay está visible
  static bool get isShowing => _isShowing;

  /// Ejecuta una operación asíncrona mostrando el loading
  ///
  /// ```
  static Future<T> during<T>(
    BuildContext context, {
    required Future<T> future,
    String? text,
  }) async {
    show(context, text: text);

    try {
      final result = await future;
      return result;
    } finally {
      hide();
    }
  }
}

/// Widget interno del overlay de carga
class _LoadingOverlay extends StatelessWidget {
  final String? text;
  final bool dismissible;
  final VoidCallback onDismiss;

  const _LoadingOverlay({
    this.text,
    required this.dismissible,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: dismissible ? onDismiss : null,
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: Colors.black.withOpacity(0.7),
          child: Center(
            child: GestureDetector(
              onTap: () {}, // Prevenir que los taps pasen a través
              child: LoadingIndicator(
                text: text,
                backgroundColor: Colors.transparent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
