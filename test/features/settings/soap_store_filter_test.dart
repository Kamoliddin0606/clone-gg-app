import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gloria_marketing_flutter/src/core/auth/backend_permission_store.dart';
import 'package:gloria_marketing_flutter/src/core/auth/permission_codenames.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
// ignore: implementation_imports
import 'package:gloria_marketing_flutter/src/features/agent/data/models/sales_req_permissions.dart';

/// SOAP carve-out for the staff-permissions rework.
///
/// The legacy `SalesReqPermissions` model carries the SOAP settings
/// blob (typed booleans like `editClientCoordinates`). The new
/// backend ships dotted codenames like `customers.change_customer`
/// via `gates.permissions`. The two stores live side-by-side; the
/// rule is that neither writes the other's shape.
///
/// This test enforces the rule on both sides:
///
///   1. `SalesReqPermissions` exposes no field whose JSON name equals
///      a codename in [PermissionCodenames.owned]. (If a SOAP author
///      ever names a field "customers.change_customer" the assertion
///      explodes — that is the entire point.)
///   2. [BackendPermissionStore.replaceFromLogin] drops any string
///      that is NOT in [PermissionCodenames.owned] — so even if a
///      future backend release adds extraneous namespaces to
///      `gates.permissions`, the store stays clean.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SOAP store / backend store carve-out', () {
    test(
        'SalesReqPermissions JSON shape contains no dotted codename '
        'from BackendPermissionStore.ownedCodenames', () {
      // Round-trip a representative SOAP row and inspect the JSON
      // keys. Any collision with the owned set must fail loudly.
      final soapRow = SalesReqPermissions(
        id: 1,
        userCode: 'AGENT-001',
        skipTINduplicateCheck: false,
        allowCreationWithoutTIN: false,
        visit: true,
        strictSequence: false,
        unplannedOrder: true,
        plannedRoute: true,
        editClientCoordinates: false,
        clientZoneAccess: 0,
        locationUpdateInterval: 0,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
        visitSteps: const <VisitStep>[],
      );

      final json = soapRow.toMap();
      final collisions = json.keys
          .where(PermissionCodenames.owned.contains)
          .toSet();
      expect(
        collisions,
        isEmpty,
        reason: 'SOAP settings row leaked a backend codename into its '
            'JSON shape — the two stores must stay disjoint.',
      );
    });

    test(
        'BackendPermissionStore.replaceFromLogin drops any non-owned '
        'codename so the persisted set is exactly the intersection',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferencesService.getInstance();
      final store = BackendPermissionStore(prefs: prefs);

      await store.replaceFromLogin(<String>[
        PermissionCodenames.customerAdd,
        // SOAP-style typed booleans should never appear here — but if
        // they did (misconfiguration), the filter would discard them.
        'editClientCoordinates',
        'visit',
        // Foreign namespaces likewise dropped.
        'users.add_user',
        'inventory.add_warehouse',
        PermissionCodenames.customerChangeCoordinates,
      ]);

      expect(store.all, <String>{
        PermissionCodenames.customerAdd,
        PermissionCodenames.customerChangeCoordinates,
      });
    });
  });
}
