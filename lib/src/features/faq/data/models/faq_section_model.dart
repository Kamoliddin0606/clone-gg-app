import 'package:flutter/material.dart';
import 'faq_item_model.dart';

/// Model representing a FAQ section containing multiple items.
class FaqSection {
  /// Unique identifier for the section
  final String id;

  /// Localization key for the section title
  final String titleKey;

  /// Icon representing the section
  final IconData icon;

  /// Color theme for the section (optional)
  final Color? accentColor;

  /// List of FAQ items in this section
  final List<FaqItem> items;

  /// Order index for sorting sections
  final int order;

  const FaqSection({
    required this.id,
    required this.titleKey,
    required this.icon,
    this.accentColor,
    required this.items,
    this.order = 0,
  });
}
