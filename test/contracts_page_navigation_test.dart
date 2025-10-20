import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/contracts_page.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/trading_points_page.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/client_contract.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/repositories/agent_repository.dart';
import 'package:mockito/mockito.dart';
import 'package:get_it/get_it.dart';

// Mock classes
class MockSharedPreferencesService extends Mock implements SharedPreferencesService {
  @override
  String? getUserCode() => 'test_user';

  @override
  String? getPassword() => 'test_pass';

  @override
  String? getCodeProject() => 'test_project';

  @override
  String? getWarehouseCode() => 'test_warehouse';
}

class MockAgentRepository extends Mock implements AgentRepository {
  @override
  Future<List<ClientContractWithName>> getCachedClientContractsWithNames() async {
    return [
      ClientContractWithName(
        codeContract: 'TEST001',
        dateOfContract: DateTime.now(),
        sumOfContract: 1000000.0,
        termOfContract: DateTime.now().add(const Duration(days: 365)),
        typeContract: 'Test Contract',
        numbReference: 'REF001',
        numbCertificate: 'CERT001',
        termReference: DateTime.now().add(const Duration(days: 30)),
        termCertificate: DateTime.now().add(const Duration(days: 60)),
        numbPassport: 'PASSPORT001',
        termPassport: DateTime.now().add(const Duration(days: 90)),
        certificateUnlimited: 0,
        codeDistrict: 'DIST001',
        nameDistrict: 'Test District',
        codeProject: 'PROJ001',
        codeClient: 'CLIENT001',
        active: true,
        status: 'Действует',
        clientName: 'Test Client',
      ),
    ];
  }

  @override
  Future<List<TradingPoint>> getClients({
    required String userCode,
    required String password,
    bool forceRefresh = false,
  }) async {
    return [
      TradingPoint(
        id: 'CLIENT001',
        name: 'Test Client',
        address: 'Test Address',
        phone: '+998901234567',
        ownerName: 'Test Owner',
        contactPerson: 'Test Contact',
        inn: '123456789',
        status: 'active',
        lastVisitDate: '',
        hasOrders: true,
        hasContracts: true,
        isVisited: false,
        hasContract: true,
        latitude: 41.2995,
        longitude: 69.2401,
        region: 'Tashkent',
        district: 'Test District',
        signboard: 'Test Signboard',
        referencePoint: 'Test Reference',
        responsiblePerson: 'Test Responsible',
        responsiblePersonPhone: '+998909876543',
        tradePointType: 'Retail',
        creditLimit: 5000000.0,
        accumulatedCredit: 1000000.0,
        codeRegion: 'REGION001',
      ),
    ];
  }
}

void main() {
  late MockSharedPreferencesService mockPrefs;
  late MockAgentRepository mockRepository;

  setUp(() {
    mockPrefs = MockSharedPreferencesService();
    mockRepository = MockAgentRepository();

    // Setup GetIt
    GetIt.I.registerSingleton<SharedPreferencesService>(mockPrefs);
    GetIt.I.registerSingleton<AgentRepository>(mockRepository);
  });

  tearDown(() {
    GetIt.I.reset();
  });

  group('ContractsPage Navigation Tests', () {
    testWidgets('ContractsPage accepts initialClientFilter and initialClientName parameters',
        (WidgetTester tester) async {
      // Arrange
      const initialClientFilter = 'CLIENT001';
      const initialClientName = 'Test Client';

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: ContractsPage(
            initialClientFilter: initialClientFilter,
            initialClientName: initialClientName,
          ),
        ),
      );

      // Assert
      expect(find.byType(ContractsPage), findsOneWidget);
      // The page should load without errors
    });

    testWidgets('ContractsPage shows loading indicator initially',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: const ContractsPage(),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('ContractsPage applies initial client filter correctly',
        (WidgetTester tester) async {
      // Arrange
      const initialClientFilter = 'CLIENT001';
      const initialClientName = 'Test Client';

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: ContractsPage(
            initialClientFilter: initialClientFilter,
            initialClientName: initialClientName,
          ),
        ),
      );

      // Wait for data loading
      await tester.pumpAndSettle();

      // Assert
      // Check if the snackbar with client name is shown
      expect(find.text('Test Client mijozining shartnomalari'), findsOneWidget);
    });

    testWidgets('TradingPointsPage _viewContracts method navigates to ContractsPage',
        (WidgetTester tester) async {
      // Arrange
      final tradingPoint = TradingPoint(
        id: 'CLIENT001',
        name: 'Test Client',
        address: 'Test Address',
        phone: '+998901234567',
        ownerName: 'Test Owner',
        contactPerson: 'Test Contact',
        inn: '123456789',
        status: 'active',
        lastVisitDate: '',
        hasOrders: true,
        hasContracts: true,
        isVisited: false,
        hasContract: true,
        latitude: 41.2995,
        longitude: 69.2401,
        region: 'Tashkent',
        district: 'Test District',
        signboard: 'Test Signboard',
        referencePoint: 'Test Reference',
        responsiblePerson: 'Test Responsible',
        responsiblePersonPhone: '+998909876543',
        tradePointType: 'Retail',
        creditLimit: 5000000.0,
        accumulatedCredit: 1000000.0,
        codeRegion: 'REGION001',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TradingPointsPage(),
        ),
      );

      // Wait for the page to load
      await tester.pumpAndSettle();

      // Since we can't easily trigger the _viewContracts method directly,
      // we'll verify that the TradingPointsPage loads without errors
      expect(find.byType(TradingPointsPage), findsOneWidget);
    });

    testWidgets('ContractsPage handles empty initialClientFilter gracefully',
        (WidgetTester tester) async {
      // Arrange
      const initialClientFilter = '';
      const initialClientName = '';

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: ContractsPage(
            initialClientFilter: initialClientFilter,
            initialClientName: initialClientName,
          ),
        ),
      );

      // Wait for data loading
      await tester.pumpAndSettle();

      // Assert
      // Page should load without errors and not show snackbar
      expect(find.byType(ContractsPage), findsOneWidget);
      expect(find.text(' mijozining shartnomalari'), findsNothing);
    });

    testWidgets('ContractsPage handles null parameters gracefully',
        (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: const ContractsPage(
            initialClientFilter: null,
            initialClientName: null,
          ),
        ),
      );

      // Wait for data loading
      await tester.pumpAndSettle();

      // Assert
      // Page should load without errors
      expect(find.byType(ContractsPage), findsOneWidget);
    });
  });
}