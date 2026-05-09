# Knowledge Base — Mobile Implementation Session (Flutter)

> Bu hujjat alohida Claude Code sessiyasi uchun mo'ljallangan to'liq ko'rsatma. Hech qanday oldingi suhbat konteksti yo'q — bu hujjatda barcha kerakli ma'lumot mavjud.

---

## 0. Sessiya maqsadi

`clone-gg-app` repo'sida yangi `lib/src/features/knowledge/` Flutter feature yaratish — Bilimlar Manbayi (Knowledge Base). Mobile ilovaning yangi bo'limi: reglamentlar, ish qo'llanmalari, training material, ilovadan foydalanish bo'yicha video va matnlar — barchasi backend'dan API orqali olib turadi va offline-first SQLite cache'da saqlaydi. Settings → Data tab'da boshqa entity'lar singari sinxronizatsiya guruhi bo'lib joylashadi.

Bu sessiya **faqat mobile** ishini bajaradi. Backend (Django) ish allaqachon tugagan deb taxmin qilinadi.

---

## 1. Old shart — Backend tayyorligini tekshirish

Bu sessiyani boshlash oldidan **tekshiring**:

```bash
# Backend dev server runs and knowledge endpoints are reachable
TOKEN=<JWT_FROM_LOGIN>
ORG=<organization_uuid>
BASE=http://192.168.0.194:8080/api/mobile/v2/knowledge

curl -s -H "Authorization: Bearer $TOKEN" -H "X-Organization-Id: $ORG" "$BASE/categories/" | jq '.[] | .slug'
# Kamida bitta kategoriya qaytishi kerak (masalan "reglament")

curl -s -H "Authorization: Bearer $TOKEN" -H "X-Organization-Id: $ORG" "$BASE/documents/" | jq '.results | length'
# > 0 bo'lishi kerak

curl -s -H "Authorization: Bearer $TOKEN" -H "X-Organization-Id: $ORG" "$BASE/sync/?since=2025-01-01T00:00:00Z" | jq 'keys'
# ["assignments", "categories", "content_blocks", "document_tags", "document_translations", "documents", "sections", "server_time", "tags"]

# Assignment'da target_staff_id field bor-yo'qligini tekshirish (STAFF target qo'llanishi):
curl -s -H "Authorization: Bearer $TOKEN" -H "X-Organization-Id: $ORG" "$BASE/sync/?since=2025-01-01T00:00:00Z" | jq '.assignments.added[0] | keys'
# "target_staff_id" ro'yxatda bo'lishi kerak (null yoki uuid)
```

Agar yuqoridagilar **ishlamasa** — to'xtang. Backend sessiyasi avval bajarilishi kerak (`SelUp_Backend/.claude/prompts/knowledge_base_session.md`).

---

## 2. Joriy holat

**Repo:** `/Users/kamoliddin/Documents/GitHub/clone-gg-app`
**Stack:** Flutter, BLoC, sqflite, Dio
**Joriy branch:** `New_version_with_backend` (yoki yangi `feature/knowledge-base` yarating)

**Backend dev URL:** `http://192.168.0.194:8080/api/mobile/v2/knowledge/` (yoki environment'dan TOKEN_BASE_URL_V2 olinadi).

---

## 3. Backend API kontrakti (qotirilgan — ishonish mumkin)

### URL prefiks
- Mobile: `/api/mobile/v2/knowledge/`

### Endpoints

| Method | Path | Maqsad |
|---|---|---|
| GET | `/categories/` | Kategoriyalar tree (assignment+published filter) |
| GET | `/documents/?category=&type=&search=&pinned=&tag=&page=&page_size=` | Listing |
| GET | `/documents/<uuid>/` | Detail — sections + blocks + media + nested translations |
| GET | `/sync/?since=<iso8601>` | Incremental — har resource uchun `{added, updated, deleted}` |
| GET | `/tags/` | Userga tegishli teglar |

### Document detail response sxemasi (yagona haqiqat manbai)

```json
{
  "id": "uuid",
  "category_id": "uuid",
  "doc_type": "REGULATION",
  "status": "PUBLISHED",
  "is_pinned": false,
  "cover_media": null,
  "translations": [
    {"language": "uz", "title": "Reglament — Supervayzer", "summary": "..."},
    {"language": "ru", "title": "...", "summary": "..."},
    {"language": "en", "title": "...", "summary": "..."}
  ],
  "tags": [{"id": "uuid", "slug": "kpi", "name": "KPI"}],
  "sections": [
    {
      "id": "uuid",
      "parent_id": null,
      "anchor": "morning-gps",
      "title_i18n": {"uz": "...", "ru": "...", "en": "..."},
      "order": 0,
      "blocks": [
        {
          "id": "uuid",
          "order": 0,
          "block_type": "PARAGRAPH",
          "data": {"markdown_i18n": {"uz": "...", "ru": "...", "en": "..."}},
          "media": null
        },
        {
          "id": "uuid",
          "order": 1,
          "block_type": "IMAGE",
          "data": {"caption_i18n": {...}, "fit": "contain"},
          "media": {
            "id": "uuid",
            "kind": "IMAGE",
            "small": "https://...", "medium": "https://...", "large": "https://...",
            "blurhash": "L9QF...",
            "width": 1200, "height": 800
          }
        },
        {
          "id": "uuid",
          "order": 2,
          "block_type": "EMBED",
          "data": {"provider": "youtube", "url": "https://youtu.be/abc123", "embed_id": "abc123"},
          "media": null
        }
      ]
    }
  ],
  "published_at": "2025-01-15T10:00:00Z",
  "expires_at": null,
  "updated_at": "2025-01-15T10:00:00Z"
}
```

### Sync incremental endpoint sxemasi

```
GET /api/mobile/v2/knowledge/sync/?since=2025-01-15T08:00:00Z

Response:
{
  "categories":            {"added": [...], "updated": [...], "deleted": ["uuid", ...]},
  "documents":             {...},
  "document_translations": {...},
  "sections":              {...},
  "content_blocks":        {...},
  "assignments":           {"added": [
                              {
                                "id": "uuid",
                                "document_id": "uuid",
                                "target_type": "STAFF",
                                "target_role_id": null,
                                "target_user_id": null,
                                "target_staff_id": "uuid",
                                "target_branch_id": null,
                                "target_territory_id": null,
                                "mandatory": true,
                                "due_at": null
                              }
                           ], "updated": [...], "deleted": ["uuid", ...]},
  "tags":                  {...},
  "document_tags":         {...},
  "server_time": "2025-01-15T10:00:00Z"
}
```

`server_time` — keyingi `since=` sifatida ishlatiladi (clock drift'dan himoya).

### Assignment target_type ro'yxati

`ALL`, `ROLE`, `USER`, `STAFF`, `BRANCH`, `TERRITORY`.

> **Eslatma:** Visibility (kim ko'radi) **server tomonida** filterlanadi —
> mobile faqat foydalanuvchiga ko'rinadigan hujjatlar haqida ma'lumot oladi.
> Mobile target_type'ga qarab UI metadata ko'rsatishi mumkin (mandatory
> badge, "siz uchun maxsus" indikatori), lekin **offline visibility logikasi
> qurish shart emas**.
>
> **Forward-compat:** noma'lum target_type qiymatini `unknown` deb tugating
> (`BlockType.unknown` patterni bilan bir xil) — backend yangi qiymat
> qo'shsa, mobile crash bo'lmasin.

### Block tiplari ro'yxati

`PARAGRAPH, HEADING, LIST, QUOTE, CALLOUT, IMAGE, EMBED, CODE, TABLE, DIVIDER, FILE`.

**Yangi tip kelishi mumkin** → mobile `BlockType.unknown` fallback bilan ishlasin (forward-compat).

### Authentication
- Header: `Authorization: Bearer <rest_v2_access_token>`
- Token mavjud `lib/src/core/services/token_service.dart` orqali boshqariladi (V2 JWT, 60-min TTL, auto-refresh)
- Multi-tenant: `X-Organization-Id: <uuid>` har so'rovda

---

## 4. Mavjud arxitektura — REUSE qiling

### Sync engine (zarur)

| Fayl | Roli | KB'da qanday ishlatamiz |
|---|---|---|
| [lib/src/core/services/data_sync_service.dart](lib/src/core/services/data_sync_service.dart) | Sync engine (333 KB) | Yangi `syncKnowledge*` metodlar qo'shamiz |
| [lib/src/core/services/data_sync_config.dart](lib/src/core/services/data_sync_config.dart) | `_groups`, `_tables` registry (855 lines) | Yangi `knowledge` guruh + 7 ta `DataSyncTable` qo'shamiz |
| [lib/src/core/services/data_sync_orchestrator.dart](lib/src/core/services/data_sync_orchestrator.dart) | Dependency/cascade resolver | **HECH O'ZGARMAYDI** — config-driven |
| [lib/src/core/services/api_database_service.dart](lib/src/core/services/api_database_service.dart) | SQLite cache (`gloria_api_cache.db`) | Version 36 → 37, faqat CREATE TABLE |
| [lib/src/features/agent/presentation/pages/settings/data_sync_tab.dart](lib/src/features/agent/presentation/pages/settings/data_sync_tab.dart) | Settings → Data tab UI | **HECH O'ZGARMAYDI** — yangi guruh avtomatik ko'rinadi |

### Token va auth
- [lib/src/core/services/token_service.dart](lib/src/core/services/token_service.dart) — V2 JWT auto-refresh, `getRestV2AccessToken()`, `getOrganizationId()`. `KnowledgeApiService` shuni reuse qiladi.

### Image arxitekturasi (pattern)
- [lib/src/core/services/images/](lib/src/core/services/images/) — UnifiedImage, NewBackendImageRepository, ImageTargetType
- [lib/src/core/widgets/product_image_widget.dart](lib/src/core/widgets/product_image_widget.dart) — patternni nusxa qilamiz `KnowledgeImageWidget` uchun (size enum, BlurHash placeholder, shimmer loading, X-Organization-Id header)

### Mavjud paketlar (reuse)
`cached_network_image`, `flutter_blurhash`, `photo_view`, `shimmer`, `open_file`, `flutter_bloc`, `dio`, `sqflite`, `connectivity_plus`, `workmanager`, `flutter_staggered_grid_view`.

---

## 5. Eski FAQ feature'i (deprecation)

Hozirgi [lib/src/features/faq/](lib/src/features/faq/) ostida statik "Reglament" feature mavjud — barcha kontent `lib/l10n/app_*.arb` da hardcoded `faq*` keylar. Faqat 2 rol uchun 6 tadan bo'lim.

**Bu sessiyaning OXIRIDA (16-qadam):**
- Backend seed command (`seed_knowledge_from_faq`) eski FAQ kontentini KnowledgeDocument'ga ko'chirgan deb taxmin qilamiz
- `lib/src/features/faq/` folderi to'liq o'chiriladi
- `lib/l10n/app_*.arb` dan `faq*` boshlanadigan barcha keylar olib tashlanadi (3 ta faylda)
- `flutter gen-l10n` qayta ishga tushiriladi
- [lib/src/core/router/app_router.dart](lib/src/core/router/app_router.dart) da `faqRoute` constanta saqlanadi (deep link backward-compat), redirect KnowledgeHomePage'ga
- [lib/src/features/agent/presentation/pages/agent_home_modern.dart:2142-2143](lib/src/features/agent/presentation/pages/agent_home_modern.dart#L2142-L2143) menyu yangilanadi

---

## 6. Skop chegaralari

### Bu sessiyada YOZILADI
- Yangi `lib/src/features/knowledge/` feature folder
- Modellar, API service, sync service, DAO, repository
- SQLite v37 migration
- `data_sync_config.dart` ga yangi `knowledge` guruh va 7 ta jadval
- 4 ta sahifa (home, category, document, search)
- ContentBlockRenderer + 11 ta block widget
- KnowledgeImageWidget (ProductImageWidget patterni)
- Routing va menyu yangilanishi
- L10n keylar
- Eski FAQ folder'i o'chirilishi
- Testlar

### Bu sessiyada YOZILMAYDI (Faza 5+)
- Acknowledgement ("I read" tugmasi)
- Versioning (KnowledgeDocumentVersion)
- Progress tracking (qaysi sectiongacha o'qigan)
- Lokal MP4 video player (faqat YouTube/Vimeo embed)
- Push notification yangi hujjat haqida
- Full-text search (server orqali — endpoint ishlaydi, lekin alohida UI yo'q; oddiy `?search=` filterga tayanamiz)

---

## 7. Folder strukturasi (yaratiladigan)

```
lib/src/features/knowledge/
├── data/
│   ├── models/
│   │   ├── knowledge_category.dart
│   │   ├── knowledge_document.dart                   # + KnowledgeDocumentTranslation embedded
│   │   ├── knowledge_document_summary.dart           # listing uchun yengil
│   │   ├── knowledge_section.dart                    # title_i18n: Map<String, String>
│   │   ├── knowledge_content_block.dart              # sealed class hierarchy
│   │   ├── knowledge_media.dart
│   │   ├── knowledge_assignment.dart
│   │   └── knowledge_tag.dart
│   ├── services/
│   │   ├── knowledge_api_service.dart                # Dio + V2 token + X-Organization-Id
│   │   ├── knowledge_sync_service.dart               # incremental sync → SQLite (since= cursor)
│   │   └── knowledge_db_dao.dart                     # SQLite CRUD per table
│   └── repositories/
│       └── knowledge_repository.dart                 # offline-first facade
├── domain/
│   ├── enums/
│   │   ├── doc_type.dart
│   │   ├── doc_status.dart
│   │   ├── block_type.dart                           # + unknown for forward-compat
│   │   └── assignment_target_type.dart               # ALL | ROLE | USER | STAFF | BRANCH | TERRITORY + unknown
│   └── usecases/
│       ├── get_categories_for_user.dart
│       └── get_document_detail.dart
└── presentation/
    ├── bloc/
    │   ├── knowledge_home_cubit.dart
    │   ├── knowledge_category_cubit.dart
    │   ├── knowledge_document_cubit.dart
    │   └── knowledge_search_cubit.dart
    ├── pages/
    │   ├── knowledge_home_page.dart                  # SliverAppBar gradient, pinned carousel, kategoriya grid
    │   ├── knowledge_category_page.dart
    │   ├── knowledge_document_page.dart              # ListView ContentBlockRenderer + TOC drawer
    │   └── knowledge_search_page.dart
    └── widgets/
        ├── content_block_renderer.dart               # switch by block_type → kerakli widget
        ├── blocks/
        │   ├── paragraph_block_widget.dart           # flutter_markdown inline
        │   ├── heading_block_widget.dart
        │   ├── list_block_widget.dart
        │   ├── quote_block_widget.dart
        │   ├── callout_block_widget.dart
        │   ├── image_block_widget.dart               # cached_network_image + photo_view + Hero
        │   ├── embed_block_widget.dart               # provider switch: youtube_player_flutter / webview
        │   ├── code_block_widget.dart
        │   ├── table_block_widget.dart
        │   ├── divider_block_widget.dart
        │   └── file_block_widget.dart                # open_file
        ├── document_toc_drawer.dart                  # mundarija sidebar, anchor jump, active highlight
        ├── knowledge_category_card.dart
        ├── knowledge_document_card.dart
        └── knowledge_image_widget.dart               # ProductImageWidget patterni
```

---

## 8. Yangi paketlar (`pubspec.yaml`'ga qo'shing)

```yaml
dependencies:
  flutter_markdown: ^0.7.4         # PARAGRAPH bloki ichida inline markdown
  youtube_player_flutter: ^9.0.0   # EmbedBlockWidget provider=youtube
  webview_flutter: ^4.7.0          # EmbedBlockWidget provider=vimeo
  visibility_detector: ^0.4.0      # TOC active section highlight
```

`flutter pub get` chaqiring.

---

## 9. SQLite migration — `api_database_service.dart`

Joriy version: **36**. Yangisi: **37**.

`_onUpgrade` metoda ichida `if (oldVersion < 37)` bloki qo'shing. **Faqat CREATE TABLE**, eski jadvallar tegmaydi (production cache buzilmasin).

```sql
CREATE TABLE knowledge_categories (
  id TEXT PRIMARY KEY,
  organization_id TEXT NOT NULL,
  parent_id TEXT,
  slug TEXT NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  icon TEXT,
  color TEXT,
  cover_media_id TEXT,
  order_idx INTEGER DEFAULT 0,
  is_active INTEGER DEFAULT 1,
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER
);
CREATE INDEX idx_kn_cat_org_parent ON knowledge_categories(organization_id, parent_id, order_idx);

CREATE TABLE knowledge_documents (
  id TEXT PRIMARY KEY,
  organization_id TEXT NOT NULL,
  category_id TEXT NOT NULL,
  slug TEXT,
  doc_type TEXT,
  status TEXT,
  is_pinned INTEGER DEFAULT 0,
  cover_media_id TEXT,
  published_at INTEGER,
  expires_at INTEGER,
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER
);
CREATE INDEX idx_kn_doc_org_cat ON knowledge_documents(organization_id, category_id, status, published_at DESC);
CREATE INDEX idx_kn_doc_pinned ON knowledge_documents(organization_id, is_pinned, published_at DESC);

CREATE TABLE knowledge_document_translations (
  document_id TEXT NOT NULL,
  language TEXT NOT NULL,
  title TEXT,
  summary TEXT,
  PRIMARY KEY(document_id, language)
);

CREATE TABLE knowledge_sections (
  id TEXT PRIMARY KEY,
  organization_id TEXT NOT NULL,
  document_id TEXT NOT NULL,
  parent_id TEXT,
  anchor TEXT,
  title_i18n_json TEXT,
  order_idx INTEGER,
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER
);
CREATE INDEX idx_kn_sec_doc ON knowledge_sections(document_id, parent_id, order_idx);

CREATE TABLE knowledge_content_blocks (
  id TEXT PRIMARY KEY,
  organization_id TEXT NOT NULL,
  section_id TEXT NOT NULL,
  order_idx INTEGER,
  block_type TEXT,
  data_json TEXT,
  media_id TEXT,
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER
);
CREATE INDEX idx_kn_block_sec ON knowledge_content_blocks(section_id, order_idx);

CREATE TABLE knowledge_media (
  id TEXT PRIMARY KEY,
  organization_id TEXT NOT NULL,
  kind TEXT,
  mime_type TEXT,
  size_bytes INTEGER,
  small_url TEXT,
  medium_url TEXT,
  large_url TEXT,
  blurhash TEXT,
  width INTEGER,
  height INTEGER,
  storage_key TEXT,
  updated_at INTEGER NOT NULL
);

CREATE TABLE knowledge_assignments (
  id TEXT PRIMARY KEY,
  organization_id TEXT NOT NULL,
  document_id TEXT NOT NULL,
  target_type TEXT,                -- ALL | ROLE | USER | STAFF | BRANCH | TERRITORY
  target_role_id TEXT,
  target_user_id TEXT,
  target_staff_id TEXT,            -- Staff record (asosiy biriktirish nuqtasi)
  target_branch_id TEXT,
  target_territory_id TEXT,
  mandatory INTEGER,
  due_at INTEGER,
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER
);
CREATE INDEX idx_kn_asg_doc ON knowledge_assignments(document_id);
CREATE INDEX idx_kn_asg_staff ON knowledge_assignments(target_staff_id);

CREATE TABLE knowledge_tags (
  id TEXT PRIMARY KEY,
  organization_id TEXT NOT NULL,
  slug TEXT,
  name TEXT,
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER
);

CREATE TABLE knowledge_document_tags (
  document_id TEXT NOT NULL,
  tag_id TEXT NOT NULL,
  PRIMARY KEY(document_id, tag_id)
);

CREATE TABLE knowledge_sync_state (
  resource_name TEXT PRIMARY KEY,
  last_synced_at INTEGER
);
```

---

## 10. Modellar — JSON serialization

### `KnowledgeContentBlock` — sealed class hierarchy (forward-compat)

```dart
sealed class KnowledgeContentBlock {
  final String id;
  final int order;
  final BlockType blockType;
  final Map<String, dynamic> data;
  final KnowledgeMedia? media;

  KnowledgeContentBlock({required this.id, required this.order,
                        required this.blockType, required this.data, this.media});

  factory KnowledgeContentBlock.fromJson(Map<String, dynamic> json) {
    final type = BlockTypeX.fromString(json['block_type'] as String);
    return KnowledgeContentBlock._dispatch(type, json);
  }

  static KnowledgeContentBlock _dispatch(BlockType t, Map<String, dynamic> j) {
    return switch (t) {
      BlockType.paragraph => ParagraphBlock.fromJson(j),
      BlockType.heading   => HeadingBlock.fromJson(j),
      BlockType.list      => ListBlock.fromJson(j),
      BlockType.quote     => QuoteBlock.fromJson(j),
      BlockType.callout   => CalloutBlock.fromJson(j),
      BlockType.image     => ImageBlock.fromJson(j),
      BlockType.embed     => EmbedBlock.fromJson(j),
      BlockType.code      => CodeBlock.fromJson(j),
      BlockType.table     => TableBlock.fromJson(j),
      BlockType.divider   => DividerBlock.fromJson(j),
      BlockType.file      => FileBlock.fromJson(j),
      BlockType.unknown   => UnknownBlock.fromJson(j),
    };
  }

  Map<String, dynamic> toJson();

  // Convenience accessors
  String? markdownFor(String lang) => (data['markdown_i18n'] as Map?)?[lang] as String?;
  String? captionFor(String lang) => (data['caption_i18n'] as Map?)?[lang] as String?;
}

class ParagraphBlock extends KnowledgeContentBlock { ... }
class ImageBlock extends KnowledgeContentBlock { ... }
class EmbedBlock extends KnowledgeContentBlock {
  String get provider => data['provider'] as String;
  String get embedId => data['embed_id'] as String;
}
// va h.k.

class UnknownBlock extends KnowledgeContentBlock {
  // Forward-compat: backend yangi block_type qo'shganda crash etmasin
}
```

### `BlockType` enum — `domain/enums/block_type.dart`

```dart
enum BlockType {
  paragraph, heading, list, quote, callout,
  image, embed, code, table, divider, file,
  unknown;

  String get wireValue => switch (this) {
    BlockType.paragraph => 'PARAGRAPH',
    // ... har biri
    BlockType.unknown   => 'UNKNOWN',
  };
}

extension BlockTypeX on BlockType {
  static BlockType fromString(String s) {
    return BlockType.values.firstWhere(
      (e) => e.wireValue == s,
      orElse: () => BlockType.unknown,
    );
  }
}
```

`DocType` va `DocStatus` shu pattern bilan.

### `AssignmentTargetType` enum — `domain/enums/assignment_target_type.dart`

```dart
enum AssignmentTargetType {
  all, role, user, staff, branch, territory,
  unknown;

  String get wireValue => switch (this) {
    AssignmentTargetType.all       => 'ALL',
    AssignmentTargetType.role      => 'ROLE',
    AssignmentTargetType.user      => 'USER',
    AssignmentTargetType.staff     => 'STAFF',
    AssignmentTargetType.branch    => 'BRANCH',
    AssignmentTargetType.territory => 'TERRITORY',
    AssignmentTargetType.unknown   => 'UNKNOWN',
  };
}

extension AssignmentTargetTypeX on AssignmentTargetType {
  static AssignmentTargetType fromString(String? s) {
    if (s == null) return AssignmentTargetType.unknown;
    return AssignmentTargetType.values.firstWhere(
      (e) => e.wireValue == s,
      orElse: () => AssignmentTargetType.unknown,
    );
  }
}
```

### `KnowledgeAssignment` modeli

```dart
class KnowledgeAssignment {
  final String id;
  final String organizationId;
  final String documentId;
  final AssignmentTargetType targetType;
  final String? targetRoleId;
  final String? targetUserId;
  final String? targetStaffId;       // ← Staff record (asosiy biriktirish nuqtasi)
  final String? targetBranchId;
  final String? targetTerritoryId;
  final bool mandatory;
  final DateTime? dueAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  factory KnowledgeAssignment.fromJson(Map<String, dynamic> json) =>
      KnowledgeAssignment(
        id: json['id'] as String,
        organizationId: json['organization_id'] as String,
        documentId: json['document_id'] as String,
        targetType: AssignmentTargetTypeX.fromString(json['target_type'] as String?),
        targetRoleId: json['target_role_id'] as String?,
        targetUserId: json['target_user_id'] as String?,
        targetStaffId: json['target_staff_id'] as String?,
        targetBranchId: json['target_branch_id'] as String?,
        targetTerritoryId: json['target_territory_id'] as String?,
        mandatory: (json['mandatory'] as bool?) ?? false,
        dueAt: _parseIso(json['due_at']),
        updatedAt: _parseIso(json['updated_at'])!,
        deletedAt: _parseIso(json['deleted_at']),
      );

  Map<String, Object?> toDbMap() => {
        'id': id,
        'organization_id': organizationId,
        'document_id': documentId,
        'target_type': targetType.wireValue,
        'target_role_id': targetRoleId,
        'target_user_id': targetUserId,
        'target_staff_id': targetStaffId,
        'target_branch_id': targetBranchId,
        'target_territory_id': targetTerritoryId,
        'mandatory': mandatory ? 1 : 0,
        'due_at': dueAt?.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
        'deleted_at': deletedAt?.millisecondsSinceEpoch,
      };
}
```

### Boshqa modellar
Standart `fromJson/toJson` + `copyWith`. SQLite uchun `toDbMap/fromDbMap` (JSON fieldlar `jsonEncode`/`jsonDecode` orqali serialize qilinadi).

---

## 11. KnowledgeApiService — Dio client

```dart
class KnowledgeApiService {
  final Dio _dio;
  final TokenService _tokenService;

  KnowledgeApiService(this._tokenService) : _dio = Dio(BaseOptions(
    baseUrl: '${EnvConfig.v2BaseUrl}/api/mobile/v2/knowledge',
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
  )) {
    _dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) async {
      final token = await _tokenService.getRestV2AccessToken();
      final orgId = await _tokenService.getOrganizationId();
      options.headers['Authorization'] = 'Bearer $token';
      options.headers['X-Organization-Id'] = orgId;
      handler.next(options);
    }));
  }

  Future<List<KnowledgeCategory>> getCategories() async {
    final r = await _dio.get('/categories/');
    return (r.data as List).map((j) => KnowledgeCategory.fromJson(j)).toList();
  }

  Future<PaginatedResponse<KnowledgeDocumentSummary>> getDocuments({
    String? category, String? type, String? search,
    bool? pinned, String? tag, int page = 1, int pageSize = 20,
  }) async { ... }

  Future<KnowledgeDocument> getDocumentDetail(String id) async {
    final r = await _dio.get('/documents/$id/');
    return KnowledgeDocument.fromJson(r.data);
  }

  Future<KnowledgeSyncResponse> sync({DateTime? since}) async {
    final r = await _dio.get('/sync/', queryParameters: {
      if (since != null) 'since': since.toUtc().toIso8601String(),
    });
    return KnowledgeSyncResponse.fromJson(r.data);
  }

  Future<List<KnowledgeTag>> getTags() async { ... }
}
```

---

## 12. KnowledgeDbDao — SQLite CRUD

Har resource uchun upsert/get/delete metodlari. Misol:

```dart
class KnowledgeDbDao {
  final ApiDatabaseService _db;
  KnowledgeDbDao(this._db);

  Future<void> upsertCategories(List<KnowledgeCategory> categories) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      for (final c in categories) {
        await txn.insert('knowledge_categories', c.toDbMap(),
                         conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<List<KnowledgeCategory>> getCategoryTree(String organizationId) async {
    final db = await _db.database;
    final rows = await db.query('knowledge_categories',
      where: 'organization_id = ? AND deleted_at IS NULL AND is_active = 1',
      whereArgs: [organizationId],
      orderBy: 'parent_id, order_idx');
    return rows.map(KnowledgeCategory.fromDbMap).toList();
  }

  Future<KnowledgeDocument?> getDocumentWithDetail(String id) async {
    // 1. Document row
    // 2. Translations
    // 3. Sections (sorted, with parent_id grouping)
    // 4. ContentBlocks per section (sorted)
    // 5. Media per block (left join via media_id)
    // 6. Build object tree
  }

  Future<void> upsertDocumentDetail(KnowledgeDocument doc) async {
    // Atomic — document + translations + sections + blocks + media
  }

  Future<void> deleteByIds(String table, List<String> ids) async { ... }

  Future<DateTime?> getLastSyncedAt(String resource) async {
    final rows = await _db.database.then((d) => d.query(
      'knowledge_sync_state', where: 'resource_name = ?', whereArgs: [resource]));
    if (rows.isEmpty) return null;
    return DateTime.fromMillisecondsSinceEpoch(rows.first['last_synced_at'] as int);
  }

  Future<void> setLastSyncedAt(String resource, DateTime ts) async { ... }
}
```

---

## 13. KnowledgeSyncService — incremental sync

```dart
class KnowledgeSyncService {
  final KnowledgeApiService _api;
  final KnowledgeDbDao _dao;

  Future<void> syncIncremental() async {
    final since = await _dao.getLastSyncedAt('knowledge');
    final response = await _api.sync(since: since);

    await _dao.upsertCategories(response.categories.added + response.categories.updated);
    await _dao.deleteByIds('knowledge_categories', response.categories.deleted);

    await _dao.upsertDocuments(response.documents.added + response.documents.updated);
    await _dao.deleteByIds('knowledge_documents', response.documents.deleted);

    // ... har resource uchun

    await _dao.setLastSyncedAt('knowledge', response.serverTime);
  }

  // Per-resource sync (orchestrator individual table sync uchun)
  Future<void> syncCategories({bool forceRefresh = false}) async { ... }
  Future<void> syncDocuments({bool forceRefresh = false}) async { ... }
  Future<void> syncDocumentTranslations({bool forceRefresh = false}) async { ... }
  Future<void> syncSections({bool forceRefresh = false}) async { ... }
  Future<void> syncContentBlocks({bool forceRefresh = false}) async { ... }
  Future<void> syncAssignments({bool forceRefresh = false}) async { ... }
  Future<void> syncTags({bool forceRefresh = false}) async { ... }

  // Detail — on-demand
  Future<KnowledgeDocument> fetchDocumentDetail(String id) async {
    final fresh = await _api.getDocumentDetail(id);
    await _dao.upsertDocumentDetail(fresh);
    return fresh;
  }
}
```

**Per-resource metodlar:** `forceRefresh=true` bo'lganda backend'dan to'liq yangilab oladi. `forceRefresh=false` da agar `last_synced_at` 30 daqiqadan kam bo'lsa, no-op.

---

## 14. KnowledgeRepository — offline-first facade

```dart
class KnowledgeRepository {
  final KnowledgeSyncService _sync;
  final KnowledgeDbDao _dao;

  Future<List<KnowledgeCategory>> getCategories() async {
    try {
      await _sync.syncCategories();
    } catch (_) {} // ignore — offline fallback
    return await _dao.getCategoryTree(_currentOrgId);
  }

  Future<List<KnowledgeDocumentSummary>> getDocuments({
    String? categoryId, DocType? type, String? search,
  }) async {
    try {
      await _sync.syncDocuments();
    } catch (_) {}
    return await _dao.getDocuments(categoryId: categoryId, type: type, search: search);
  }

  Future<KnowledgeDocument> getDocumentDetail(String id) async {
    final cached = await _dao.getDocumentWithDetail(id);
    if (cached != null) {
      // Background refresh — fire-and-forget
      _sync.fetchDocumentDetail(id).catchError((_) => cached);
      return cached;
    }
    final fresh = await _sync.fetchDocumentDetail(id);
    return fresh;
  }
}
```

---

## 15. Sync integration — `data_sync_config.dart`

`_initializeGroups()` ichida yangi guruh:

```dart
_groups['knowledge'] = const DataSyncGroup(
  id: 'knowledge',
  nameEn: 'Knowledge Base', nameRu: 'База знаний', nameUz: 'Bilimlar manbayi',
  icon: Icons.menu_book,
  tableIds: [
    'knowledge_categories',
    'knowledge_documents',
    'knowledge_document_translations',
    'knowledge_sections',
    'knowledge_content_blocks',
    'knowledge_assignments',
    'knowledge_tags',
  ],
  color: Colors.deepPurple,
);
```

`_initializeTables()` ichida 7 ta yangi `DataSyncTable`:

```dart
_tables['knowledge_categories'] = DataSyncTable(
  id: 'knowledge_categories',
  tableName: 'knowledge_categories',
  nameEn: 'Knowledge Categories', nameRu: 'Категории знаний', nameUz: 'Bilim kategoriyalari',
  icon: Icons.category_outlined,
  dependsOn: const [],
  cascadeTo: const ['knowledge_documents'],
  groupId: 'knowledge',
  syncFunction: () => syncService.syncKnowledgeCategories(forceRefresh: true),
);

_tables['knowledge_documents'] = DataSyncTable(
  id: 'knowledge_documents',
  tableName: 'knowledge_documents',
  nameEn: 'Knowledge Documents', nameRu: 'Документы', nameUz: 'Hujjatlar',
  icon: Icons.article_outlined,
  dependsOn: const ['knowledge_categories'],
  cascadeTo: const [
    'knowledge_document_translations', 'knowledge_sections',
    'knowledge_assignments',
  ],
  groupId: 'knowledge',
  syncFunction: () => syncService.syncKnowledgeDocuments(forceRefresh: true),
);

// va h.k. har 7 ta jadval uchun
```

`knowledge_media` jadvali bor, lekin **DataSyncTable yo'q** — on-demand `cached_network_image` keshlash, image URL'lar block detail'da inline keladi.

`DataSyncTab` UI hech qanday o'zgartirish talab qilmaydi — yangi guruh avtomatik `GroupSyncCard` orqali ko'rinadi (config-driven).

---

## 16. Sync metodlar — `data_sync_service.dart`

```dart
// Bitta katta sync (homepage refresh, manual sync all)
Future<void> syncKnowledge({bool forceRefresh = false}) async {
  await _knowledgeSyncService.syncIncremental();
}

// Per-resource (orchestrator tables uchun)
Future<void> syncKnowledgeCategories({bool forceRefresh = false}) async {
  return _knowledgeSyncService.syncCategories(forceRefresh: forceRefresh);
}
Future<void> syncKnowledgeDocuments({bool forceRefresh = false}) async { ... }
Future<void> syncKnowledgeDocumentTranslations({bool forceRefresh = false}) async { ... }
Future<void> syncKnowledgeSections({bool forceRefresh = false}) async { ... }
Future<void> syncKnowledgeContentBlocks({bool forceRefresh = false}) async { ... }
Future<void> syncKnowledgeAssignments({bool forceRefresh = false}) async { ... }
Future<void> syncKnowledgeTags({bool forceRefresh = false}) async { ... }

// Detail — on-demand
Future<KnowledgeDocument> fetchKnowledgeDocumentDetail(String id) async {
  return _knowledgeSyncService.fetchDocumentDetail(id);
}
```

`KnowledgeSyncService` `service_locator.dart` orqali singleton sifatida ro'yxatdan o'tkaziladi.

---

## 17. ContentBlockRenderer — block-based rendering

Strukturali rendering — markdown emas (asosan).

```dart
class ContentBlockRenderer extends StatelessWidget {
  final KnowledgeContentBlock block;
  final String currentLanguage;          // 'uz', 'ru', 'en'

  const ContentBlockRenderer({super.key, required this.block, required this.currentLanguage});

  @override
  Widget build(BuildContext context) {
    return switch (block.blockType) {
      BlockType.paragraph => ParagraphBlockWidget(block as ParagraphBlock, currentLanguage),
      BlockType.heading   => HeadingBlockWidget(block as HeadingBlock, currentLanguage),
      BlockType.list      => ListBlockWidget(block as ListBlock, currentLanguage),
      BlockType.quote     => QuoteBlockWidget(block as QuoteBlock, currentLanguage),
      BlockType.callout   => CalloutBlockWidget(block as CalloutBlock, currentLanguage),
      BlockType.image     => ImageBlockWidget(block as ImageBlock, currentLanguage),
      BlockType.embed     => EmbedBlockWidget(block as EmbedBlock, currentLanguage),
      BlockType.code      => CodeBlockWidget(block as CodeBlock),
      BlockType.table     => TableBlockWidget(block as TableBlock, currentLanguage),
      BlockType.divider   => const Divider(height: 24),
      BlockType.file      => FileBlockWidget(block as FileBlock, currentLanguage),
      BlockType.unknown   => const SizedBox.shrink(),  // forward-compat
    };
  }
}
```

### Asosiy bloklar uchun spetsifikatsiya

**ParagraphBlockWidget:**
```dart
final markdown = block.markdownFor(currentLanguage) ?? '';
return Padding(
  padding: const EdgeInsets.symmetric(vertical: 8),
  child: MarkdownBody(data: markdown, selectable: true,
                      onTapLink: (_, href, __) => _openUrl(href)),
);
```

**HeadingBlockWidget:** TextStyle level=1..4 mapping (h1=24, h2=20, h3=18, h4=16). FontWeight.w600.

**ImageBlockWidget:**
```dart
final media = block.media!;
final url = media.medium ?? media.small ?? media.large;
final caption = block.captionFor(currentLanguage);
return Column(
  children: [
    Hero(
      tag: 'kn-img-${block.id}',
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => PhotoView(imageProvider: NetworkImage(media.large ?? url!)))),
        child: AspectRatio(
          aspectRatio: media.width != null && media.height != null
              ? media.width! / media.height! : 16/9,
          child: CachedNetworkImage(
            imageUrl: url!,
            placeholder: (_, __) => media.blurhash != null
                ? BlurHash(hash: media.blurhash!)
                : Container(color: Colors.grey.shade300),
            errorWidget: (_, __, ___) => const Icon(Icons.image_not_supported),
            fit: BoxFit.contain,
          ),
        ),
      ),
    ),
    if (caption != null && caption.isNotEmpty)
      Padding(padding: const EdgeInsets.only(top: 4),
              child: Text(caption, style: Theme.of(context).textTheme.bodySmall)),
  ],
);
```

**EmbedBlockWidget:**
```dart
final provider = block.provider;
final embedId = block.embedId;
return AspectRatio(
  aspectRatio: 16/9,
  child: provider == 'youtube'
    ? YoutubePlayer(
        controller: YoutubePlayerController(
          initialVideoId: embedId,
          flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
        ),
        showVideoProgressIndicator: true,
      )
    : provider == 'vimeo'
        ? WebViewWidget(
            controller: WebViewController()
              ..setJavaScriptMode(JavaScriptMode.unrestricted)
              ..loadRequest(Uri.parse('https://player.vimeo.com/video/$embedId')))
        : const Center(child: Text('Unsupported provider')),
);
```

YouTube controller — `dispose()` chaqirilsin (StatefulWidget pattern).

**ListBlockWidget:** `data['style']` ga qarab — bullet/ordered/check. Items: `data['items_i18n'][lang]`.

**TableBlockWidget:** Native `Table` widget. `data['headers_i18n'][lang]` + `rows_i18n[lang]`.

**CalloutBlockWidget:** Container with variant color (info=blue, warn=orange, danger=red, success=green) + Icon + text.

**FileBlockWidget:** Tile with file icon, caption, tap → `open_file` paketi orqali tashqi viewer.

---

## 18. Pages

### `KnowledgeHomePage`
- SliverAppBar gradient (FaqPage patterndek)
- Pinned hujjatlar carousel (yuqorida) — agar bor bo'lsa
- Kategoriya gridi (`flutter_staggered_grid_view`) — har biri `KnowledgeCategoryCard`
- Pull-to-refresh → `repository.getCategories()` + sync
- Optional `initialCategorySlug` param — backward-compat /faq route uchun

### `KnowledgeCategoryPage`
- AppBar — kategoriya nomi
- ListView of `KnowledgeDocumentCard` (cover image, title, summary, doc_type badge, tags)
- Filter chips (doc_type)
- Search bar yuqorida → `KnowledgeSearchPage`
- Pull-to-refresh

### `KnowledgeDocumentPage`
- SliverAppBar — cover_image, title (joriy tilda), Drawer toggle (TOC)
- `Drawer` (left) — `DocumentTocDrawer`: section tree + anchor jump (`Scrollable.ensureVisible`)
- Body — `ListView`:
  - Doc summary (joriy tilda)
  - Sections (parent → children rekursiv) — har section title (`Theme.headlineMedium`) + blocks (ContentBlockRenderer)
- Joriy til — `Localizations.localeOf(context).languageCode` (`'uz'`, `'ru'`, `'en'`)
- Visibility detector `_onSectionVisible` — TOC active section highlight
- Loading state — `Shimmer.fromColors`

### `KnowledgeSearchPage`
- TextField
- Debounce 300ms
- `repository.getDocuments(search: query)`
- Results: `KnowledgeDocumentCard` list

---

## 19. Cubit pattern

```dart
class KnowledgeDocumentCubit extends Cubit<KnowledgeDocumentState> {
  final KnowledgeRepository _repository;
  final String documentId;

  KnowledgeDocumentCubit({required KnowledgeRepository repository, required this.documentId})
    : _repository = repository,
      super(KnowledgeDocumentState.initial()) {
    _load();
  }

  Future<void> _load() async {
    emit(state.toLoading());
    try {
      final doc = await _repository.getDocumentDetail(documentId);
      emit(state.toSuccess(doc));
    } catch (e) {
      emit(state.toError(e.toString()));
    }
  }

  Future<void> refresh() async => _load();
}
```

---

## 20. Routing — `app_router.dart`

```dart
static const String knowledgeRoute = '/knowledge';
static const String knowledgeCategoryRoute = '/knowledge/category';
static const String knowledgeDocumentRoute = '/knowledge/document';
static const String knowledgeSearchRoute = '/knowledge/search';

// generateRoute switch ichiga qo'shing:
case knowledgeRoute:
  return MaterialPageRoute(builder: (_) => const KnowledgeHomePage());
case knowledgeCategoryRoute:
  final args = settings.arguments as Map<String, dynamic>;
  return MaterialPageRoute(builder: (_) => KnowledgeCategoryPage(categoryId: args['id']));
case knowledgeDocumentRoute:
  final args = settings.arguments as Map<String, dynamic>;
  return MaterialPageRoute(builder: (_) => KnowledgeDocumentPage(documentId: args['id']));
case knowledgeSearchRoute:
  return MaterialPageRoute(builder: (_) => const KnowledgeSearchPage());

// Backward compat — eski /faq link Knowledge'ga redirect:
case faqRoute:
  return MaterialPageRoute(builder: (_) =>
    const KnowledgeHomePage(initialCategorySlug: 'reglament'));
```

---

## 21. Menyu o'zgartirish — `agent_home_modern.dart`

[Line ~2142-2143](lib/src/features/agent/presentation/pages/agent_home_modern.dart#L2142):

```dart
// Hozirgi:
_MenuItem(
  icon: Icons.help_outline,
  title: AppLocalizations.of(context)!.faqPageTitle,
  onTap: () => Navigator.pushNamed(context, AppRouter.faqRoute),
),

// Yangisi:
_MenuItem(
  icon: Icons.menu_book,
  title: AppLocalizations.of(context)!.knowledgeBaseTitle,
  onTap: () => Navigator.pushNamed(context, AppRouter.knowledgeRoute),
),
```

---

## 22. L10n keylar — `app_*.arb`

3 ta faylga (app_en.arb, app_ru.arb, app_uz.arb) yangi keylar qo'shing:

```json
"knowledgeBaseTitle": "Knowledge Base" / "База знаний" / "Bilimlar manbayi",
"knowledgeCategoryEmpty": "No documents in this category" / ...,
"knowledgeDocumentLoading": "Loading document..." / ...,
"knowledgeNoDocumentsAssigned": "No documents assigned" / ...,
"knowledgeSearchPlaceholder": "Search documents..." / ...,
"knowledgeSyncStatus": "Last synced: {time}" / ...,
"knowledgeRetry": "Retry" / ...,
"knowledgeOfflineNotice": "You're offline. Showing cached content." / ...,
"knowledgeTocTitle": "Table of Contents" / ...,
"knowledgeOpenInBrowser": "Open in browser" / ...
```

`flutter gen-l10n` chaqiring.

---

## 23. KnowledgeImageWidget — `widgets/knowledge_image_widget.dart`

[lib/src/core/widgets/product_image_widget.dart](lib/src/core/widgets/product_image_widget.dart) patternini nusxa qiling. Farqi:
- `mediaId` (UUID) o'rniga to'g'ridan-to'g'ri `KnowledgeMedia` model qabul qiladi (image URL'lar API'da inline keldi, alohida fetch yo'q)
- Size enum: `KnowledgeImageSize { thumbnail, small, medium, large }`
- `urlFor(size)` — `media.small/medium/large` mapping
- BlurHash placeholder, shimmer loading, multi-org header (`X-Organization-Id` mavjud `cached_network_image` headers parameter orqali)

---

## 24. FAQ folder o'chirish (oxirgi qadam — 16-bosqich)

Bu qadam **eng oxirida** bajariladi, knowledge feature to'liq ishlayotgani tasdiqlangach.

```bash
# 1. Folder o'chirish
rm -rf lib/src/features/faq/

# 2. L10n keylar — 3 ta arb faylda faq* boshlanadiganlarni o'chirish
# Manually: app_en.arb, app_ru.arb, app_uz.arb
# Eski keylar: faqPageTitle, faqRoleSupervisor, faqRoleSalesRep, faqSv*, faqTp*, faqSectionsCount va h.k.

# 3. Qayta gen-l10n
flutter gen-l10n

# 4. Static analyze
dart analyze
flutter test
```

`app_router.dart` da `faqRoute` const **saqlanadi** — backward compat redirect uchun.

---

## 25. ServiceLocator — `service_locator.dart`

`KnowledgeApiService`, `KnowledgeDbDao`, `KnowledgeSyncService`, `KnowledgeRepository` ni mavjud DI patternda ro'yxatdan o'tkazing:

```dart
serviceLocator.registerLazySingleton(() =>
  KnowledgeApiService(serviceLocator<TokenService>()));
serviceLocator.registerLazySingleton(() =>
  KnowledgeDbDao(serviceLocator<ApiDatabaseService>()));
serviceLocator.registerLazySingleton(() =>
  KnowledgeSyncService(serviceLocator(), serviceLocator()));
serviceLocator.registerLazySingleton(() =>
  KnowledgeRepository(serviceLocator(), serviceLocator()));
```

---

## 26. Implementation tartibi (qadam-ba-qadam)

```
1.  feature/knowledge-base branchini yarat
2.  pubspec.yaml ga 4 paket qo'shish: flutter_markdown, youtube_player_flutter, webview_flutter, visibility_detector
3.  flutter pub get
4.  domain/enums/ (doc_type, doc_status, block_type) — wireValue + fromString
5.  data/models/ — barcha 8 ta model (sealed class hierarchy ehtiyot bilan)
6.  api_database_service.dart v37 migration — 10 ta CREATE TABLE
7.  data/services/knowledge_db_dao.dart — CRUD per table
8.  data/services/knowledge_api_service.dart — Dio client
9.  data/services/knowledge_sync_service.dart — incremental + per-resource
10. data/repositories/knowledge_repository.dart — offline-first
11. service_locator.dart ga 4 singleton registration
12. data_sync_config.dart ga yangi 'knowledge' guruh + 7 ta table entry
13. data_sync_service.dart ga 8 ta yangi sync metodi (1 ta umumiy + 7 ta per-table) + 1 ta detail fetch
14. presentation/widgets/blocks/ — 11 ta block widget + content_block_renderer.dart
15. presentation/widgets/ — knowledge_image_widget.dart, document_toc_drawer.dart, knowledge_category_card.dart, knowledge_document_card.dart
16. presentation/bloc/ — 4 ta cubit
17. presentation/pages/ — knowledge_home_page.dart, knowledge_category_page.dart, knowledge_document_page.dart, knowledge_search_page.dart
18. core/router/app_router.dart — 4 ta yangi route + faqRoute redirect
19. agent_home_modern.dart line ~2142 — menyu yangilanishi
20. lib/l10n/app_*.arb — 3 ta faylga yangi knowledgeBaseTitle, va h.k.
21. flutter gen-l10n
22. flutter run — manual smoke test (verification §27)
23. test/features/knowledge/ — testlar
24. flutter test — yashil
25. dart analyze — toza
26. (Faza 4) FAQ folder o'chirish — eng oxirgi qadam, hammasi ishlaganidan so'ng
27. Commit + push
```

---

## 27. Tests — `test/features/knowledge/`

**`widgets/content_block_renderer_test.dart`:**
- `renders ParagraphBlock with markdown` — flutter_markdown widget mavjud
- `renders ImageBlock with cached_network_image`
- `renders EmbedBlock youtube provider`
- `renders unknown BlockType as SizedBox.shrink` ← forward-compat

**`data/knowledge_repository_test.dart`:**
- `getCategories returns from cache when api throws`
- `getDocumentDetail returns cached and triggers background refresh`
- `mock api error → cached returned`

**`data/knowledge_sync_test.dart`:**
- `syncIncremental uses last_synced_at as since`
- `deleted ids are removed from sqlite`
- `server_time becomes new last_synced_at`

**`data/knowledge_api_service_test.dart`:**
- `Authorization header set correctly`
- `X-Organization-Id header set correctly`
- `parses document detail with sections + blocks + media`

`flutter test test/features/knowledge/`.

---

## 28. Verification — qabul mezonlari (oxirgi qadam)

Backend dev server running, `seed_knowledge_from_faq` bajarilgan:

1. **Login va navigatsiya**: token tushadi, AgentHomePage → "Bilimlar manbayi" tugmasi → KnowledgeHomePage ochiladi
2. **Pull-to-refresh**: kategoriyalar ro'yxati ko'rinadi (kamida "Reglament")
3. **Detail**: "Reglament — Supervayzer" hujjatini ochish — sectionlar va PARAGRAPH/HEADING bloklar ko'rinadi
4. **Til o'zgartirish**: tilni uz → ru → en o'zgartirsa, kontent tarjimasi yangilanadi
5. **TOC drawer**: drawer ochilsa, sectionlar tree ko'rinadi, biriga bosish — scroll qiladi
6. **Settings → Data tab**: "Bilimlar manbayi" guruhi ko'rinadi, manual sync tugmasi ishlaydi
7. **Offline**: Wi-Fi off → cached hujjat ochiladi, "Showing cached content" indikator
8. **Test image bloki**: admin panel orqali yoki Django shellda hujjatga IMAGE blok qo'shing — mobile pull-refresh, ko'radi, photo_view zoom ishlaydi
9. **Test embed bloki**: YouTube URL bilan EMBED blok — mobile play tugmasi ishlaydi, video oqadi
10. **Multi-tenant izolyatsiya**: A va B tashkilot user'lari turli hujjatlarni ko'radi
11. **Backward compat redirect**: `Navigator.pushNamed(context, AppRouter.faqRoute)` — KnowledgeHomePage ochiladi (initialCategorySlug='reglament')
12. **Static checks**: `dart analyze` toza, `flutter test` yashil
13. **Cache size**: SQLite jadvallari to'lib turibdi — `select count(*) from knowledge_documents` > 0

Hammasi yashil → keyin **eng oxirgi qadam** sifatida (16-bosqich):
- `lib/src/features/faq/` o'chirish
- L10n `faq*` keylar olib tashlash
- `flutter gen-l10n` qayta
- `dart analyze` toza ekanini tekshirish
- Commit

---

## 29. Eslatmalar va qiyinchiliklar

- **Versioning, Acknowledgement, Progress tracking** — bu sessiyada YO'Q (Faza 5)
- **Lokal MP4 video** — bu sessiyada YO'Q (faqat YouTube/Vimeo embed). Backend `KnowledgeMedia.kind=VIDEO` keyingi fazada qo'shiladi
- **Backend kontrakti qotirilgan** (§3) — agar backend so'nggi daqiqada o'zgarsa, alohida bilamiz
- **`BlockType.unknown`** — kelajakda backend yangi blok turi qo'shsa, ilova crash etmaydi va UI'da bo'sh ko'rinadi
- **Mavjud `data_sync_orchestrator.dart` ni o'zgartirish SHART EMAS** — yangi guruh avtomatik qo'llab-quvvatlanadi (config-driven)
- **YouTube player StatefulWidget** — `dispose()` da controller'ni tozalash unutilmasin (memory leak)
- **WebView (Vimeo)** — Android va iOS uchun runtime permissions tekshiring (mavjud `permission_handler` mavjud)
- **Image hero animation** — fullscreen photo_view sahifaga o'tganda Hero tag mos kelishi shart
- **Scrollable.ensureVisible (TOC anchor jump)** — `RenderObject` topiladigan `GlobalKey` har section uchun. Ko'p section bo'lsa map of keys
- **L10n joriy til** — `Localizations.localeOf(context).languageCode` qaytaradi `'uz'`, `'ru'`, yoki `'en'` (mavjud locale tutiladi). `'kk'` yoki `'tr'` qaytmasligiga ishonch hosil qiling
- **Multi-tenant header** — `KnowledgeApiService` har so'rovda `X-Organization-Id` qo'shadi; `token_service.dart`da `getOrganizationId()` mavjudligini tekshiring (yoki o'sha yerga qo'shing)
- **FAQ o'chirish — eng oxirgi qadam** — knowledge feature to'liq ishlaganini tasdiqlanmaguncha o'chirmang
- **`agent_home_modern.dart`** — l10n key o'zgartirilgan, lekin import'lar va boshqa references — `dart analyze` orqali tekshirish
- **Mavjud `lib/src/features/faq/domain/enums/employee_type.dart`** — knowledge'da kerak emas (assignment backend'da hal qilingan), faqat foydalanuvchi rolini olishda foydalanasiz (hozirgi pattern saqlanadi)
