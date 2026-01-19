import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';

/// Minimalist timer display widget for visit and visit step duration tracking
/// 
/// Features:
/// - Soft transparent design that doesn't disrupt user workflow
/// - Professional Material Design 3 styling
/// - Tabular figures for consistent time display
/// - Subtle animations and color transitions
/// - Accessibility-friendly contrast ratios
/// 
/// Usage:
/// ```dart
/// VisitTimerWidget(
///   durationSeconds: 3665,
///   label: 'Visit Duration',
///   isActive: true,
/// )
/// ```
class VisitTimerWidget extends StatelessWidget {
  /// Duration in seconds to display
  final int durationSeconds;
  
  /// Optional label text to show next to timer
  final String? label;
  
  /// Whether the timer is actively running
  /// Affects visual styling (active timers have more prominent colors)
  final bool isActive;
  
  /// Whether to show the label
  final bool showLabel;
  
  /// Custom icon to display (defaults to timer icon)
  final IconData? icon;

  const VisitTimerWidget({
    super.key,
    required this.durationSeconds,
    this.label,
    this.isActive = true,
    this.showLabel = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        // Soft transparent background - non-intrusive design
        color: isActive 
          ? colorScheme.primaryContainer.withOpacity(0.15)
          : colorScheme.surfaceVariant.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
            ? colorScheme.primary.withOpacity(0.3)
            : colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Subtle icon with opacity
          Icon(
            icon ?? Icons.timer_outlined,
            size: 16,
            color: isActive
              ? colorScheme.primary.withOpacity(0.7)
              : colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(width: 6),
          // Time display with tabular figures for alignment
          Text(
            _formatDuration(durationSeconds),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isActive
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant.withOpacity(0.7),
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
              letterSpacing: 0.5,
            ),
          ),
          // Optional label with reduced opacity
          if (showLabel && label != null && label!.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(
              label!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Format duration in seconds to HH:MM:SS format
  /// 
  /// Examples:
  /// - 65 seconds -> "00:01:05"
  /// - 3665 seconds -> "01:01:05"
  /// - 86400 seconds -> "24:00:00"
  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    return '${hours.toString().padLeft(2, '0')}:'
           '${minutes.toString().padLeft(2, '0')}:'
           '${secs.toString().padLeft(2, '0')}';
  }
}

/// Compact version of timer widget for use in constrained spaces
/// 
/// Shows only the time without label, with smaller padding
class CompactVisitTimerWidget extends StatelessWidget {
  final int durationSeconds;
  final bool isActive;

  const CompactVisitTimerWidget({
    super.key,
    required this.durationSeconds,
    this.isActive = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive 
          ? colorScheme.primaryContainer.withOpacity(0.12)
          : colorScheme.surfaceVariant.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 14,
            color: isActive
              ? colorScheme.primary.withOpacity(0.6)
              : colorScheme.onSurfaceVariant.withOpacity(0.4),
          ),
          const SizedBox(width: 4),
          Text(
            _formatDuration(durationSeconds),
            style: theme.textTheme.bodySmall?.copyWith(
              color: isActive
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant.withOpacity(0.7),
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    return '${hours.toString().padLeft(2, '0')}:'
           '${minutes.toString().padLeft(2, '0')}:'
           '${secs.toString().padLeft(2, '0')}';
  }
}

/// Timer widget with elapsed time label for completed visits/steps
/// 
/// Used to display historical duration data
class ElapsedTimeWidget extends StatelessWidget {
  final int durationSeconds;
  final String? customLabel;

  const ElapsedTimeWidget({
    super.key,
    required this.durationSeconds,
    this.customLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 14,
            color: colorScheme.primary.withOpacity(0.6),
          ),
          const SizedBox(width: 6),
          Text(
            _formatDuration(durationSeconds),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (customLabel != null || l10n != null) ...[
            const SizedBox(width: 4),
            Text(
              customLabel ?? l10n?.elapsedTime ?? 'elapsed',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${secs}s';
    } else {
      return '${secs}s';
    }
  }
}
