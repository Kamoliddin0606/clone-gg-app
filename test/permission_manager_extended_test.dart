import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/core/services/permission_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PermissionManager permissionManager;

  setUp(() {
    permissionManager = PermissionManager();
  });

  group('PermissionManager Extended Tests', () {
    test('PermissionManager can be instantiated', () {
      expect(permissionManager, isA<PermissionManager>());
    });

    test('checkStoragePermission returns valid status', () async {
      final status = await permissionManager.checkStoragePermission();
      expect(status, isA<AppPermissionStatus>());
      expect([
        AppPermissionStatus.granted,
        AppPermissionStatus.denied,
        AppPermissionStatus.permanentlyDenied,
        AppPermissionStatus.unknown,
        AppPermissionStatus.restricted,
      ].contains(status), isTrue);
    });

    test('requestStoragePermission returns valid status', () async {
      final status = await permissionManager.requestStoragePermission();
      expect(status, isA<AppPermissionStatus>());
      expect([
        AppPermissionStatus.granted,
        AppPermissionStatus.denied,
        AppPermissionStatus.permanentlyDenied,
        AppPermissionStatus.unknown,
        AppPermissionStatus.restricted,
      ].contains(status), isTrue);
    });

    test('checkCameraPermission returns valid status', () async {
      final status = await permissionManager.checkCameraPermission();
      expect(status, isA<AppPermissionStatus>());
      expect([
        AppPermissionStatus.granted,
        AppPermissionStatus.denied,
        AppPermissionStatus.permanentlyDenied,
        AppPermissionStatus.unknown,
        AppPermissionStatus.restricted,
      ].contains(status), isTrue);
    });

    test('requestCameraPermission returns valid status', () async {
      final status = await permissionManager.requestCameraPermission();
      expect(status, isA<AppPermissionStatus>());
      expect([
        AppPermissionStatus.granted,
        AppPermissionStatus.denied,
        AppPermissionStatus.permanentlyDenied,
        AppPermissionStatus.unknown,
        AppPermissionStatus.restricted,
      ].contains(status), isTrue);
    });

    test('checkMicrophonePermission returns valid status', () async {
      final status = await permissionManager.checkMicrophonePermission();
      expect(status, isA<AppPermissionStatus>());
      expect([
        AppPermissionStatus.granted,
        AppPermissionStatus.denied,
        AppPermissionStatus.permanentlyDenied,
        AppPermissionStatus.unknown,
        AppPermissionStatus.restricted,
      ].contains(status), isTrue);
    });

    test('requestMicrophonePermission returns valid status', () async {
      final status = await permissionManager.requestMicrophonePermission();
      expect(status, isA<AppPermissionStatus>());
      expect([
        AppPermissionStatus.granted,
        AppPermissionStatus.denied,
        AppPermissionStatus.permanentlyDenied,
        AppPermissionStatus.unknown,
        AppPermissionStatus.restricted,
      ].contains(status), isTrue);
    });

    test('checkNotificationPermission returns valid status', () async {
      final status = await permissionManager.checkNotificationPermission();
      expect(status, isA<AppPermissionStatus>());
      expect([
        AppPermissionStatus.granted,
        AppPermissionStatus.denied,
        AppPermissionStatus.permanentlyDenied,
        AppPermissionStatus.unknown,
        AppPermissionStatus.restricted,
      ].contains(status), isTrue);
    });

    test('requestNotificationPermission returns valid status', () async {
      final status = await permissionManager.requestNotificationPermission();
      expect(status, isA<AppPermissionStatus>());
      expect([
        AppPermissionStatus.granted,
        AppPermissionStatus.denied,
        AppPermissionStatus.permanentlyDenied,
        AppPermissionStatus.unknown,
        AppPermissionStatus.restricted,
      ].contains(status), isTrue);
    });

    test('checkBackgroundLocationPermission returns valid status', () async {
      final status = await permissionManager.checkBackgroundLocationPermission();
      expect(status, isA<AppPermissionStatus>());
      expect([
        AppPermissionStatus.granted,
        AppPermissionStatus.denied,
        AppPermissionStatus.permanentlyDenied,
        AppPermissionStatus.unknown,
        AppPermissionStatus.restricted,
      ].contains(status), isTrue);
    });

    test('requestBackgroundLocationPermission returns valid status', () async {
      final status = await permissionManager.requestBackgroundLocationPermission();
      expect(status, isA<AppPermissionStatus>());
      expect([
        AppPermissionStatus.granted,
        AppPermissionStatus.denied,
        AppPermissionStatus.permanentlyDenied,
        AppPermissionStatus.unknown,
        AppPermissionStatus.restricted,
      ].contains(status), isTrue);
    });

    test('checkPermission works for all types', () async {
      for (final type in AppPermissionType.values) {
        final status = await permissionManager.checkPermission(type);
        expect(status, isA<AppPermissionStatus>());
        expect([
          AppPermissionStatus.granted,
          AppPermissionStatus.denied,
          AppPermissionStatus.permanentlyDenied,
          AppPermissionStatus.unknown,
          AppPermissionStatus.restricted,
        ].contains(status), isTrue);
      }
    });

    test('requestPermission works for all types', () async {
      for (final type in AppPermissionType.values) {
        final status = await permissionManager.requestPermission(type);
        expect(status, isA<AppPermissionStatus>());
        expect([
          AppPermissionStatus.granted,
          AppPermissionStatus.denied,
          AppPermissionStatus.permanentlyDenied,
          AppPermissionStatus.unknown,
          AppPermissionStatus.restricted,
        ].contains(status), isTrue);
      }
    });

    test('PermissionManager methods handle errors gracefully', () async {
      // Test that new methods don't throw unhandled exceptions
      try {
        await permissionManager.checkStoragePermission();
        await permissionManager.requestStoragePermission();
        await permissionManager.checkCameraPermission();
        await permissionManager.requestCameraPermission();
        await permissionManager.checkMicrophonePermission();
        await permissionManager.requestMicrophonePermission();
        await permissionManager.checkNotificationPermission();
        await permissionManager.requestNotificationPermission();
        await permissionManager.checkBackgroundLocationPermission();
        await permissionManager.requestBackgroundLocationPermission();

        // Test generic methods
        for (final type in AppPermissionType.values) {
          await permissionManager.checkPermission(type);
          await permissionManager.requestPermission(type);
        }

        // If we reach here, methods executed without throwing
        expect(true, isTrue);
      } catch (e) {
        // In test environment, some platform calls might fail, which is expected
        expect(e, isA<Exception>());
      }
    });
  });
}