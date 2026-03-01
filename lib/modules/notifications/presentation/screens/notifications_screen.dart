import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:herramienta_case/core/constants/app_colors.dart';
import 'package:herramienta_case/core/constants/app_styles.dart';
import 'package:herramienta_case/core/utils/notification_service.dart';
import 'package:herramienta_case/modules/notifications/presentation/providers/notification_provider.dart';
import 'package:herramienta_case/modules/notifications/presentation/widgets/notification_item.dart';

/// Pantalla de notificaciones
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notificaciones'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notifProvider, _) {
              if (notifProvider.hasUnread) {
                return IconButton(
                  icon: const Icon(Icons.done_all),
                  onPressed: () async {
                    await notifProvider.markAllAsRead();
                    if (context.mounted) {
                      NotificationService.showSuccess(
                        context,
                        'Notificaciones marcadas como leídas',
                      );
                    }
                  },
                  tooltip: 'Marcar todas como leídas',
                );
              }
              return const SizedBox.shrink();
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              final notifProvider = context.read<NotificationProvider>();
              if (value == 'clear') {
                final confirmed = await _showClearConfirmDialog(context);
                if (confirmed && context.mounted) {
                  await notifProvider.clearAll();
                  if (context.mounted) {
                    NotificationService.showSuccess(
                      context,
                      'Notificaciones eliminadas',
                    );
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Limpiar todas'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, notifProvider, child) {
          if (notifProvider.notifications.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              // Tabs para filtrar
              _buildFilterTabs(notifProvider),

              // Lista de notificaciones
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppStyles.paddingSmall,
                    ),
                    itemCount: notifProvider.notifications.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final notification = notifProvider.notifications[index];
                      return NotificationItem(
                        notification: notification,
                        onTap: () async {
                          // Marcar como leída al tocar
                          await notifProvider.markAsRead(notification.id);

                          // Si tiene una acción, navegar
                          if (notification.actionRoute != null && context.mounted) {
                            Navigator.pushNamed(
                              context,
                              notification.actionRoute!,
                              arguments: notification.actionData,
                            );
                          }
                        },
                        onDelete: () async {
                          await notifProvider.deleteNotification(notification.id);
                          if (context.mounted) {
                            NotificationService.showSuccess(
                              context,
                              'Notificación eliminada',
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterTabs(NotificationProvider provider) {
    return Container(
      padding: const EdgeInsets.all(AppStyles.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.divider,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.notifications_active,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '${provider.notifications.length} notificaciones',
            style: AppStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          if (provider.hasUnread) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${provider.unreadCount} nuevas',
                style: AppStyles.bodySmall.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none,
              size: 80,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: AppStyles.paddingLarge),
          Text(
            'No hay notificaciones',
            style: AppStyles.heading3.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppStyles.paddingSmall),
          Text(
            'Aquí aparecerán tus notificaciones',
            style: AppStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<bool> _showClearConfirmDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Limpiar notificaciones'),
              content: const Text(
                '¿Está seguro de eliminar todas las notificaciones? Esta acción no se puede deshacer.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    'Eliminar todas',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}
