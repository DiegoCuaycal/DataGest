/// Modelo para actividad reciente del usuario
class RecentActivityModel {
  final String tableName;
  final String action; // 'view', 'create', 'update', 'delete'
  final DateTime timestamp;

  RecentActivityModel({
    required this.tableName,
    required this.action,
    required this.timestamp,
  });

  String get actionLabel {
    switch (action) {
      case 'view':
        return 'Consultó';
      case 'create':
        return 'Creó registro en';
      case 'update':
        return 'Actualizó';
      case 'delete':
        return 'Eliminó de';
      default:
        return 'Acción en';
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Hace ${difference.inSeconds}s';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours}h';
    } else {
      return 'Hace ${difference.inDays}d';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'tableName': tableName,
      'action': action,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory RecentActivityModel.fromJson(Map<String, dynamic> json) {
    return RecentActivityModel(
      tableName: json['tableName'] as String,
      action: json['action'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  @override
  String toString() => 'RecentActivityModel($actionLabel $tableName - $timeAgo)';
}
