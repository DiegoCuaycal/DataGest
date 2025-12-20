import 'package:flutter/material.dart';
import 'package:herramienta_case/core/constants/app_colors.dart';
import 'package:herramienta_case/modules/help/domain/models/faq_item.dart';

/// Widget reutilizable para mostrar un item de FAQ expandible
class FaqExpansionTile extends StatelessWidget {
  final FaqItem faqItem;

  const FaqExpansionTile({
    super.key,
    required this.faqItem,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(
          faqItem.question,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        leading: const Icon(
          Icons.help_outline,
          color: AppColors.primary,
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              faqItem.answer,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
