import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:herramienta_case/core/constants/app_colors.dart';
import 'package:herramienta_case/core/constants/app_icons.dart';
import 'package:herramienta_case/core/constants/app_strings.dart';
import 'package:herramienta_case/core/constants/app_styles.dart';
import 'package:herramienta_case/modules/auth/presentation/widgets/login_form.dart';
import 'package:herramienta_case/modules/database_selector/presentation/providers/database_selector_provider.dart';

/// Pantalla de login
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final dbProvider = context.watch<DatabaseSelectorProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.login),
        leading: IconButton(
          icon: const Icon(AppIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 24 : 32,
              vertical: 16,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  // Logo o icono de la app
                  Container(
                    padding: const EdgeInsets.all(AppStyles.paddingMedium),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      AppIcons.architecture,
                      size: 64,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppStyles.paddingLarge),

                  // Mostrar BD seleccionada
                  if (dbProvider.selectedDatabase != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppStyles.paddingMedium,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            AppIcons.database,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: AppStyles.paddingSmall),
                          Flexible(
                            child: Text(
                              dbProvider.selectedDatabase!.name,
                              style: AppStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (dbProvider.selectedDatabase != null)
                    const SizedBox(height: 24),

                  // Título
                  Text(
                    AppStrings.appName,
                    style: AppStyles.heading1.copyWith(fontSize: 28),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Subtítulo
                  Text(
                    AppStrings.loginToContinue,
                    style: AppStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Card con formulario
                  Container(
                    padding: const EdgeInsets.all(AppStyles.paddingLarge),
                    decoration: AppStyles.modernCardDecoration(
                      borderRadius: AppStyles.radiusXLarge,
                    ),
                    child: const LoginForm(),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
