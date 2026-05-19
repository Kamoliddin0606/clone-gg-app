import 'package:flutter/widgets.dart';

import 'task_pages/task_context.dart';

typedef TaskRendererFactory = Widget Function(TaskContext ctx);

/// Maps a wire `task_code` to the widget that renders it.
///
/// Look-up falls back to a caller-supplied [defaultRenderer] (the
/// `GenericFormRenderer` in production) when a code isn't registered — that
/// lets the server roll out new tasks ahead of a mobile build, the
/// passport's "Lego" extensibility model.
class TaskRendererRegistry {
  TaskRendererRegistry._();
  static final TaskRendererRegistry instance = TaskRendererRegistry._();

  final Map<String, TaskRendererFactory> _factories = {};
  TaskRendererFactory? _defaultFactory;

  void register(String taskCode, TaskRendererFactory factory) {
    _factories[taskCode] = factory;
  }

  /// Sets the fallback used when a wire code has no explicit renderer.
  void setDefault(TaskRendererFactory factory) {
    _defaultFactory = factory;
  }

  /// Returns the widget for [ctx]. Throws if no factory is registered AND
  /// no [setDefault] has been wired — that's a programmer error, not a
  /// recoverable state.
  Widget resolve(TaskContext ctx) {
    final factory = _factories[ctx.taskCode] ?? _defaultFactory;
    if (factory == null) {
      throw StateError(
        'No renderer registered for task_code "${ctx.taskCode}" '
        'and no default fallback set. Did you forget '
        'TaskRendererRegistry.instance.setDefault(...)?',
      );
    }
    return factory(ctx);
  }

  /// Test helper.
  @visibleForTesting
  void clear() {
    _factories.clear();
    _defaultFactory = null;
  }
}
