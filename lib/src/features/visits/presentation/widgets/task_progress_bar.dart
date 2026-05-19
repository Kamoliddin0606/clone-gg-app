import 'package:flutter/material.dart';

import '../../domain/entities/task.dart';

/// Horizontal indicator that shows "N of M required tasks complete".
///
/// Skipped optional tasks are counted as complete for progress purposes
/// because the finish button only gates on required completion.
class TaskProgressBar extends StatelessWidget {
  const TaskProgressBar({super.key, required this.tasks});

  final List<VisitTask> tasks;

  @override
  Widget build(BuildContext context) {
    final total = tasks.length;
    final completed = tasks
        .where((t) =>
            t.status == TaskRunStatus.completed ||
            t.status == TaskRunStatus.skipped)
        .length;
    final value = total == 0 ? 0.0 : completed / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            'Bajarildi: $completed / $total',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        LinearProgressIndicator(value: value),
      ],
    );
  }
}
