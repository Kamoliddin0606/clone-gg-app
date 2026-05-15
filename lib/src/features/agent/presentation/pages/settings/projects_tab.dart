import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/project_context.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/soap_api_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/user_project.dart';

/// Sozlamalar → Loyihalar tab. Foydalanuvchining faol loyihasini
/// ko'rsatadi va shu yerda boshqa loyihaga o'tish imkonini beradi.
///
/// Tenant qaysi `customer_scope` ostida bo'lishidan qat'iy nazar ishlaydi:
///   * `customer_scope == organization` tenantlarda picker mavjud emas
///     edi — endi shu yerda alohida tab orqali tanlash mumkin.
///   * `customer_scope == project` tenantlarda mavjud picker'ga
///     muqobil tezkor kirish.
///
/// Loyihalar ro'yxati `user_projects` jadvalidan o'qiladi; ro'yxat bo'sh
/// bo'lsa, SOAP `GetUserProjects` orqali bir martalik tortib olishga
/// urinish qilinadi (xuddi [ProjectPickerPage] qilgani kabi).
class ProjectsTab extends StatefulWidget {
  const ProjectsTab({super.key});

  @override
  State<ProjectsTab> createState() => _ProjectsTabState();
}

class _ProjectsTabState extends State<ProjectsTab> {
  late final ProjectContext _projectContext;
  List<UserProject> _projects = const [];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _projectContext = sl<ProjectContext>();
    _projectContext.addListener(_onProjectContextChanged);
    _loadProjects();
  }

  @override
  void dispose() {
    _projectContext.removeListener(_onProjectContextChanged);
    super.dispose();
  }

  void _onProjectContextChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final prefs = sl<SharedPreferencesService>();
      final db = sl<ApiDatabaseService>();
      final userCode = prefs.getUserCode() ?? '';
      if (userCode.isEmpty) {
        setState(() {
          _projects = const [];
          _isLoading = false;
        });
        return;
      }
      var rows = await db.getUserProjects(userCode);
      if (rows.isEmpty) {
        try {
          rows = await sl<SoapApiService>().getProjectsUser(userCode: userCode);
          if (rows.isNotEmpty) {
            await db.saveUserProjects(userCode, rows);
          }
        } catch (e) {
          if (kDebugMode) {
            print('ProjectsTab: SOAP fallback fetch failed: $e');
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _projects = rows;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _onPick(UserProject project) async {
    final active = _projectContext.activeProject;
    if (active?.code == project.code) return;
    await _projectContext.setActiveProject(project);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.projectsTab_switchedSnackbar(project.name)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final active = _projectContext.activeProject;
    final isProjectScope = _projectContext.requiresProjectHeader;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ActiveProjectCard(
            active: active,
            isProjectScope: isProjectScope,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.projectsTab_pickerSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_loadError != null)
            _ErrorBlock(
              message: l10n.projectsTab_loadError(_loadError!),
              onRetry: _loadProjects,
            )
          else if (_projects.isEmpty)
            _EmptyBlock(text: l10n.projectsTab_empty)
          else
            ..._projects.map((project) => _ProjectRow(
                  project: project,
                  selected: active?.code == project.code,
                  onTap: () => _onPick(project),
                )),
        ],
      ),
    );
  }
}

class _ActiveProjectCard extends StatelessWidget {
  final UserProject? active;
  final bool isProjectScope;
  const _ActiveProjectCard({
    required this.active,
    required this.isProjectScope,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.folder_special_outlined,
                    color: cs.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.projectsTab_sectionTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _kv(
              context,
              label: l10n.projectsTab_activeLabel,
              value: active?.name ?? '—',
              valueStyle: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: active != null ? cs.primary : cs.onSurfaceVariant,
              ),
            ),
            if (active != null) ...[
              const SizedBox(height: 6),
              _kv(
                context,
                label: 'code',
                value: active!.code,
                monospace: true,
              ),
              if (active!.debtLimit != null) ...[
                const SizedBox(height: 6),
                _kv(
                  context,
                  label: l10n.projectDebtLimits_limitLabel,
                  value:
                      '${_formatNumber(active!.debtLimit!)} ${active!.debtLimitCurrency ?? 'UZS'}',
                ),
              ],
            ],
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: cs.secondaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isProjectScope
                    ? l10n.projectsTab_scopeProject
                    : l10n.projectsTab_scopeOrganization,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSecondaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _kv(
    BuildContext context, {
    required String label,
    required String value,
    TextStyle? valueStyle,
    bool monospace = false,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: valueStyle ??
                theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface,
                  fontFamily: monospace ? 'monospace' : null,
                ),
          ),
        ),
      ],
    );
  }

  static String _formatNumber(double value) {
    final localeTag = 'uz_UZ';
    final formatter = NumberFormat.decimalPattern(localeTag);
    return formatter.format(value);
  }
}

class _ProjectRow extends StatelessWidget {
  final UserProject project;
  final bool selected;
  final VoidCallback onTap;
  const _ProjectRow({
    required this.project,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      elevation: selected ? 2 : 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? cs.primary : cs.outlineVariant.withOpacity(0.4),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selected
                      ? cs.primary.withOpacity(0.15)
                      : cs.primaryContainer.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.folder_outlined,
                  color: selected ? cs.primary : cs.onPrimaryContainer,
                  size: 20,
                ),
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
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
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
              if (selected)
                Icon(Icons.check_circle, color: cs.primary)
              else
                Icon(Icons.radio_button_unchecked,
                    color: cs.onSurfaceVariant.withOpacity(0.6)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  final String text;
  const _EmptyBlock({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.folder_off_outlined, size: 40, color: cs.onSurfaceVariant),
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

class _ErrorBlock extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBlock({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 40, color: cs.error),
            const SizedBox(height: 8),
            Text(
              message,
              style:
                  theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
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
}
