import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/core/services/permission_manager.dart';
import 'package:gloria_marketing_flutter/src/core/widgets/permission_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Permission Dialog Integration Tests', () {
    testWidgets('PermissionWarningDialog displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PermissionWarningDialog(),
          ),
        ),
      );

      // Check if the dialog title is displayed
      expect(find.text('Ruxsatlar tekshiruvi'), findsOneWidget);

      // Check if permission items are displayed
      expect(find.text('Fayl saqlash'), findsOneWidget);
      expect(find.text('Joylashuv'), findsOneWidget);
      expect(find.text('Kamera'), findsOneWidget);
      expect(find.text('Mikrofon'), findsOneWidget);
      expect(find.text('Bildirishnomalar'), findsOneWidget);

      // Check if the start button is present
      expect(find.text('Boshlash'), findsOneWidget);
    });

    testWidgets('PermissionWarningDialog start button works', (WidgetTester tester) async {
      bool dialogClosed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (context) => const PermissionWarningDialog(),
                  );
                  dialogClosed = result == true;
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Tap the button to show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Tap the start button
      await tester.tap(find.text('Boshlash'));
      await tester.pumpAndSettle();

      expect(dialogClosed, isTrue);
    });

    testWidgets('ComprehensivePermissionDialog initializes correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ComprehensivePermissionDialog(),
          ),
        ),
      );

      // The dialog should show loading initially
      expect(find.text('Tekshirilmoqda...'), findsOneWidget);
    });

    testWidgets('RequiredPermission data class works correctly', (WidgetTester tester) async {
      const permission = RequiredPermission(
        type: AppPermissionType.storage,
        title: 'Test Permission',
        description: 'Test Description',
        purpose: 'Test Purpose',
        isRequired: true,
      );

      expect(permission.type, equals(AppPermissionType.storage));
      expect(permission.title, equals('Test Permission'));
      expect(permission.description, equals('Test Description'));
      expect(permission.purpose, equals('Test Purpose'));
      expect(permission.isRequired, isTrue);
    });

    testWidgets('AppPermissionType enum has all required values', (WidgetTester tester) async {
      expect(AppPermissionType.values.length, equals(6));
      expect(AppPermissionType.storage, isNotNull);
      expect(AppPermissionType.location, isNotNull);
      expect(AppPermissionType.locationAlways, isNotNull);
      expect(AppPermissionType.camera, isNotNull);
      expect(AppPermissionType.microphone, isNotNull);
      expect(AppPermissionType.notification, isNotNull);
    });

    testWidgets('AppPermissionStatus enum has all required values', (WidgetTester tester) async {
      expect(AppPermissionStatus.values.length, equals(5));
      expect(AppPermissionStatus.granted, isNotNull);
      expect(AppPermissionStatus.denied, isNotNull);
      expect(AppPermissionStatus.permanentlyDenied, isNotNull);
      expect(AppPermissionStatus.restricted, isNotNull);
      expect(AppPermissionStatus.unknown, isNotNull);
    });
  });
}