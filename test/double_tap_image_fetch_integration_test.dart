import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/trading_points_page.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart' as model;
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/repositories/agent_repository.dart';
import 'package:gloria_marketing_flutter/src/core/services/thumbnail_image_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/permission_manager.dart';
import 'package:gloria_marketing_flutter/src/core/services/location_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/core/maps/services/map_cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

// Generate mocks
@GenerateMocks([
  SharedPreferencesService,
  AgentRepository,
  ThumbnailImageService,
  PermissionManager,
  LocationService,
  DataSyncService,
  ApiDatabaseService,
  MapCacheService,
  SharedPreferences,
])
import 'double_tap_image_fetch_integration_test.mocks.dart';

/// Integration test for double-tap image fetching functionality
/// This test verifies the end-to-end flow of double-tapping a client card
/// to fetch images and display them in the client details
void main() {
  late MockSharedPreferencesService mockPrefs;
  late MockAgentRepository mockRepository;
  late MockThumbnailImageService mockThumbnailService;
  late MockPermissionManager mockPermissionManager;
  late MockLocationService mockLocationService;
  late MockDataSyncService mockDataSyncService;
  late MockApiDatabaseService mockApiDatabaseService;
  late MockMapCacheService mockMapCacheService;
  late MockSharedPreferences mockSharedPreferences;

  setUp(() {
    mockPrefs = MockSharedPreferencesService();
    mockRepository = MockAgentRepository();
    mockThumbnailService = MockThumbnailImageService();
    mockPermissionManager = MockPermissionManager();
    mockLocationService = MockLocationService();
    mockDataSyncService = MockDataSyncService();
    mockApiDatabaseService = MockApiDatabaseService();
    mockMapCacheService = MockMapCacheService();
    mockSharedPreferences = MockSharedPreferences();

    // Setup service locator with all required services
    sl.registerSingleton<SharedPreferencesService>(mockPrefs);
    sl.registerSingleton<AgentRepository>(mockRepository);
    sl.registerSingleton<ThumbnailImageService>(mockThumbnailService);
    sl.registerSingleton<PermissionManager>(mockPermissionManager);
    sl.registerSingleton<LocationService>(mockLocationService);
    sl.registerSingleton<DataSyncService>(mockDataSyncService);
    sl.registerSingleton<ApiDatabaseService>(mockApiDatabaseService);
    sl.registerSingleton<MapCacheService>(mockMapCacheService);

    // Setup basic stubs for initialization
    when(mockPermissionManager.checkLocationPermission()).thenAnswer((_) async => AppPermissionStatus.granted);
    when(mockLocationService.ensureTrackingStarted()).thenAnswer((_) async {});
    when(mockMapCacheService.initialize()).thenAnswer((_) async {});
    when(mockPrefs.preferences).thenReturn(mockSharedPreferences);
    when(mockSharedPreferences.getString('default_map_provider')).thenReturn('google');
  });

  tearDown(() {
    sl.reset();
  });

  group('Double-tap Image Fetch Integration', () {
    testWidgets('should fetch and display client images on double-tap', (WidgetTester tester) async {
      // Arrange
      final testTradingPoint = model.TradingPoint(
        id: 'test_client_123',
        name: 'Test Client Store',
        address: 'Test Address 123',
        phone: '+998901234567',
        ownerName: 'Test Owner',
        contactPerson: 'Test Person',
        inn: '123456789',
        status: 'active',
        lastVisitDate: '',
        hasOrders: false,
        hasContracts: false,
        isVisited: false,
        hasContract: false,
        latitude: 41.2995,
        longitude: 69.2401,
        region: 'Tashkent',
        district: 'Yunusabad',
        signboard: '',
        referencePoint: '',
        responsiblePerson: '',
        responsiblePersonPhone: '',
        tradePointType: '',
        creditLimit: 0.0,
        accumulatedCredit: 0.0,
        codeRegion: '01',
      );

      // Mock initial setup
      when(mockPrefs.getUserCode()).thenReturn('test_user');
      when(mockPrefs.getPassword()).thenReturn('test_pass');
      when(mockRepository.getClients(userCode: 'test_user', password: 'test_pass'))
          .thenAnswer((_) async => [testTradingPoint]);
      when(mockRepository.getCachedBusinessRegions()).thenAnswer((_) async => []);

      // Mock no cached images initially
      when(mockThumbnailService.getClientImages('test_client_123')).thenAnswer((_) async => []);

      // Mock successful image fetch
      when(mockThumbnailService.fetchAndSaveClientImages('test_client_123')).thenAnswer((_) async {});

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: TradingPointsPage(),
        ),
      );

      // Wait for initial load
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify client card is displayed
      expect(find.text('Test Client Store'), findsOneWidget);

      // Find the TradingPointCard
      final cardFinder = find.byType(TradingPointCard);
      expect(cardFinder, findsOneWidget);

      // Perform double-tap
      await tester.tap(cardFinder);
      await tester.tap(cardFinder);
      await tester.pumpAndSettle();

      // Verify that image fetching methods were called
      verify(mockThumbnailService.getClientImages('test_client_123')).called(1);
      verify(mockThumbnailService.fetchAndSaveClientImages('test_client_123')).called(1);

      // Verify that details page opens (bottom sheet should be present)
      // Note: In integration test, we verify the behavior rather than UI details
    });

    testWidgets('should handle image fetch errors gracefully', (WidgetTester tester) async {
      // Arrange
      final testTradingPoint = model.TradingPoint(
        id: 'error_client_456',
        name: 'Error Client Store',
        address: 'Error Address 456',
        phone: '+998907654321',
        ownerName: 'Error Owner',
        contactPerson: 'Error Person',
        inn: '987654321',
        status: 'active',
        lastVisitDate: '',
        hasOrders: false,
        hasContracts: false,
        isVisited: false,
        hasContract: false,
        latitude: 41.2995,
        longitude: 69.2401,
        region: 'Tashkent',
        district: 'Yunusabad',
        signboard: '',
        referencePoint: '',
        responsiblePerson: '',
        responsiblePersonPhone: '',
        tradePointType: '',
        creditLimit: 0.0,
        accumulatedCredit: 0.0,
        codeRegion: '01',
      );

      when(mockPrefs.getUserCode()).thenReturn('test_user');
      when(mockPrefs.getPassword()).thenReturn('test_pass');
      when(mockRepository.getClients(userCode: 'test_user', password: 'test_pass'))
          .thenAnswer((_) async => [testTradingPoint]);
      when(mockRepository.getCachedBusinessRegions()).thenAnswer((_) async => []);

      // Mock no cached images and fetch error
      when(mockThumbnailService.getClientImages('error_client_456')).thenAnswer((_) async => []);
      when(mockThumbnailService.fetchAndSaveClientImages('error_client_456'))
          .thenThrow(Exception('Network error'));

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: TradingPointsPage(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Perform double-tap
      final cardFinder = find.byType(TradingPointCard);
      await tester.tap(cardFinder);
      await tester.tap(cardFinder);
      await tester.pumpAndSettle();

      // Verify error handling - methods were called but details still open
      verify(mockThumbnailService.getClientImages('error_client_456')).called(1);
      verify(mockThumbnailService.fetchAndSaveClientImages('error_client_456')).called(1);

      // Client details should still be accessible despite image fetch error
      expect(find.text('Error Client Store'), findsOneWidget);
    });

    testWidgets('should use cached images when available', (WidgetTester tester) async {
      // Arrange
      final testTradingPoint = model.TradingPoint(
        id: 'cached_client_789',
        name: 'Cached Client Store',
        address: 'Cached Address 789',
        phone: '+998905556667',
        ownerName: 'Cached Owner',
        contactPerson: 'Cached Person',
        inn: '555666777',
        status: 'active',
        lastVisitDate: '',
        hasOrders: false,
        hasContracts: false,
        isVisited: false,
        hasContract: false,
        latitude: 41.2995,
        longitude: 69.2401,
        region: 'Tashkent',
        district: 'Yunusabad',
        signboard: '',
        referencePoint: '',
        responsiblePerson: '',
        responsiblePersonPhone: '',
        tradePointType: '',
        creditLimit: 0.0,
        accumulatedCredit: 0.0,
        codeRegion: '01',
      );

      when(mockPrefs.getUserCode()).thenReturn('test_user');
      when(mockPrefs.getPassword()).thenReturn('test_pass');
      when(mockRepository.getClients(userCode: 'test_user', password: 'test_pass'))
          .thenAnswer((_) async => [testTradingPoint]);
      when(mockRepository.getCachedBusinessRegions()).thenAnswer((_) async => []);

      // Mock cached images available
      final cachedImages = [
        ClientImage(
          clientCode: 'cached_client_789',
          imageUrl: 'http://example.com/cached_image.jpg',
          isMain: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      when(mockThumbnailService.getClientImages('cached_client_789')).thenAnswer((_) async => cachedImages);

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: TradingPointsPage(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Perform double-tap
      final cardFinder = find.byType(TradingPointCard);
      await tester.tap(cardFinder);
      await tester.tap(cardFinder);
      await tester.pumpAndSettle();

      // Verify cached images were used (no server fetch)
      verify(mockThumbnailService.getClientImages('cached_client_789')).called(1);
      verifyNever(mockThumbnailService.fetchAndSaveClientImages('cached_client_789'));
    });
  });
}