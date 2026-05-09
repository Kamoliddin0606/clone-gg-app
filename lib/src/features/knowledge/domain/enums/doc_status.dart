/// Publication state of a knowledge document. Mobile only renders
/// `published`; other values appear in the cache only when the backend
/// transitionally returns them via the sync feed (then dropped at
/// listing time).
enum DocStatus {
  draft,
  published,
  archived,
  unknown;

  String get wireValue => switch (this) {
        DocStatus.draft => 'DRAFT',
        DocStatus.published => 'PUBLISHED',
        DocStatus.archived => 'ARCHIVED',
        DocStatus.unknown => 'UNKNOWN',
      };
}

extension DocStatusX on DocStatus {
  static DocStatus fromString(String? raw) {
    if (raw == null) return DocStatus.unknown;
    return DocStatus.values.firstWhere(
      (e) => e.wireValue == raw,
      orElse: () => DocStatus.unknown,
    );
  }
}
