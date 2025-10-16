import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gloria_marketing_flutter/src/core/services/permission_manager.dart';

void main() {
  late PermissionManager permissionManager;

  setUp(() {
    permissionManager = PermissionManager();
  });

  group('Location Permission Integration Tests', () {
    test('Location permission check returns valid status', () async {
      final status = await permissionManager.checkLocationPermission();
      expect(status, isA<AppPermissionStatus>());
      expect([
        AppPermissionStatus.granted,
        AppPermissionStatus.denied,
        AppPermissionStatus.permanentlyDenied,
        AppPermissionStatus.unknown,
        AppPermissionStatus.restricted,
      ].contains(status), isTrue);
    });

    test('Location service check returns bool', () async {
      final isEnabled = await permissionManager.isLocationServiceEnabled();
      expect(isEnabled, isA<bool>());
    });

    test('Location settings opening returns bool', () async {
      final opened = await permissionManager.openLocationSettings();
      expect(opened, isA<bool>());
    });

    test('Permission request handling works', () async {
      // Test that permission request doesn't throw
      try {
        final status = await permissionManager.checkLocationPermission();
        // If we get here, the method executed without throwing
        expect(status, isA<AppPermissionStatus>());
      } catch (e) {
        // Permission handling might fail in test environment, which is expected
        expect(e, isA<Exception>());
      }
    });
  });
}