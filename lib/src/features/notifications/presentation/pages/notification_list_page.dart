import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:gloria_marketing_flutter/src/core/router/app_router.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/models/app_notification.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/repositories/notification_repository.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/presentation/bloc/notification_list_cubit.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/presentation/pages/notification_detail_page.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/services/notification_tap_router.dart';

/// Tablet breakpoint — anything ≥ this is treated as a wide layout and
/// gets the Phase 2d master-detail split. Matches Material's "expanded"
/// window class (https://m3.material.io/foundations/layout/applying-layout).
const double _tabletBreakpoint = 720;

/// Long-press bottom-sheet options on a notification row (Phase 2b).
enum _RowAction { markUnread, snooze1h, snooze4h, snoozeTomorrow }

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

  /// Tablet-only — id of the row showing in the right pane. `null`
  /// means the empty-state placeholder is rendered. Reset whenever the
  /// list re-syncs and the previously selected row is no longer
  /// visible (e.g. it got snoozed or expired).
  String? _selectedId;

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

  /// Tablet-mode row tap: keep the selection in this widget and let
  /// the right pane render the detail. Deep links still take priority
  /// — they're cross-feature jumps (e.g. customer page) that don't
  /// belong inside the notifications screen.
  void _selectRow(AppNotification item) {
    if (item.deepLink != null && item.deepLink!.isNotEmpty) {
      NotificationTapRouter.handleDeepLink(
        context,
        deepLink: item.deepLink,
        notificationId: item.id,
      );
      return;
    }
    setState(() => _selectedId = item.id);
    // Mark-read fires inside the detail cubit (NotificationDetailView
    // → NotificationDetailCubit.load), so we don't need to call it
    // here.
  }

  @override
  Widget build(BuildContext context) {
    final list = _buildList(onSelect: widget.embedded ? null : _selectRow);

    final l10n = AppLocalizations.of(context)!;

    if (widget.embedded) {
      // Marketing tab — single-pane regardless of screen size; the
      // tab is already a sub-region of a larger screen, splitting it
      // again wastes horizontal space.
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
                    label: Text(l10n.notif_markAllReadButton),
                  ),
                ),
              );
            },
          ),
          Expanded(child: list),
        ],
      );
    }

    // Full-screen variant — decide phone vs tablet at runtime so the
    // same widget tree works in foldables / orientation changes.
    final isTablet = MediaQuery.of(context).size.width >= _tabletBreakpoint;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notif_listTitle),
        actions: [
          BlocBuilder<NotificationListCubit, NotificationListState>(
            buildWhen: (a, b) => a.items != b.items,
            builder: (context, state) {
              final hasUnread = state.items.any((n) => n.isUnread);
              return IconButton(
                tooltip: l10n.notif_markAllReadTooltip,
                onPressed: hasUnread
                    ? () => context.read<NotificationListCubit>().markAllRead()
                    : null,
                icon: const Icon(Icons.done_all),
              );
            },
          ),
          IconButton(
            tooltip: l10n.notif_settings,
            onPressed: () => Navigator.pushNamed(
              context,
              AppRouter.notificationPreferencesRoute,
            ),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: isTablet ? _buildSplitView(list) : list,
    );
  }

  /// Inner list — extracted so it can be reused in both single-pane
  /// and split-pane layouts. [onSelect] is called instead of the
  /// row's default route-push when non-null (tablet mode).
  Widget _buildList({void Function(AppNotification)? onSelect}) {
    return BlocBuilder<NotificationListCubit, NotificationListState>(
      builder: (context, state) {
        if (state.loading && state.items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.items.isEmpty) {
          final l10n = AppLocalizations.of(context)!;
          return RefreshIndicator(
            onRefresh: () =>
                context.read<NotificationListCubit>().refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 120),
                const Center(child: Icon(Icons.inbox_outlined, size: 64)),
                const SizedBox(height: 12),
                Center(child: Text(l10n.notif_emptyTitle)),
              ],
            ),
          );
        }
        // If the previously-selected row disappeared from the list
        // (snoozed, expired, evicted), drop the selection so the
        // right pane shows the empty state.
        if (_selectedId != null &&
            !state.items.any((n) => n.id == _selectedId)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _selectedId = null);
          });
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
              return _Row(
                item: item,
                isSelected: onSelect != null && item.id == _selectedId,
                onTap: onSelect,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSplitView(Widget list) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final id = _selectedId;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 360,
          child: Material(
            color: theme.colorScheme.surface,
            child: list,
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: id == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.mail_outline,
                          size: 64,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.notif_tabletPlaceholder,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : NotificationDetailView(id: id),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final AppNotification item;

  /// True when this row is the currently-active selection in the
  /// tablet split layout. Renders a tinted background so the user can
  /// tell which row the right pane is showing.
  final bool isSelected;

  /// Tablet mode hook — if provided, called instead of the default
  /// route push. Phone single-pane mode passes `null` so the existing
  /// navigator-based behaviour stays.
  final void Function(AppNotification item)? onTap;

  const _Row({
    required this.item,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final formatter = DateFormat('dd.MM HH:mm');
    return ListTile(
      selected: isSelected,
      selectedTileColor:
          theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
      leading: CircleAvatar(
        backgroundColor:
            theme.colorScheme.primary.withValues(alpha: item.isUnread ? 1 : 0.4),
        child: Icon(_iconForType(item.type), color: Colors.white, size: 20),
      ),
      title: Text(
        item.title.isEmpty ? l10n.notif_untitled : item.title,
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
        // Tablet split mode — defer to the host so it can render the
        // detail in the right pane without pushing a new route.
        if (onTap != null) {
          onTap!(item);
          return;
        }
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
      onLongPress: () => _showRowActions(context, item),
    );
  }

  Future<void> _showRowActions(
    BuildContext context,
    AppNotification item,
  ) async {
    final cubit = context.read<NotificationListCubit>();
    final l10n = AppLocalizations.of(context)!;
    final action = await showModalBottomSheet<_RowAction>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!item.isUnread)
              ListTile(
                leading: const Icon(Icons.mark_email_unread_outlined),
                title: Text(l10n.notif_rowMarkUnread),
                onTap: () => Navigator.pop(ctx, _RowAction.markUnread),
              ),
            ListTile(
              leading: const Icon(Icons.snooze),
              title: Text(l10n.notif_rowSnooze1h),
              onTap: () => Navigator.pop(ctx, _RowAction.snooze1h),
            ),
            ListTile(
              leading: const Icon(Icons.snooze),
              title: Text(l10n.notif_rowSnooze4h),
              onTap: () => Navigator.pop(ctx, _RowAction.snooze4h),
            ),
            ListTile(
              leading: const Icon(Icons.bedtime_outlined),
              title: Text(l10n.notif_rowSnoozeTomorrow),
              onTap: () => Navigator.pop(ctx, _RowAction.snoozeTomorrow),
            ),
          ],
        ),
      ),
    );

    if (action == null) return;
    switch (action) {
      case _RowAction.markUnread:
        await cubit.markUnread(item.id);
        break;
      case _RowAction.snooze1h:
        await cubit.snooze(item.id, const Duration(hours: 1));
        break;
      case _RowAction.snooze4h:
        await cubit.snooze(item.id, const Duration(hours: 4));
        break;
      case _RowAction.snoozeTomorrow:
        await cubit.snooze(item.id, _untilTomorrowMorning());
        break;
    }
  }

  /// Returns the [Duration] from now until 08:00 the next day (local).
  Duration _untilTomorrowMorning() {
    final now = DateTime.now();
    final tomorrow8 = DateTime(now.year, now.month, now.day + 1, 8);
    return tomorrow8.difference(now);
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
