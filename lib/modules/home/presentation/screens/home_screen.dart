import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:herramienta_case/core/constants/app_colors.dart';
import 'package:herramienta_case/core/constants/app_strings.dart';
import 'package:herramienta_case/core/constants/app_styles.dart';
import 'package:herramienta_case/core/config/routes.dart';
import 'package:herramienta_case/core/utils/helpers.dart';
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
                return Card(
                  elevation: AppStyles.elevationMedium,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppStyles.radiusMedium),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppStyles.paddingLarge),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primaryLight,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius:
                          BorderRadius.circular(AppStyles.radiusMedium),
                    ),
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
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: AppStyles.paddingLarge),

            // Título de sección
            Text(
              'Accesos Rápidos',
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
                  icon: Icons.build_outlined,
                  color: AppColors.primary,
                  onTap: () {
                    AppRoutes.navigateTo(context, AppRoutes.toolsList);
                  },
                ),
                HomeCard(
                  title: 'Categorías',
                  icon: Icons.category_outlined,
                  color: AppColors.secondary,
                  onTap: () {
                    Helpers.showInfoSnackBar(
                      context,
                      'Funcionalidad en desarrollo',
                    );
                  },
                ),
                HomeCard(
                  title: 'Reportes',
                  icon: Icons.assessment_outlined,
                  color: AppColors.success,
                  onTap: () {
                    Helpers.showInfoSnackBar(
                      context,
                      'Funcionalidad en desarrollo',
                    );
                  },
                ),
                HomeCard(
                  title: 'Configuración',
                  icon: Icons.settings_outlined,
                  color: AppColors.warning,
                  onTap: () {
                    Helpers.showInfoSnackBar(
                      context,
                      'Funcionalidad en desarrollo',
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
