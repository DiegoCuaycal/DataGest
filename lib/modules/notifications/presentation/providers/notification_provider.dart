import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:herramienta_case/modules/notifications/domain/models/notification_model.dart';

/// ChangeNotifier that manages the in-app notification list.
///
/// Notifications are persisted to [SharedPreferences] so they survive
/// app restarts. The list is capped at [_maxNotifications] entries.
class NotificationProvider extends ChangeNotifier {
  static const String _storageKey = 'app_notifications';
  static const int _maxNotifications = 50;

  final List<NotificationModel> _notifications = [];
  bool _isInitialized = false;

  /// All notifications in chronological order (newest first).
  List<NotificationModel> get notifications => List.unmodifiable(_notifications);

  /// Notifications that have not yet been read.
  List<NotificationModel> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();

  /// Number of unread notifications.
  int get unreadCount => unreadNotifications.length;

  /// `true` if there is at least one unread notification.
  bool get hasUnread => unreadCount > 0;

  /// Loads persisted notifications from storage and seeds a welcome
  /// notification on the first run.
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

      if (_notifications.isEmpty) {
        await addNotification(
          title: 'Bienvenido',
          message: 'Bienvenido a la herramienta CASE. Aquí verás tus notificaciones.',
          type: NotificationType.info,
        );
      }

      _isInitialized = true;
      notifyListeners();
    } catch (_) {
      // Initialisation errors are non-fatal; the app continues with an
      // empty notification list.
    }
  }

  /// Adds a new notification and persists the updated list.
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

      if (_notifications.length > _maxNotifications) {
        _notifications.removeRange(_maxNotifications, _notifications.length);
      }

      await _saveNotifications();
      notifyListeners();
    } catch (_) {
      // Persistence errors are non-fatal; the in-memory list is still updated.
    }
  }

  /// Marks the notification identified by [id] as read.
  Future<void> markAsRead(String id) async {
    try {
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1 && !_notifications[index].isRead) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        await _saveNotifications();
        notifyListeners();
      }
    } catch (_) {
      // Persistence errors are non-fatal.
    }
  }

  /// Marks all notifications as read.
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
    } catch (_) {
      // Persistence errors are non-fatal.
    }
  }

  /// Removes the notification identified by [id].
  Future<void> deleteNotification(String id) async {
    try {
      _notifications.removeWhere((n) => n.id == id);
      await _saveNotifications();
      notifyListeners();
    } catch (_) {
      // Persistence errors are non-fatal.
    }
  }

  /// Removes all notifications.
  Future<void> clearAll() async {
    try {
      _notifications.clear();
      await _saveNotifications();
      notifyListeners();
    } catch (_) {
      // Persistence errors are non-fatal.
    }
  }

  /// Persists the current notification list to [SharedPreferences].
  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = jsonEncode(
        _notifications.map((n) => n.toJson()).toList(),
      );
      await prefs.setString(_storageKey, notificationsJson);
    } catch (_) {
      // Persistence errors are non-fatal.
    }
  }

  /// Adds an informational notification.
  Future<void> notifyInfo(String title, String message, {String? actionRoute}) async {
    await addNotification(
      title: title,
      message: message,
      type: NotificationType.info,
      actionRoute: actionRoute,
    );
  }

  /// Adds a success notification.
  Future<void> notifySuccess(String title, String message, {String? actionRoute}) async {
    await addNotification(
      title: title,
      message: message,
      type: NotificationType.success,
      actionRoute: actionRoute,
    );
  }

  /// Adds a warning notification.
  Future<void> notifyWarning(String title, String message, {String? actionRoute}) async {
    await addNotification(
      title: title,
      message: message,
      type: NotificationType.warning,
      actionRoute: actionRoute,
    );
  }

  /// Adds an error notification.
  Future<void> notifyError(String title, String message) async {
    await addNotification(
      title: title,
      message: message,
      type: NotificationType.error,
    );
  }

  /// Adds a system notification.
  Future<void> notifySystem(String title, String message, {String? actionRoute}) async {
    await addNotification(
      title: title,
      message: message,
      type: NotificationType.system,
      actionRoute: actionRoute,
    );
  }
}
