/// Canonical task identifiers exchanged with `/api/mobile/v2/visits/`.
///
/// The mobile UI never compares localized step names (the legacy SOAP path
/// did `step.stepName.toLowerCase() == 'фото до (facing correction)'`,
/// which the v2 architecture removes). Server `visit_task_catalog` rows
/// carry the same `taskCode` string and a `name_i18n` map for display.
enum TaskCode {
  photoBefore('PHOTO_BEFORE'),
  photoAfter('PHOTO_AFTER'),
  auditOwn('AUDIT_OWN'),
  auditCompetitor('AUDIT_COMPETITOR'),
  orderCreate('ORDER_CREATE'),
  pricetagCheck('PRICETAG_CHECK'),
  signature('SIGNATURE'),
  note('NOTE'),
  kpiCheck('KPI_CHECK'),
  shelfPlanogram('SHELF_PLANOGRAM'),
  customerSurvey('CUSTOMER_SURVEY'),
  deviceInventory('DEVICE_INVENTORY');

  const TaskCode(this.code);

  /// Wire value as used in the REST envelope and `VisitTaskCatalog.task_code`.
  final String code;

  /// Resolves a wire string to a known enum entry. Unknown codes return
  /// `null` so callers can fall back to a generic renderer (server may
  /// publish new task types ahead of a mobile release — see passport §9).
  static TaskCode? fromCode(String code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return null;
  }
}
