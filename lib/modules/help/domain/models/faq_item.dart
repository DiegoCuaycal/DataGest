/// Modelo para representar un item de FAQ (Preguntas Frecuentes)
class FaqItem {
  final String question;
  final String answer;
  final String? category;

  const FaqItem({
    required this.question,
    required this.answer,
    this.category,
  });
}

/// Modelo para representar una categoría de ayuda
class HelpCategory {
  final String title;
  final String description;
  final List<FaqItem> items;

  const HelpCategory({
    required this.title,
    required this.description,
    required this.items,
  });
}
