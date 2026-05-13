import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:gloria_marketing_flutter/src/core/router/app_router.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/models/app_notification.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/repositories/notification_repository.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/presentation/bloc/notification_list_cubit.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/services/notification_tap_router.dart';

/// Full-screen page version with its own Scaffold + AppBar.
/// Used by the bell tap (route `notificationListRoute`).
class NotificationListPage extends StatelessWidget {
  const NotificationListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NotificationListCubit>(
      create: (_) => NotificationListCubit(sl<NotificationRepository>()),
      child: const _Body(embedded: false),
    );
  }
}

/// Embedded variant — body only, no Scaffold/AppBar. Drop into a tab
/// (e.g. marketing → Announcements). The host owns the AppBar and
/// supplies its own actions.
class NotificationListView extends StatelessWidget {
  const NotificationListView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NotificationListCubit>(
      create: (_) => NotificationListCubit(sl<NotificationRepository>()),
      child: const _Body(embedded: true),
    );
  }
}

class _Body extends StatefulWidget {
  final bool embedded;

  const _Body({required this.embedded});

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  late final ScrollController _scroll;

  @override
  void initState() {
    super.initState();
    _scroll = ScrollController()..addListener(_maybeLoadMore);
  }

  void _maybeLoadMore() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels >=
        _scroll.position.maxScrollExtent - 200) {
      context.read<NotificationListCubit>().loadMore();
    }
  }

  @override
  void dispose() {
    _scroll.removeListener(_maybeLoadMore);
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = BlocBuilder<NotificationListCubit, NotificationListState>(
      builder: (context, state) {
        if (state.loading && state.items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.items.isEmpty) {
          return RefreshIndicator(
            onRefresh: () =>
                context.read<NotificationListCubit>().refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                Center(child: Icon(Icons.inbox_outlined, size: 64)),
                SizedBox(height: 12),
                Center(child: Text('Bildirishnomalar yo\'q')),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => context.read<NotificationListCubit>().refresh(),
          child: ListView.separated(
            controller: _scroll,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: state.items.length + (state.hasMore ? 1 : 0),
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              if (i >= state.items.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final item = state.items[i];
              return _Row(item: item);
            },
          ),
        );
      },
    );

    if (widget.embedded) {
      // Host (e.g. marketing tab) supplies the AppBar. Surface the
      // "mark all read" affordance via an inline header so the action
      // stays reachable.
      return Column(
        children: [
          BlocBuilder<NotificationListCubit, NotificationListState>(
            buildWhen: (a, b) => a.items != b.items,
            builder: (context, state) {
              final hasUnread = state.items.any((n) => n.isUnread);
              if (!hasUnread) return const SizedBox.shrink();
              return Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: TextButton.icon(
                    onPressed: () =>
                        context.read<NotificationListCubit>().markAllRead(),
                    icon: const Icon(Icons.done_all, size: 18),
                    label: const Text('Hammasini o\'qilgan'),
                  ),
                ),
              );
            },
          ),
          Expanded(child: list),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirishnomalar'),
        actions: [
          BlocBuilder<NotificationListCubit, NotificationListState>(
            buildWhen: (a, b) => a.items != b.items,
            builder: (context, state) {
              final hasUnread = state.items.any((n) => n.isUnread);
              return IconButton(
                tooltip: 'Hammasini o\'qilgan deb belgilash',
                onPressed: hasUnread
                    ? () => context.read<NotificationListCubit>().markAllRead()
                    : null,
                icon: const Icon(Icons.done_all),
              );
            },
          ),
          IconButton(
            tooltip: 'Sozlamalar',
            onPressed: () => Navigator.pushNamed(
              context,
              AppRouter.notificationPreferencesRoute,
            ),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: list,
    );
  }
}

class _Row extends StatelessWidget {
  final AppNotification item;

  const _Row({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = DateFormat('dd.MM HH:mm');
    return ListTile(
      leading: CircleAvatar(
        backgroundColor:
            theme.colorScheme.primary.withValues(alpha: item.isUnread ? 1 : 0.4),
        child: Icon(_iconForType(item.type), color: Colors.white, size: 20),
      ),
      title: Text(
        item.title.isEmpty ? '(Sarlavhasiz)' : item.title,
        style: TextStyle(
          fontWeight: item.isUnread ? FontWeight.w600 : FontWeight.normal,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        item.body,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            formatter.format(item.createdAt.toLocal()),
            style: theme.textTheme.bodySmall,
          ),
          if (item.isUnread)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: theme.colorScheme.error,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
      onTap: () {
        // Mark-read auto-fires inside the detail cubit (passport §5.3).
        // Deep-link routes still funnel through the detail screen by
        // default — only the detail screen can decide whether to bounce
        // the user further (e.g. tap "Open customer" CTA).
        if (item.deepLink != null && item.deepLink!.isNotEmpty) {
          NotificationTapRouter.handleDeepLink(
            context,
            deepLink: item.deepLink,
            notificationId: item.id,
          );
        } else {
          Navigator.pushNamed(
            context,
            AppRouter.notificationDetailRoute,
            arguments: {'id': item.id},
          );
        }
      },
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'debt_alert':
        return Icons.warning_amber_rounded;
      case 'order_new':
        return Icons.receipt_long;
      case 'stock_lot_expiring':
        return Icons.inventory_2;
      case 'system_announcement':
        return Icons.campaign;
      default:
        return Icons.notifications;
    }
  }
}
