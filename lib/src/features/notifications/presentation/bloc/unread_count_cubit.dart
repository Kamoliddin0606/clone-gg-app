import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gloria_marketing_flutter/src/features/notifications/data/repositories/notification_repository.dart';

/// Bell-badge counter. Pure pass-through over [NotificationRepository.unreadCountStream].
class UnreadCountCubit extends Cubit<int> {
  final NotificationRepository _repo;
  StreamSubscription<int>? _sub;

  UnreadCountCubit(this._repo) : super(_repo.unreadCountValue) {
    _sub = _repo.unreadCountStream.listen(emit);
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
