# Visits v2 — Mobile Scope-Cascade & Unplanned RBAC

> **Mobile-side summary** of the 2026-05-17 backend rollout. Pair
> document for the backend passport at
> `SelUp_Backend/docs/integration-prompts/visits-v2-mobile-scope-cascade-passport.md`.
> Mobile work for this contract change lives on branch
> `New_version_with_backend`, R1 pilot ready.

---

## What changed on the wire

`GET /api/mobile/v2/visits/permissions/` now ships three additional
fields. Everything else (`enabled_tasks`, `thresholds`, `task_order`,
`task_required`) stays in the same shape — the values themselves are
now resolved by the backend's `user → project → organization` cascade,
but mobile consumes them exactly the same way.

```jsonc
{
  // ... existing fields unchanged ...
  "flags": {
    "visit_submission_path": "rest_v2",
    "allow_unplanned_visit": true,    // NEW
    "unplanned_only_mode":   false    // NEW
  },
  "resolved_scope": "project"          // NEW — debug-only
}
```

| Field | Type | Mobile use |
|---|---|---|
| `flags.allow_unplanned_visit` | bool | True when user has `visits.add_unplanned_visit` codename. Required to start any visit with `planned_flag=false`. |
| `flags.unplanned_only_mode` | bool | True when no scope level has tasks configured. Visit creation is blocked unless `allow_unplanned_visit=true`. |
| `resolved_scope` | string \| null | Diagnostics. One of `"user"`, `"project"`, `"organization"`, `"none"`. **UI must not branch on this** — Crashlytics tag only. |

Older backend responses (pre-rollout) omit all three. Mobile parser
defaults `allow_unplanned_visit=false`, `unplanned_only_mode=false`,
`resolved_scope=null`, which maps to `VisitMode.plannedOnly` — the
existing pilot flow. Backward-compat is exercised by the contract
regression suite.

---

## The four-mode UX rule

`VisitMode` ([visit_mode.dart](../lib/src/features/visits/domain/entities/visit_mode.dart))
collapses the two flag fields into a single enum the UI branches on:

| `unplannedOnlyMode` | `allowUnplannedVisit` | `VisitMode` | UX |
|---|---|---|---|
| true  | false | `blocked`        | Configuration-missing dialog, no entry buttons |
| false | false | `plannedOnly`    | Standard planned-route flow, radius enforced |
| true  | true  | `unplannedOnly`  | Ad-hoc order entry only, no radius shown |
| false | true  | `both`           | Both entry points present |

Trading-points page enforces this in two spots:

- [`_informVisit`](../lib/src/features/agent/presentation/pages/trading_points_page.dart) — refuses to start a planned visit in `blocked` or `unplannedOnly` modes; surfaces a guard dialog with an admin-action hint.
- [`_createOrder`](../lib/src/features/agent/presentation/pages/trading_points_page.dart) — refuses to start an unplanned visit when `allow_unplanned_visit=false`; surfaces a different guard dialog.

Both guards short-circuit **before** navigating to `VisitSessionPage`,
so backend's 403 `permission_denied` should be a never-happens path
for any mobile build that honours the contract.

---

## Visit history — planned vs unplanned sections

[`VisitListPage`](../lib/src/features/visits/presentation/pages/visit_list_page.dart)
groups the cursor-paginated history into two sections by
`plannedFlag`. Within each section the original chronological order
(newest first) is preserved — the page only groups, never re-sorts.
Empty sections render nothing.

```
📅 Bugungi reja (3)
   • Mijoz A
   • Mijoz B
   • Mijoz C
⚡ Reja tashqari (2)
   • Mijoz X
   • Mijoz Y
```

---

## Geofence visualisation

Already correct in the existing `GeofenceRule.check` ([geofence_rule.dart:54](../lib/src/features/visits/domain/entities/geofence_rule.dart#L54)) — the distance check is gated on
`planned && radiusM > 0`. Unplanned visits skip the distance check
client-side and the backend skips the matching server-side validator,
so no new code was needed for the "no radius circle when unplanned"
rule. The `DistanceValidationDialog` is only invoked from the planned
flow (`_informVisit`), not from `_createOrder`.

---

## Contract-violation telemetry

If the backend ever returns 403 `permission_denied` on a
`POST /visits/finish/`, the contract is broken on the mobile side —
the UI guards above should have stopped that envelope long before
the outbox dispatcher ran. To make the regression visible:

1. `OutboxDispatcher` propagates `httpStatus` and the server `code`
   on `OutboxStatus.deadLettered` events.
2. `VisitsCrashlyticsReporter._logOutbox` watches for
   `kind=dead_lettered` + `http=403` + `code=permission_denied` and
   files a non-fatal `visits.contract_violation.unplanned_403`
   with the envelope ID in the report's reason field.

The non-fatal class is intentionally distinct from generic outbox
breadcrumbs so a flaky uplink can't drown it out. Anything filed
under `visits.contract_violation.unplanned_403` is a bug — the UI
guards leak a case, or permissions cache went stale during a
mid-session role change.

---

## Tests

- [`visit_mode_test.dart`](../test/features/visits/domain/visit_mode_test.dart) — truth table + accessors + backward-compat default.
- [`backend_contract_regression_test.dart`](../test/features/visits/contract/backend_contract_regression_test.dart) — three new cases pin the canonical body shape, the post-rollout body shape, and the `unplanned_only_mode + resolved_scope="none"` shape.
- [`visit_list_separation_test.dart`](../test/features/visits/presentation/visit_list_separation_test.dart) — partitioning by `plannedFlag` + section copy ("Bugungi reja" / "Reja tashqari").

---

## Backward compatibility

| Scenario | Behaviour |
|---|---|
| Older backend (no new flags) | Mobile reads defaults → `plannedOnly` mode → existing pilot flow keeps working. |
| Older mobile vs new backend | Ignores `resolved_scope`, ignores the two new flags. Risk: user can still tap "Buyurtmasiz yakunlash" without the codename — backend returns 403, outbox dead-letters. Single rollout pass closes that gap. |
| Cache stale during role change | Backend changelog § 1 has mobile refresh `/permissions/` on every visit start, so a flag flip propagates within ≤ 1 round-trip rather than waiting for the 1-hour ETag TTL. Crashed envelopes show up in Crashlytics under `visits.contract_violation.unplanned_403`. |

---

## Localisation TODO

The three guard dialogs in [`trading_points_page.dart`](../lib/src/features/agent/presentation/pages/trading_points_page.dart)
ship with hardcoded Uzbek copy. `AppLocalizations` getter additions
(`visitsScopeBlockedTitle/Body`, `visitsPlannedUnavailableTitle/Body`,
`visitsUnplannedNotAllowedTitle/Body`, `commonOk`) land in a follow-up
PR once the pilot agents confirm the wording. The shared
`_showScopeGuardDialog` shell makes the translation rewire a single
swap inside three two-line factories.

---

## References

- Backend passport (this doc's pair): `SelUp_Backend/docs/integration-prompts/visits-v2-mobile-scope-cascade-passport.md`
- Backend promt (execution checklist): `SelUp_Backend/docs/integration-prompts/visits-v2-mobile-scope-cascade-promt.md`
- Previous mobile changelog (v1): `SelUp_Backend/docs/integration-prompts/visits-v2-mobile-changes.md`
- Mobile pilot quickstart: [`visits-v2-pilot-quickstart.md`](visits-v2-pilot-quickstart.md)
- Mobile device smoke matrix: [`visits-v2-device-smoke-test.md`](visits-v2-device-smoke-test.md)
