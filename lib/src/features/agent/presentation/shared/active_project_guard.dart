// =============================================================================
// active_project_guard.dart
// =============================================================================
//
// Gate rail for the Settings page: every user-initiated data refresh / sync
// must first verify that an active project is selected (when the tenant is
// project-scope). Without one, the backend rejects sync calls with
// `customer_project_required` and the per-project debt-limit / customer
// list cannot be filtered — there is literally nothing useful to fetch.
//
// Two public surfaces:
//
//   * `ensureActiveProject(context)` — async guard called inline before any
//     sync trigger. Returns `false` and shows a snackbar when blocked so
//     the caller can `early return`.
//
//   * `ActiveProjectRequiredBanner` — a small persistent banner that lives
//     at the top of the affected tab and offers a one-tap shortcut to the
//     Projects tab. It listens to [ProjectContext] so picking a project
//     anywhere hides the banner automatically.
//
// `org-scope` tenants are never blocked: `requiresProjectHeader == false`
// and the bootstrap auto-elects a project from `user_projects` if any
// exist. The guard short-circuits to `true` for them.
// =============================================================================

import 'package:flutter/material.dart';

import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:gloria_marketing_flutter/src/core/services/project_context.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';

/// `true` when the current tenant is project-scope AND no project has
/// been picked yet. This is the only condition that blocks sync — org
/// tenants pass straight through.
bool isBlockedByProjectGate(ProjectContext pc) =>
    pc.requiresProjectHeader && pc.activeProject == null;

/// Inline guard. Call before every user-initiated sync / refresh on the
/// Settings page. Returns `true` to proceed, `false` to abort (a
/// snackbar has already been shown to the user).
///
/// The check is O(1) — two getter reads on the singleton
/// [ProjectContext] — and never performs I/O. Safe to call on every
/// button tap without measurable cost.
Future<bool> ensureActiveProject(BuildContext context) async {
  final pc = sl<ProjectContext>();
  if (!isBlockedByProjectGate(pc)) return true;

  if (!context.mounted) return false;
  final l10n = AppLocalizations.of(context);
  ScaffoldMessenger.of(context).removeCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        l10n?.projectGate_blockedSnackbar ??
            'Select an active project first. You can pick one from '
                'the Projects tab.',
      ),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Theme.of(context).colorScheme.error,
      duration: const Duration(seconds: 3),
    ),
  );
  return false;
}

/// Banner that surfaces the "no active project" state. Watches
/// [ProjectContext] so it appears / disappears automatically as the
/// user picks a project. Returns `SizedBox.shrink()` (i.e. nothing) in
/// the steady-state where a project is already active or the tenant
/// is org-scope — zero visual cost in the happy path.
class ActiveProjectRequiredBanner extends StatelessWidget {
  /// Tapped when the user wants to jump to the Projects picker. The
  /// parent supplies this so the banner stays decoupled from the
  /// Settings-tab navigation mechanism.
  final VoidCallback onPickProject;

  const ActiveProjectRequiredBanner({super.key, required this.onPickProject});

  @override
  Widget build(BuildContext context) {
    final pc = sl<ProjectContext>();
    return ListenableBuilder(
      listenable: pc,
      builder: (context, _) {
        if (!isBlockedByProjectGate(pc)) return const SizedBox.shrink();
        return _BannerCard(onPickProject: onPickProject);
      },
    );
  }
}

class _BannerCard extends StatelessWidget {
  final VoidCallback onPickProject;
  const _BannerCard({required this.onPickProject});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      decoration: BoxDecoration(
        color: cs.errorContainer.withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.error.withOpacity(0.45), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cs.error.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.error_outline_rounded, color: cs.error, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.projectGate_bannerTitle ?? 'No active project',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n?.projectGate_bannerMessage ??
                      'Pick an active project before refreshing or '
                          'syncing any data.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.tonalIcon(
                    onPressed: onPickProject,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: Text(
                      l10n?.projectGate_bannerCta ?? 'Pick a project',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: cs.error,
                      foregroundColor: cs.onError,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
