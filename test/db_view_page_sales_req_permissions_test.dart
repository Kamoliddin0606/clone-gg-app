import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/db_view_page.dart';

void main() {
  group('DbViewPage Sales Req Permissions Tests', () {
    testWidgets('should display sales req permissions tab', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: DbViewPage()));

      // Wait for data loading
      await tester.pumpAndSettle();

      // Check if Sales Req Permissions tab exists
      expect(find.text('Sales Req Permissions'), findsOneWidget);
    });

    testWidgets('should display visit steps tab', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: DbViewPage()));

      // Wait for data loading
      await tester.pumpAndSettle();

      // Check if Visit Steps tab exists
      expect(find.text('Visit Steps'), findsOneWidget);
    });

    testWidgets('should display sales req permissions columns correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: DbViewPage()));

      // Wait for data loading
      await tester.pumpAndSettle();

      // Navigate to Sales Req Permissions tab
      await tester.tap(find.text('Sales Req Permissions'));
      await tester.pumpAndSettle();

      // Check for column headers
      expect(find.text('ID'), findsOneWidget);
      expect(find.text('User Code'), findsOneWidget);
      expect(find.text('Skip TIN Duplicate'), findsOneWidget);
      expect(find.text('Allow Creation Without TIN'), findsOneWidget);
      expect(find.text('Allow Creating POS'), findsOneWidget);
      expect(find.text('Visit'), findsOneWidget);
      expect(find.text('Strict Sequence'), findsOneWidget);
      expect(find.text('Unplanned Order'), findsOneWidget);
      expect(find.text('Planned Route'), findsOneWidget);
      expect(find.text('Visit Steps Count'), findsOneWidget);
      expect(find.text('Created At'), findsOneWidget);
      expect(find.text('Updated At'), findsOneWidget);
    });

    testWidgets('should display visit steps columns correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: DbViewPage()));

      // Wait for data loading
      await tester.pumpAndSettle();

      // Navigate to Visit Steps tab
      await tester.tap(find.text('Visit Steps'));
      await tester.pumpAndSettle();

      // Check for column headers
      expect(find.text('ID'), findsOneWidget);
      expect(find.text('Permissions ID'), findsOneWidget);
      expect(find.text('Step Code'), findsOneWidget);
      expect(find.text('Step Name'), findsOneWidget);
      expect(find.text('Required'), findsOneWidget);
      expect(find.text('Created At'), findsOneWidget);
      expect(find.text('Updated At'), findsOneWidget);
    });

    testWidgets('should handle empty sales req permissions data', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: DbViewPage()));

      // Wait for data loading
      await tester.pumpAndSettle();

      // Navigate to Sales Req Permissions tab
      await tester.tap(find.text('Sales Req Permissions'));
      await tester.pumpAndSettle();

      // Should not crash with empty data - columns should still be visible
      expect(find.text('ID'), findsOneWidget);
    });

    testWidgets('should handle empty visit steps data', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: DbViewPage()));

      // Wait for data loading
      await tester.pumpAndSettle();

      // Navigate to Visit Steps tab
      await tester.tap(find.text('Visit Steps'));
      await tester.pumpAndSettle();

      // Should not crash with empty data - columns should still be visible
      expect(find.text('ID'), findsOneWidget);
    });

    testWidgets('should refresh data when refresh button is pressed', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: DbViewPage()));

      // Wait for initial data loading
      await tester.pumpAndSettle();

      // Find and tap the refresh button
      final refreshButton = find.byIcon(Icons.refresh);
      expect(refreshButton, findsOneWidget);

      await tester.tap(refreshButton);
      await tester.pumpAndSettle();

      // Should still be on the page without errors
      expect(find.text('Database View'), findsOneWidget);
    });

    testWidgets('should handle navigation between tabs', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: DbViewPage()));

      // Wait for data loading
      await tester.pumpAndSettle();

      // Start on first tab (Users)
      expect(find.text('Users'), findsOneWidget);

      // Navigate to Sales Req Permissions tab
      await tester.tap(find.text('Sales Req Permissions'));
      await tester.pumpAndSettle();

      // Should be on Sales Req Permissions tab
      expect(find.text('User Code'), findsOneWidget);

      // Navigate to Visit Steps tab
      await tester.tap(find.text('Visit Steps'));
      await tester.pumpAndSettle();

      // Should be on Visit Steps tab
      expect(find.text('Step Code'), findsOneWidget);

      // Navigate back to Users tab
      await tester.tap(find.text('Users'));
      await tester.pumpAndSettle();

      // Should be back on Users tab
      expect(find.text('Code'), findsOneWidget);
    });
  });
}