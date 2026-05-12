import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/core/auth/permission_codenames.dart';

void main() {
  group('PermissionCodenames', () {
    test('exposes the four customer-photo dotted codenames', () {
      expect(PermissionCodenames.customerAddPhoto,
          'customers.add_customer_photo');
      expect(PermissionCodenames.customerChangePhoto,
          'customers.change_customer_photo');
      expect(PermissionCodenames.customerDeletePhoto,
          'customers.delete_customer_photo');
      expect(PermissionCodenames.customerReplacePhoto,
          'customers.replace_customer_photo');
    });

    test('customerPhotoAny lists exactly the four codenames', () {
      expect(
        PermissionCodenames.customerPhotoAny,
        containsAll(<String>[
          PermissionCodenames.customerAddPhoto,
          PermissionCodenames.customerChangePhoto,
          PermissionCodenames.customerDeletePhoto,
          PermissionCodenames.customerReplacePhoto,
        ]),
      );
      expect(PermissionCodenames.customerPhotoAny.length, 4);
    });
  });

  group('PermissionCheck.has', () {
    test('returns true for an empty list while optimistic default is on', () {
      // Optimistic default is on while backend roll-out is in progress.
      expect(<String>[].has(PermissionCodenames.customerAddPhoto), isTrue);
    });

    test('returns true when the codename is explicitly present', () {
      final perms = <String>[
        PermissionCodenames.customerAddPhoto,
        PermissionCodenames.customerDeletePhoto,
      ];
      expect(perms.has(PermissionCodenames.customerAddPhoto), isTrue);
      expect(perms.has(PermissionCodenames.customerDeletePhoto), isTrue);
    });

    test('returns false when the codename is absent from a non-empty list',
        () {
      final perms = <String>[PermissionCodenames.customerAddPhoto];
      expect(perms.has(PermissionCodenames.customerDeletePhoto), isFalse);
      expect(perms.has(PermissionCodenames.customerReplacePhoto), isFalse);
    });
  });

  group('PermissionCheck.hasAny', () {
    test('returns true for empty list under optimistic default', () {
      expect(
        <String>[].hasAny(PermissionCodenames.customerPhotoAny),
        isTrue,
      );
    });

    test('returns true if at least one codename matches', () {
      final perms = <String>[PermissionCodenames.customerChangePhoto];
      expect(perms.hasAny(PermissionCodenames.customerPhotoAny), isTrue);
    });

    test('returns false when none of the codenames match', () {
      final perms = <String>['some.unrelated_perm'];
      expect(perms.hasAny(PermissionCodenames.customerPhotoAny), isFalse);
    });
  });
}
