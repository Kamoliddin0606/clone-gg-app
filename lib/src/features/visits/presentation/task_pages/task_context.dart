/// Per-task arguments passed by the runner to the renderer.
///
/// The renderer never reads from the BLoC directly — it only knows the
/// callbacks. This keeps every renderer independently testable.
class TaskContext {
  const TaskContext({
    required this.visitId,
    required this.taskId,
    required this.taskCode,
    required this.payloadSchema,
    required this.config,
    required this.onCompleted,
    required this.onSkipped,
    required this.onBack,
    this.draftPayload,
  });

  final String visitId;
  final String taskId;
  final String taskCode;
  final Map<String, dynamic> payloadSchema;
  final Map<String, dynamic> config;
  final Map<String, dynamic>? draftPayload;
  final void Function(Map<String, dynamic> payload) onCompleted;
  final void Function(String reason) onSkipped;
  final void Function() onBack;
}
