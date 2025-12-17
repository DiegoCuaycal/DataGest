import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../domain/models/recent_activity_model.dart';

/// Provider para gestionar la actividad reciente del usuario
class RecentActivityProvider extends ChangeNotifier {
  static const String _storageKey = 'recent_activities';
  static const int _maxActivities = 10;

  List<RecentActivityModel> _activities = [];

  List<RecentActivityModel> get activities => _activities;

  /// Inicializa el provider cargando actividades desde storage
  Future<void> init() async {
    await _loadActivities();
  }

  /// Registra una nueva actividad
  Future<void> addActivity({
    required String tableName,
    required String action,
  }) async {
    final activity = RecentActivityModel(
      tableName: tableName,
      action: action,
      timestamp: DateTime.now(),
    );

    // Agregar al inicio de la lista
    _activities.insert(0, activity);

    // Mantener solo las últimas N actividades
    if (_activities.length > _maxActivities) {
      _activities = _activities.take(_maxActivities).toList();
    }

    await _saveActivities();
    notifyListeners();
  }

  /// Limpia todas las actividades
  Future<void> clearActivities() async {
    _activities = [];
    await _saveActivities();
    notifyListeners();
  }

  /// Carga actividades desde SharedPreferences
  Future<void> _loadActivities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        _activities = jsonList
            .map((json) => RecentActivityModel.fromJson(json))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading activities: $e');
      _activities = [];
    }
  }

  /// Guarda actividades en SharedPreferences
  Future<void> _saveActivities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _activities.map((a) => a.toJson()).toList();
      await prefs.setString(_storageKey, json.encode(jsonList));
    } catch (e) {
      debugPrint('Error saving activities: $e');
    }
  }
}
