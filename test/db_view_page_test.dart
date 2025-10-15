import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/db_view_page.dart';
import 'package:mockito/mockito.dart';

// Mock classes
class MockApiDatabaseService extends Mock implements ApiDatabaseService {}

void main() {
  late MockApiDatabaseService mockApiDatabaseService;

  setUp(() {
    mockApiDatabaseService = MockApiDatabaseService();

    // Register the mock service with GetIt
    GetIt.instance.registerSingleton<ApiDatabaseService>(mockApiDatabaseService);
  });

  tearDown(() {
    // Unregister the mock service
    GetIt.instance.unregister<ApiDatabaseService>();
  });

  group('DbViewPage Widget Tests', () {
    testWidgets('should render DbViewPage without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: DbViewPage()));

      // Check if the page renders
      expect(find.byType(DbViewPage), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Database View'), findsOneWidget);
    });

    testWidgets('should have refresh button in app bar', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: DbViewPage()));

      // Check if refresh button is present
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('should display loading indicator initially', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: DbViewPage()));

      // Initially should show loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should have tab bar with multiple tabs', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: DbViewPage()));

      // Check if TabBar is present
      expect(find.byType(TabBar), findsOneWidget);

      // Check if some tabs are present (we can't check all due to scrolling)
      expect(find.text('KPI Data'), findsOneWidget);
      expect(find.text('Clients'), findsOneWidget);
    });
  });
}