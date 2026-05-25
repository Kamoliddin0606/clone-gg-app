import 'api_project.dart';

/// Lightweight organization model for the pre-login public API.
///
/// Contains a nested list of active [ApiProject]s. Used on the login
/// page to let the user pick an organization and then a project before
/// entering credentials.
class ApiOrganization {
  final String id;
  final String code1c;
  final String name;
  final List<ApiProject> projects;

  const ApiOrganization({
    required this.id,
    required this.code1c,
    required this.name,
    required this.projects,
  });

  factory ApiOrganization.fromJson(Map<String, dynamic> json) {
    final projectsList = (json['projects'] as List<dynamic>?)
            ?.map((e) => ApiProject.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return ApiOrganization(
      id: json['id'] as String? ?? '',
      code1c: json['code_1c'] as String? ?? '',
      name: json['name'] as String? ?? '',
      projects: projectsList,
    );
  }

  @override
  String toString() =>
      'ApiOrganization(id=$id, name=$name, projects=${projects.length})';
}
