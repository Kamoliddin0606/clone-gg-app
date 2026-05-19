import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/features/visits/domain/entities/sequence_policy.dart';
import 'package:gloria_marketing_flutter/src/features/visits/domain/entities/task.dart';

VisitTask _t({
  required String id,
  required int order,
  required bool required,
  required TaskRunStatus status,
}) =>
    VisitTask(
      taskId: id,
      taskCodeRaw: 'X_$id',
      displayOrder: order,
      required: required,
      status: status,
      payload: const {},
      payloadSchemaVersion: 1,
    );

void main() {
  group('FreeSequencePolicy', () {
    test('never blocks', () {
      const policy = FreeSequencePolicy();
      final tasks = [
        _t(id: '1', order: 0, required: true, status: TaskRunStatus.pending),
        _t(id: '2', order: 1, required: true, status: TaskRunStatus.pending),
      ];
      expect(policy.canStart(task: tasks[1], allTasks: tasks), isNull);
    });
  });

  group('StrictSequencePolicy', () {
    test('blocks second task when first required one is pending', () {
      const policy = StrictSequencePolicy();
      final tasks = [
        _t(id: '1', order: 0, required: true, status: TaskRunStatus.pending),
        _t(id: '2', order: 1, required: true, status: TaskRunStatus.pending),
      ];
      final block = policy.canStart(task: tasks[1], allTasks: tasks);
      expect(block?.blockingTask.taskId, '1');
    });

    test('allows skipping over optional pending tasks', () {
      const policy = StrictSequencePolicy();
      final tasks = [
        _t(id: '1', order: 0, required: false, status: TaskRunStatus.pending),
        _t(id: '2', order: 1, required: true, status: TaskRunStatus.pending),
      ];
      final block = policy.canStart(task: tasks[1], allTasks: tasks);
      expect(block, isNull);
    });

    test('clears once the prior required task is completed', () {
      const policy = StrictSequencePolicy();
      final tasks = [
        _t(id: '1', order: 0, required: true, status: TaskRunStatus.completed),
        _t(id: '2', order: 1, required: true, status: TaskRunStatus.pending),
      ];
      expect(policy.canStart(task: tasks[1], allTasks: tasks), isNull);
    });

    test('first task is never blocked', () {
      const policy = StrictSequencePolicy();
      final tasks = [
        _t(id: '1', order: 0, required: true, status: TaskRunStatus.pending),
      ];
      expect(policy.canStart(task: tasks.first, allTasks: tasks), isNull);
    });
  });
}
