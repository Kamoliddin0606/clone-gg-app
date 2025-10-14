import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/agent_home_modern.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_service.dart';

// Mock classes
class MockDataSyncService extends Mock implements DataSyncService {}

void main() {
  late MockDataSyncService mockDataSyncService;

  setUp(() {
    mockDataSyncService = MockDataSyncService();
  });

  group('AgentHomeModern Widget Tests', () {
    testWidgets('should render AgentHomeModern with required parameters', (WidgetTester tester) async {
      // Arrange
      const userName = 'Test User';
      const userCode = '12345';
      const kpiView = KpiView(
        salesSum: '1000000',
        totalPercent: '75%',
        akbPlan: '500',
        akbFact: '400',
        akbPercent: '80%',
        okb: '25',
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (context) => AgentHomeBloc(dataSyncService: mockDataSyncService),
            child: AgentHomeModern(
              userName: userName,
              userCode: userCode,
              kpi: kpiView,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text(userName), findsOneWidget);
      expect(find.text('ID: $userCode'), findsOneWidget);
    });

    testWidgets('should display KPI data correctly', (WidgetTester tester) async {
      // Arrange
      const kpiView = KpiView(
        salesSum: '1000000',
        totalPercent: '75%',
        akbPlan: '500',
        akbFact: '400',
        akbPercent: '80%',
        okb: '25',
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (context) => AgentHomeBloc(dataSyncService: mockDataSyncService),
            child: AgentHomeModern(
              userName: 'Test User',
              userCode: '12345',
              kpi: kpiView,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('OKB'), findsOneWidget);
      expect(find.text('AKB Plan'), findsOneWidget);
      expect(find.text('AKB Fact'), findsOneWidget);
    });

    testWidgets('should handle null KPI data gracefully', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (context) => AgentHomeBloc(dataSyncService: mockDataSyncService),
            child: const AgentHomeModern(
              userName: 'Test User',
              userCode: '12345',
              kpi: null,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('ID: 12345'), findsOneWidget);
    });
  });

  group('AnimatedPercentageWidget Tests', () {
    testWidgets('should render circular progress correctly', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedPercentageWidget(
              percentage: 0.75,
              type: PercentageDisplayType.circular,
              color: Colors.blue,
              valueText: '75%',
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('75%'), findsOneWidget);
    });

    testWidgets('should render linear progress correctly', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedPercentageWidget(
              percentage: 0.6,
              type: PercentageDisplayType.linear,
              color: Colors.green,
              valueText: '60%',
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('60%'), findsOneWidget);
    });

    testWidgets('should handle zero percentage', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedPercentageWidget(
              percentage: 0.0,
              type: PercentageDisplayType.circular,
              color: Colors.red,
              valueText: '0%',
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('0%'), findsOneWidget);
    });
  });

  group('AgentHomeBloc Tests', () {
    late AgentHomeBloc bloc;

    setUp(() {
      bloc = AgentHomeBloc(dataSyncService: mockDataSyncService);
    });

    tearDown(() {
      bloc.close();
    });

    test('initial state should be AgentHomeInitial', () {
      expect(bloc.state, isA<AgentHomeInitial>());
    });

    test('should emit AgentHomeLoading when LoadAgentHomeData is added', () {
      // Act
      bloc.add(const LoadAgentHomeData(userCode: '123', password: 'pass'));

      // Assert
      expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AgentHomeLoading>(),
        ]),
      );
    });

    test('should handle ToggleExpanded event', () async {
      // Arrange
      bloc.emit(const AgentHomeLoaded(kpi: KpiView()));

      // Act
      bloc.add(ToggleExpanded());

      // Assert
      await expectLater(
        bloc.stream,
        emits(isA<AgentHomeLoaded>()),
      );
    });
  });

  group('KpiView Model Tests', () {
    test('should create KpiView with all parameters', () {
      // Act
      const kpiView = KpiView(
        salesSum: '1000000',
        itemsSold: '500',
        customersServed: '50',
        totalPercent: '75%',
        akbPlan: '1000',
        akbFact: '800',
        akbPercent: '80%',
        okb: '25',
      );

      // Assert
      expect(kpiView.salesSum, '1000000');
      expect(kpiView.itemsSold, '500');
      expect(kpiView.customersServed, '50');
      expect(kpiView.totalPercent, '75%');
      expect(kpiView.akbPlan, '1000');
      expect(kpiView.akbFact, '800');
      expect(kpiView.akbPercent, '80%');
      expect(kpiView.okb, '25');
    });

    test('should handle null values in KpiView', () {
      // Act
      const kpiView = KpiView();

      // Assert
      expect(kpiView.salesSum, isNull);
      expect(kpiView.itemsSold, isNull);
      expect(kpiView.customersServed, isNull);
      expect(kpiView.totalPercent, isNull);
      expect(kpiView.akbPlan, isNull);
      expect(kpiView.akbFact, isNull);
      expect(kpiView.akbPercent, isNull);
      expect(kpiView.okb, isNull);
    });
  });
}