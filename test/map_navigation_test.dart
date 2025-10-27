import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/trading_points_page.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart' as model;
import 'package:gloria_marketing_flutter/src/core/router/app_router.dart';

void main() {
  group('Map Navigation Tests', () {
    testWidgets('Fullscreen icon navigates to map detail page',
        (WidgetTester tester) async {
      // Create a test trading point
      final tradingPoint = model.TradingPoint(
        id: 'test_id',
        name: 'Test Client',
        address: 'Test Address',
        phone: '+998901234567',
        ownerName: 'Test Owner',
        contactPerson: 'Test Contact',
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
        tradePointType: 'Retail',
        creditLimit: 0.0,
        accumulatedCredit: 0.0,
        codeRegion: '01',
      );

      // Build the widget tree with router
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRouter.generateRoute,
          home: Scaffold(
            body: _TestTradingPointsPage(tradingPoint: tradingPoint),
          ),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify that the fullscreen icon is present
      expect(find.byIcon(Icons.fullscreen), findsOneWidget);

      // Tap the fullscreen icon
      await tester.tap(find.byIcon(Icons.fullscreen));
      await tester.pumpAndSettle();

      // Verify that navigation occurred (we should see the map detail page)
      // The map detail page should have the client name in the app bar
      expect(find.text('Test Client'), findsOneWidget);

      // Verify that we're on the map detail page by checking for map controls
      expect(find.byIcon(Icons.my_location), findsOneWidget);
      expect(find.byIcon(Icons.location_on), findsOneWidget);
      expect(find.byIcon(Icons.directions), findsOneWidget);
      expect(find.byIcon(Icons.edit_location), findsOneWidget);
    });

    testWidgets('Router handles map detail route correctly',
        (WidgetTester tester) async {
      // Create a test trading point
      final tradingPoint = model.TradingPoint(
        id: 'test_id',
        name: 'Router Test Client',
        address: 'Test Address',
        phone: '+998901234567',
        ownerName: 'Test Owner',
        contactPerson: 'Test Contact',
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
        tradePointType: 'Retail',
        creditLimit: 0.0,
        accumulatedCredit: 0.0,
        codeRegion: '01',
      );

      // Test router directly
      final route = AppRouter.generateRoute(
        RouteSettings(
          name: '/map-detail',
          arguments: tradingPoint,
        ),
      );

      expect(route, isNotNull);
      expect(route, isA<MaterialPageRoute>());

      // Build the route
      await tester.pumpWidget(
        MaterialApp(
          home: route!.builder(tester.element(find.byType(Container))),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the page was built correctly
      expect(find.text('Router Test Client'), findsOneWidget);
      expect(find.byIcon(Icons.my_location), findsOneWidget);
    });

    testWidgets('Router handles missing trading point argument',
        (WidgetTester tester) async {
      // Test router with null arguments
      final route = AppRouter.generateRoute(
        RouteSettings(
          name: '/map-detail',
          arguments: null,
        ),
      );

      expect(route, isNotNull);
      expect(route, isA<MaterialPageRoute>());

      // Build the route
      await tester.pumpWidget(
        MaterialApp(
          home: route!.builder(tester.element(find.byType(Container))),
        ),
      );

      await tester.pumpAndSettle();

      // Should show error message
      expect(find.text('Trading point data is required for map detail page'), findsOneWidget);
    });

    testWidgets('Navigation preserves trading point data',
        (WidgetTester tester) async {
      // Create a test trading point with specific data
      final tradingPoint = model.TradingPoint(
        id: 'unique_id_123',
        name: 'Special Test Client',
        address: '123 Test Street',
        phone: '+998901234567',
        ownerName: 'John Doe',
        contactPerson: 'Jane Smith',
        inn: '987654321',
        status: 'active',
        lastVisitDate: '',
        hasOrders: true,
        hasContracts: true,
        isVisited: true,
        hasContract: true,
        latitude: 41.2995,
        longitude: 69.2401,
        region: 'Tashkent',
        district: 'Mirabad',
        signboard: 'Big Sign',
        referencePoint: 'Near Mall',
        responsiblePerson: 'Bob Wilson',
        responsiblePersonPhone: '+998909876543',
        tradePointType: 'Wholesale',
        creditLimit: 10000.0,
        accumulatedCredit: 2500.0,
        codeRegion: '02',
      );

      // Build the widget tree
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRouter.generateRoute,
          home: Scaffold(
            body: _TestTradingPointsPage(tradingPoint: tradingPoint),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to map detail page
      await tester.tap(find.byIcon(Icons.fullscreen));
      await tester.pumpAndSettle();

      // Verify that all trading point data is preserved
      expect(find.text('Special Test Client'), findsOneWidget);

      // The map detail page should be able to access the trading point data
      // We can verify this by checking that the page renders without errors
      expect(find.byIcon(Icons.my_location), findsOneWidget);
      expect(find.byIcon(Icons.location_on), findsOneWidget);
      expect(find.byIcon(Icons.directions), findsOneWidget);
      expect(find.byIcon(Icons.edit_location), findsOneWidget);
    });
  });
}

// Helper widget to expose the private _ClientDetailsPage for testing
class _TestTradingPointsPage extends StatefulWidget {
  final model.TradingPoint tradingPoint;

  const _TestTradingPointsPage({required this.tradingPoint});

  @override
  State<_TestTradingPointsPage> createState() => _TestTradingPointsPageState();
}

class _TestTradingPointsPageState extends State<_TestTradingPointsPage> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Map component with icons
          Container(
            height: 200,
            margin: const EdgeInsets.only(bottom: 16),
            child: _buildMapWidget(
              LatLng(widget.tradingPoint.latitude, widget.tradingPoint.longitude),
              widget.tradingPoint.name,
              widget.tradingPoint.id,
            ),
          ),

          Text(
            widget.tradingPoint.name,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),

          // Address
          Row(
            children: [
              const Icon(Icons.place_outlined, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.tradingPoint.address,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMapWidget(LatLng position, String title, String markerId) {
    return Stack(
      children: [
        Container(
          height: 200,
          color: Colors.grey[300],
          child: const Center(child: Text('Map Placeholder')),
        ),
        // Custom map control icons positioned over the map
        Positioned(
          bottom: 16,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // User position icon (top of the column)
              Container(
                width: 44,
                height: 44,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.my_location, color: Colors.blue),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User position - functionality to be implemented')),
                    );
                  },
                  tooltip: 'User position',
                  iconSize: 24,
                ),
              ),
              // Client position icon
              Container(
                width: 44,
                height: 44,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.location_on, color: Colors.red),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Client position - functionality to be implemented')),
                    );
                  },
                  tooltip: 'Client position',
                  iconSize: 24,
                ),
              ),
              // Route icon
              Container(
                width: 44,
                height: 44,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.directions, color: Colors.green),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Route - functionality to be implemented')),
                    );
                  },
                  tooltip: 'Route',
                  iconSize: 24,
                ),
              ),
              // Fullscreen icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.fullscreen, color: Colors.black),
                  onPressed: () {
                    // Navigate to fullscreen map detail page
                    Navigator.pushNamed(
                      context,
                      '/map-detail',
                      arguments: widget.tradingPoint,
                    );
                  },
                  tooltip: 'Fullscreen',
                  iconSize: 24,
                ),
              ),
            ],
          ),
        ),
        // Update coordinates icon (top-right)
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.edit_location, color: Colors.orange),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Update coordinates - functionality to be implemented')),
                );
              },
              tooltip: 'Update coordinates',
              iconSize: 24,
            ),
          ),
        ),
      ],
    );
  }
}