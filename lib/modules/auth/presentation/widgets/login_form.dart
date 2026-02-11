import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:herramienta_case/core/constants/app_strings.dart';
import 'package:herramienta_case/core/constants/app_styles.dart';
import 'package:herramienta_case/core/utils/helpers.dart';
import 'package:herramienta_case/core/utils/notification_service.dart';
import 'package:herramienta_case/core/config/routes.dart';
import 'package:herramienta_case/core/config/app_build_config.dart';
import 'package:herramienta_case/core/services/loading_overlay_service.dart';
import 'package:herramienta_case/modules/auth/presentation/providers/auth_provider.dart';
import 'package:herramienta_case/modules/database_selector/presentation/providers/database_selector_provider.dart';
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
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;

  @override
  void dispose() {
    _usernameController.dispose();
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
    final databaseProvider = context.read<DatabaseSelectorProvider>();

    // Obtener el nombre de la base de datos seleccionada (si aplica)
    final databaseName = databaseProvider.currentDatabaseName;

    // Mostrar loading overlay
    LoadingOverlayService.show(context, text: 'Verificando credenciales...');

    try {
      // Realizar login
      final success = await authProvider.login(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        databaseName: databaseName,
      );

      if (!mounted) return;

      // Ocultar loading
      LoadingOverlayService.hide();

      if (success) {
        // Verificar el Rol para decidir la navegación
        final userRole = authProvider.currentUser?.role;
        final modulo = authProvider.currentUser?.moduloOrigen;

        if (userRole == 'ProfileConnection' && !AppBuildConfig.isPreConfigured) {
          // CASO 1: Configuración de Servidor (solo en modo GENÉRICO)
          // En APK pre-configurada la BD ya fue inyectada por C#, no redirigir al selector
          NotificationService.showSuccess(
            context,
            'Perfil "$modulo" configurado correctamente'
          );
          AppRoutes.navigateAndRemoveUntil(context, AppRoutes.selectDatabase);

        } else {
          // CASO 2: Login normal O APK pre-configurada → siempre al Home
          NotificationService.showSuccess(context, AppStrings.successLogin);
          AppRoutes.navigateAndRemoveUntil(context, AppRoutes.home);
        }

      } else {
        // Login fallido
        final errorMessage = authProvider.errorMessage ?? AppStrings.errorGeneric;
        NotificationService.showError(context, errorMessage);
      }
    } catch (e) {
      LoadingOverlayService.hide();
      if (mounted) {
        NotificationService.showError(context, 'Error de conexión o credenciales');
      }
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
            controller: _usernameController,
            label: 'Usuario',
            hint: 'Ej: Remote, admin, jperez...',
            prefixIcon: Icons.person,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ingresa un usuario válido';
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
                return 'Ingresa tu contraseña';
              }
              return null;
            },
          ),
          const SizedBox(height: AppStyles.paddingSmall),

          // Remember me checkbox
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
        ],
      ),
    );
  }
}