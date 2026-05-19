import 'package:flutter/material.dart';

import '../../domain/entities/task.dart';

/// Card surface for a task the user can't start yet (strict sequence).
///
/// Replaces the legacy "disabled button with no reason" UX. Tapping shows
/// a `SnackBar` naming the task that must be completed first; the lock
/// icon and tooltip surface the same hint passively.
class LockedTaskCard extends StatelessWidget {
  const LockedTaskCard({
    super.key,
    required this.task,
    required this.blockingTask,
    required this.displayName,
    required this.blockingDisplayName,
  });

  final VisitTask task;
  final VisitTask blockingTask;
  final String displayName;
  final String blockingDisplayName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reason = 'Avval "$blockingDisplayName" vazifasini yakunlang';
    return Card(
      child: Tooltip(
        message: reason,
        child: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(reason)));
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.lock_outline,
                    color: theme.colorScheme.outline),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displayName,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(color: theme.colorScheme.outline)),
                      const SizedBox(height: 4),
                      Text(reason,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.outline)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: theme.colorScheme.outline),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
