import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:herramienta_case/core/constants/app_colors.dart';
import 'package:herramienta_case/core/constants/app_strings.dart';
import 'package:herramienta_case/core/constants/app_styles.dart';
import 'package:herramienta_case/core/utils/helpers.dart';
import 'package:herramienta_case/core/utils/notification_service.dart';
import 'package:herramienta_case/core/config/routes.dart';
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

  /// Obtiene las credenciales correspondientes según la base de datos seleccionada
  Map<String, String> _getCredentialsForDatabase(String? databaseName) {
    if (databaseName == null) {
      return {
        'dbName': 'Prueba',
        'username': 'profe_juan',
        'password': 'hash123',
        'note': 'Selecciona una base de datos para ver sus credenciales',
      };
    }

    // Normalizar el nombre de la BD para comparación
    final dbNameLower = databaseName.toLowerCase();

    // Credenciales específicas por base de datos
    if (dbNameLower.contains('estudiante')) {
      return {
        'dbName': 'Estudiantes',
        'username': 'profe_juan',
        'password': 'hash123',
      };
    } else if (dbNameLower.contains('medico') || dbNameLower.contains('médico')) {
      return {
        'dbName': 'Médicos',
        'username': 'dr_house',
        'password': 'hash789',
      };
    } else if (dbNameLower.contains('producto')) {
      return {
        'dbName': 'Productos',
        'username': 'admin_stock',
        'password': 'hash123',
      };
    } else {
      // BD personalizada o no reconocida
      return {
        'dbName': databaseName,
        'username': 'admin',
        'password': '******',
        'note': 'Usa las credenciales que configuraste al crear esta BD',
      };
    }
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

    // Obtener el nombre de la base de datos seleccionada
    final databaseName = databaseProvider.currentDatabaseName;

    // Realizar login con la base de datos seleccionada (si existe)
    final success = await authProvider.login(
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      databaseName: databaseName,
    );

    if (!mounted) return;

    if (success) {
      // Login exitoso - navegar al Home Dashboard
      NotificationService.showSuccess(context, AppStrings.successLogin);
      AppRoutes.navigateAndRemoveUntil(context, AppRoutes.home);
    } else {
      // Login fallido - mostrar error
      final errorMessage = authProvider.errorMessage ?? AppStrings.errorGeneric;
      NotificationService.showError(context, errorMessage);
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
            hint: 'admin',
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
                  NotificationService.showInfo(
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
          Consumer<DatabaseSelectorProvider>(
            builder: (context, dbProvider, child) {
              // Obtener credenciales según la BD seleccionada
              final credentials = _getCredentialsForDatabase(
                dbProvider.currentDatabaseName,
              );

              return Container(
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Credenciales de ${credentials['dbName'] ?? 'Prueba'}:',
                            style: AppStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (dbProvider.currentDatabaseName != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              credentials['dbName'] ?? 'N/A',
                              style: AppStyles.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Usuario: ${credentials['username'] ?? 'N/A'}',
                      style: AppStyles.bodySmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Contraseña: ${credentials['password'] ?? 'N/A'}',
                      style: AppStyles.bodySmall,
                    ),
                    if (credentials.containsKey('note') && credentials['note'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          credentials['note']!,
                          style: AppStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
