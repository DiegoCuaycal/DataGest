import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:herramienta_case/core/constants/app_colors.dart';
import 'package:herramienta_case/core/constants/app_icons.dart';
import 'package:herramienta_case/core/constants/app_strings.dart';
import 'package:herramienta_case/core/constants/app_styles.dart';
import 'package:herramienta_case/core/config/routes.dart';
import 'package:herramienta_case/core/utils/notification_service.dart';
import 'package:herramienta_case/modules/auth/presentation/providers/auth_provider.dart';

/// Drawer (menú lateral) del home
class HomeDrawer extends StatelessWidget {
  const HomeDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Header del drawer
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final user = authProvider.currentUser;
              return UserAccountsDrawerHeader(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primaryLight,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: AppColors.white,
                  child: Text(
                    user?.nombre != null && user!.nombre!.isNotEmpty
                        ? user.nombre!.substring(0, 1).toUpperCase()
                        : 'U',
                    style: AppStyles.heading2.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
                accountName: Text(
                  user?.nombre ?? 'Usuario',
                  style: AppStyles.bodyLarge.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                accountEmail: Text(
                  user?.email ?? '',
                  style: AppStyles.bodyMedium.copyWith(
                    color: AppColors.white.withValues(alpha: 0.9),
                  ),
                ),
              );
            },
          ),

          // Opciones del menú
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  context,
                  icon: AppIcons.home,
                  title: AppStrings.home,
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: AppIcons.tool,
                  title: AppStrings.tools,
                  onTap: () {
                    Navigator.pop(context);
                    AppRoutes.navigateTo(context, AppRoutes.toolsList);
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: AppIcons.category,
                  title: AppStrings.categories,
                  onTap: () {
                    Navigator.pop(context);
                    NotificationService.showInfo(
                      context,
                      AppStrings.featureInDevelopment,
                    );
                  },
                ),
                const Divider(),
                _buildDrawerItem(
                  context,
                  icon: AppIcons.settings,
                  title: AppStrings.configuration,
                  onTap: () {
                    Navigator.pop(context);
                    NotificationService.showInfo(
                      context,
                      AppStrings.featureInDevelopment,
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: AppIcons.help,
                  title: AppStrings.help,
                  onTap: () {
                    Navigator.pop(context);
                    NotificationService.showInfo(
                      context,
                      AppStrings.featureInDevelopment,
                    );
                  },
                ),
              ],
            ),
          ),

          // Botón de cerrar sesión
          const Divider(),
          _buildDrawerItem(
            context,
            icon: AppIcons.logout,
            title: AppStrings.logout,
            textColor: AppColors.error,
            onTap: () async {
              final confirmed = await NotificationService.showConfirmDialog(
                context,
                title: AppStrings.logout,
                message: AppStrings.confirmLogout,
                confirmText: AppStrings.logout,
                cancelText: AppStrings.cancel,
                confirmColor: AppColors.error,
              );

              if (confirmed && context.mounted) {
                final authProvider = context.read<AuthProvider>();
                await authProvider.logout();

                if (context.mounted) {
                  AppRoutes.navigateAndRemoveUntil(
                    context,
                    AppRoutes.selectDatabase,
                  );
                }
              }
            },
          ),
          const SizedBox(height: AppStyles.paddingSmall),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? AppColors.textPrimary),
      title: Text(
        title,
        style: AppStyles.bodyMedium.copyWith(
          color: textColor ?? AppColors.textPrimary,
        ),
      ),
      onTap: onTap,
    );
  }
}
