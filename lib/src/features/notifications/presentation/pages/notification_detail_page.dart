import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/models/app_notification.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/repositories/notification_repository.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/presentation/bloc/notification_detail_cubit.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/services/notification_tap_router.dart';

class NotificationDetailPage extends StatelessWidget {
  final String id;

  const NotificationDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NotificationDetailCubit>(
      create: (_) => NotificationDetailCubit(sl<NotificationRepository>(), id),
      child: const _Body(),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirishnoma'),
      ),
      body: BlocBuilder<NotificationDetailCubit, NotificationDetailState>(
        builder: (context, state) {
          if (state.loading && state.notification == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.notification == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Bu bildirishnoma topilmadi yoki muddati o\'tgan.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return _DetailView(notification: state.notification!);
        },
      ),
    );
  }
}

class _DetailView extends StatelessWidget {
  final AppNotification notification;

  const _DetailView({required this.notification});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = DateFormat('dd MMMM y, HH:mm');
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            _Chip(
              label: _priorityLabel(notification.priority),
              color: _priorityColor(theme, notification.priority),
            ),
            const SizedBox(width: 8),
            _Chip(
              label: _typeLabel(notification.type),
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

  String _priorityLabel(String priority) {
    switch (priority) {
      case 'urgent':
        return 'Shoshilinch';
      case 'high':
        return 'Yuqori';
      case 'low':
        return 'Past';
      case 'normal':
      default:
        return 'Oddiy';
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

  String _typeLabel(String type) {
    switch (type) {
      case 'debt_alert':
        return 'Qarz';
      case 'order_new':
        return 'Buyurtma';
      case 'stock_lot_expiring':
        return 'Lot tugaydi';
      case 'system_announcement':
        return 'E\'lon';
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
    String label;
    IconData icon;
    switch (notification.type) {
      case 'debt_alert':
        label = 'Mijozni ochish';
        icon = Icons.person;
        break;
      case 'order_new':
        label = 'Buyurtmani ochish';
        icon = Icons.receipt_long;
        break;
      default:
        label = 'Ochish';
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
