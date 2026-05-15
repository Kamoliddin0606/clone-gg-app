# Backend — Knowledge Base authoring web UI + sales-rep seed (implementation prompt)

> Bu hujjatni butunligicha **yangi backend sessiyaga** task brief sifatida nusxalang.
> Self-contained — oldindan kontekst kerak emas.
> Mobile tomondagi ish allaqachon bajarilgan: Knowledge feature **faqat o'qish (read-only)** rejimida ishlaydi — `/api/mobile/v2/knowledge/*` endpoint'lariga ulangan. Mobile bu yerda yozilgan backend ish bajarilgandan keyin yangi kontentni avtomatik ko'radi (assignment-filtered sync orqali).

## Maqsad

1. Backend `/dev/` sahifalar to'plamiga (mavjud: `/dev/customers/`, `/dev/notifications/`, `/dev/balance/`, `/dev/images/`, `/dev/onec/`) **yangi `/dev/knowledge-authoring/`** sahifa qo'shish. Operator JWT bilan login bo'ladi, organizatsiya tanlaydi, Knowledge'ning to'liq CRUD'ini ishlatadi: kategoriya/hujjat/bo'lim/blok yaratish-tahrirlash, media yuklash (drag-drop + file input), uz/ru/en tarjimalarini bir paytda boshqarish, hujjatlarni publish/archive/clone qilish, **bulk-assign** orqali rol (`sales_rep`) yoki ALL bo'yicha biriktirish.
2. **Savdo vakili uchun mukammal bilimlar manbayi** (ushbu hujjatga ilova qilingan [knowledge-base-sales-rep-seed.py](./knowledge-base-sales-rep-seed.py) faylida tayyor turibdi) — `apps/knowledge/data/sales_rep_seed.py` ga ko'chirilib, **idempotent management command** `seed_sales_rep_knowledge` orqali backendga yuklanadi. Tarkib: 6 kategoriya, ~14 hujjat, ~30 bo'lim, ~50 blok, hammasi `uz/ru/en` da. IMAGE bloklar `placeholder_key` bilan belgilangan — operator UI orqali real screenshotlarni yuklab joylashtiradi.
3. `/dev/knowledge-authoring/` sahifasidan **"Seed default sales-rep content"** tugmasi orqali (yoki CLI orqali `python manage.py seed_sales_rep_knowledge --organization <uuid>`) operatorlarga ushbu kontentni har bir organizatsiyaga bir martalik yuklash imkoni beriladi.

## Repository

- **Backend repo'si:** `/Users/kamoliddin/Documents/GitHub/SelUp_Backend`
- **Stack:** Django 5.1 + DRF, PostgreSQL, Redis + Celery, Uvicorn (ASGI), Docker. Python 3.12. drf-spectacular (Swagger/Redoc), djangorestframework-simplejwt.
- **Knowledge app:** [src/apps/knowledge/](../../../SelUp_Backend/src/apps/knowledge/) — `models/`, `views/admin.py`, `views/mobile.py`, `selectors/`, `serializers/`, `permissions.py`, `enums.py`, `management/commands/seed_knowledge_from_faq.py` (referans pattern).
- **Existing /dev/ pages:**
  - View funksiyalari: [src/apps/core/views.py](../../../SelUp_Backend/src/apps/core/views.py) qator 144–300 (`dev_image_upload`, `dev_onec_sync`, `dev_notifications`, `dev_customers`, `dev_balance`, `dev_target_search`)
  - Templatelar: [src/apps/core/templates/dev/](../../../SelUp_Backend/src/apps/core/templates/dev/) — `customers.html` (1619 qator), `notifications.html` (1693 qator), `balance.html` (1208 qator) — referans uchun
  - URL routing: [src/config/urls.py](../../../SelUp_Backend/src/config/urls.py) qator 73–83, **`DEBUG=True` ostida**

## Mavjud kontekst (taxmin qilinadi)

- **Knowledge models** ([src/apps/knowledge/models/](../../../SelUp_Backend/src/apps/knowledge/models/)):
  - `KnowledgeCategory` — UUID PK, `organization_id`, `parent_id` (nullable, hierarchy), `slug` (unique per org), `name`, `description`, `icon`, `color`, `cover_media_id`, `order`, `is_active`
  - `KnowledgeDocument` — UUID PK, `organization_id`, `category_id`, `slug`, `doc_type` (regulation/manual/training/policy/faq/announcement/other), `status` (DRAFT/PUBLISHED/ARCHIVED), `is_pinned`, `cover_media_id`, `published_at`, `expires_at`, `created_by`, `updated_by`
  - `KnowledgeDocumentTranslation` — `(document_id, language)` composite natural key, `title`, `summary`
  - `KnowledgeSection` — UUID PK, `organization_id`, `document_id`, `parent_id` (nullable), `anchor`, `title_i18n` (JSONB), `order`
  - `KnowledgeContentBlock` — UUID PK, `organization_id`, `section_id`, `order`, `block_type` (PARAGRAPH/HEADING/LIST/QUOTE/CALLOUT/IMAGE/EMBED/CODE/TABLE/DIVIDER/FILE), `data` (JSONB — type-specific), `media_id` (FK, nullable)
  - `KnowledgeMedia` — UUID PK, `kind` (IMAGE/FILE), `mime_type`, `size_bytes`, `storage_key`, image variants (`small`/`medium`/`large` URLs + `blurhash` + `width`/`height`), `processing_state` (PENDING/PROCESSING/READY/FAILED)
  - `KnowledgeAssignment` — UUID PK, `document_id`, `target_type` (ALL/ROLE/USER/STAFF/BRANCH/TERRITORY), `target_role_id`/`target_user_id`/`target_staff_id`/`target_branch_id`/`target_territory_id`, `mandatory`, `due_at`
  - `KnowledgeTag` — `slug`, `name`

- **Admin endpoints** (mavjud, `IsKnowledgeAdminForOrg` permission'i bilan himoyalangan):
  - `/api/admin/v1/knowledge/categories/` — CRUD
  - `/api/admin/v1/knowledge/documents/` — CRUD + `{id}/publish/`, `/archive/`, `/clone/`
  - `/api/admin/v1/knowledge/sections/`, `.../blocks/`, `.../tags/`, `.../translations/`, `.../assignments/`
  - `/api/admin/v1/knowledge/media/upload/` — `multipart/form-data` (`file`, `kind`=IMAGE|FILE)
  - `/api/admin/v1/knowledge/assignments/bulk-assign/` — `{document_id, targets:[{target_type, target_id?}, ...]}`

- **Permission gate:** `IsKnowledgeAdminForOrg` ([src/apps/knowledge/permissions.py](../../../SelUp_Backend/src/apps/knowledge/permissions.py)) — superuser yoki Role.code ∈ `{KB_ADMIN, KB_EDITOR, ADMIN}` bo'lgan foydalanuvchilarga ruxsat beradi (RoleAssignment yoki UserAccessScope orqali).

- **Sales-rep rol kodi:** `sales_rep` (lowercase, snake_case) — `_ROLE_TO_DOC_SLUG = {"sales_rep": "reglament-sales-rep"}` da tasdiqlangan ([src/apps/knowledge/management/commands/seed_knowledge_from_faq.py](../../../SelUp_Backend/src/apps/knowledge/management/commands/seed_knowledge_from_faq.py) qator 33–36).

- **Existing seed pattern:** [src/apps/knowledge/management/commands/seed_knowledge_from_faq.py](../../../SelUp_Backend/src/apps/knowledge/management/commands/seed_knowledge_from_faq.py) — `apps.knowledge.data.faq_seed.FAQ_SEED` dan o'qiydi, har organizatsiya uchun get-or-create qiladi, idempotent. Yangi command shu patternga rioya qilishi kerak.

- **`/dev/` UI tech stack:** vanilla HTML + inline CSS variables (dark-mode aware via `@media (prefers-color-scheme: light)`) + vanilla JS + `fetch` (jQuery/Bootstrap/bundler yo'q). Har sahifa **self-contained** — `customers.html` (1619 qator) eng yaqin referans, chunki u ham JWT login + organizatsiya picker + paginated list + CRUD modal + toast UX patternlariga ega.

---

## Yangi artefaktlar (3 ta)

### 1) `apps/knowledge/data/sales_rep_seed.py`

Tarkibi: ushbu hujjatga ilova qilingan [knowledge-base-sales-rep-seed.py](./knowledge-base-sales-rep-seed.py) faylini **butunligicha** `src/apps/knowledge/data/sales_rep_seed.py` ga ko'chiring. Hech qanday modifikatsiya kerak emas — fayl o'zining `dataclass` modellari (`SeedCategory`/`SeedDocument`/`SeedSection`/`SeedBlock`) va `SALES_REP_SEED_V1` const tree'ni eksport qiladi.

Imports faqat ikkita:
```python
from apps.knowledge.enums import BlockType, DocType
```

Agar `apps/knowledge/enums.py` da `BlockType.PARAGRAPH`, `BlockType.HEADING`, ..., `DocType.MANUAL`, `DocType.TRAINING`, `DocType.REGULATION` qiymatlari mavjud bo'lmasa, seed faylidan keladigan `BlockType.PARAGRAPH` referenslari ishlamaydi — bunday holda enum nomlarini mavjud `enums.py`'dagi kanonlarga moslang (masalan, `BlockType.paragraph` lowercase bo'lsa).

### 2) `apps/knowledge/management/commands/seed_sales_rep_knowledge.py`

[seed_knowledge_from_faq.py](../../../SelUp_Backend/src/apps/knowledge/management/commands/seed_knowledge_from_faq.py) patterniga to'liq amal qiladi. Skelet:

```python
"""Idempotent seed command: populates the sales-rep knowledge tree.

Run:
    ./manage.py seed_sales_rep_knowledge --organization <UUID>
    ./manage.py seed_sales_rep_knowledge --all-orgs
    ./manage.py seed_sales_rep_knowledge --organization <UUID> --assign-to-role sales_rep
    ./manage.py seed_sales_rep_knowledge --organization <UUID> --dry-run

Safe to re-run — every (organization, slug) pair is checked before insert.
"""

from __future__ import annotations

from django.core.management.base import BaseCommand, CommandError
from django.db import transaction
from django.utils import timezone

from apps.knowledge.data.sales_rep_seed import SALES_REP_SEED_V1, SeedCategory, SeedDocument
from apps.knowledge.enums import AssignmentTargetType, DocStatus
from apps.knowledge.models import (
    KnowledgeAssignment,
    KnowledgeCategory,
    KnowledgeContentBlock,
    KnowledgeDocument,
    KnowledgeDocumentTranslation,
    KnowledgeSection,
)
from apps.permissions.models import Role
from apps.tenants.models import Organization


class Command(BaseCommand):
    help = "Seed Knowledge Base with the comprehensive sales-rep manual. Idempotent."

    def add_arguments(self, parser):
        group = parser.add_mutually_exclusive_group(required=True)
        group.add_argument("--organization", help="Organization UUID")
        group.add_argument("--all-orgs", action="store_true")
        parser.add_argument(
            "--assign-to-role",
            default=None,
            help="Role.code to bulk-assign documents to (e.g. 'sales_rep'). Omit to skip.",
        )
        parser.add_argument(
            "--target-all",
            action="store_true",
            help="Create an ALL assignment (visible to every user in the org).",
        )
        parser.add_argument("--dry-run", action="store_true")

    def handle(self, *args, **opts):
        if opts["all_orgs"]:
            orgs = list(Organization.objects.all())
        else:
            try:
                orgs = [Organization.objects.get(id=opts["organization"])]
            except Organization.DoesNotExist as exc:
                raise CommandError(f"Organization {opts['organization']} not found.") from exc

        for org in orgs:
            self.stdout.write(f"Seeding for {org.code or org.id}...")
            try:
                with transaction.atomic():
                    self._seed_org(
                        org,
                        assign_role=opts.get("assign_to_role"),
                        target_all=opts.get("target_all", False),
                        dry_run=opts.get("dry_run", False),
                    )
                    if opts.get("dry_run"):
                        transaction.set_rollback(True)
                        self.stdout.write(self.style.WARNING(f"  dry-run: rolled back"))
            except Exception as exc:
                self.stdout.write(self.style.ERROR(f"  FAILED: {exc}"))
                raise
        self.stdout.write(self.style.SUCCESS("Done."))

    def _seed_org(self, org, assign_role, target_all, dry_run):
        # Walk SALES_REP_SEED_V1 depth-first, get-or-create categories,
        # then docs, then translations, then sections, then blocks.
        # Maintain {slug -> id} maps for parent linking.
        cat_id_by_slug: dict[str, str] = {}
        doc_id_by_slug: dict[str, str] = {}

        def upsert_category(seed: SeedCategory, parent_slug: str | None):
            cat, created = KnowledgeCategory.objects.update_or_create(
                organization=org, slug=seed.slug,
                defaults={
                    "parent_id": cat_id_by_slug.get(parent_slug) if parent_slug else None,
                    "name": seed.name.get("uz") or next(iter(seed.name.values())),
                    "description": (seed.description or {}).get("uz"),
                    "icon": seed.icon,
                    "color": seed.color,
                    "order": seed.order,
                    "is_active": True,
                },
            )
            cat_id_by_slug[seed.slug] = str(cat.id)
            for d in seed.documents:
                upsert_document(d, cat.id)
            for child in seed.children:
                upsert_category(child, seed.slug)

        def upsert_document(seed: SeedDocument, category_id):
            doc, _ = KnowledgeDocument.objects.update_or_create(
                organization=org, slug=seed.slug,
                defaults={
                    "category_id": category_id,
                    "doc_type": seed.doc_type,
                    "status": DocStatus.DRAFT,
                    "is_pinned": seed.is_pinned,
                },
            )
            doc_id_by_slug[seed.slug] = str(doc.id)
            # Translations
            for lang, title in seed.title.items():
                KnowledgeDocumentTranslation.objects.update_or_create(
                    document=doc, language=lang,
                    defaults={
                        "title": title,
                        "summary": (seed.summary or {}).get(lang),
                    },
                )
            # Sections + blocks
            for sec_order, sec_seed in enumerate(seed.sections):
                section, _ = KnowledgeSection.objects.update_or_create(
                    organization=org, document=doc, anchor=sec_seed.anchor,
                    defaults={
                        "title_i18n": sec_seed.title,
                        "order": sec_order,
                    },
                )
                for blk_order, blk_seed in enumerate(sec_seed.blocks):
                    data = dict(blk_seed.data)
                    if blk_seed.placeholder_key:
                        data["placeholder_key"] = blk_seed.placeholder_key
                    KnowledgeContentBlock.objects.update_or_create(
                        organization=org, section=section, order=blk_order,
                        defaults={
                            "block_type": blk_seed.type,
                            "data": data,
                            "media_id": None,
                        },
                    )

        for root in SALES_REP_SEED_V1:
            upsert_category(root, None)

        # Assignments
        if assign_role:
            try:
                role = Role.objects.get(organization=org, code=assign_role)
            except Role.DoesNotExist:
                self.stdout.write(self.style.WARNING(
                    f"  Role code '{assign_role}' not found in org — skipping assignments."
                ))
                role = None
            if role:
                for slug, doc_id in doc_id_by_slug.items():
                    KnowledgeAssignment.objects.update_or_create(
                        organization=org, document_id=doc_id,
                        target_type=AssignmentTargetType.ROLE,
                        target_role_id=role.id,
                        defaults={"mandatory": False},
                    )
        if target_all:
            for slug, doc_id in doc_id_by_slug.items():
                KnowledgeAssignment.objects.update_or_create(
                    organization=org, document_id=doc_id,
                    target_type=AssignmentTargetType.ALL,
                    defaults={"mandatory": False},
                )

        self.stdout.write(self.style.SUCCESS(
            f"  {len(cat_id_by_slug)} categories, {len(doc_id_by_slug)} documents seeded."
        ))
```

Eslatma: `KnowledgeCategory`, `KnowledgeDocument`, `KnowledgeSection` modellaringizdagi `Meta.unique_together` (yoki ekvivalent constraint) `(organization, slug)` / `(document, anchor)` ekanligini tasdiqlang. Agar yo'q bo'lsa migrate qiling, aks holda `update_or_create` ko'p qator yaratadi.

### 3) `/dev/knowledge-authoring/` Django view + template

#### 3a. View qo'shilishi — [src/apps/core/views.py](../../../SelUp_Backend/src/apps/core/views.py)

`dev_balance` keyin (qator ~300 atrofida) yangi qo'shing:

```python
@require_GET
@never_cache
def dev_knowledge_authoring(request):
    """Knowledge Base authoring console.

    One-page UI that exercises every endpoint of the knowledge admin
    module: categories tree CRUD, documents CRUD + translations +
    publish/archive/clone, sections + blocks editor (11 block types),
    media upload (drag-drop + file input), bulk-assign by role/user/
    branch/territory/ALL. Includes a "Seed default sales-rep content"
    button that posts to /dev/api/seed-knowledge/ to run the
    `seed_sales_rep_knowledge` management command for the selected
    organization.

    Acts as the temporary FE until the React admin panel ships.
    """
    if not settings.DEBUG:
        raise Http404()
    return render(request, "dev/knowledge_authoring.html")


@require_POST
@never_cache
def dev_seed_knowledge(request):
    """HTTP shortcut to run `seed_sales_rep_knowledge` for one org.

    Body JSON: {"organization": "<uuid>", "assign_to_role": "sales_rep"|null,
                "target_all": bool, "dry_run": bool}
    Returns: {"ok": true, "stdout": "..."}
    """
    if not settings.DEBUG:
        raise Http404()
    import io, json
    from django.core.management import call_command
    payload = json.loads(request.body or "{}")
    org_id = payload.get("organization")
    if not org_id:
        return JsonResponse({"ok": False, "error": "organization required"}, status=400)
    out = io.StringIO()
    try:
        call_command(
            "seed_sales_rep_knowledge",
            organization=org_id,
            assign_to_role=payload.get("assign_to_role"),
            target_all=bool(payload.get("target_all")),
            dry_run=bool(payload.get("dry_run")),
            stdout=out,
        )
        return JsonResponse({"ok": True, "stdout": out.getvalue()})
    except Exception as exc:
        return JsonResponse({"ok": False, "error": str(exc), "stdout": out.getvalue()}, status=500)
```

Importlarni view fayl boshida qo'shing: `from django.views.decorators.http import require_GET, require_POST`, `from django.http import Http404, JsonResponse`, `from django.shortcuts import render`, `from django.views.decorators.cache import never_cache`, `from django.conf import settings`.

#### 3b. URL routing — [src/config/urls.py](../../../SelUp_Backend/src/config/urls.py)

`DEBUG=True` ostidagi `urlpatterns` ga qo'shing (qator ~76–83):

```python
path("dev/knowledge-authoring/", dev_knowledge_authoring, name="dev-knowledge-authoring"),
path("dev/api/seed-knowledge/", dev_seed_knowledge, name="dev-seed-knowledge"),
```

`from apps.core.views import dev_knowledge_authoring, dev_seed_knowledge` importini fayl boshida qo'shing.

#### 3c. Template — `src/apps/core/templates/dev/knowledge_authoring.html`

Tuzilishi va texnik talablar (umumiy hajm ~2500–3500 qator, `customers.html`'dan ko'p, chunki ko'proq funksiya):

**HEAD bloki:**
- `<title>SelUp · Dev · Knowledge authoring</title>`
- Inline `<style>` — `customers.html` dan ko'chirilgan CSS variables, dark/light theme, toast, modal, button styles. Qo'shimcha: tree view (indented list + chevron toggles), language tabs, block list, drag-drop dropzone.

**Body — 7 panel:**

1. **Header panel** — title, dark/light toggle indicator, "Help" button (mini-doc modal: ushbu UI'ning qisqacha qo'llanmasi).

2. **Auth + org picker** (`customers.html` patterni):
   - JWT token input + "Load" button
   - Organization dropdown (paginated `/api/admin/v1/tenants/organizations/` orqali yuklanadi)
   - Token validatsiya holati (yashil/qizil indikator)
   - **Seed defaults** button — modal ochadi: assign-to-role checkbox (default `sales_rep`), target-all checkbox, dry-run checkbox, "Run" tugmasi → `POST /dev/api/seed-knowledge/`

3. **Categories tree panel** (chap, taxminan 320px width):
   - Hierarchik daraxt (indented + chevron icons), `GET /api/admin/v1/knowledge/categories/` dan
   - Har element: nom + icon + (∶) menu (Edit, Add child, Add document, Delete)
   - "New root category" tugmasi pastda
   - Category modal: slug, name (uz/ru/en), description (uz/ru/en), icon (emoji input), color (HEX), parent_id (dropdown), order

4. **Documents list panel** (markaz yuqori, taxminan 30% balandlik):
   - Tanlangan kategoriya ostidagi hujjatlar — `GET /api/admin/v1/knowledge/documents/?category=<id>`
   - Status filter chip'lari: Draft / Published / Archived / All
   - Har qatori: title (joriy til) + status badge + (∶) menu (Edit, Publish, Archive, Clone, Delete)
   - "New document" tugmasi yuqori o'ngda

5. **Document editor panel** (markaz pastki, taxminan 70% balandlik):
   - Yuqori panel: language chip group (uz/ru/en — bittasi tanlangan), title input (i18n), summary input (i18n), slug, doc_type dropdown, is_pinned switch, status badge
   - Sections list (reorderable, drag handle): har section uchun title (i18n) + (∶) menu (Edit, Delete) + bloklar ro'yxati
   - Block list (per-section, reorderable): har blok uchun type icon + preview (1 qator) + (∶) menu (Edit, Delete)
   - "Add section" button section list pastida; "Add block" button har section'ning oxirida — block type picker modal ochadi (11 tip)
   - Bottom action bar: **Save** (sariq agar dirty), **Publish**, **Archive**, **Clone**, **Assignments** tugmalari

6. **Block editor modal** (per-block-type):
   - **PARAGRAPH/QUOTE**: textarea (Markdown), language tab switch
   - **HEADING**: level select (1–4) + textarea, language tab
   - **LIST**: style radio (bullet/ordered/check) + dynamic textarea-list (add/remove rows), language tab
   - **CALLOUT**: variant select (info/warn/success/danger) + textarea, language tab
   - **IMAGE**: media picker (existing library grid + "Upload new" dropzone via `POST /api/admin/v1/knowledge/media/upload/`) + caption (i18n) + fit select (contain/cover)
   - **EMBED**: provider select (youtube default) + URL input + auto-extract embed_id (regex) + caption (i18n)
   - **CODE**: language input + textarea (monospace, no i18n)
   - **TABLE**: rows/cols steppers + i18n grid (textarea per cell), language tab
   - **DIVIDER**: no body, just "Save" button
   - **FILE**: file dropzone → upload `kind=FILE` → filename + caption (i18n)
   - **Save** persists via `POST/PATCH /api/admin/v1/knowledge/blocks/{?id}/` — return updated block; editor inserts/updates locally

7. **Assignments panel** (modal yoki side-drawer):
   - Tanlangan hujjat assignmentlari ro'yxati — `GET /api/admin/v1/knowledge/assignments/?document_id=<id>`
   - Har qator: target_type badge + target nomi (role/user/branch nomi rezolyutsiya qilingan) + delete button
   - **Add assignment** formasi:
     - target_type radio: ALL / ROLE / USER / STAFF / BRANCH / TERRITORY
     - Conditional: ROLE → role dropdown (`GET /api/admin/v1/permissions/roles/?organization=<id>` — agar endpoint mavjud bo'lmasa, backend team'i ham qo'shsin yoki UI'da `target_role_id` UUID input bilan davom etadi)
     - USER/STAFF/BRANCH/TERRITORY uchun ham mos picker yoki UUID input
     - mandatory checkbox, due_at (optional datetime)
   - **Bulk-assign** formasi: bir nechta hujjatni multi-select + ALL/ROLE target picker → `POST /api/admin/v1/knowledge/assignments/bulk-assign/`

**JS arxitekturasi:**
- Vanilla, modulesiz, `(function() { ... })()` IIFE bloklari
- `api(url, opts)` wrapper — `customers.html` dagi pattern: JWT header, `X-Organization-Id` header, 401 → token tozalash + toast, JSON parse, throw on non-2xx
- `toast(level, title, msg)`, `confirm(msg)`, `modal(...)` UI util'lari — yana customers.html'dan ko'chirib oling
- State: `state = {token, orgId, currentLang, selectedCategoryId, selectedDocumentId, draftDoc, ...}` plain object
- Rendering: imperative DOM updates (innerHTML + addEventListener), framework yo'q

**Markdown preview** uchun — operator tanlash: (a) ServerSide rendering (qo'shimcha admin endpoint), (b) `marked.js` CDN (offline holatda ishlamaydi) yoki (c) plain textarea (preview yo'q). **Tavsiya:** (c) — eng oddiy, mobile renderer chiqaradi.

---

## URL summary (yangilanish kerak bo'lgan fayllar)

- [src/apps/core/views.py](../../../SelUp_Backend/src/apps/core/views.py) — 2 ta yangi view qo'shish (`dev_knowledge_authoring`, `dev_seed_knowledge`)
- [src/config/urls.py](../../../SelUp_Backend/src/config/urls.py) — 2 ta yangi route + 2 ta import (`DEBUG=True` ostida)
- [src/apps/core/templates/dev/knowledge_authoring.html](../../../SelUp_Backend/src/apps/core/templates/dev/knowledge_authoring.html) — yangi fayl
- [src/apps/knowledge/data/sales_rep_seed.py](../../../SelUp_Backend/src/apps/knowledge/data/sales_rep_seed.py) — yangi fayl (ushbu hujjatga ilova)
- [src/apps/knowledge/management/commands/seed_sales_rep_knowledge.py](../../../SelUp_Backend/src/apps/knowledge/management/commands/seed_sales_rep_knowledge.py) — yangi fayl

---

## Xavf-xatarlar / Open questions

1. **Enum mapping** — agar `apps.knowledge.enums.BlockType` qiymatlari `paragraph`, `heading`, ... lowercase bo'lsa, seed faylida `BlockType.PARAGRAPH` ni mavjud nomga moslang yoki `enums.py` ga case-insensitive `__getitem__` qo'shing.

2. **Slug uniqueness** — `KnowledgeCategory` va `KnowledgeDocument` da `(organization, slug)` uchun UNIQUE constraint bo'lishi muhim, aks holda seed har gal qayta ishga tushganda duplikat yaratadi. Migrate kerak bo'lsa qiling.

3. **Permission/Role endpoint** — `/api/admin/v1/permissions/roles/?organization=<id>` bormi? Agar yo'q bo'lsa, kichik admin endpoint qo'shing (faqat `id`, `code`, `name`) yoki UI'da `target_role_id` UUID input bilan boshlang.

4. **Image processing pipeline** — Celery worker `KnowledgeMedia.processing_state` ni `PENDING → READY` ga avtomatik o'tkazyaptimi? UI yuklab bo'lgach 2–10 soniya `processing_state` ga poll qiladi. Agar pipeline ishlamasa, UI "Processing..." da to'xtab qoladi.

5. **`KnowledgeContentBlock.data` JSON schema** — har block_type uchun mavjud serializer validation'i bormi? UI yuborgan ma'lumot yetib boradimi? Mobile renderer kutadi: PARAGRAPH/QUOTE/CALLOUT — `markdown_i18n` (dict[lang, str]); HEADING — `level` (int) + `text_i18n`; LIST — `style` + `items_i18n` (dict[lang, list[str]]); IMAGE — `caption_i18n` + `fit`; EMBED — `provider` + `embed_id` + `url`; CODE — `language` + `code`; TABLE — `headers_i18n` + `rows_i18n`; FILE — `filename` + `caption_i18n`; DIVIDER — bo'sh; CALLOUT — `variant`.

6. **Seed re-run idempotentlik** — birinchi run uchun `update_or_create` ishlatiladi. Kategoriya/hujjat slug'lari o'zgarsa, eski qatorlar qoladi (manual cleanup kerak). Bu rejada qabul qilingan.

7. **`/dev/api/seed-knowledge/` autentifikatsiyasi** — boshqa /dev/ sahifalardagi kabi `DEBUG=True` ostida cheklash kifoya, lekin agar production'da test/staging muhitida ishlasa, CSRF token va admin JWT ham tekshiring.

---

## Verification plan

Backend team tomonidan:

1. **Migrations** — `python manage.py makemigrations apps.knowledge && migrate` (agar UNIQUE constraint qo'shilgan bo'lsa)
2. **Seed dry-run:**
   ```bash
   python manage.py seed_sales_rep_knowledge --organization <UUID> --dry-run
   ```
   Kutilgan: progress logi (kategoriya/hujjat sonlari), keyin "dry-run: rolled back" — DB tegmaydi.

3. **Real seed:**
   ```bash
   python manage.py seed_sales_rep_knowledge --organization <UUID> --assign-to-role sales_rep
   ```
   Kutilgan: 6 kategoriya, ~14 hujjat, ~14 assignment yaratilishi:
   ```sql
   SELECT COUNT(*) FROM knowledge_categories WHERE slug LIKE 'savdo-vakili-%';
   -- 5
   SELECT COUNT(*) FROM knowledge_documents WHERE slug IN ('login-va-kirish', ...);
   -- 14
   SELECT COUNT(*) FROM knowledge_assignments WHERE target_type='ROLE';
   -- 14
   ```

4. **Re-run idempotentlik:** komandani ikkinchi marta ishga tushiring — yangi qator paydo bo'lmasligi kerak (faqat `updated_at` yangilanadi).

5. **`/dev/knowledge-authoring/` sahifasini ochish:**
   - URL: http://localhost:8080/dev/knowledge-authoring/
   - JWT login (KB_ADMIN/superuser hisobi)
   - Organizatsiyani tanlash → tree va documentlar ko'rinishi
   - Bitta hujjatni ochish → uz/ru/en tab almashtirib title o'zgartirish → Save → reload da o'zgarish saqlangan
   - Sectionga PARAGRAPH blok qo'shish → markdown yozish → Save → DB'da `KnowledgeContentBlock` qatori paydo bo'lishi
   - IMAGE blok qo'shish → "Capture" emas, **drag-drop** ekran ostonasi (web) → media yuklanadi, `processing_state=READY` bo'lgach blok thumbnaildan ko'rinadi
   - Hujjatni **Publish** qilish → status PUBLISHED ga aylanadi
   - Bulk-assign: ROLE=`sales_rep` → assignment yaratiladi

6. **Mobile uchini tekshirish (mavjud read-side):**
   - Login savdo vakili hisobi bilan (rol = `sales_rep`)
   - Knowledge bo'limini ochish → sync → yangi kategoriya/hujjatlar paydo bo'lishi
   - Hujjat ichida blok renderer to'g'ri ishlashi (PARAGRAPH/HEADING/LIST/CALLOUT/IMAGE/...) — barcha 11 tip
   - Til chip'larini uz/ru/en bilan o'zgartirish → tarjimalar to'g'ri ko'rinishi

7. **Negative tests:**
   - Non-admin foydalanuvchi `/dev/knowledge-authoring/` ni ochsa ham, admin endpoint chaqiruvlari 403 qaytarishi kerak (sahifa ochiladi, lekin API ishlamaydi)
   - `DEBUG=False` muhitida `/dev/knowledge-authoring/` 404 qaytarishi kerak
   - `seed_sales_rep_knowledge --organization <noto'g'ri UUID>` — `CommandError` aniq xabar bilan

---

## Mavzular hajmi

- **Seed kontent:** [knowledge-base-sales-rep-seed.py](./knowledge-base-sales-rep-seed.py) — taxminan 1100–1200 qator (mobil dart faylidan 1:1 ko'chirma)
- **Management command:** ~150–200 qator
- **`/dev/` view + URL:** ~70 qator
- **`knowledge_authoring.html` template:** ~3000–3500 qator (eng katta dev sahifa, lekin sodda HTML+CSS+JS)

Backend team 3–5 ish kunlik ishni rejalashtirsa, sifat va testlar bilan bajarish mumkin. Mobile tomoni qo'shimcha o'zgartirishlarni talab qilmaydi — `seed_sales_rep_knowledge` ishga tushgach va `--assign-to-role sales_rep` bilan biriktirilgach, mobil foydalanuvchilari keyingi sync'dan keyin kontentni ko'radi.
