/// Who an assignment scopes the document to.
///
/// Visibility ('kim ko'radi') is filtered server-side — mobile only
/// renders metadata (mandatory badge, "for you" indicator). Forward-
/// compat fallback `unknown` mirrors the [BlockType.unknown] pattern:
/// new wire values from the backend round-trip safely instead of
/// crashing the parser.
enum AssignmentTargetType {
  all,
  role,
  user,
  staff,
  branch,
  territory,
  unknown;

  String get wireValue => switch (this) {
        AssignmentTargetType.all => 'ALL',
        AssignmentTargetType.role => 'ROLE',
        AssignmentTargetType.user => 'USER',
        AssignmentTargetType.staff => 'STAFF',
        AssignmentTargetType.branch => 'BRANCH',
        AssignmentTargetType.territory => 'TERRITORY',
        AssignmentTargetType.unknown => 'UNKNOWN',
      };
}

extension AssignmentTargetTypeX on AssignmentTargetType {
  static AssignmentTargetType fromString(String? raw) {
    if (raw == null) return AssignmentTargetType.unknown;
    return AssignmentTargetType.values.firstWhere(
      (e) => e.wireValue == raw,
      orElse: () => AssignmentTargetType.unknown,
    );
  }
}
