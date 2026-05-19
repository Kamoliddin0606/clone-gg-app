import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/outbox_status/outbox_status_cubit.dart';

/// Small indicator that surfaces unflushed envelopes (pending / retrying)
/// and dead-letter entries the user must act on.
///
/// Wraps a child (typically the AppBar's sync icon). Hides itself when the
/// queue is empty.
class OutboxStatusBadge extends StatelessWidget {
  const OutboxStatusBadge({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OutboxStatusCubit, OutboxStatusState>(
      builder: (context, state) {
        final unflushed = state.unflushed;
        final dead = state.deadLetter;
        if (unflushed == 0 && dead == 0) return child;
        return Badge(
          label: Text('${unflushed + dead}'),
          backgroundColor:
              dead > 0 ? Colors.red : Theme.of(context).colorScheme.tertiary,
          child: child,
        );
      },
    );
  }
}
