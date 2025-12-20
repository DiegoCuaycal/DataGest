import 'package:flutter/material.dart';
import 'package:herramienta_case/core/constants/app_colors.dart';
import 'package:herramienta_case/core/constants/app_strings.dart';
import 'package:herramienta_case/modules/help/domain/models/faq_item.dart';
import 'package:herramienta_case/modules/help/presentation/widgets/faq_expansion_tile.dart';

/// Pantalla de ayuda con FAQs y soporte
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.help),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Sección de bienvenida
          _buildWelcomeCard(context),

          const SizedBox(height: 24),

          // Sección de FAQs
          _buildFaqSection(context),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Card de bienvenida
  Widget _buildWelcomeCard(BuildContext context) {
    return Card(
      color: AppColors.primary.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(
              Icons.help_center_outlined,
              size: 48,
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            const Text(
              '¿Cómo podemos ayudarte?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Encuentra respuestas a tus preguntas o contacta con soporte',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Sección de preguntas frecuentes
  Widget _buildFaqSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Preguntas frecuentes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...getFaqItems().map((faq) => FaqExpansionTile(faqItem: faq)),
      ],
    );
  }

  // Datos de preguntas frecuentes
  List<FaqItem> getFaqItems() {
    return const [
      FaqItem(
        question: '¿Cómo me conecto a una base de datos?',
        answer:
            'Para conectarte a una base de datos, ve al selector de base de datos en la pantalla inicial. Ingresa el host, puerto, nombre de la base de datos y tus credenciales. La aplicación validará la conexión y guardará la configuración.',
      ),
      FaqItem(
        question: '¿Cómo creo un nuevo registro en una tabla?',
        answer:
            'Navega a la tabla deseada desde el menú principal, luego presiona el botón "+" en la esquina inferior derecha. Completa el formulario con los datos requeridos y presiona "Guardar".',
      ),
      FaqItem(
        question: '¿Puedo editar registros existentes?',
        answer:
            'Sí, para editar un registro, toca sobre él en la lista de la tabla. Esto abrirá el formulario de edición donde podrás modificar los campos. Al finalizar, presiona "Guardar" para aplicar los cambios.',
      ),
      FaqItem(
        question: '¿Cómo exporto datos?',
        answer:
            'Ve a la sección de Exportación desde el menú principal. Selecciona la tabla que deseas exportar, elige el formato (CSV o JSON) y configura las opciones de exportación. Luego presiona "Exportar" para descargar el archivo.',
      ),
      FaqItem(
        question: '¿Cómo filtro y busco registros?',
        answer:
            'En la vista de lista de cualquier tabla, usa el campo de búsqueda en la parte superior para buscar texto en todos los campos. También puedes usar los filtros avanzados para criterios más específicos.',
      ),
      FaqItem(
        question: '¿Qué hacer si olvido mi contraseña?',
        answer:
            'En la pantalla de inicio de sesión, presiona "¿Olvidaste tu contraseña?". Ingresa tu email y recibirás un enlace para restablecer tu contraseña.',
      ),
      FaqItem(
        question: '¿La aplicación funciona sin conexión?',
        answer:
            'La aplicación requiere conexión a internet para comunicarse con la base de datos. Sin embargo, algunas funcionalidades como visualizar datos previamente cargados pueden estar disponibles sin conexión.',
      ),
      FaqItem(
        question: '¿Cómo cambio la base de datos conectada?',
        answer:
            'Ve a Configuración > Base de datos > Conexión. Desde allí puedes modificar los parámetros de conexión o seleccionar una base de datos diferente.',
      ),
    ];
  }

}
