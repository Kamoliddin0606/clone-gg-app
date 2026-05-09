/// Knowledge document classification — drives icon + filter chips.
enum DocType {
  regulation,
  manual,
  training,
  policy,
  faq,
  announcement,
  other,
  unknown;

  String get wireValue => switch (this) {
        DocType.regulation => 'REGULATION',
        DocType.manual => 'MANUAL',
        DocType.training => 'TRAINING',
        DocType.policy => 'POLICY',
        DocType.faq => 'FAQ',
        DocType.announcement => 'ANNOUNCEMENT',
        DocType.other => 'OTHER',
        DocType.unknown => 'UNKNOWN',
      };
}

extension DocTypeX on DocType {
  static DocType fromString(String? raw) {
    if (raw == null) return DocType.unknown;
    return DocType.values.firstWhere(
      (e) => e.wireValue == raw,
      orElse: () => DocType.unknown,
    );
  }
}
