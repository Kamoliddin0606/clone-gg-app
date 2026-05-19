import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../domain/entities/local_visit_status.dart';
import '../domain/entities/visit_session.dart';
import '../domain/repositories/visit_repository.dart';
import 'bloc/visit_session/visit_session_bloc.dart';
import 'bloc/visit_session/visit_session_event.dart';
import '../visits_module.dart';
import 'pages/visit_session_page.dart';

/// Detects an unfinished visit on the local DB and offers the agent a
/// resume / discard choice. Called from the home page once on the first
/// build after login, so a crash mid-visit doesn't lose context.
///
/// The widget is intentionally a side-channel — it does NOT replace the
/// home screen. It mounts a microtask on the next frame so the dialog
/// surfaces over the home UI rather than blocking the splash.
class VisitRecoveryGate {
  const VisitRecoveryGate._();

  /// Inspects the local store and, if an in-progress visit exists,
  /// shows a dialog. Returns `true` when the user opted to resume.
  static Future<bool> probe(BuildContext context) async {
    final sl = GetIt.instance;
    if (!sl.isRegistered<VisitRepository>()) return false;
    final repo = sl<VisitRepository>();
    final candidates = await repo.findByStatus(const [
      'in_progress',
      'finished_local',
    ]);
    if (candidates.isEmpty || !context.mounted) return false;

    // Prefer the most recently updated session; older ones are
    // surfaced via the dead-letter screen only.
    candidates.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    final newest = candidates.first;

    final choice = await showDialog<_RecoveryChoice>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _RecoveryDialog(session: newest),
    );

    if (!context.mounted) return false;

    switch (choice) {
      case _RecoveryChoice.resume:
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => VisitsBlocProviders(
            child: _ResumeOnMount(visitId: newest.visitId),
          ),
        ));
        return true;
      case _RecoveryChoice.discard:
        await repo.markCancelled(newest.visitId);
        return false;
      case _RecoveryChoice.later:
      case null:
        return false;
    }
  }
}

enum _RecoveryChoice { resume, discard, later }

class _RecoveryDialog extends StatelessWidget {
  const _RecoveryDialog({required this.session});

  final VisitSession session;

  @override
  Widget build(BuildContext context) {
    final completed = session.tasks
        .where((t) => t.status.wire == 'completed')
        .length;
    final total = session.tasks.length;
    final isLocal = session.status == LocalVisitStatus.finishedLocal;

    return AlertDialog(
      title: const Text('Yakunlanmagan tashrif'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isLocal
                ? 'Avvalgi tashrif yakunlangan, lekin serverga yuborilmagan.'
                : 'Avvalgi tashrif chala qoldi.',
          ),
          const SizedBox(height: 8),
          Text('Mijoz: ${session.customerId}'),
          Text('Boshlangan: ${session.startedAt.toLocal()}'),
          Text('Bajarilgan: $completed / $total vazifa'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.pop(context, _RecoveryChoice.later),
          child: const Text('Keyinroq'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.pop(context, _RecoveryChoice.discard),
          child: const Text('Bekor qilish'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.pop(context, _RecoveryChoice.resume),
          child: const Text('Davom etish'),
        ),
      ],
    );
  }
}

/// Wraps [VisitSessionPage] but dispatches `ResumeVisit` once the bloc is
/// mounted. Saves callers from juggling `BlocProvider` lifecycle.
class _ResumeOnMount extends StatefulWidget {
  const _ResumeOnMount({required this.visitId});
  final String visitId;

  @override
  State<_ResumeOnMount> createState() => _ResumeOnMountState();
}

class _ResumeOnMountState extends State<_ResumeOnMount> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<VisitSessionBloc>().add(ResumeVisit(widget.visitId));
    });
  }

  @override
  Widget build(BuildContext context) => const VisitSessionPage();
}
