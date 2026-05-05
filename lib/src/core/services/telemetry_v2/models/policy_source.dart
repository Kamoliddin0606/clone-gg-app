/// Tracking policy manbasi — qaysi qatlamdan kelgan.
/// Server javobida `source` field sifatida keladi.
///
/// Priority tartibi: user > role > project > organization > defaultOff.
enum PolicySource {
  user,
  role,
  project,
  organization,
  defaultOff;

  static PolicySource fromString(String? value) {
    switch (value) {
      case 'user':
        return PolicySource.user;
      case 'role':
        return PolicySource.role;
      case 'project':
        return PolicySource.project;
      case 'organization':
        return PolicySource.organization;
      case 'default_off':
      default:
        return PolicySource.defaultOff;
    }
  }

  String toServerValue() {
    switch (this) {
      case PolicySource.user:
        return 'user';
      case PolicySource.role:
        return 'role';
      case PolicySource.project:
        return 'project';
      case PolicySource.organization:
        return 'organization';
      case PolicySource.defaultOff:
        return 'default_off';
    }
  }
}
