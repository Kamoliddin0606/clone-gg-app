import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/src/core/models/sync_progress.dart';
import 'package:gloria_marketing_flutter/src/core/router/app_router.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/widgets/sync_notification_card.dart';

/// Service responsible for managing non-blocking sync progress notifications.
///
/// It uses the global Overlay to display a floating progress card that doesn't
/// block the rest of the application UI.
class SyncNotificationService {
  OverlayEntry? _overlayEntry;

  /// Show a non-blocking progress card for the given [stream]
  void showProgress(Stream<SyncProgress> stream, String title) {
    // Ensure any existing notification is dismissed
    dismiss();

    final overlayState = AppRouter.navigatorKey.currentState?.overlay;
    if (overlayState == null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => SyncNotificationCard(
        stream: stream,
        title: title,
        onDismiss: dismiss,
      ),
    );

    overlayState.insert(_overlayEntry!);
  }

  /// Dismiss the current notification
  void dismiss() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
  }
}
