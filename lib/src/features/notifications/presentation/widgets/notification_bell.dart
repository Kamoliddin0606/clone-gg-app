import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gloria_marketing_flutter/src/core/router/app_router.dart';
import 'package:gloria_marketing_flutter/src/core/services/permission_manager.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/repositories/notification_repository.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/presentation/bloc/unread_count_cubit.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

/// Top-right bell icon with an unread badge.
///
/// * Tap → notification list screen.
/// * Long-press → "mark all as read" confirmation.
/// * First interaction also triggers the OS notification permission
///   request (pasport §2.4 — do NOT prompt at cold start).
class NotificationBell extends StatelessWidget {
  final Color? iconColor;

  const NotificationBell({super.key, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<UnreadCountCubit>(
      create: (_) => UnreadCountCubit(sl<NotificationRepository>()),
      child: _Bell(iconColor: iconColor),
    );
  }
}

class _Bell extends StatelessWidget {
  final Color? iconColor;

  const _Bell({this.iconColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<UnreadCountCubit, int>(
      builder: (context, count) {
        return Semantics(
          label: count > 0 ? 'Bildirishnomalar ($count o\'qilmagan)' : 'Bildirishnomalar',
          button: true,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => _open(context),
            onLongPress: () => _confirmMarkAll(context),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.notifications_outlined,
                    color: iconColor ?? theme.iconTheme.color,
                  ),
                  if (count > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Center(
                          child: Text(
                            count > 99 ? '99+' : '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _open(BuildContext context) async {
    // First-touch permission prompt (pasport §2.4): only here, not at
    // cold start. PermissionManager.handleNotificationPermissionFlow is
    // a thin wrapper around permission_handler.
    await _requestNotificationPermissionIfNeeded();
    if (!context.mounted) return;
    Navigator.pushNamed(context, AppRouter.notificationListRoute);
  }

  Future<void> _confirmMarkAll(BuildContext context) async {
    final cubit = context.read<UnreadCountCubit>();
    if (cubit.state == 0) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hammasini o\'qilgan deb belgilash'),
        content: const Text(
            'Barcha o\'qilmagan bildirishnomalarni o\'qilgan deb belgilashni xohlaysizmi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ha, belgilash'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await sl<NotificationRepository>().markAllRead();
    }
  }

  Future<void> _requestNotificationPermissionIfNeeded() async {
    try {
      // permission_handler returns granted on iOS regardless on Android
      // <13; only the Android 13+ prompt actually fires.
      final status = await ph.Permission.notification.status;
      if (status.isDenied) {
        await ph.Permission.notification.request();
      }
      // Touch the PermissionManager singleton so callers wanting to
      // query a cached value see a consistent state.
      sl<PermissionManager>();
    } catch (_) {
      // Best-effort; the user can still toggle it from Settings.
    }
  }
}
