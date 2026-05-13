import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/models/app_notification.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/repositories/notification_repository.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/presentation/bloc/notification_detail_cubit.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/services/notification_tap_router.dart';

/// Full-screen detail with its own Scaffold + AppBar. Used by the
/// route push (phone deep link, terminated-push tap).
class NotificationDetailPage extends StatelessWidget {
  final String id;

  const NotificationDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NotificationDetailCubit>(
      create: (_) => NotificationDetailCubit(sl<NotificationRepository>(), id),
      child: const _DetailScaffold(),
    );
  }
}

/// Embedded detail body — no Scaffold/AppBar. Used by the tablet
/// master-detail layout (Phase 2d) where the list page hosts the
/// AppBar and the right pane just shows content.
class NotificationDetailView extends StatelessWidget {
  final String id;

  const NotificationDetailView({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NotificationDetailCubit>(
      // ValueKey on id forces a fresh cubit when the user selects a
      // different row in the master pane — the existing cubit would
      // otherwise stay bound to the previous id.
      key: ValueKey('detail-$id'),
      create: (_) => NotificationDetailCubit(sl<NotificationRepository>(), id),
      child: const _DetailBody(),
    );
  }
}

class _DetailScaffold extends StatelessWidget {
  const _DetailScaffold();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notif_title),
      ),
      body: const _DetailBody(),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationDetailCubit, NotificationDetailState>(
      builder: (context, state) {
        if (state.loading && state.notification == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.notification == null) {
          final l10n = AppLocalizations.of(context)!;
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                l10n.notif_detailNotFound,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return _DetailView(notification: state.notification!);
      },
    );
  }
}

class _DetailView extends StatelessWidget {
  final AppNotification notification;

  const _DetailView({required this.notification});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final formatter = DateFormat('dd MMMM y, HH:mm');
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            _Chip(
              label: _priorityLabel(l10n, notification.priority),
              color: _priorityColor(theme, notification.priority),
            ),
            const SizedBox(width: 8),
            _Chip(
              label: _typeLabel(l10n, notification.type),
              color: theme.colorScheme.primaryContainer,
              textColor: theme.colorScheme.onPrimaryContainer,
            ),
            const Spacer(),
            Text(
              formatter.format(notification.createdAt.toLocal()),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(notification.title, style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(notification.body, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 24),
        if (notification.deepLink != null && notification.deepLink!.isNotEmpty)
          _ActionButton(notification: notification),
      ],
    );
  }

  String _priorityLabel(AppLocalizations l10n, String priority) {
    switch (priority) {
      case 'urgent':
        return l10n.notif_priority_urgent;
      case 'high':
        return l10n.notif_priority_high;
      case 'low':
        return l10n.notif_priority_low;
      case 'normal':
      default:
        return l10n.notif_priority_normal;
    }
  }

  Color _priorityColor(ThemeData theme, String priority) {
    switch (priority) {
      case 'urgent':
        return theme.colorScheme.error;
      case 'high':
        return Colors.orange.shade400;
      case 'low':
        return theme.colorScheme.surfaceContainerHighest;
      case 'normal':
      default:
        return theme.colorScheme.secondaryContainer;
    }
  }

  String _typeLabel(AppLocalizations l10n, String type) {
    switch (type) {
      case 'debt_alert':
        return l10n.notif_typeShort_debtAlert;
      case 'order_new':
        return l10n.notif_typeShort_orderNew;
      case 'stock_lot_expiring':
        return l10n.notif_typeShort_stockLotExpiring;
      case 'system_announcement':
        return l10n.notif_typeShort_systemAnnouncement;
      default:
        return type;
    }
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final Color? textColor;

  const _Chip({required this.label, required this.color, this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor ?? Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final AppNotification notification;

  const _ActionButton({required this.notification});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String label;
    IconData icon;
    switch (notification.type) {
      case 'debt_alert':
        label = l10n.notif_action_openCustomer;
        icon = Icons.person;
        break;
      case 'order_new':
        label = l10n.notif_action_openOrder;
        icon = Icons.receipt_long;
        break;
      default:
        label = l10n.notif_action_openGeneric;
        icon = Icons.open_in_new;
    }
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () {
          NotificationTapRouter.handleDeepLink(
            context,
            deepLink: notification.deepLink,
            notificationId: notification.id,
          );
        },
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}
