/// Lightweight project model for the pre-login public API.
///
/// Distinct from [UserProject] (agent feature) which is scoped to a
/// logged-in user and stored in SQLite after authentication.
class ApiProject {
  final String id;
  final String code1c;
  final String name;
  final String servicePath;

  const ApiProject({
    required this.id,
    required this.code1c,
    required this.name,
    required this.servicePath,
  });

  factory ApiProject.fromJson(Map<String, dynamic> json) {
    return ApiProject(
      id: json['id'] as String? ?? '',
      code1c: json['code_1c'] as String? ?? '',
      name: json['name'] as String? ?? '',
      servicePath: (json['service_url'] ?? json['service_path']) as String? ?? '',
    );
  }

  /// Whether [servicePath] is a full URL (e.g. `http://host:port/path`)
  /// rather than a bare path (`/path`).
  bool get isFullUrl =>
      servicePath.startsWith('http://') || servicePath.startsWith('https://');

  /// Extracts just the path portion from [servicePath].
  /// Returns as-is when it is already a bare path.
  String get pathOnly {
    if (!isFullUrl) return servicePath;
    final uri = Uri.tryParse(servicePath);
    return uri?.path ?? servicePath;
  }

  @override
  String toString() => 'ApiProject(id=$id, name=$name, servicePath=$servicePath)';
}
