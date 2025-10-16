import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/trading_points_page.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart' as model;
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/repositories/agent_repository.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

// Generate mocks
@GenerateMocks([SharedPreferencesService, AgentRepository])
import 'trading_points_page_test.mocks.dart';

void main() {
  late MockSharedPreferencesService mockPrefs;
  late MockAgentRepository mockRepository;

  setUp(() {
    mockPrefs = MockSharedPreferencesService();
    mockRepository = MockAgentRepository();

    // Setup service locator
    sl.registerSingleton<SharedPreferencesService>(mockPrefs);
    sl.registerSingleton<AgentRepository>(mockRepository);
  });

  tearDown(() {
    sl.reset();
  });

  group('TradingPointsPage', () {
    testWidgets('should display loading indicator initially', (WidgetTester tester) async {
      // Arrange
      when(mockPrefs.getUserCode()).thenReturn('test_user');
      when(mockPrefs.getPassword()).thenReturn('test_pass');

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: TradingPointsPage(),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display empty state when no trading points', (WidgetTester tester) async {
      // Arrange
      when(mockPrefs.getUserCode()).thenReturn('test_user');
      when(mockPrefs.getPassword()).thenReturn('test_pass');
      when(mockRepository.getClients(userCode: 'test_user', password: 'test_pass'))
          .thenAnswer((_) async => []);
      when(mockRepository.getCachedBusinessRegions()).thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: TradingPointsPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Savdo nuqtalari topilmadi'), findsOneWidget);
    });

    testWidgets('should handle PageStorage key conflicts properly', (WidgetTester tester) async {
      // Arrange
      final testTradingPoint = model.TradingPoint(
        id: '1',
        name: 'Test Store',
        address: 'Test Address',
        phone: '+998901234567',
        ownerName: 'Test Owner',
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

      when(mockPrefs.getUserCode()).thenReturn('test_user');
      when(mockPrefs.getPassword()).thenReturn('test_pass');
      when(mockRepository.getClients(userCode: 'test_user', password: 'test_pass'))
          .thenAnswer((_) async => [testTradingPoint]);
      when(mockRepository.getCachedBusinessRegions()).thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: TradingPointsPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Test that ListView has separate PageStorageKey for scroll
      final listView = find.byType(ListView);
      expect(listView, findsOneWidget);

      // Test that ExpansionTile has separate PageStorageKey for expansion state
      final expansionTile = find.byType(ExpansionTile);
      expect(expansionTile, findsOneWidget);

      // Verify no type cast errors occur during scrolling and expansion
      // This test ensures the PageStorage keys are properly separated
      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle();

      // Should not throw any exceptions
      expect(tester.takeException(), isNull);
    });

    testWidgets('should display trading points in list view', (WidgetTester tester) async {
      // Arrange
      final testTradingPoint = model.TradingPoint(
        id: '1',
        name: 'Test Store',
        address: 'Test Address',
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

      when(mockPrefs.getUserCode()).thenReturn('test_user');
      when(mockPrefs.getPassword()).thenReturn('test_pass');
      when(mockRepository.getClients(userCode: 'test_user', password: 'test_pass'))
          .thenAnswer((_) async => [testTradingPoint]);
      when(mockRepository.getCachedBusinessRegions()).thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: TradingPointsPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Test Store'), findsOneWidget);
      expect(find.text('Test Address'), findsOneWidget);
    });

    testWidgets('should handle search functionality', (WidgetTester tester) async {
      // Arrange
      final testTradingPoint1 = model.TradingPoint(
        id: '1',
        name: 'Apple Store',
        address: 'Apple Address',
        phone: '+998901234567',
        contactPerson: 'Apple Person',
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

      final testTradingPoint2 = model.TradingPoint(
        id: '2',
        name: 'Banana Store',
        address: 'Banana Address',
        phone: '+998907654321',
        contactPerson: 'Banana Person',
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
          .thenAnswer((_) async => [testTradingPoint1, testTradingPoint2]);
      when(mockRepository.getCachedBusinessRegions()).thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: TradingPointsPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Search for "Apple"
      await tester.enterText(find.byType(TextField), 'Apple');
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Apple Store'), findsOneWidget);
      expect(find.text('Banana Store'), findsNothing);
    });

    testWidgets('should handle PageStorage key conflicts properly', (WidgetTester tester) async {
      // Arrange
      final testTradingPoint = model.TradingPoint(
        id: '1',
        name: 'Test Store',
        address: 'Test Address',
        phone: '+998901234567',
        ownerName: 'Test Owner',
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

      when(mockPrefs.getUserCode()).thenReturn('test_user');
      when(mockPrefs.getPassword()).thenReturn('test_pass');
      when(mockRepository.getClients(userCode: 'test_user', password: 'test_pass'))
          .thenAnswer((_) async => [testTradingPoint]);
      when(mockRepository.getCachedBusinessRegions()).thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: TradingPointsPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Test that ListView has separate PageStorageKey for scroll
      final listView = find.byType(ListView);
      expect(listView, findsOneWidget);

      // Test that ExpansionTile has separate PageStorageKey for expansion state
      final expansionTile = find.byType(ExpansionTile);
      expect(expansionTile, findsOneWidget);

      // Verify no type cast errors occur during scrolling and expansion
      // This test ensures the PageStorage keys are properly separated
      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle();

      // Should not throw any exceptions
      expect(tester.takeException(), isNull);
    });

    testWidgets('should switch between list and grid view', (WidgetTester tester) async {
      // Arrange
      final testTradingPoint = model.TradingPoint(
        id: '1',
        name: 'Test Store',
        address: 'Test Address',
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

      when(mockPrefs.getUserCode()).thenReturn('test_user');
      when(mockPrefs.getPassword()).thenReturn('test_pass');
      when(mockRepository.getClients(userCode: 'test_user', password: 'test_pass'))
          .thenAnswer((_) async => [testTradingPoint]);
      when(mockRepository.getCachedBusinessRegions()).thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: TradingPointsPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Initially should be in list view
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(GridView), findsNothing);

      // Tap the tune button to show view toolbar
      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();

      // Switch to grid view
      await tester.tap(find.byIcon(Icons.grid_view_rounded));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(ListView), findsNothing);
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('should handle call functionality', (WidgetTester tester) async {
      // Arrange
      final testTradingPoint = model.TradingPoint(
        id: '1',
        name: 'Test Store',
        address: 'Test Address',
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

      when(mockPrefs.getUserCode()).thenReturn('test_user');
      when(mockPrefs.getPassword()).thenReturn('test_pass');
      when(mockRepository.getClients(userCode: 'test_user', password: 'test_pass'))
          .thenAnswer((_) async => [testTradingPoint]);
      when(mockRepository.getCachedBusinessRegions()).thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: TradingPointsPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Expand the trading point card
      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle();

      // Find and tap the phone number (should be clickable)
      final phoneText = find.text('+998901234567');
      expect(phoneText, findsOneWidget);

      // Note: We can't easily test url_launcher in unit tests,
      // but we can verify the UI renders correctly
    });

    testWidgets('should handle refresh functionality', (WidgetTester tester) async {
      // Arrange
      final testTradingPoint = model.TradingPoint(
        id: '1',
        name: 'Test Store',
        address: 'Test Address',
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

      when(mockPrefs.getUserCode()).thenReturn('test_user');
      when(mockPrefs.getPassword()).thenReturn('test_pass');
      when(mockRepository.getClients(userCode: 'test_user', password: 'test_pass'))
          .thenAnswer((_) async => [testTradingPoint]);
      when(mockRepository.getCachedBusinessRegions()).thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: TradingPointsPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify initial load
      expect(find.text('Test Store'), findsOneWidget);

      // Trigger refresh by pulling down
      await tester.drag(find.byType(ListView), const Offset(0, 300));
      await tester.pumpAndSettle();

      // Verify repository was called again
      verify(mockRepository.getClients(userCode: 'test_user', password: 'test_pass')).called(2);
    });
  });
}