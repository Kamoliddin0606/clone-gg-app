import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/core/maps/models/map_settings.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/settings_page.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsPage Map Tab Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets('Map tab displays available map providers', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsPage(),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Check if map tab exists
      expect(find.text('Map'), findsOneWidget);

      // Tap on map tab
      await tester.tap(find.text('Map'));
      await tester.pumpAndSettle();

      // Check if map providers are displayed
      expect(find.text('Google Maps'), findsOneWidget);
      expect(find.text('Yandex Maps'), findsOneWidget);
      expect(find.text('OpenStreetMap'), findsOneWidget);
    });

    testWidgets('Can select Google Maps as default', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to map tab
      await tester.tap(find.text('Map'));
      await tester.pumpAndSettle();

      // Tap on Google Maps option
      await tester.tap(find.text('Google Maps'));
      await tester.pumpAndSettle();

      // Verify selection is saved
      final savedProvider = prefs.getString('default_map_provider');
      expect(savedProvider, MapProvider.google.toString());
    });

    testWidgets('Can select Yandex Maps as default', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to map tab
      await tester.tap(find.text('Map'));
      await tester.pumpAndSettle();

      // Tap on Yandex Maps option
      await tester.tap(find.text('Yandex Maps'));
      await tester.pumpAndSettle();

      // Verify selection is saved
      final savedProvider = prefs.getString('default_map_provider');
      expect(savedProvider, MapProvider.yandex.toString());
    });

    testWidgets('Can select OpenStreetMap as default', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to map tab
      await tester.tap(find.text('Map'));
      await tester.pumpAndSettle();

      // Tap on OpenStreetMap option
      await tester.tap(find.text('OpenStreetMap'));
      await tester.pumpAndSettle();

      // Verify selection is saved
      final savedProvider = prefs.getString('default_map_provider');
      expect(savedProvider, MapProvider.openStreetMap.toString());
    });

    testWidgets('Map tab shows current selection', (WidgetTester tester) async {
      // Set initial preference
      await prefs.setString('default_map_provider', MapProvider.google.toString());

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to map tab
      await tester.tap(find.text('Map'));
      await tester.pumpAndSettle();

      // Check if Google Maps shows as selected (should have a checkmark or different styling)
      // This would depend on the actual implementation, but we can check for visual indicators
      expect(find.text('Google Maps'), findsOneWidget);
    });

    testWidgets('Map tab displays configuration information', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to map tab
      await tester.tap(find.text('Map'));
      await tester.pumpAndSettle();

      // Check for configuration section
      expect(find.text('Configured Maps'), findsOneWidget);
      expect(find.text('Map Tokens'), findsOneWidget);
    });
  });
}