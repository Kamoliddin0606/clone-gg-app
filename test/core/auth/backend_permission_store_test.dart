import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gloria_marketing_flutter/src/core/auth/backend_permission_store.dart';
import 'package:gloria_marketing_flutter/src/core/auth/permission_codenames.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferencesService prefs;
  late BackendPermissionStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferencesService.getInstance();
    // The SharedPreferencesService singleton caches its underlying
    // SharedPreferences instance across tests; `setMockInitialValues`
    // only resets the next-fetched mock backing. To get a guaranteed
    // clean slate per test, wipe the in-process map too.
    await prefs.preferences.clear();
    store = BackendPermissionStore(prefs: prefs);
  });

  group('BackendPermissionStore', () {
    test('replaceFromLogin keeps only owned codenames', () async {
      await store.replaceFromLogin(<String>[
        PermissionCodenames.customerAdd,
        PermissionCodenames.customerChange,
        'users.add_user', // not owned — should be dropped
        'inventory.read_warehouse', // not owned — should be dropped
      ]);

      expect(store.has(PermissionCodenames.customerAdd), isTrue);
      expect(store.has(PermissionCodenames.customerChange), isTrue);
      expect(store.has('users.add_user'), isFalse);
      expect(store.has('inventory.read_warehouse'), isFalse);
      expect(store.all, <String>{
        PermissionCodenames.customerAdd,
        PermissionCodenames.customerChange,
      });
    });

    test('replaceFromLogin overwrites the previous set wholesale',
        () async {
      await store.replaceFromLogin(<String>[
        PermissionCodenames.customerAdd,
        PermissionCodenames.customerChange,
      ]);
      await store.replaceFromLogin(<String>[
        PermissionCodenames.customerChangeCoordinates,
      ]);

      expect(store.has(PermissionCodenames.customerAdd), isFalse);
      expect(store.has(PermissionCodenames.customerChange), isFalse);
      expect(
        store.has(PermissionCodenames.customerChangeCoordinates),
        isTrue,
      );
    });

    test('clear empties the stored set', () async {
      await store.replaceFromLogin(<String>[
        PermissionCodenames.customerAdd,
      ]);
      await store.clear();

      // After clear() with the optimistic flag still on, an empty
      // store reports every codename as granted — that is the
      // documented rollout-window behavior.
      expect(store.has(PermissionCodenames.customerAdd), isTrue);
      // But the underlying disk state is truly empty.
      expect(
        prefs.preferences.getString('backend_permissions_v1'),
        isNull,
      );
    });

    test('empty store reports has() as true under optimistic default',
        () {
      // Fresh store with no replaceFromLogin → empty → optimistic =>
      // every codename granted.
      expect(store.has(PermissionCodenames.customerAdd), isTrue);
      expect(store.has(PermissionCodenames.customerChange), isTrue);
      expect(
        store.has(PermissionCodenames.customerChangeCoordinates),
        isTrue,
      );
    });

    test(
        'after replaceFromLogin([], provided=true) empty store is '
        'pessimistic — has() returns false for every codename', () async {
      // Simulates a backend that explicitly returns an empty
      // `gates.permissions` array (user has no codenames). The
      // optimistic fallback must NOT fire here — that is the gap
      // the `provided` flag closes vs. the rollout-window case.
      await store.replaceFromLogin(const <String>[], provided: true);
      expect(store.has(PermissionCodenames.customerAdd), isFalse);
      expect(store.has(PermissionCodenames.customerChange), isFalse);
      expect(
        store.has(PermissionCodenames.customerChangeCoordinates),
        isFalse,
      );
      expect(
        store.hasAny(PermissionCodenames.customerPhotoAny),
        isFalse,
      );
    });

    test(
        'replaceFromLogin([], provided=false) keeps optimistic '
        'fallback active (rollout window)', () async {
      // Backend has not yet shipped the field — provided=false. The
      // store stays empty but `has()` still falls back to optimistic
      // so existing roles do not regress mid-rollout.
      await store.replaceFromLogin(const <String>[], provided: false);
      expect(store.has(PermissionCodenames.customerAdd), isTrue);
      expect(
        store.hasAny(PermissionCodenames.customerPhotoAny),
        isTrue,
      );
    });

    test('provided flag is sticky across calls', () async {
      // Once any login confirms the field is shipped, a later
      // refresh that somehow omits the field must NOT regress to
      // optimistic — protects against backend response flakiness.
      await store.replaceFromLogin(const <String>[
        PermissionCodenames.customerAdd,
      ], provided: true);
      // Simulate a later refresh that drops the field.
      await store.replaceFromLogin(const <String>[], provided: false);
      // Still pessimistic for missing codenames.
      expect(store.has(PermissionCodenames.customerChange), isFalse);
    });

    test('non-empty store rejects ungranted codenames', () async {
      await store.replaceFromLogin(<String>[
        PermissionCodenames.customerAdd,
      ]);

      expect(store.has(PermissionCodenames.customerAdd), isTrue);
      expect(store.has(PermissionCodenames.customerChange), isFalse);
      expect(
        store.has(PermissionCodenames.customerChangeCoordinates),
        isFalse,
      );
    });

    test('hasAny short-circuits to true under optimistic-empty', () {
      expect(
        store.hasAny(<String>[PermissionCodenames.customerAdd]),
        isTrue,
      );
    });

    test('hasAny returns true on intersection', () async {
      await store.replaceFromLogin(<String>[
        PermissionCodenames.customerChangePhoto,
      ]);
      expect(
        store.hasAny(PermissionCodenames.customerPhotoAny),
        isTrue,
      );
    });

    test('hasAny returns false on no intersection (non-empty)',
        () async {
      await store.replaceFromLogin(<String>[
        PermissionCodenames.customerAdd,
      ]);
      expect(
        store.hasAny(PermissionCodenames.customerPhotoAny),
        isFalse,
      );
    });

    test('persists across store instantiations', () async {
      await store.replaceFromLogin(<String>[
        PermissionCodenames.customerAdd,
      ]);

      // Fresh store reading from the same SharedPreferences instance.
      final reborn = BackendPermissionStore(prefs: prefs);
      expect(reborn.has(PermissionCodenames.customerAdd), isTrue);
      expect(reborn.has(PermissionCodenames.customerChange), isFalse);
    });

    test('ownedCodenames matches PermissionCodenames.owned', () {
      expect(BackendPermissionStore.ownedCodenames,
          equals(PermissionCodenames.owned));
    });

    test('notifies listeners on replaceFromLogin / clear / recordFailure',
        () async {
      var notifyCount = 0;
      store.addListener(() => notifyCount++);

      await store.replaceFromLogin(<String>[
        PermissionCodenames.customerAdd,
      ]);
      expect(notifyCount, 1);

      await store.recordFailure('parse_error');
      expect(notifyCount, 2);

      await store.clear();
      expect(notifyCount, 3);
    });

    test('replaceFromLogin records an OK sync event with count', () async {
      await store.replaceFromLogin(<String>[
        PermissionCodenames.customerAdd,
        PermissionCodenames.customerChange,
      ]);
      final event = store.lastEvent;
      expect(event.status, BackendPermissionSyncStatus.ok);
      expect(event.timestamp, isNotNull);
      expect(event.detail, '2/${PermissionCodenames.owned.length}');
    });

    test('recordFailure persists status + detail without clearing grants',
        () async {
      await store.replaceFromLogin(<String>[
        PermissionCodenames.customerAdd,
      ]);
      await store.recordFailure('parse_error');

      final event = store.lastEvent;
      expect(event.status, BackendPermissionSyncStatus.failed);
      expect(event.detail, 'parse_error');
      // Critical UX rule: a failed refresh must never silently
      // revoke an existing grant.
      expect(store.has(PermissionCodenames.customerAdd), isTrue);
    });

    test('clear resets event to idle', () async {
      await store.replaceFromLogin(<String>[
        PermissionCodenames.customerAdd,
      ]);
      await store.clear();
      final event = store.lastEvent;
      expect(event.status, BackendPermissionSyncStatus.idle);
      expect(event.timestamp, isNull);
      expect(event.detail, isNull);
    });

    test('event survives store re-instantiation', () async {
      await store.replaceFromLogin(<String>[
        PermissionCodenames.customerAdd,
      ]);
      final firstEvent = store.lastEvent;
      final reborn = BackendPermissionStore(prefs: prefs);
      final secondEvent = reborn.lastEvent;
      expect(secondEvent.status, firstEvent.status);
      expect(secondEvent.detail, firstEvent.detail);
      expect(secondEvent.timestamp?.millisecondsSinceEpoch,
          firstEvent.timestamp?.millisecondsSinceEpoch);
    });

    test('disk format is a JSON-encoded sorted list', () async {
      await store.replaceFromLogin(<String>[
        PermissionCodenames.customerChange,
        PermissionCodenames.customerAdd,
      ]);
      final raw = prefs.preferences.getString('backend_permissions_v1');
      expect(raw, isNotNull);
      final decoded = jsonDecode(raw!) as List;
      // Sorted alphabetically — 'add_customer' < 'change_customer'.
      expect(decoded.cast<String>(), <String>[
        PermissionCodenames.customerAdd,
        PermissionCodenames.customerChange,
      ]);
    });
  });
}
