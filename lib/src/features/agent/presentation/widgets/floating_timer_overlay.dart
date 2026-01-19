import 'package:flutter/material.dart';
import 'dart:async';

/// Step timer info for display
class StepTimerInfo {
  final String stepName;
  final int stepCode;
  final int? durationSeconds;
  final bool isActive;
  final bool isCompleted;

  const StepTimerInfo({
    required this.stepName,
    required this.stepCode,
    this.durationSeconds,
    this.isActive = false,
    this.isCompleted = false,
  });
}

/// Floating timer overlay widget that displays visit and all step timers
/// with transparency effects and auto-hide behavior
class FloatingTimerOverlay extends StatefulWidget {
  final int? visitDurationSeconds;
  final int? stepDurationSeconds; // Deprecated - use allSteps instead
  final List<StepTimerInfo> allSteps; // All steps with their timer info
  final VoidCallback onClose;
  final bool isStepActive; // Deprecated

  const FloatingTimerOverlay({
    super.key,
    this.visitDurationSeconds,
    this.stepDurationSeconds,
    this.allSteps = const [],
    required this.onClose,
    this.isStepActive = true,
  });

  @override
  State<FloatingTimerOverlay> createState() => _FloatingTimerOverlayState();
}

class _FloatingTimerOverlayState extends State<FloatingTimerOverlay> {
  Timer? _autoRestoreTimer;
  Timer? _autoHideTimer;
  double _currentOpacity = 0.7; // Default transparency (70% visible)

  @override
  void dispose() {
    _autoRestoreTimer?.cancel();
    _autoHideTimer?.cancel();
    super.dispose();
  }

  /// Handle tap on timer overlay - reduces transparency temporarily
  void _onTimerTap() {
    setState(() {
      _currentOpacity = 0.95; // Almost fully opaque when tapped
    });

    // Cancel any existing timer
    _autoRestoreTimer?.cancel();

    // Restore transparency after 3 seconds
    _autoRestoreTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _currentOpacity = 0.7; // Back to default transparency
        });
      }
    });
  }

  /// Start auto-hide timer when other UI elements are interacted with
  void _startAutoHideTimer() {
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        widget.onClose();
      }
    });
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      // Detect taps outside the timer card to trigger auto-hide
      onTap: _startAutoHideTimer,
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          // Positioned timer card at top center
          Positioned(
            top: 8,
            left: 16,
            right: 16,
            child: GestureDetector(
              onTap: _onTimerTap,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _currentOpacity,
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primaryContainer,
                          theme.colorScheme.secondaryContainer,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header with close button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Timer',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.close,
                                color: theme.colorScheme.onPrimaryContainer,
                                size: 20,
                              ),
                              onPressed: widget.onClose,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        // Visit timer
                        if (widget.visitDurationSeconds != null)
                          _buildTimerRow(
                            icon: Icons.access_time,
                            label: 'Visit',
                            duration: _formatDuration(widget.visitDurationSeconds!),
                            color: theme.colorScheme.primary,
                            theme: theme,
                          ),
                        
                        // All steps with their timers
                        if (widget.allSteps.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Divider(
                            color: theme.colorScheme.onPrimaryContainer.withOpacity(0.2),
                            height: 1,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Steps',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer.withOpacity(0.7),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...widget.allSteps.map((step) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: _buildStepTimerRow(
                              stepName: step.stepName,
                              duration: step.durationSeconds != null && step.durationSeconds! > 0
                                  ? _formatDuration(step.durationSeconds!)
                                  : '--:--',
                              isActive: step.isActive,
                              isCompleted: step.isCompleted,
                              theme: theme,
                            ),
                          )),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerRow({
    required IconData icon,
    required String label,
    required String duration,
    required Color color,
    required ThemeData theme,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            duration,
            style: theme.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepTimerRow({
    required String stepName,
    required String duration,
    required bool isActive,
    required bool isCompleted,
    required ThemeData theme,
  }) {
    Color statusColor;
    IconData statusIcon;
    
    if (isCompleted) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (isActive) {
      statusColor = theme.colorScheme.secondary;
      statusIcon = Icons.play_circle;
    } else {
      statusColor = Colors.grey;
      statusIcon = Icons.circle_outlined;
    }

    return Row(
      children: [
        Icon(
          statusIcon,
          color: statusColor,
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            stepName,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          duration,
          style: theme.textTheme.bodySmall?.copyWith(
            color: statusColor,
            fontWeight: FontWeight.w600,
            fontFeatures: [const FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
