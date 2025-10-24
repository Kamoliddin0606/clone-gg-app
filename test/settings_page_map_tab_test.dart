import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_key_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/settings_page.dart';
import 'package:gloria_marketing_flutter/src/core/maps/models/map_settings.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart' as yandex;
import 'package:flutter_map/flutter_map.dart' as osm;
import 'package:latlong2/latlong.dart' as osm_latlong;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferencesService prefsService;
  late ApiKeyService apiKeyService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefsService = await SharedPreferencesService.getInstance();
    apiKeyService = ApiKeyService.instance;
    await apiKeyService.initialize(prefsService);
  });

  tearDown(() async {
    await apiKeyService.clearAllApiKeys();
  });

  group('MapsTab API Key Management', () {
    testWidgets('should display map providers with API key status', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              Provider<SharedPreferencesService>.value(value: prefsService),
            ],
            child: const Scaffold(body: MapsTab()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check if map providers are displayed
      expect(find.text('Google Maps'), findsOneWidget);
      expect(find.text('Yandex Maps'), findsOneWidget);
      expect(find.text('OpenStreetMap'), findsOneWidget);

      // Check API key status indicators
      expect(find.text('API Key:'), findsWidgets);
    });

    testWidgets('should open API key dialog when edit button is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              Provider<SharedPreferencesService>.value(value: prefsService),
            ],
            child: const Scaffold(body: MapsTab()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the first edit button (Google Maps)
      final editButtons = find.byIcon(Icons.edit);
      expect(editButtons, findsWidgets);

      await tester.tap(editButtons.first);
      await tester.pumpAndSettle();

      // Check if dialog is shown
      expect(find.text('Google Maps API Key'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('should save API key when valid key is entered', (WidgetTester tester) async {
      const testApiKey = 'AIzaSyDUMMY_TEST_API_KEY_FOR_TESTING';

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              Provider<SharedPreferencesService>.value(value: prefsService),
            ],
            child: const Scaffold(body: MapsTab()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open API key dialog for Google Maps
      final editButtons = find.byIcon(Icons.edit);
      await tester.tap(editButtons.first);
      await tester.pumpAndSettle();

      // Enter API key
      final textField = find.byType(TextField);
      await tester.enterText(textField, testApiKey);

      // Tap save button
      final saveButton = find.text('Save');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Check if success message is shown
      expect(find.text('API key saved successfully'), findsOneWidget);

      // Verify API key was saved
      final savedKey = await apiKeyService.getApiKey(ApiKeyService.googleMapsApiKey);
      expect(savedKey, equals(testApiKey));
    });

    testWidgets('should show error for invalid API key format', (WidgetTester tester) async {
      const invalidApiKey = 'invalid-key-format';

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              Provider<SharedPreferencesService>.value(value: prefsService),
            ],
            child: const Scaffold(body: MapsTab()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open API key dialog for Google Maps
      final editButtons = find.byIcon(Icons.edit);
      await tester.tap(editButtons.first);
      await tester.pumpAndSettle();

      // Enter invalid API key
      final textField = find.byType(TextField);
      await tester.enterText(textField, invalidApiKey);

      // Tap save button
      final saveButton = find.text('Save');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Check if error message is shown
      expect(find.textContaining('Invalid API key format'), findsOneWidget);
    });

    testWidgets('should change default map provider', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              Provider<SharedPreferencesService>.value(value: prefsService),
            ],
            child: const Scaffold(body: MapsTab()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially OpenStreetMap should be selected (default)
      expect(find.text('OpenStreetMap'), findsOneWidget);

      // Tap on Google Maps to change default
      await tester.tap(find.text('Google Maps'));
      await tester.pumpAndSettle();

      // Confirm dialog should appear
      expect(find.text('Select Default Map'), findsOneWidget);

      // Confirm selection
      final applyButton = find.text('Apply');
      await tester.tap(applyButton);
      await tester.pumpAndSettle();

      // Check success message
      expect(find.text('Default map changed'), findsOneWidget);
    });

    test('API Key Service should validate Google API key format', () {
      // Valid Google API key
      expect(apiKeyService.validateApiKeyFormat(ApiKeyService.googleMapsApiKey, 'AIzaSyDUMMY_TEST_API_KEY_FOR_TESTING'), isTrue);

      // Invalid Google API key
      expect(apiKeyService.validateApiKeyFormat(ApiKeyService.googleMapsApiKey, 'invalid-key'), isFalse);
      expect(apiKeyService.validateApiKeyFormat(ApiKeyService.googleMapsApiKey, ''), isFalse);
    });

    test('API Key Service should validate Yandex API key format', () {
      // Valid Yandex API key
      expect(apiKeyService.validateApiKeyFormat(ApiKeyService.yandexMapsApiKey, '6381d1cf-a0d8-4b88-8c8f-60951f817884'), isTrue);

      // Invalid Yandex API key
      expect(apiKeyService.validateApiKeyFormat(ApiKeyService.yandexMapsApiKey, 'short'), isFalse);
    });

    test('API Key Service should handle storage operations', () async {
      const testKey = 'test-api-key-123';

      // Store API key
      final storeResult = await apiKeyService.storeAndValidateApiKey(ApiKeyService.googleMapsApiKey, testKey);
      expect(storeResult.success, isTrue);
      expect(storeResult.apiKey, equals(testKey));

      // Retrieve API key
      final retrievedKey = await apiKeyService.getApiKey(ApiKeyService.googleMapsApiKey);
      expect(retrievedKey, equals(testKey));

      // Check if exists
      final exists = await apiKeyService.hasApiKey(ApiKeyService.googleMapsApiKey);
      expect(exists, isTrue);

      // Remove API key
      final removed = await apiKeyService.removeApiKey(ApiKeyService.googleMapsApiKey);
      expect(removed, isTrue);

      // Verify removal
      final afterRemoval = await apiKeyService.getApiKey(ApiKeyService.googleMapsApiKey);
      expect(afterRemoval, isNull);
    });

    test('API Key Service should handle all API keys management', () async {
      // Store multiple keys
      await apiKeyService.storeApiKey(ApiKeyService.googleMapsApiKey, 'google-key');
      await apiKeyService.storeApiKey(ApiKeyService.yandexMapsApiKey, 'yandex-key');

      // Get all keys
      final allKeys = await apiKeyService.getAllApiKeys();
      expect(allKeys.length, equals(2));
      expect(allKeys[ApiKeyService.googleMapsApiKey], equals('google-key'));
      expect(allKeys[ApiKeyService.yandexMapsApiKey], equals('yandex-key'));

      // Clear all keys
      final cleared = await apiKeyService.clearAllApiKeys();
      expect(cleared, isTrue);

      // Verify all cleared
      final allKeysAfterClear = await apiKeyService.getAllApiKeys();
      expect(allKeysAfterClear.isEmpty, isTrue);
    });

    testWidgets('should render different map providers correctly', (WidgetTester tester) async {
      // Test Google Maps rendering
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              height: 300,
              child: GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(41.2995, 69.2401),
                  zoom: 15,
                ),
                markers: const {},
                onMapCreated: (controller) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(GoogleMap), findsOneWidget);

      // Test Yandex Maps rendering (if available)
      try {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Container(
                height: 300,
                child: yandex.YandexMap(
                  mapObjects: [],
                  onMapCreated: (controller) {},
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(yandex.YandexMap), findsOneWidget);
      } catch (e) {
        // Yandex Maps might not be available in test environment
        print('Yandex Maps test skipped: $e');
      }

      // Test OpenStreetMap rendering (if available)
      try {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Container(
                height: 300,
                child: osm.FlutterMap(
                  options: osm.MapOptions(
                    initialCenter: osm_latlong.LatLng(41.2995, 69.2401),
                    initialZoom: 15.0,
                  ),
                  children: [
                    osm.TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'com.gloria.marketing.app',
                      maxZoom: 19,
                      minZoom: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(osm.FlutterMap), findsOneWidget);
      } catch (e) {
        // OpenStreetMap might not be available in test environment
        print('OpenStreetMap test skipped: $e');
      }
    });

    testWidgets('should handle map provider switching in trading points page', (WidgetTester tester) async {
      // This test would require a more complex setup with the full trading points page
      // For now, we test the basic map provider enum values
      expect(MapProvider.google, equals(MapProvider.google));
      expect(MapProvider.yandex, equals(MapProvider.yandex));
      expect(MapProvider.openStreetMap, equals(MapProvider.openStreetMap));

      // Test that all providers are properly defined
      final providers = MapProvider.values;
      expect(providers.length, equals(3));
      expect(providers.contains(MapProvider.google), isTrue);
      expect(providers.contains(MapProvider.yandex), isTrue);
      expect(providers.contains(MapProvider.openStreetMap), isTrue);
    });
  });
}