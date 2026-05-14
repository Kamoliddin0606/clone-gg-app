import 'package:flutter/material.dart';

import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/project_context.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/soap_api_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/user_project.dart';

/// Picker for the active project under `customer_scope=project`.
///
/// Sources of project rows (in order):
///  1. Local SQLite cache (`user_projects` table, sourced from
///     `SoapApiService.getProjectsUser`).
///  2. Fallback live SOAP fetch when the cache is empty.
///
/// When opened with [mandatory] = true (e.g. on app start for a
/// project-scope tenant with no active project) the back gesture is
/// blocked: the user must pick a project before continuing.
class ProjectPickerPage extends StatefulWidget {
  const ProjectPickerPage({
    super.key,
    this.mandatory = false,
  });

  final bool mandatory;

  @override
  State<ProjectPickerPage> createState() => _ProjectPickerPageState();
}

class _ProjectPickerPageState extends State<ProjectPickerPage> {
  late Future<List<UserProject>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadProjects();
  }

  Future<List<UserProject>> _loadProjects() async {
    final prefs = sl<SharedPreferencesService>();
    final db = sl<ApiDatabaseService>();
    final userCode = prefs.getUserCode() ?? '';
    if (userCode.isEmpty) return const <UserProject>[];

    var rows = await db.getUserProjects(userCode);
    if (rows.isEmpty) {
      try {
        rows = await sl<SoapApiService>().getProjectsUser(userCode: userCode);
        if (rows.isNotEmpty) {
          await db.saveUserProjects(userCode, rows);
        }
      } catch (_) {
        // Network/SOAP error — show empty state, user can retry.
      }
    }
    return rows;
  }

  Future<void> _onPick(UserProject project) async {
    final context = sl<ProjectContext>();
    await context.setActiveProject(project);
    if (!mounted) return;
    Navigator.of(this.context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = l10n?.projectPickerTitle ?? 'Select project';
    return PopScope(
      canPop: !widget.mandatory,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          automaticallyImplyLeading: !widget.mandatory,
        ),
        body: FutureBuilder<List<UserProject>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final rows = snapshot.data ?? const <UserProject>[];
            if (rows.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n?.projectListEmpty ?? 'No projects found',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _future = _loadProjects();
                          });
                        },
                        child: Text(l10n?.retry ?? 'Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView.separated(
              itemCount: rows.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final project = rows[index];
                return ListTile(
                  leading: const Icon(Icons.folder_outlined),
                  title: Text(project.name),
                  subtitle: Text(project.idUuid ?? project.id1c ?? project.code),
                  onTap: () => _onPick(project),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
