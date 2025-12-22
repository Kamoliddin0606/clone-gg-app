import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/src/core/models/sync_progress.dart';

/// A floating notification card that displays real-time sync progress.
///
/// Designed to be used within an [OverlayEntry] via [SyncNotificationService].
/// It listens to a [SyncProgress] stream and updates its UI accordingly.
class SyncNotificationCard extends StatefulWidget {
  final Stream<SyncProgress> stream;
  final String title;
  final VoidCallback onDismiss;

  const SyncNotificationCard({
    super.key,
    required this.stream,
    required this.title,
    required this.onDismiss,
  });

  @override
  State<SyncNotificationCard> createState() => _SyncNotificationCardState();
}

class _SyncNotificationCardState extends State<SyncNotificationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  SyncProgress? _lastProgress;
  StreamSubscription? _subscription;
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOutCubic,
    );
    _fadeController.forward();

    _subscription = widget.stream.listen(
      (progress) {
        if (mounted) {
          setState(() {
            _lastProgress = progress;
          });
        }

        // Auto-dismiss logic based on result
        if (progress.isComplete) {
          _autoDismiss(progress.hasError ? 5 : 2);
        }
      },
      onError: (e) {
        _autoDismiss(5);
      },
    );
  }

  void _autoDismiss(int seconds) {
    if (_isClosing) return;
    Future.delayed(Duration(seconds: seconds), () {
      if (mounted) {
        _close();
      }
    });
  }

  Future<void> _close() async {
    if (_isClosing || !mounted) return;
    _isClosing = true;
    await _fadeController.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 20,
      left: 16,
      right: 16,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _fadeAnimation.drive(
            Tween<Offset>(
              begin: const Offset(0, 0.5),
              end: Offset.zero,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? colorScheme.surfaceContainer.withOpacity(0.95)
                    : Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: colorScheme.outlineVariant.withOpacity(0.4),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      _buildStatusIcon(colorScheme),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.2,
                              ),
                            ),
                            if (_lastProgress?.tableName != null)
                              Text(
                                _lastProgress!.tableName,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_lastProgress?.progressPercent ?? 0}%',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _lastProgress?.progress ?? 0,
                      minHeight: 10,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _lastProgress?.hasError == true
                            ? Colors.redAccent
                            : (_lastProgress?.isComplete == true
                                ? Colors.green
                                : colorScheme.primary),
                      ),
                    ),
                  ),
                  if (_lastProgress?.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                size: 14, color: Colors.red),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _lastProgress!.errorMessage!,
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: Colors.red.shade700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(ColorScheme colorScheme) {
    if (_lastProgress?.hasError == true) {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.priority_high, color: Colors.white, size: 14),
      );
    }
    if (_lastProgress?.isComplete == true) {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, color: Colors.white, size: 14),
      );
    }
    return SizedBox(
      width: 22,
      height: 22,
      child: CircularProgressIndicator(
        strokeWidth: 3,
        valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
      ),
    );
  }
}
