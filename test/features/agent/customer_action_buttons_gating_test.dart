import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gloria_marketing_flutter/src/core/auth/backend_permission_store.dart';
import 'package:gloria_marketing_flutter/src/core/auth/permission_codenames.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';

/// Lightweight gating contract test for the trading-points card
/// action row.
///
/// The full widget tree for `trading_points_page.dart` is too heavy
/// to mount in a unit test (depends on Yandex MapKit, Google Maps,
/// Geolocator, multiple SOAP DAOs, etc.). What matters for the
/// staff-permissions rework is the gate semantics:
///
///   * Edit / coordinates / photos icons all rely on
///     [BackendPermissionStore.has].
///   * Icons render when the codename is granted, hidden entirely
///     otherwise (no greyed-out states — runbook requirement).
///
/// This test pins the contract by exercising the store directly with
/// each gate codename and asserting the boolean outcome. The widget-
/// level rendering is then a straight `if (store.has(...))` per the
/// runbook — verified by inspection in
/// `trading_points_page.dart:_buildActionButtons`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Customer action icon gates (codename → render bool)', () {
    late SharedPreferencesService prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      prefs = await SharedPreferencesService.getInstance();
    });

    test('edit icon: gated on customers.change_customer', () async {
      final store = BackendPermissionStore(prefs: prefs);
      await store.replaceFromLogin(<String>[
        PermissionCodenames.customerChange,
      ]);
      expect(store.has(PermissionCodenames.customerChange), isTrue);

      await store.replaceFromLogin(<String>[
        PermissionCodenames.customerAdd,
      ]);
      expect(store.has(PermissionCodenames.customerChange), isFalse);
    });

    test(
        'coordinates icon: gated on '
        'customers.change_customer_coordinates', () async {
      final store = BackendPermissionStore(prefs: prefs);
      await store.replaceFromLogin(<String>[
        PermissionCodenames.customerChangeCoordinates,
      ]);
      expect(
        store.has(PermissionCodenames.customerChangeCoordinates),
        isTrue,
      );

      await store.replaceFromLogin(<String>[
        PermissionCodenames.customerChange,
      ]);
      expect(
        store.has(PermissionCodenames.customerChangeCoordinates),
        isFalse,
      );
    });

    test(
        'photos entry: gated on any of the four photo codenames '
        '(hasAny)', () async {
      final store = BackendPermissionStore(prefs: prefs);
      await store.replaceFromLogin(<String>[
        PermissionCodenames.customerAddPhoto,
      ]);
      expect(
        store.hasAny(PermissionCodenames.customerPhotoAny),
        isTrue,
      );

      await store.replaceFromLogin(<String>[
        PermissionCodenames.customerChange,
      ]);
      expect(
        store.hasAny(PermissionCodenames.customerPhotoAny),
        isFalse,
      );
    });

    test('FAB (add customer): gated on customers.add_customer', () async {
      final store = BackendPermissionStore(prefs: prefs);
      await store.replaceFromLogin(<String>[
        PermissionCodenames.customerAdd,
      ]);
      expect(store.has(PermissionCodenames.customerAdd), isTrue);

      await store.replaceFromLogin(<String>[
        PermissionCodenames.customerChange,
      ]);
      expect(store.has(PermissionCodenames.customerAdd), isFalse);
    });
  });
}
