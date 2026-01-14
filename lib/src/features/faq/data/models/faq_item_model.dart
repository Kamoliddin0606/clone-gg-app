import 'package:flutter/material.dart';

/// Model representing a single FAQ item with question and answer.
class FaqItem {
  /// Unique identifier for the item
  final String id;

  /// Localization key for the title/question
  final String titleKey;

  /// Localization key for the content/answer
  final String contentKey;

  /// Optional icon for visual representation
  final IconData? icon;

  /// Order index for sorting
  final int order;

  const FaqItem({
    required this.id,
    required this.titleKey,
    required this.contentKey,
    this.icon,
    this.order = 0,
  });
}
