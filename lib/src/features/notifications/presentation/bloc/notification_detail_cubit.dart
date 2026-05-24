import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gloria_marketing_flutter/src/features/notifications/data/models/app_notification.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/repositories/notification_repository.dart';

class NotificationDetailState extends Equatable {
  final bool loading;
  final AppNotification? notification;
  final String? error;

  const NotificationDetailState({
    this.loading = false,
    this.notification,
    this.error,
  });

  NotificationDetailState copyWith({
    bool? loading,
    AppNotification? notification,
    String? error,
    bool clearError = false,
  }) {
    return NotificationDetailState(
      loading: loading ?? this.loading,
      notification: notification ?? this.notification,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [loading, notification, error];
}

class NotificationDetailCubit extends Cubit<NotificationDetailState> {
  final NotificationRepository _repo;
  final String id;

  NotificationDetailCubit(this._repo, this.id)
      : super(const NotificationDetailState(loading: true)) {
    load();
  }

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearError: true));
    final cached = await _repo.getById(id);
    if (cached != null) {
      emit(state.copyWith(loading: false, notification: cached));
    }
    // removeOnNotFound=false: if the backend returns 404 we keep the
    // cached stub visible rather than deleting it and emptying the list.
    // A push stub that the server hasn't yet fanned-out to this user's
    // recipient table is the main case; genuine hard-deletes are
    // handled by list-sync eviction instead.
    final fresh = await _repo.fetchAndCache(id, removeOnNotFound: false);
    if (fresh != null) {
      emit(state.copyWith(loading: false, notification: fresh));
    } else if (cached == null) {
      emit(state.copyWith(
        loading: false,
        error: 'notification_not_found',
      ));
    }
    // Mark-read on open (debounced: only fires when still unread).
    final current = state.notification;
    if (current != null && current.isUnread) {
      await _repo.markRead(id);
    }
  }
}
