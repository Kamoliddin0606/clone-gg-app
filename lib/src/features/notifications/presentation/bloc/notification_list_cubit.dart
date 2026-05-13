import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gloria_marketing_flutter/src/features/notifications/data/models/app_notification.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/repositories/notification_repository.dart';

class NotificationListState extends Equatable {
  final bool loading;
  final bool refreshing;
  final List<AppNotification> items;
  final bool hasMore;
  final String? error;

  const NotificationListState({
    this.loading = false,
    this.refreshing = false,
    this.items = const [],
    this.hasMore = false,
    this.error,
  });

  NotificationListState copyWith({
    bool? loading,
    bool? refreshing,
    List<AppNotification>? items,
    bool? hasMore,
    String? error,
    bool clearError = false,
  }) {
    return NotificationListState(
      loading: loading ?? this.loading,
      refreshing: refreshing ?? this.refreshing,
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [loading, refreshing, items, hasMore, error];
}

class NotificationListCubit extends Cubit<NotificationListState> {
  final NotificationRepository _repo;
  StreamSubscription<List<AppNotification>>? _sub;

  NotificationListCubit(this._repo)
      : super(NotificationListState(
          loading: _repo.listValue.isEmpty,
          items: _repo.listValue,
        )) {
    _sub = _repo.listStream.listen((items) {
      emit(state.copyWith(items: items));
    });
    // Kick off the first incremental sync.
    refresh();
  }

  Future<void> refresh() async {
    emit(state.copyWith(
      refreshing: state.items.isNotEmpty,
      loading: state.items.isEmpty,
      clearError: true,
    ));
    await _repo.syncIncremental(force: true);
    emit(state.copyWith(loading: false, refreshing: false));
  }

  Future<void> loadMore() async {
    if (state.refreshing) return;
    final more = await _repo.loadMore();
    emit(state.copyWith(hasMore: more));
  }

  Future<void> markRead(String id) => _repo.markRead(id);
  Future<void> markAllRead() => _repo.markAllRead();

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
