# Product / Client / Project Images — Flutter Mobile Plan (v2)

> **How to use this file**: open a fresh Claude Code session in
> the mobile repo (`/Users/kamoliddin/Documents/GitHub/clone-gg-app`)
> and paste **everything below the next horizontal rule** as the
> first message. The prompt is self-contained — the agent does NOT
> need to read the backend repo, but can if a contract question
> arises (`/Users/kamoliddin/Documents/GitHub/SelUp_Backend/`).

> **What changed from v1**: the contract now keys images by **1C
> code** (`code_1c`) rather than backend UUIDs. The mobile keeps
> using its existing `productCode` / `clientCode` strings end-to-end
> — no new sync flow needed. Multi-org safety unchanged.
> See "Backend contract" section below for the full diff.

---

## Role

You are a senior Flutter engineer working on the SelUp B2B
sales-agent app at `/Users/kamoliddin/Documents/GitHub/clone-gg-app`.
The app today fetches product / client metadata from 1C (SOAP) and
fetches their **images** from a separate REST service at
`http://178.218.200.120:1596/api/v1/{nomenklatura,client}-image/`.

The Django backend (SelUp) has shipped a unified image API under
`/api/admin/v1/images/` with a mobile-readable mirror at
`/api/mobile/v1/images/` that serves the same kind of data with
better variants (WebP small/medium/large) plus BlurHash placeholders.

**The backend keys entities by UUID internally**, but mobile only
ever knows the 1C `code_1c`. The mobile-facing endpoint accepts
`?code_1c=` (and `?target_organization_id=`) as a filter that
resolves to UUIDs server-side — see "Backend contract" below.
Mobile code never sees a backend UUID.

Your job is to migrate the mobile app to consume the new API
**without breaking** the current 1C+legacy-image flow.

## Mission

1. Add a feature flag `useNewImageBackend` (per-organisation,
   defaults to `false`) that controls whether image lookups go to
   the new `/api/mobile/v1/images/` endpoint or the legacy
   `1596` host.
2. When the flag is on for an org:
   - All product / client images are fetched from the new
     backend.
   - The existing widget API (`ProductImageWidget`,
     `ClientImageWidget`) is unchanged — only the URL source moves.
   - BlurHash placeholders replace today's shimmer for the
     "loading" state.
3. When the flag is off:
   - Today's behaviour is identical — the legacy `1596` host
     keeps serving the same fields.
4. Add support for `Project` images (which the legacy API never
   had). Projects render in the new backend only.
5. Future-proof: when `Customer` / `Product` / `Project` tables
   grow new fields on the backend, image consumption stays stable
   because we lock onto `target.{type, id}` plus
   `{small, medium, large, blurhash}` and pass the entity's
   `code_1c` rather than its backend UUID.

## What already exists (do NOT rewrite)

| Capability | Where | Status |
|---|---|---|
| Stable per-install UUID | `lib/src/core/services/local_uuid_service.dart` | ✅ used by auth; not relevant here but DON'T touch it |
| `ProductImageWidget` | `lib/src/core/widgets/product_image_widget.dart` | ✅ Single abstraction over `cached_network_image` + shimmer + error fallback. Reuse it. |
| `ClientImageWidget` | `lib/src/core/widgets/client_image_widget.dart` | ✅ Same pattern as above. |
| `ProductImageService` | `lib/src/core/services/product_image_service.dart` | ✅ Has 200-entry in-memory LRU + `selectImageUrl(image, size)` fallback chain. Reuse. |
| `cached_network_image` | `pubspec.yaml` | ✅ Primary disk + memory cache |
| `image_picker` + `flutter_image_compress` | `pubspec.yaml` | ✅ Used for client image upload |
| Client image upload | `lib/src/features/agent/presentation/pages/client_images_management_page.dart` | ✅ Existing flow uses `POST /api/v1/client-image/bulk-upload/` on legacy host |
| `LoginGatesEnvelope.organizationId` | `lib/src/features/auth/data/models/login_gates_envelope.dart` | ✅ Cached after login. Surfaces the agent's primary org. |

## What's missing (this prompt fixes)

- BlurHash decoder (no package imported yet).
- Project image rendering — not yet supported anywhere.
- Per-organisation feature flag for the URL switch.
- Polling for `status="processing"` (today's legacy API was
  always synchronous; the new API is async).
- **`cached_network_image` configuration**: today the package runs
  with defaults. We must explicitly cap disk size and set a TTL so
  agents' phones don't accumulate stale variants forever.
- **List pagination**: current code pulls all images for a target
  in one shot. The new backend supports cursor pagination
  (`?cursor=...`) — adopt it for product list pages where one org
  could have thousands of images.
- **List-view lazy-loading hooks**: today `ListView` builds every
  off-screen tile. Switch hot lists to `ListView.builder` +
  `cacheExtent` so memory stays bounded.
- **`AgentOrganizationContext`**: a helper that surfaces the
  agent's primary org (from cached gates) so widget call sites
  can opt into the new backend without rewiring every screen.

---

## Backend contract (frozen — already deployed)

> **Cross-reference**: the backend's task list is in
> `/Users/kamoliddin/Documents/GitHub/SelUp_Backend/backend.md`.
> The contract below is the slice mobile depends on.

### Auth

JWT bearer in `Authorization: Bearer <access>`. The mobile app
already manages this via `TokenService`. No change needed.

### Identity model

The backend stores `EntityImage` rows keyed by a generic
`(content_type, object_id)` pair where `object_id` is the owning
entity's **UUID**. Mobile, however, only knows the **1C
`code_1c`** for products / customers (and `id_1c` for projects).

To bridge this without forcing mobile to learn UUIDs:

1. Backend denormalises `code_1c` onto `Customer`, `ProjectProduct`,
   and (already present) `Project` so it's queryable with one index
   lookup.
2. The mobile-facing list endpoint accepts an `external_code` query
   param. Backend resolves `(target_type, external_code,
   target_organization_id)` to the underlying UUID and returns the
   image rows.
3. Mobile NEVER sees a UUID. Variant URLs and `id` (image PK) are
   opaque strings; the mobile treats them as black-box identifiers.

### List images for a target

`GET /api/mobile/v1/images/?target_type=product&external_code=<code_1c>&target_organization_id=<uuid>&status=ready`

The mobile-facing endpoint is read-only. Query params:
- `target_type` — `"product"` / `"customer"` / `"project"`
- `external_code` — 1C code of the entity (mobile passes
  `productCode` / `clientCode` straight through). Mutually
  exclusive with `target_id`; backend accepts either.
- `target_organization_id` — REQUIRED when using `external_code`,
  because the same `code_1c` can collide across organisations.
  Empty / missing ⇒ resolver falls back to legacy.
- `target_id` — optional UUID escape hatch for callers that
  already hold one (admin tools). Mobile never uses this.
- `status` — usually omit (only `ready` images for end users);
  the mobile endpoint silently filters to `status=ready` even
  when the param is absent.
- `is_primary` — `true` when you want only the cover.
- `ordering` — `"order"` (default), `"-order"`, `"created_at"`.

Response is paginated:

```json
{
  "count": 5,
  "next": "https://api.selup.uz/api/mobile/v1/images/?cursor=...",
  "previous": null,
  "results": [
    {
      "id": "5b1f4e60-...",
      "target": {
        "type": "product",
        "id":   "<uuid>",
        "code_1c": "GLR0000123"
      },
      "small":    "https://api.selup.uz/media/img/s/2026/05/abc.webp",
      "medium":   "https://api.selup.uz/media/img/m/2026/05/abc.webp",
      "large":    "https://api.selup.uz/media/img/l/2026/05/abc.webp",
      "width":    3000,
      "height":   2000,
      "blurhash": "L6PZfSi_.AyE_3t7t7R**0o#DgR4",
      "alt":      "Product front view",
      "order":    0,
      "is_primary": true,
      "status":   "ready",
      "error_message": "",
      "created_at": "2026-05-06T12:34:56Z",
      "processed_at": "2026-05-06T12:34:58Z"
    }
  ]
}
```

When mobile uploads a new image (only relevant for client
images today; future for products/projects), the row arrives in
`status="processing"` and `small/medium/large` are `null`. Poll
until ready (see "Upload polling" below).

### Upload (client images today; same shape future for products)

Mobile keeps using its existing client image flow until the
operator decides to retire the legacy `1596` upload. The new
backend has a parallel upload endpoint at:

`POST /api/admin/v1/images/` (multipart):

| Field | Required | Notes |
|---|---|---|
| `target_type` | yes | `"product"` / `"customer"` / `"project"` |
| `external_code` | yes (one of) | 1C code of the owning entity |
| `target_id` | yes (one of) | UUID — admin-only escape hatch |
| `target_organization_id` | yes when `external_code` is used | scopes the lookup |
| `image` | yes | File ≤ 15 MB, JPEG/PNG/WebP/HEIC, 200×200..8000×8000 |
| `alt` | no | ≤ 200 chars |
| `order` | no | Default 0 |
| `is_primary` | no | Default false |

Returns 202 with the row in `"pending"`.

Bulk variant: `POST /api/admin/v1/images/bulk-upload/` with up to 20
images.

### Error envelope (project-wide standard)

```json
{
  "error": { "code": "image_too_large", "message": "...", "details": null },
  "request_id": "..."
}
```

Codes the mobile must recognise:
- `image_too_large` (400)
- `image_invalid_format` (400)
- `image_dimensions_too_small` (400)
- `image_dimensions_too_large` (400)
- `permission_denied` (403)
- `not_found` (404)
- `external_code_ambiguous` (400) — `code_1c` matched > 1 row
  within the org (data corruption signal; mobile shows a generic
  "image unavailable" placeholder and logs the request id)

---

## Architecture — strategy in detail

### Layer 1 — Source resolver

A new `ImageSourceResolver` that returns a list of
`UnifiedImage` records for a given `(targetType, targetId,
targetOrganizationId)`, choosing between the legacy and new backend
based on the feature flag.

```
lib/src/core/services/images/
├── image_source_resolver.dart         ← top-level facade
├── unified_image.dart                 ← the consumer model
├── unified_image_page.dart            ← cursor-paginated page envelope
├── image_repository.dart              ← abstract repo interface
├── new_backend_image_repository.dart  ← /api/mobile/v1/images/
├── legacy_image_repository.dart       ← /api/v1/{nomenklatura,client}-image/
├── image_target_type.dart             ← canonical target keys
├── image_cache_manager.dart           ← entity-image CacheManager singleton
└── agent_organization_context.dart    ← reads agent's primary org from cached gates
```

`UnifiedImage` is the **only** model widgets consume. Both
repositories produce it. This is the abstraction that lets us
swap the source without touching widgets.

```dart
@immutable
class UnifiedImage {
  const UnifiedImage({
    required this.id,
    required this.targetType,
    required this.targetId,                  // 1C code on legacy; UUID on new (treat as opaque)
    required this.targetOrganizationId,
    required this.smallUrl,
    required this.mediumUrl,
    required this.largeUrl,
    required this.blurhash,
    required this.width,
    required this.height,
    required this.isPrimary,
    required this.alt,
    required this.order,
  });

  final String id;
  final String targetType;       // 'product' | 'customer' | 'project'
  final String targetId;         // OPAQUE — never parse as UUID
  final String targetOrganizationId;  // org owning the target → drives feature flag
  final String? smallUrl;
  final String? mediumUrl;
  final String? largeUrl;
  final String blurhash;         // empty string when none (legacy)
  final int? width;
  final int? height;
  final bool isPrimary;
  final String alt;
  final int order;

  /// The URL the widget should load. Returns the best variant
  /// for the requested size, falling back through the chain.
  String? urlForSize(UnifiedImageSize size) { /* ... */ }
}
```

### Layer 2 — Repositories

Both implement the same Dart interface:

```dart
abstract class ImageRepository {
  Future<UnifiedImagePage> listForTarget({
    required String targetType,
    required String targetId,                // 1C code for both legacy & new
    required String targetOrganizationId,
    String? cursor,
    int limit = 50,
    CancelToken? cancelToken,
  });

  Future<UnifiedImage?> primaryForTarget({
    required String targetType,
    required String targetId,
    required String targetOrganizationId,
    CancelToken? cancelToken,
  });
}
```

`NewBackendImageRepository`:
- `GET /api/mobile/v1/images/?target_type=…&external_code=<code_1c>&target_organization_id=<uuid>&status=ready`
- Maps response items to `UnifiedImage`. The response's
  `target.id` is a UUID; mobile stores it on `UnifiedImage.targetId`
  as an opaque string but never exposes it to call sites — the
  `UnifiedImage.target.code_1c` field is what the rest of the app
  matches on.
- Cancels in-flight requests on widget dispose
  (`CancelToken`).

`LegacyImageRepository`:
- Reads from the local SQLite cache (already populated by today's
  sync flow against the legacy host). NO direct HTTP calls — that
  keeps "behaviour identical when flag is off" trivially true.
- For `target_type=product`, queries `product_images` by
  `product_code` (== 1C code).
- For `target_type=customer`, queries the existing client_images
  cache by `client_code` (== 1C code).
- For `target_type=project`, returns empty (legacy never had
  projects).
- Sets `blurhash = ""` because legacy doesn't have it — widgets
  fall back to shimmer in this case (existing behaviour).
- Always returns `nextCursor: null`.

`ImageSourceResolver`:
- Reads `featureFlags.useNewImageBackend(orgId)`.
- Picks the repository.
- Falls back to the OTHER repo on a 5xx / network error
  (configurable; default ON for graceful degradation).
- Caches the resolved list per `(targetType, targetId, cursor ?? '')`
  for 5 minutes (mirrors today's `ProductImageService` LRU TTL).

### Layer 3 — Widgets

`ProductImageWidget` and `ClientImageWidget` keep their public
API. Internally they:

1. Replace direct calls to the legacy service with
   `ImageSourceResolver.listForTarget(...)`.
2. When BlurHash is present, render it via `flutter_blurhash`
   under the `CachedNetworkImage`'s `placeholder` prop.
3. When BlurHash is absent (legacy path), keep today's shimmer.
4. Resolve `targetOrganizationId` via a small `_resolveOrgId()`
   helper: explicit `widget.targetOrganizationId` wins; otherwise
   fall back to `AgentOrganizationContext.primaryOrganizationId`.
   Both null → empty string (legacy fallback).

Add a NEW widget `ProjectImageWidget` (same API as
`ProductImageWidget`, parametrised by `targetId` only) for the
new project-images use case. It can short-circuit when the
feature flag is off (no project images on the legacy host) and
just render the placeholder.

### Layer 3.5 — Caching & lazy-loading (NON-OPTIONAL)

The new backend ships variants with
`Cache-Control: public, max-age=31536000, immutable`.
`cached_network_image` honours HTTP cache headers via its
underlying `flutter_cache_manager`. We just have to configure
sane storage caps and trust the headers.

**Cache manager setup** — create
`lib/src/core/services/images/image_cache_manager.dart`:

```dart
class ImageCacheManagerStore {
  static const String _key = 'selupEntityImages';
  static final CacheManager instance = CacheManager(
    Config(
      _key,
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 2000,
    ),
  );
}
```

Pass `cacheManager: ImageCacheManagerStore.instance` into every
`CachedNetworkImage` inside `ProductImageWidget`,
`ClientImageWidget`, `ProjectImageWidget`.

**List-view lazy-loading**:

1. Every product/client list MUST use `ListView.builder` (NOT
   `ListView(children: [...])`) so off-screen rows aren't built.
2. Set `cacheExtent: 600` (≈ 2 viewports) — enough to make scroll
   feel instant without ballooning memory.
3. `addAutomaticKeepAlives: false` on lists where the user
   typically scrolls one direction (catalog, customers). Saves
   memory; disabled by default in newer Flutter.
4. For grid catalogues with > 200 items, switch to
   `GridView.builder` with `SliverChildBuilderDelegate` and
   the same `cacheExtent`.

**BlurHash placement**: render the BlurHash widget as the
`placeholder:` callback of `CachedNetworkImage`. Once the WebP
finishes decoding, `cached_network_image` cross-fades to the
real bitmap (default 250ms — keep it).

```dart
CachedNetworkImage(
  imageUrl: image.urlForSize(size)!,
  cacheManager: ImageCacheManagerStore.instance,
  placeholder: (ctx, _) => image.blurhash.isEmpty
      ? const _ShimmerBox()                 // legacy path
      : BlurHash(hash: image.blurhash),     // new backend
  errorWidget: (ctx, _, __) => const _BrokenImage(),
);
```

**Pagination** in `NewBackendImageRepository`:

The mobile read endpoint paginates with cursor (next/prev URLs in
the response envelope). The list method honours that:

```dart
Future<UnifiedImagePage> listForTarget({
  required String targetType,
  required String targetId,
  required String targetOrganizationId,
  String? cursor,
  int limit = 50,
}) async { ... }

class UnifiedImagePage {
  final List<UnifiedImage> images;
  final String? nextCursor;        // null when no more pages
}
```

Consumer widgets call `listForTarget` once for the first page,
then call again with `nextCursor` on scroll-to-bottom.
**`LegacyImageRepository.listForTarget` returns `nextCursor: null`**
unconditionally — the legacy host has no pagination. That keeps
the consumer interface uniform.

**Poll budget for processing rows** (mobile uploads only):

If the mobile upload flow ever switches to the new backend (Stage
3 of mobile rollout), poll the detail endpoint with this schedule:
`2s, 2s, 2s, 4s, 8s, 16s` then stop and surface "still
processing — retry later". Total budget ≈ 35s. Match the frontend
prompt — never poll faster than 1 req/s.

### Layer 4 — Feature flag

`featureFlags.useNewImageBackend(orgId)` reads from a remote
config endpoint OR (simpler MVP) from a hard-coded allowlist in
`lib/src/core/config/image_backend_flag.dart`:

```dart
const Set<String> _enabledOrgIds = {
  // Add organisation UUIDs here as they roll over.
  // 'a4d…',
};

bool useNewImageBackend(String? orgId) {
  if (orgId == null || orgId.isEmpty) return false;
  return _enabledOrgIds.contains(orgId);
}
```

This is intentionally simple. The user's PR can replace it with
a runtime config later (Firebase Remote Config, custom endpoint)
without touching the rest of the code.

**CRITICAL — flag is keyed by the TARGET's organization, NOT the
agent's primary organization.** Multi-org agents exist (one
sales rep covering two adjacent organizations). If we keyed by
`LoginGatesEnvelope.organizationId` (the agent's primary org)
and the agent opens a product belonging to org B while their
primary is org A, the resolver picks the WRONG repo and fetches
org B's images from the legacy host even though org B has been
flipped to the new backend (or vice versa). Concretely:

```dart
// WRONG — uses agent's primary org
final useNew = featureFlags.useNewImageBackend(authBloc.primaryOrgId);

// RIGHT — uses the target's owning org
final useNew = featureFlags.useNewImageBackend(target.organizationId);
```

Today no entity in the local cache carries `organizationId`, so
widgets accept it as an OPTIONAL parameter and fall back to the
agent's primary org via `AgentOrganizationContext`. As soon as
catalog sync grows the field, callers pass it explicitly and the
fallback never kicks in. The resolver MUST receive the target's
`organizationId`, not infer it from auth state once entity-level
org data is available:

```dart
abstract class ImageRepository {
  Future<UnifiedImagePage> listForTarget({
    required String targetType,
    required String targetId,
    required String targetOrganizationId,  // pass through
    String? cursor,
    int limit = 50,
  });
}

class ImageSourceResolver {
  Future<UnifiedImagePage> listForTarget({...}) {
    final repo = featureFlags.useNewImageBackend(targetOrganizationId)
        ? _newRepo
        : _legacyRepo;
    return repo.listForTarget(...);
  }
}
```

If `targetOrganizationId` is missing on a cached entity (older
sync schema) AND `AgentOrganizationContext.primaryOrganizationId`
is also null (cold-start before login completes), the resolver
MUST fall back to `_legacyRepo` — never to the new backend with
the agent's primary org guessed from elsewhere. Tests assert this
path explicitly.

### Layer 5 — Agent organisation context

```dart
class AgentOrganizationContext {
  final LoginGatesEnvelope? Function() _readGates;

  factory AgentOrganizationContext({
    required SharedPreferencesService prefs,
  }) =>
      AgentOrganizationContext._(readGates: prefs.getCachedGates);

  String? get primaryOrganizationId => _readGates()?.organizationId;
}
```

Widgets call `_resolveOrgId()` which:
1. Returns `widget.targetOrganizationId` when explicitly passed.
2. Otherwise reads from `AgentOrganizationContext` (registered
   via `sl<>()`).
3. Otherwise returns `''` (resolver → legacy).

This keeps the public widget API ergonomic without leaking auth
state into call sites.

---

## Files to create / modify (concrete list)

**Create**:
- `lib/src/core/services/images/unified_image.dart`
- `lib/src/core/services/images/unified_image_page.dart` (cursor-paginated)
- `lib/src/core/services/images/image_repository.dart` (abstract)
- `lib/src/core/services/images/image_target_type.dart`
- `lib/src/core/services/images/new_backend_image_repository.dart`
- `lib/src/core/services/images/legacy_image_repository.dart`
- `lib/src/core/services/images/image_source_resolver.dart`
- `lib/src/core/services/images/image_cache_manager.dart` (Section "Layer 3.5")
- `lib/src/core/services/images/agent_organization_context.dart`
- `lib/src/core/config/image_backend_flag.dart`
- `lib/src/core/widgets/project_image_widget.dart`
- Tests under `test/core/services/images/` and
  `test/core/widgets/`.

**Modify**:
- `lib/src/core/services/service_locator.dart` — register the
  two repositories + `ImageSourceResolver` + `AgentOrganizationContext`.
- `lib/src/core/widgets/product_image_widget.dart` — wire to
  resolver instead of legacy service. Add BlurHash placeholder
  branch. Add `_resolveOrgId()` helper.
- `lib/src/core/widgets/client_image_widget.dart` — same.
- `lib/src/core/services/product_image_service.dart` — keep its
  public API; redirect internals to call `LegacyImageRepository`.
  After migration completes you can delete this file in a
  follow-up PR.
- `pubspec.yaml` — add `flutter_blurhash: ^0.8.x`. Pin
  `flutter_cache_manager: ^3.4.x` explicitly even though it
  arrives transitively via `cached_network_image` — the
  `ImageCacheManagerStore` config (Section "Layer 3.5") imports
  `Config` from it directly.
- `lib/l10n/app_{en,ru,uz}.arb` — add the new strings (table
  below).
- Hot list pages (catalog, customers, prices, orders) — switch
  to `ListView.builder` / `GridView.builder` + `cacheExtent: 600`
  + `addAutomaticKeepAlives: false`. Pages already audited:
  - `lib/src/features/agent/presentation/pages/prices_page.dart`
  - `lib/src/features/agent/presentation/pages/trading_points_page.dart`
  - `lib/src/features/agent/presentation/pages/step_pages/product_selection_page.dart`
  - `lib/src/features/agent/presentation/pages/step_pages/create_order_page.dart`
  - `lib/src/features/agent/presentation/widgets/order_items_card_view.dart`

---

## Localization keys

```
imageNotAvailable        → "Image not available" / "Изображение недоступно" / "Rasm mavjud emas"
imageProcessing          → "Image is being processed" / "Изображение обрабатывается" / "Rasm tayyorlanmoqda"
imageLoadFailed          → "Could not load image" / "Не удалось загрузить" / "Rasmni yuklab bo'lmadi"
imageLoadRetry           → "Retry" / "Повторить" / "Qayta urinish"
projectImageEmpty        → "No images yet" / "Пока нет изображений" / "Hali rasmlar yo'q"
```

Run `flutter gen-l10n` after adding.

---

## Code-quality requirements (non-negotiable)

1. **Comments in English**, regardless of conversation language.
2. **Public Dart APIs** carry `///` doc comments. Inline comments
   only where the *why* is non-obvious.
3. **Models are immutable** — `final class`, `const` constructors,
   `final` fields. Equality via `Equatable` (project already uses
   it).
4. **No magic strings** — JSON keys, route paths, header names —
   all in `const` declarations grouped at the top of the file.
5. **DI through `GetIt`** — match the existing `lazySingleton`
   pattern in `service_locator.dart`.
6. **No widget business logic** — UI calls into bloc / service
   only.
7. **Cancellation** — long-running list requests use Dio's
   `CancelToken`; cancel in `dispose()` of the consuming widget.
8. **Tests** — `test/` mirrors `lib/`. Use hand-rolled fakes for
   simple stubs; reach for `mockito` (`@GenerateMocks`) only when
   the surface is large enough to justify codegen.
9. **Don't break the legacy path**. While the feature flag is
   off, every code path must reach the same legacy service it
   does today. Run the full `flutter test` suite at every PR
   stage and fix any regression.

---

## Test matrix

### Unit
- `UnifiedImage.urlForSize` returns the expected variant for each
  size including fallback chains.
- `LegacyImageRepository.fromJson` parses both legacy product and
  client schemas.
- `NewBackendImageRepository.parseImageJson` parses the new
  envelope including the `target.code_1c` field.
- `NewBackendImageRepository.listForTarget` returns
  `UnifiedImagePage` with `nextCursor` populated when the response
  carries `next`.
- `LegacyImageRepository.listForTarget` always returns
  `nextCursor: null` (parity with new repo's interface).
- `ImageSourceResolver` picks the right repo based on the flag;
  falls back to the other on 5xx; surfaces the original error on
  4xx.
- **Multi-org safety**: resolver keyed by `targetOrganizationId`,
  NOT by agent's primary org. Test setup: agent's primary org A
  has `useNewImageBackend=true`; agent opens a product whose
  `organizationId` is org B (flag OFF) → resolver MUST use the
  legacy repo, not the new backend.
- **Missing `targetOrganizationId`** (older catalog sync schema)
  → resolver falls back to legacy repo via the
  `AgentOrganizationContext` chain; test asserts new repo is
  never called when both sources are empty.
- `AgentOrganizationContext`: cached envelope, missing envelope,
  superuser (`organizationId == null`), entity-org override.

### Widget
- `ProductImageWidget` renders the existing shimmer when BlurHash
  is empty.
- `ProductImageWidget` shows error icon when image has no URL
  variants (processing state from new backend).
- `ClientImageWidget` same.
- `ProjectImageWidget` renders the empty-state placeholder when
  the flag is off (legacy repo always returns empty for
  projects).

### Integration
- Cold start with the flag OFF for the active org → product
  detail page renders images from the legacy service (no
  contract change visible).
- Switch flag ON in test settings → same page renders from the
  new backend; URLs swap; BlurHash visible.
- Force a 500 from the new backend → resolver falls back to
  legacy → image still appears.

---

## Verification

1. `flutter analyze` — no new warnings.
2. `flutter test` — green; new tests cover the matrix above.
3. `flutter pub run build_runner build --delete-conflicting-outputs`
   succeeds (mockito + l10n codegen) when invoked.
4. **Manual smoke** (against staging once backend ships
   `/api/mobile/v1/images/` AND the `?external_code=` filter):
   - Flag OFF for org X → open a product → images load from
     `1596` host (network inspector confirms).
   - Add org X to `_enabledOrgIds` → restart app → same product
     loads images from the new backend; URLs end in `.webp`;
     BlurHash flashes briefly before the network image arrives.
   - Open a project (new feature) — if any images exist, they
     render; otherwise the empty-state placeholder shows.
   - Kill the new backend (stop the Docker container in dev) →
     image still loads via legacy fallback.

---

## Phasing (3 PRs)

### PR 1 — Resolver + repositories (read-only)  ✅ DONE
- New files for `UnifiedImage` / repositories / resolver.
- `flutter_blurhash` dep added.
- Existing widgets refactored to read from the resolver.
- Feature flag defaults OFF; ZERO behaviour change in
  production.
- 40 unit + widget tests green.
- `cacheExtent: 600` audit on hot lists complete.
- `AgentOrganizationContext` wired through widgets.

### PR 2 — Project images
- `ProjectImageWidget` integrated into a real screen (TBD —
  the contract form's project dropdown could grow a thumbnail).
- Backend `external_code` filter exercised end-to-end against
  staging.
- Flag flipped on for staging org; mobile QA validates products
  + clients + projects.

### PR 3 — Production rollout
- Add production org IDs to `_enabledOrgIds` one at a time,
  monitoring crash reports + image error rate per org.

---

## Definition of done

- [x] `UnifiedImage` is the only image model widgets consume.
- [x] `ImageSourceResolver` picks repository per feature flag;
      falls back on 5xx.
- [x] `ProductImageWidget`, `ClientImageWidget`, new
      `ProjectImageWidget` all use `flutter_blurhash` when a
      hash is available; existing shimmer for legacy.
- [x] Localization parity in en / ru / uz; no hard-coded
      strings.
- [x] `flutter analyze` + `flutter test` green; new files
      under `lib/src/core/services/images/` covered by ≥ 30 tests.
- [x] No reference to the new `/api/mobile/v1/images/` endpoint
      escapes the resolver layer (widgets must not import
      Dio for HTTP — `CancelToken` import is fine).
- [x] When the feature flag is OFF, every widget renders
      pixel-identical results to the pre-PR build.
- [x] **`ImageCacheManagerStore` configured with 30-day `stalePeriod`
      and 2000-object cap**, and every `CachedNetworkImage` in the
      three widgets passes
      `cacheManager: ImageCacheManagerStore.instance`.
- [x] **Hot lists (catalog, customers) use `ListView.builder` /
      `GridView.builder` with `cacheExtent: 600`** — no
      `ListView(children: [...])` left for image grids.
- [x] **`NewBackendImageRepository.listForTarget` returns
      `UnifiedImagePage` with cursor**; consumer widgets handle
      scroll-to-bottom paging.
- [x] **No URL cache-busting** (no `?v=` / `?ts=` appended to
      variant URLs anywhere — grep proves it).
- [x] **BlurHash widget rendered as `placeholder:` callback** of
      `CachedNetworkImage`, not as a separate widget over the top.
- [x] **Multi-org safety** — resolver uses
      `target.organizationId` for the feature-flag check, NOT
      the agent's primary org as the SOURCE of org id when an
      explicit one is available. Test proves: agent primary in
      org A (flag ON) opens a product owned by org B (flag OFF)
      → legacy repo is called.
- [x] **`AgentOrganizationContext` fallback** — when no explicit
      org id is supplied, widgets read agent's primary org from
      cached gates so existing call sites work without rewiring.
- [x] **Missing `targetOrganizationId` falls back to legacy** —
      old catalog cache without the new field still renders
      images, never accidentally hits the new backend with
      wrong-org context.
- [ ] **Cursor pagination works end-to-end** — once backend
      `external_code` filter ships, list of > 50 images on a
      single product yields a `nextCursor`, mobile re-issues the
      full URL, second page rendered. Pending backend PR.

---

## What you must NOT do

- Do not delete `LegacyImageRepository` until ops confirms the
  `178.218.200.120:1596` host is decommissioned. The two paths
  must coexist for the entire migration.
- Do not change the public API of `ProductImageWidget` or
  `ClientImageWidget`. Hundreds of call sites depend on them;
  any signature change snowballs into a massive PR. New optional
  parameters (`targetOrganizationId`) are fine because they
  default to `null`.
- Do not introduce a new image cache. `cached_network_image`
  already does memory + disk; layering another LRU on top
  doubles memory pressure on agents' phones.
- Do not log full URLs or BlurHash strings in production. They
  are not secret per se, but the network log noise on a busy
  list view is enormous.
- Do not call any URL on `/api/admin/v1/...` from the mobile —
  that route is admin-only and may enforce stricter
  authorisation. Use `/api/mobile/v1/images/` for reads.
- Do not edit the backend repo. The contract is fixed; if you
  need a contract change, raise a separate request via
  `/Users/kamoliddin/Documents/GitHub/SelUp_Backend/backend.md`.
- Do not parse `UnifiedImage.targetId` as a UUID. Treat it as an
  opaque identifier — the legacy path stores the 1C code there,
  the new path stores a UUID. Match on `target_type` +
  `code_1c` instead.

Begin in this order: `UnifiedImage` model → repository
interface + 2 implementations → resolver + flag → widget
integration → tests → BlurHash placeholder → ProjectImageWidget
→ localisation → AgentOrganizationContext → manual smoke.
