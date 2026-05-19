import 'task.dart';

/// Whether the user may jump between tasks or must complete required ones in
/// order. Picked from `PermissionFlags.strictSequence` at session start.
sealed class SequencePolicy {
  const SequencePolicy();

  /// Returns `null` if the task can be started, or a [SequenceBlock] with the
  /// task that must be completed first.
  SequenceBlock? canStart({
    required VisitTask task,
    required List<VisitTask> allTasks,
  });
}

class FreeSequencePolicy extends SequencePolicy {
  const FreeSequencePolicy();

  @override
  SequenceBlock? canStart({
    required VisitTask task,
    required List<VisitTask> allTasks,
  }) =>
      null;
}

class StrictSequencePolicy extends SequencePolicy {
  const StrictSequencePolicy();

  @override
  SequenceBlock? canStart({
    required VisitTask task,
    required List<VisitTask> allTasks,
  }) {
    for (final t in allTasks) {
      if (t.taskId == task.taskId) return null; // reached self → no blocker
      if (!t.required) continue;
      if (t.status != TaskRunStatus.completed) {
        return SequenceBlock(blockingTask: t);
      }
    }
    return null;
  }
}

class SequenceBlock {
  const SequenceBlock({required this.blockingTask});
  final VisitTask blockingTask;
}
