import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/features/visits/presentation/task_pages/task_context.dart';
import 'package:gloria_marketing_flutter/src/features/visits/presentation/task_renderer_registry.dart';

TaskContext _ctx(String code) => TaskContext(
      visitId: 'v',
      taskId: 't',
      taskCode: code,
      payloadSchema: const {},
      config: const {},
      onCompleted: (_) {},
      onSkipped: (_) {},
      onBack: () {},
    );

void main() {
  setUp(() => TaskRendererRegistry.instance.clear());
  tearDown(() => TaskRendererRegistry.instance.clear());

  test('resolves a registered renderer', () {
    TaskRendererRegistry.instance
        .register('PHOTO_BEFORE', (_) => const SizedBox(key: ValueKey('photo')));
    final w = TaskRendererRegistry.instance.resolve(_ctx('PHOTO_BEFORE'));
    expect(w.key, const ValueKey('photo'));
  });

  test('falls back to the default renderer for unknown codes', () {
    TaskRendererRegistry.instance
        .setDefault((_) => const SizedBox(key: ValueKey('generic')));
    final w = TaskRendererRegistry.instance.resolve(_ctx('NEW_TASK_2027'));
    expect(w.key, const ValueKey('generic'));
  });

  test('throws when neither a specific nor default factory is set', () {
    expect(
      () => TaskRendererRegistry.instance.resolve(_ctx('PHOTO_BEFORE')),
      throwsStateError,
    );
  });
}
