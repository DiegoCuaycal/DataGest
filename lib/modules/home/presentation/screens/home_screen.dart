import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:herramienta_case/core/constants/app_colors.dart';
import 'package:herramienta_case/core/constants/app_icons.dart';
import 'package:herramienta_case/core/constants/app_strings.dart';
import 'package:herramienta_case/core/constants/app_styles.dart';
import 'package:herramienta_case/core/config/routes.dart';
import 'package:herramienta_case/core/utils/notification_service.dart';
import 'package:herramienta_case/modules/auth/presentation/providers/auth_provider.dart';
import 'package:herramienta_case/modules/home/presentation/widgets/home_drawer.dart';
import 'package:herramienta_case/modules/home/presentation/widgets/home_card.dart';

/// Pantalla principal (Home)
class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.home),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      drawer: const HomeDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppStyles.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Saludo al usuario
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final userName = authProvider.currentUser?.nombre ?? 'Usuario';
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppStyles.paddingLarge),
                  decoration: AppStyles.cardGradientDecoration(
                    colors: AppColors.primaryGradient,
                    borderRadius: AppStyles.radiusLarge,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppStyles.paddingMedium),
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
                        ),
                        child: const Icon(
                          AppIcons.person,
                          size: 40,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(width: AppStyles.paddingMedium),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${AppStrings.welcome},',
                              style: AppStyles.bodyLarge.copyWith(
                                color: AppColors.white.withValues(alpha: 0.9),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              userName,
                              style: AppStyles.heading2.copyWith(
                                color: AppColors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: AppStyles.paddingLarge),

            // Título de sección
            Text(
              AppStrings.quickAccess,
              style: AppStyles.heading3,
            ),
            const SizedBox(height: AppStyles.paddingMedium),

            // Grid de tarjetas
            GridView.count(
              crossAxisCount: _getCrossAxisCount(context),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppStyles.paddingMedium,
              crossAxisSpacing: AppStyles.paddingMedium,
              children: [
                HomeCard(
                  title: AppStrings.tools,
                  icon: AppIcons.tool,
                  color: AppColors.primary,
                  onTap: () {
                    AppRoutes.navigateTo(context, AppRoutes.toolsList);
                  },
                ),
                HomeCard(
                  title: AppStrings.categories,
                  icon: AppIcons.category,
                  color: AppColors.secondary,
                  onTap: () {
                    NotificationService.showInfo(
                      context,
                      AppStrings.featureInDevelopment,
                    );
                  },
                ),
                HomeCard(
                  title: AppStrings.reports,
                  icon: AppIcons.report,
                  color: AppColors.success,
                  onTap: () {
                    NotificationService.showInfo(
                      context,
                      AppStrings.featureInDevelopment,
                    );
                  },
                ),
                HomeCard(
                  title: AppStrings.configuration,
                  icon: AppIcons.settings,
                  color: AppColors.warning,
                  onTap: () {
                    NotificationService.showInfo(
                      context,
                      AppStrings.featureInDevelopment,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) {
      return 2; // Móvil
    } else if (width < 1024) {
      return 3; // Tablet
    } else {
      return 4; // Desktop
    }
  }
}
