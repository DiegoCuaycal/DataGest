import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:herramienta_case/core/constants/app_colors.dart';
import 'package:herramienta_case/core/constants/app_icons.dart';
import 'package:herramienta_case/core/constants/app_strings.dart';
import 'package:herramienta_case/modules/auth/presentation/providers/auth_provider.dart';
import 'package:herramienta_case/modules/settings/domain/models/setting_item.dart';
import 'package:herramienta_case/modules/settings/presentation/widgets/setting_section_widget.dart';
import 'package:herramienta_case/core/utils/notification_service.dart';

/// Pantalla de configuración de la aplicación
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.configuration),
      ),
      body: ListView(
        children: [
          // Header con información del usuario
          _buildUserHeader(context, user?.nombre ?? '', user?.email ?? ''),

          const SizedBox(height: 16),

          // Sección de Cuenta
          SettingSectionWidget(
            section: SettingSection(
              title: 'Cuenta',
              items: [
                SettingItem(
                  icon: AppIcons.person,
                  title: 'Perfil',
                  subtitle: 'Información del usuario',
                  onTap: () => _showProfileDialog(context, user),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Sección de Información
          SettingSectionWidget(
            section: SettingSection(
              title: 'Información',
              items: [
                SettingItem(
                  icon: Icons.info_outline,
                  title: 'Acerca de',
                  subtitle: 'Versión 1.0.0',
                  onTap: () => _showAboutDialog(context),
                ),
                SettingItem(
                  icon: Icons.description_outlined,
                  title: 'Términos y condiciones',
                  onTap: () => _showTermsDialog(context),
                ),
                SettingItem(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Política de privacidad',
                  onTap: () => _showPrivacyDialog(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Widget del header con información del usuario
  Widget _buildUserHeader(BuildContext context, String name, String email) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.white,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Métodos para mostrar diálogos de configuración

  void _showProfileDialog(BuildContext context, dynamic user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Perfil de usuario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nombre: ${user?.nombre ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Email: ${user?.email ?? 'N/A'}'),
            const SizedBox(height: 8),
            const Text('Rol: Administrador'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              NotificationService.showInfo(
                context,
                'Edición de perfil disponible próximamente',
              );
            },
            child: const Text('Editar'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppStrings.appName,
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.smartphone,
        size: 48,
        color: AppColors.primary,
      ),
      children: [
        const Text(
          'Herramienta CASE para gestión de bases de datos relacionales.',
        ),
        const SizedBox(height: 8),
        const Text(
          'Desarrollado con Flutter y tecnologías modernas.',
        ),
      ],
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Términos y condiciones'),
        content: const SingleChildScrollView(
          child: Text(
            'Aquí irían los términos y condiciones de uso de la aplicación.\n\n'
            'Este es un texto de ejemplo que debería ser reemplazado con los términos reales.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Política de privacidad'),
        content: const SingleChildScrollView(
          child: Text(
            'Aquí iría la política de privacidad de la aplicación.\n\n'
            'Este es un texto de ejemplo que debería ser reemplazado con la política real.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
