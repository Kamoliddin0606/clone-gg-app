import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:gloria_marketing_flutter/src/core/services/connectivity_monitor_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/user_project.dart';

/// Settings → Permissions tab section listing the user's projects together
/// with their backend-issued debt limits (synced from
/// `/api/mobile/v2/projects/config/`).
///
/// Surface contract:
/// - The list is sourced from `user_projects` (offline-friendly cache).
/// - Limit values come from [UserProject.debtLimit] / [debtLimitCurrency].
/// - When the device is offline, a non-blocking banner is shown to make it
///   clear that values may be stale.
/// - When the most recent refresh attempt failed, a separate error banner
///   surfaces the reason without hiding the cached rows.
/// - The "last updated" timestamp is the newest `updated_at` across the
///   user's projects, formatted in the device locale.
class ProjectDebtLimitsSection extends StatefulWidget {
  const ProjectDebtLimitsSection({super.key});

  @override
  State<ProjectDebtLimitsSection> createState() =>
      _ProjectDebtLimitsSectionState();
}

class _ProjectDebtLimitsSectionState extends State<ProjectDebtLimitsSection> {
  List<UserProject> _projects = const [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _loadErrorMessage;
  String? _refreshErrorMessage;
  DateTime? _lastUpdated;
  String? _userCode;

  ConnectivityMonitorService? _connectivity;
  StreamSubscription<bool>? _connectivitySubscription;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _setupConnectivity();
    _loadProjects();
  }

  void _setupConnectivity() {
    if (sl.isRegistered<ConnectivityMonitorService>()) {
      _connectivity = sl<ConnectivityMonitorService>();
      _isOnline = _connectivity!.isConnected;
      _connectivitySubscription =
          _connectivity!.connectivityStream.listen((connected) {
        if (!mounted) return;
        setState(() => _isOnline = connected);
      });
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  /// Mirrors [DataSyncService._projectsConfigSyncErrorKey]; the sync layer
  /// writes the last `/projects/config/` failure here so this section can
  /// surface it after a cold start even though the user did not press the
  /// refresh button this session.
  static const String _projectsConfigSyncErrorKey =
      'projects_config_last_sync_error';

  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
      _loadErrorMessage = null;
    });
    try {
      final prefs = sl<SharedPreferencesService>();
      final userCode = prefs.getUserCode();
      _userCode = userCode;
      if (userCode == null || userCode.isEmpty) {
        setState(() {
          _isLoading = false;
          _projects = const [];
        });
        return;
      }
      final dataSync = sl<DataSyncService>();
      final projects = await dataSync.getCachedUserProjects(userCode);
      final persistedError =
          prefs.preferences.getString(_projectsConfigSyncErrorKey);
      if (!mounted) return;
      setState(() {
        _projects = _sortProjects(projects);
        _lastUpdated = _newestUpdatedAt(projects);
        _isLoading = false;
        _refreshErrorMessage =
            (persistedError != null && persistedError.isNotEmpty)
                ? persistedError
                : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadErrorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;
    final userCode = _userCode;
    if (userCode == null || userCode.isEmpty) {
      // ignore: avoid_print
      print('[PROJECTS_SYNC] refresh aborted: userCode missing');
      _loadProjects();
      return;
    }
    // ignore: avoid_print
    print(
        '[PROJECTS_SYNC] refresh tapped userCode=$userCode forceRefresh=true');
    setState(() {
      _isRefreshing = true;
      _refreshErrorMessage = null;
    });
    final stopwatch = Stopwatch()..start();
    try {
      final dataSync = sl<DataSyncService>();
      final refreshed = await dataSync.syncUserProjects(
          userCode: userCode, forceRefresh: true);
      stopwatch.stop();
      // ignore: avoid_print
      print(
          '[PROJECTS_SYNC] refresh OK projects=${refreshed.length} '
          'totalMs=${stopwatch.elapsedMilliseconds} '
          'limits=${refreshed.map((p) => "${p.code}:${p.debtLimit ?? "null"}").toList()}');
      if (!mounted) return;
      setState(() {
        _projects = _sortProjects(refreshed);
        _lastUpdated = _newestUpdatedAt(refreshed);
        _isRefreshing = false;
      });
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.projectDebtLimits_refreshSuccess),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e, st) {
      stopwatch.stop();
      // ignore: avoid_print
      print(
          '[PROJECTS_SYNC] refresh FAILED totalMs=${stopwatch.elapsedMilliseconds} '
          'error=$e');
      // ignore: avoid_print
      print('[PROJECTS_SYNC] refresh stack: $st');
      if (!mounted) return;
      setState(() {
        _refreshErrorMessage = e.toString();
        _isRefreshing = false;
      });
    }
  }

  static List<UserProject> _sortProjects(List<UserProject> projects) {
    final list = [...projects];
    list.sort((a, b) {
      final aHas = a.debtLimit != null;
      final bHas = b.debtLimit != null;
      if (aHas != bHas) return aHas ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return list;
  }

  static DateTime? _newestUpdatedAt(List<UserProject> projects) {
    DateTime? newest;
    for (final p in projects) {
      final ts = p.updatedAt;
      if (ts == null) continue;
      if (newest == null || ts.isAfter(newest)) newest = ts;
    }
    return newest;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(
              projectCount: _projects.length,
              isRefreshing: _isRefreshing,
              onRefresh: _isLoading ? null : _refresh,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                l10n.projectDebtLimits_sectionSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _MetadataRow(
                isOnline: _isOnline,
                isRefreshing: _isRefreshing,
                lastUpdated: _lastUpdated,
              ),
            ),
            if (!_isOnline)
              Padding(
                padding: const EdgeInsets.only(top: 12, right: 8),
                child: _Notice(
                  icon: Icons.cloud_off_outlined,
                  text: l10n.projectDebtLimits_offlineNotice,
                  tone: _NoticeTone.warning,
                ),
              ),
            if (_refreshErrorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 12, right: 8),
                child: _Notice(
                  icon: Icons.error_outline,
                  text: l10n.projectDebtLimits_errorNotice,
                  detail: _refreshErrorMessage,
                  tone: _NoticeTone.error,
                ),
              ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _Body(
                isLoading: _isLoading,
                loadError: _loadErrorMessage,
                userCodeMissing: _userCode == null || _userCode!.isEmpty,
                projects: _projects,
                onRetry: _loadProjects,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int projectCount;
  final bool isRefreshing;
  final VoidCallback? onRefresh;

  const _Header({
    required this.projectCount,
    required this.isRefreshing,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: cs.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.account_balance_wallet_outlined,
              color: cs.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            l10n.projectDebtLimits_sectionTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
        ),
        if (projectCount > 0)
          Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              l10n.projectDebtLimits_countBadge(projectCount),
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        IconButton(
          tooltip: l10n.projectDebtLimits_refreshTooltip,
          onPressed: onRefresh,
          icon: isRefreshing
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: cs.primary,
                  ),
                )
              : Icon(Icons.refresh, color: cs.primary),
        ),
      ],
    );
  }
}

class _MetadataRow extends StatelessWidget {
  final bool isOnline;
  final bool isRefreshing;
  final DateTime? lastUpdated;

  const _MetadataRow({
    required this.isOnline,
    required this.isRefreshing,
    required this.lastUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final lastUpdatedText = isRefreshing
        ? l10n.projectDebtLimits_refreshing
        : (lastUpdated == null
            ? l10n.projectDebtLimits_neverUpdated
            : _formatTimestamp(context, lastUpdated!));

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (!isOnline)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: cs.error.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off, size: 14, color: cs.error),
                const SizedBox(width: 6),
                Text(
                  l10n.offline,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule, size: 14, color: cs.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              '${l10n.projectDebtLimits_lastUpdatedLabel}: $lastUpdatedText',
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatTimestamp(BuildContext context, DateTime ts) {
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final now = DateTime.now();
    final isToday = ts.year == now.year &&
        ts.month == now.month &&
        ts.day == now.day;
    final fmt = isToday
        ? DateFormat.Hm(localeTag)
        : DateFormat.yMMMd(localeTag).add_Hm();
    return fmt.format(ts);
  }
}

enum _NoticeTone { warning, error }

class _Notice extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? detail;
  final _NoticeTone tone;

  const _Notice({
    required this.icon,
    required this.text,
    required this.tone,
    this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final base = tone == _NoticeTone.error ? cs.error : cs.tertiary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: base.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: base.withOpacity(0.30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: base, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: base,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (detail != null && detail!.isNotEmpty && kDebugMode) ...[
                  const SizedBox(height: 2),
                  Text(
                    detail!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: base.withOpacity(0.8),
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final bool isLoading;
  final String? loadError;
  final bool userCodeMissing;
  final List<UserProject> projects;
  final VoidCallback onRetry;

  const _Body({
    required this.isLoading,
    required this.loadError,
    required this.userCodeMissing,
    required this.projects,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(Icons.error_outline, color: cs.error, size: 40),
              const SizedBox(height: 8),
              Text(
                l10n.projectDebtLimits_loadingError(loadError!),
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    if (userCodeMissing) {
      return _EmptyOrInfoState(
        icon: Icons.person_off_outlined,
        text: l10n.projectDebtLimits_userCodeMissing,
      );
    }

    if (projects.isEmpty) {
      return _EmptyOrInfoState(
        icon: Icons.folder_off_outlined,
        text: l10n.projectDebtLimits_emptyState,
      );
    }

    return Column(
      children: [
        for (var i = 0; i < projects.length; i++) ...[
          _ProjectTile(project: projects[i]),
          if (i != projects.length - 1)
            Divider(height: 1, color: cs.outlineVariant.withOpacity(0.4)),
        ],
      ],
    );
  }
}

class _EmptyOrInfoState extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyOrInfoState({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 40, color: cs.onSurfaceVariant),
            const SizedBox(height: 8),
            Text(
              text,
              style:
                  theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectTile extends StatelessWidget {
  final UserProject project;
  const _ProjectTile({required this.project});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final hasLimit = project.debtLimit != null;
    final limitColor = hasLimit ? cs.primary : cs.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cs.primaryContainer.withOpacity(0.55),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.folder_outlined,
                color: cs.onPrimaryContainer, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  project.name,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  project.code,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.projectDebtLimits_limitLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              _LimitValue(
                amount: project.debtLimit,
                currency: project.debtLimitCurrency,
                color: limitColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LimitValue extends StatelessWidget {
  final double? amount;
  final String? currency;
  final Color color;

  const _LimitValue({
    required this.amount,
    required this.currency,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (amount == null) {
      return Text(
        l10n.projectDebtLimits_noLimit,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: color,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final formatter = NumberFormat.decimalPattern(localeTag);
    final formatted = formatter.format(amount);
    final unit = (currency != null && currency!.isNotEmpty) ? currency : 'UZS';

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          formatted,
          style: theme.textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          unit!,
          style: theme.textTheme.labelMedium?.copyWith(
            color: color.withOpacity(0.85),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
