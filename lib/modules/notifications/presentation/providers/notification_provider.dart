import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:herramienta_case/modules/notifications/domain/models/notification_model.dart';

/// Provider para manejar el estado de las notificaciones
class NotificationProvider extends ChangeNotifier {
  static const String _storageKey = 'app_notifications';
  static const int _maxNotifications = 50; // Límite de notificaciones almacenadas

  final List<NotificationModel> _notifications = [];
  bool _isInitialized = false;

  /// Obtiene todas las notificaciones
  List<NotificationModel> get notifications => List.unmodifiable(_notifications);

  /// Obtiene las notificaciones no leídas
  List<NotificationModel> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();

  /// Obtiene el contador de notificaciones no leídas
  int get unreadCount => unreadNotifications.length;

  /// Indica si hay notificaciones no leídas
  bool get hasUnread => unreadCount > 0;

  /// Inicializa el provider cargando las notificaciones guardadas
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getString(_storageKey);

      if (notificationsJson != null) {
        final List<dynamic> decoded = jsonDecode(notificationsJson);
        _notifications.clear();
        _notifications.addAll(
          decoded.map((json) => NotificationModel.fromJson(json)),
        );
      }

      // Agregar notificación de bienvenida si no hay notificaciones
      if (_notifications.isEmpty) {
        await addNotification(
          title: 'Bienvenido',
          message: 'Bienvenido a la herramienta CASE. Aquí verás tus notificaciones.',
          type: NotificationType.info,
        );
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error al inicializar notificaciones: $e');
    }
  }

  /// Agrega una nueva notificación
  Future<void> addNotification({
    required String title,
    required String message,
    NotificationType type = NotificationType.info,
    String? actionRoute,
    Map<String, dynamic>? actionData,
  }) async {
    try {
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        message: message,
        type: type,
        timestamp: DateTime.now(),
        actionRoute: actionRoute,
        actionData: actionData,
      );

      _notifications.insert(0, notification);

      // Limitar el número de notificaciones
      if (_notifications.length > _maxNotifications) {
        _notifications.removeRange(_maxNotifications, _notifications.length);
      }

      await _saveNotifications();
      notifyListeners();
    } catch (e) {
      debugPrint('Error al agregar notificación: $e');
    }
  }

  /// Marca una notificación como leída
  Future<void> markAsRead(String id) async {
    try {
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1 && !_notifications[index].isRead) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        await _saveNotifications();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error al marcar notificación como leída: $e');
    }
  }

  /// Marca todas las notificaciones como leídas
  Future<void> markAllAsRead() async {
    try {
      bool hasChanges = false;
      for (int i = 0; i < _notifications.length; i++) {
        if (!_notifications[i].isRead) {
          _notifications[i] = _notifications[i].copyWith(isRead: true);
          hasChanges = true;
        }
      }

      if (hasChanges) {
        await _saveNotifications();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error al marcar todas las notificaciones como leídas: $e');
    }
  }

  /// Elimina una notificación
  Future<void> deleteNotification(String id) async {
    try {
      _notifications.removeWhere((n) => n.id == id);
      await _saveNotifications();
      notifyListeners();
    } catch (e) {
      debugPrint('Error al eliminar notificación: $e');
    }
  }

  /// Elimina todas las notificaciones
  Future<void> clearAll() async {
    try {
      _notifications.clear();
      await _saveNotifications();
      notifyListeners();
    } catch (e) {
      debugPrint('Error al limpiar notificaciones: $e');
    }
  }

  /// Guarda las notificaciones en SharedPreferences
  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = jsonEncode(
        _notifications.map((n) => n.toJson()).toList(),
      );
      await prefs.setString(_storageKey, notificationsJson);
    } catch (e) {
      debugPrint('Error al guardar notificaciones: $e');
    }
  }

  // ========== MÉTODOS DE UTILIDAD PARA CREAR NOTIFICACIONES ESPECÍFICAS ==========

  /// Crea una notificación de información
  Future<void> notifyInfo(String title, String message, {String? actionRoute}) async {
    await addNotification(
      title: title,
      message: message,
      type: NotificationType.info,
      actionRoute: actionRoute,
    );
  }

  /// Crea una notificación de éxito
  Future<void> notifySuccess(String title, String message, {String? actionRoute}) async {
    await addNotification(
      title: title,
      message: message,
      type: NotificationType.success,
      actionRoute: actionRoute,
    );
  }

  /// Crea una notificación de advertencia
  Future<void> notifyWarning(String title, String message, {String? actionRoute}) async {
    await addNotification(
      title: title,
      message: message,
      type: NotificationType.warning,
      actionRoute: actionRoute,
    );
  }

  /// Crea una notificación de error
  Future<void> notifyError(String title, String message) async {
    await addNotification(
      title: title,
      message: message,
      type: NotificationType.error,
    );
  }

  /// Crea una notificación del sistema
  Future<void> notifySystem(String title, String message, {String? actionRoute}) async {
    await addNotification(
      title: title,
      message: message,
      type: NotificationType.system,
      actionRoute: actionRoute,
    );
  }
}
