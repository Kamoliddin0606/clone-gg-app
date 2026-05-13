import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';

/// Renders a transient "Notification arrived" banner at the top of the
/// current scaffold when a push lands in the foreground.
///
/// Usage:
///   1. Wrap the main shell with [InAppBannerHost].
///   2. From [PushHandlerService.onForegroundBanner], call
///      `InAppBannerController.of(context).show(message)` (or set the
///      service's callback to the controller's `show`).
class InAppBannerHost extends StatefulWidget {
  final Widget child;
  final void Function(String? deepLink, String? notificationId)? onTap;

  const InAppBannerHost({
    super.key,
    required this.child,
    this.onTap,
  });

  @override
  State<InAppBannerHost> createState() => InAppBannerHostState();
}

class InAppBannerHostState extends State<InAppBannerHost> {
  OverlayEntry? _entry;
  Timer? _timer;

  void show(RemoteMessage message) {
    _dismiss();
    // Localised fallback when neither the FCM payload nor the data
    // map provides a title — keeps the banner readable in tests and
    // for legacy server templates that ship body-only messages.
    final l10n = AppLocalizations.of(context);
    final title = message.notification?.title ??
        message.data['title'] as String? ??
        (l10n?.notif_title ?? 'Notification');
    final body =
        message.notification?.body ?? message.data['body'] as String? ?? '';
    final deepLink = message.data['deep_link'] as String?;
    final notificationId = message.data['notification_id'] as String?;

    final overlay = Overlay.of(context, rootOverlay: true);
    _entry = OverlayEntry(
      builder: (ctx) => _BannerCard(
        title: title,
        body: body,
        onTap: () {
          _dismiss();
          widget.onTap?.call(deepLink, notificationId);
        },
        onDismiss: _dismiss,
      ),
    );
    overlay.insert(_entry!);
    _timer = Timer(const Duration(seconds: 5), _dismiss);
  }

  void _dismiss() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }

  @override
  void dispose() {
    _dismiss();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _InAppBannerScope(state: this, child: widget.child);
  }
}

class _InAppBannerScope extends InheritedWidget {
  final InAppBannerHostState state;

  const _InAppBannerScope({required this.state, required super.child});

  @override
  bool updateShouldNotify(_InAppBannerScope oldWidget) =>
      oldWidget.state != state;
}

class InAppBannerController {
  final InAppBannerHostState _state;

  InAppBannerController._(this._state);

  static InAppBannerController? maybeOf(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<_InAppBannerScope>();
    if (scope == null) return null;
    return InAppBannerController._(scope.state);
  }

  void show(RemoteMessage message) => _state.show(message);
}

class _BannerCard extends StatelessWidget {
  final String title;
  final String body;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _BannerCard({
    required this.title,
    required this.body,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final theme = Theme.of(context);
    return Positioned(
      top: media.padding.top + 8,
      left: 12,
      right: 12,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surface,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.notifications_active,
                    color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (body.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          body,
                          style: theme.textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: onDismiss,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
