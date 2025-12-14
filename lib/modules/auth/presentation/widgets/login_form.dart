import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:herramienta_case/core/constants/app_colors.dart';
import 'package:herramienta_case/core/constants/app_strings.dart';
import 'package:herramienta_case/core/constants/app_styles.dart';
import 'package:herramienta_case/core/utils/helpers.dart';
import 'package:herramienta_case/core/config/routes.dart';
import 'package:herramienta_case/modules/auth/presentation/providers/auth_provider.dart';
import 'package:herramienta_case/shared/widgets/custom_button.dart';
import 'package:herramienta_case/shared/widgets/custom_text_field.dart';

/// Formulario de login
class LoginForm extends StatefulWidget {
  const LoginForm({Key? key}) : super(key: key);

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Ocultar teclado
    Helpers.hideKeyboard(context);

    // Validar formulario
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();

    // Realizar login
    final success = await authProvider.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      // Login exitoso - navegar al menú de tablas
      Helpers.showSuccessSnackBar(context, AppStrings.successLogin);
      AppRoutes.navigateAndRemoveUntil(context, AppRoutes.tablesMenu);
    } else {
      // Login fallido - mostrar error
      final errorMessage = authProvider.errorMessage ?? AppStrings.errorGeneric;
      Helpers.showErrorSnackBar(context, errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Usuario field
          CustomTextField(
            controller: _emailController,
            label: 'Correo Electrónico',
            hint: 'admin',
            prefixIcon: Icons.person,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ingresa un correo electrónico válido';
              }
              return null;
            },
          ),
          const SizedBox(height: AppStyles.paddingMedium),

          // Password field
          PasswordTextField(
            controller: _passwordController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'La contraseña debe tener al menos 6 caracteres';
              }
              return null;
            },
          ),
          const SizedBox(height: AppStyles.paddingSmall),

          // Remember me checkbox y olvidar contraseña
          Row(
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: Checkbox(
                  value: _rememberMe,
                  onChanged: (value) {
                    setState(() {
                      _rememberMe = value ?? false;
                    });
                  },
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppStrings.rememberMe,
                  style: AppStyles.bodySmall,
                ),
              ),
              CustomTextButton(
                text: AppStrings.forgotPassword,
                onPressed: () {
                  // TODO: Implementar recuperación de contraseña
                  Helpers.showInfoSnackBar(
                    context,
                    'Funcionalidad en desarrollo',
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: AppStyles.paddingLarge),

          // Login button
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return CustomButton(
                text: AppStrings.login,
                onPressed: authProvider.isLoading ? null : _handleLogin,
                isLoading: authProvider.isLoading,
                icon: Icons.login_rounded,
                height: 52,
              );
            },
          ),
          const SizedBox(height: AppStyles.paddingMedium),

          // Divider con texto
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppStyles.paddingMedium,
                ),
                child: Text(
                  'Credenciales de prueba',
                  style: AppStyles.caption,
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: AppStyles.paddingMedium),

          // Información de credenciales de prueba
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.info.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Para probar el backend:',
                  style: AppStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Email: admin@test.com',
                  style: AppStyles.bodySmall,
                ),
                const SizedBox(height: 2),
                Text(
                  'Contraseña: 123456',
                  style: AppStyles.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
