/// Enum representing the type of employee in the system.
/// Used to filter FAQ content based on user role.
enum EmployeeType {
  /// Sales representative (Торговый представитель / Savdo vakili)
  salesRep,

  /// Supervisor (Супервайзер / Supervayzer)
  supervisor;

  /// Returns true if this employee type is a supervisor
  bool get isSupervisor => this == EmployeeType.supervisor;

  /// Returns true if this employee type is a sales representative
  bool get isSalesRep => this == EmployeeType.salesRep;

  /// Creates an EmployeeType from a role string (from database/API)
  static EmployeeType fromRole(String? role) {
    switch (role?.toLowerCase()) {
      case 'supervisor':
        return EmployeeType.supervisor;
      case 'agent':
      default:
        return EmployeeType.salesRep;
    }
  }
}
