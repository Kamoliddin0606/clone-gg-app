// =============================================================================
// POST ORDER SYNC NOTIFICATION WIDGET
// =============================================================================
// This widget displays a small, user-friendly, modern notification to the user
// about background synchronization progress after an order is successfully
// submitted.
//
// Features:
// - Non-intrusive (doesn't block user interaction)
// - Animated progress bar
// - Auto-dismiss on completion
// - Material 3 design
// - Can be manually dismissed
//
// Usage:
// PostOrderSyncNotification.show(context, progress);
// =============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/src/features/agent/services/post_order_sync_manager.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';

/// =============================================================================
/// POST ORDER SYNC NOTIFICATION WIDGET
/// =============================================================================
/// Small notification widget displayed to user about background sync.
/// Similar to SnackBar style but more informative.
/// =============================================================================
class PostOrderSyncNotification extends StatefulWidget {
  /// Current progress data
  final PostOrderSyncProgress progress;
  
  /// Callback when dismissed
  final VoidCallback? onDismiss;
  
  /// Auto-dismiss time (in milliseconds)
  /// If null, won't auto-dismiss
  final int? autoDismissMs;
  
  const PostOrderSyncNotification({
    super.key,
    required this.progress,
    this.onDismiss,
    this.autoDismissMs,
  });
  
  /// ==========================================================================
  /// STATIC SHOW METHOD
  /// ==========================================================================
  /// Static method to show notification as overlay.
  /// Creates OverlayEntry and displays at top of screen.
  ///
  /// [context] - BuildContext
  /// [progressStream] - Progress stream
  /// [autoDismissOnComplete] - Auto-dismiss on completion
  /// ==========================================================================
  static OverlayEntry? _currentOverlay;
  static StreamSubscription<PostOrderSyncProgress>? _subscription;
  
  static void show(
    BuildContext context,
    Stream<PostOrderSyncProgress> progressStream, {
    bool autoDismissOnComplete = true,
    Duration autoDismissDelay = const Duration(seconds: 3),
  }) {
    // If overlay is already showing, dismiss first
    dismiss();
    
    // Create new overlay
    final overlay = Overlay.of(context);
    
    _currentOverlay = OverlayEntry(
      builder: (context) => _SyncNotificationOverlay(
        progressStream: progressStream,
        autoDismissOnComplete: autoDismissOnComplete,
        autoDismissDelay: autoDismissDelay,
        onDismiss: dismiss,
      ),
    );
    
    overlay.insert(_currentOverlay!);
  }
  
  /// Dismiss notification
  static void dismiss() {
    _subscription?.cancel();
    _subscription = null;
    _currentOverlay?.remove();
    _currentOverlay = null;
  }
  
  @override
  State<PostOrderSyncNotification> createState() => _PostOrderSyncNotificationState();
}

class _PostOrderSyncNotificationState extends State<PostOrderSyncNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.progress.progressPercent,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }
  
  @override
  void didUpdateWidget(PostOrderSyncNotification oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress.progressPercent != widget.progress.progressPercent) {
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: widget.progress.progressPercent,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ));
      _animationController.forward(from: 0.0);
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = widget.progress;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress bar
            AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return LinearProgressIndicator(
                  value: progress.isInProgress ? _progressAnimation.value : 
                         (progress.status == PostOrderSyncStatus.completed ? 1.0 : null),
                  backgroundColor: theme.colorScheme.surfaceContainerLow,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getStatusColor(progress.status, theme),
                  ),
                  minHeight: 3,
                );
              },
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Status icon
                  _buildStatusIcon(progress.status, theme),
                  
                  const SizedBox(width: 12),
                  
                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getLocalizedStatusTitle(context, progress.status),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          progress.message,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  
                  // Dismiss button (only visible in completed or error state)
                  if (!progress.isInProgress)
                    IconButton(
                      onPressed: widget.onDismiss,
                      icon: Icon(
                        Icons.close,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Build status icon
  Widget _buildStatusIcon(PostOrderSyncStatus status, ThemeData theme) {
    IconData icon;
    Color color;
    bool showSpinner = false;
    
    switch (status) {
      case PostOrderSyncStatus.idle:
        icon = Icons.hourglass_empty;
        color = theme.colorScheme.onSurfaceVariant;
        break;
      case PostOrderSyncStatus.syncingProducts:
      case PostOrderSyncStatus.syncingProductBalances:
      case PostOrderSyncStatus.syncingOrders:
        icon = Icons.sync;
        color = theme.colorScheme.primary;
        showSpinner = true;
        break;
      case PostOrderSyncStatus.completed:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case PostOrderSyncStatus.error:
        icon = Icons.error_outline;
        color = theme.colorScheme.error;
        break;
    }
    
    if (showSpinner) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
    }
    
    return Icon(icon, color: color, size: 24);
  }
  
  /// Get status color
  Color _getStatusColor(PostOrderSyncStatus status, ThemeData theme) {
    switch (status) {
      case PostOrderSyncStatus.idle:
        return theme.colorScheme.onSurfaceVariant;
      case PostOrderSyncStatus.syncingProducts:
      case PostOrderSyncStatus.syncingProductBalances:
      case PostOrderSyncStatus.syncingOrders:
        return theme.colorScheme.primary;
      case PostOrderSyncStatus.completed:
        return Colors.green;
      case PostOrderSyncStatus.error:
        return theme.colorScheme.error;
    }
  }
  
  /// Get status title key for localization
  String _getStatusTitleKey(PostOrderSyncStatus status) {
    switch (status) {
      case PostOrderSyncStatus.idle:
        return 'syncStatusIdle';
      case PostOrderSyncStatus.syncingProducts:
        return 'syncStatusProducts';
      case PostOrderSyncStatus.syncingProductBalances:
        return 'syncStatusBalances';
      case PostOrderSyncStatus.syncingOrders:
        return 'syncStatusOrders';
      case PostOrderSyncStatus.completed:
        return 'syncStatusCompleted';
      case PostOrderSyncStatus.error:
        return 'syncStatusError';
    }
  }

  /// Get localized status title
  String _getLocalizedStatusTitle(BuildContext context, PostOrderSyncStatus status) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return _getStatusTitleKey(status);
    
    switch (status) {
      case PostOrderSyncStatus.idle:
        return l10n.syncStatusIdle;
      case PostOrderSyncStatus.syncingProducts:
        return l10n.syncStatusProducts;
      case PostOrderSyncStatus.syncingProductBalances:
        return l10n.syncStatusBalances;
      case PostOrderSyncStatus.syncingOrders:
        return l10n.syncStatusOrders;
      case PostOrderSyncStatus.completed:
        return l10n.syncStatusCompleted;
      case PostOrderSyncStatus.error:
        return l10n.syncStatusError;
    }
  }
}

/// =============================================================================
/// SYNC NOTIFICATION OVERLAY
/// =============================================================================
/// Notification wrapper widget displayed inside overlay.
/// Receives progress data from stream and updates UI.
/// =============================================================================
class _SyncNotificationOverlay extends StatefulWidget {
  final Stream<PostOrderSyncProgress> progressStream;
  final bool autoDismissOnComplete;
  final Duration autoDismissDelay;
  final VoidCallback onDismiss;
  
  const _SyncNotificationOverlay({
    required this.progressStream,
    required this.autoDismissOnComplete,
    required this.autoDismissDelay,
    required this.onDismiss,
  });
  
  @override
  State<_SyncNotificationOverlay> createState() => _SyncNotificationOverlayState();
}

class _SyncNotificationOverlayState extends State<_SyncNotificationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  StreamSubscription<PostOrderSyncProgress>? _subscription;
  Timer? _autoDismissTimer;
  
  PostOrderSyncProgress _currentProgress = const PostOrderSyncProgress(
    status: PostOrderSyncStatus.idle,
    message: 'syncStarting',
  );
  
  @override
  void initState() {
    super.initState();
    
    // Slide animation
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));
    
    _slideController.forward();
    
    // Subscribe to stream
    _subscription = widget.progressStream.listen(
      (progress) {
        if (mounted) {
          setState(() {
            _currentProgress = progress;
          });
          
          // Auto-dismiss on completion
          if (widget.autoDismissOnComplete && 
              (progress.status == PostOrderSyncStatus.completed ||
               progress.status == PostOrderSyncStatus.error)) {
            _autoDismissTimer?.cancel();
            _autoDismissTimer = Timer(widget.autoDismissDelay, _dismiss);
          }
        }
      },
      onError: (error) {
        debugPrint('PostOrderSyncNotification: Stream error: $error');
        if (mounted) {
          setState(() {
            _currentProgress = PostOrderSyncProgress(
              status: PostOrderSyncStatus.error,
              message: 'syncError',
              errorMessage: error.toString(),
            );
          });
        }
      },
    );
  }
  
  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _subscription?.cancel();
    _slideController.dispose();
    super.dispose();
  }
  
  void _dismiss() async {
    await _slideController.reverse();
    widget.onDismiss();
  }
  
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: Material(
          color: Colors.transparent,
          child: PostOrderSyncNotification(
            progress: _currentProgress,
            onDismiss: _dismiss,
          ),
        ),
      ),
    );
  }
}

/// =============================================================================
/// COMPACT SYNC INDICATOR WIDGET
/// =============================================================================
/// Minimal sync indicator displayed at bottom of screen.
/// Almost doesn't interfere with user interaction.
/// =============================================================================
class CompactSyncIndicator extends StatelessWidget {
  final PostOrderSyncProgress progress;
  final VoidCallback? onTap;
  
  const CompactSyncIndicator({
    super.key,
    required this.progress,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // If idle, don't show anything
    if (progress.status == PostOrderSyncStatus.idle) {
      return const SizedBox.shrink();
    }
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon/Spinner
            if (progress.isInProgress)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              )
            else
              Icon(
                progress.status == PostOrderSyncStatus.completed
                    ? Icons.check_circle
                    : Icons.error_outline,
                size: 16,
                color: progress.status == PostOrderSyncStatus.completed
                    ? Colors.green
                    : theme.colorScheme.error,
              ),
            
            const SizedBox(width: 8),
            
            // Text
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context);
                String text;
                if (progress.isInProgress) {
                  text = l10n?.syncInProgress ?? 'Syncing...';
                } else if (progress.status == PostOrderSyncStatus.completed) {
                  text = l10n?.syncStatusCompleted ?? 'Updated';
                } else {
                  text = l10n?.syncStatusError ?? 'Error';
                }
                return Text(
                  text,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
