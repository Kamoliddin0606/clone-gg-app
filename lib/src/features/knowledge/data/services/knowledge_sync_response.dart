/// Wire shape of `GET /api/mobile/v2/knowledge/sync/?since=...`.
///
/// Each resource carries `added`, `updated`, and `deleted` arrays.
/// `serverTime` becomes the next `since=` cursor — the backend supplies
/// it so client clock drift cannot create gaps in the delta stream.
class KnowledgeSyncResource<T> {
  final List<T> added;
  final List<T> updated;
  final List<String> deleted;

  const KnowledgeSyncResource({
    this.added = const [],
    this.updated = const [],
    this.deleted = const [],
  });

  static KnowledgeSyncResource<T> fromJson<T>(
    Map<String, dynamic>? json,
    T Function(Map<String, dynamic>) itemFromJson,
  ) {
    if (json == null) {
      return const KnowledgeSyncResource(
        added: [],
        updated: [],
        deleted: [],
      );
    }
    List<T> parseList(dynamic raw) {
      if (raw is! List) return const [];
      final out = <T>[];
      for (final v in raw) {
        if (v is Map<String, dynamic>) {
          out.add(itemFromJson(v));
        } else if (v is Map) {
          out.add(itemFromJson(v.cast<String, dynamic>()));
        }
      }
      return out;
    }

    List<String> parseIds(dynamic raw) {
      if (raw is! List) return const [];
      return raw
          .map((v) => v?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    }

    return KnowledgeSyncResource<T>(
      added: parseList(json['added']),
      updated: parseList(json['updated']),
      deleted: parseIds(json['deleted']),
    );
  }

  List<T> get addedAndUpdated => [...added, ...updated];
  bool get isEmpty =>
      added.isEmpty && updated.isEmpty && deleted.isEmpty;
}
