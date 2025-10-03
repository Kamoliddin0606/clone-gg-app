import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class PromotionCardShimmer extends StatelessWidget {
  const PromotionCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cs.surface,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Shimmer.fromColors(
        baseColor: cs.surfaceContainerHighest.withOpacity(0.3),
        highlightColor: cs.surfaceContainerHighest.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Image placeholder
              Container(
                width: 100,
                height: 100,
                color: cs.surfaceContainerHighest,
              ),
              const SizedBox(width: 12),
              // Details placeholder
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Container(
                      height: 16,
                      width: double.infinity,
                      color: cs.surfaceContainerHighest,
                    ),
                    const SizedBox(height: 8),
                    // ID
                    Container(
                      height: 12,
                      width: 80,
                      color: cs.surfaceContainerHighest,
                    ),
                    const SizedBox(height: 8),
                    // Description
                    Container(
                      height: 14,
                      width: double.infinity,
                      color: cs.surfaceContainerHighest,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 14,
                      width: MediaQuery.of(context).size.width * 0.6,
                      color: cs.surfaceContainerHighest,
                    ),
                    const SizedBox(height: 8),
                    // Date
                    Container(
                      height: 12,
                      width: 120,
                      color: cs.surfaceContainerHighest,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}