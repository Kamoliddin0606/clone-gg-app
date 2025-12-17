import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/pages/client_images_page.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point_with_permissions.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart' as model;

void main() {
  testWidgets('ClientImagesPage renders and shows refresh indicator', (tester) async {
    final tp = TradingPointWithPermissions(
      tradingPoint: model.TradingPoint(
        id: 'client-1c-code',
        name: 'Test Client',
        address: 'Test address',
        phone: '+998900000000',
        ownerName: 'Owner',
        contactPerson: 'Contact',
        inn: '000000000',
        status: 'active',
        lastVisitDate: '',
        hasOrders: false,
        hasContracts: false,
        isVisited: false,
        hasContract: false,
        latitude: 0.0,
        longitude: 0.0,
        region: 'Test region',
        district: 'Test district',
        signboard: '',
        referencePoint: '',
        responsiblePerson: '',
        responsiblePersonPhone: '',
        tradePointType: '',
        creditLimit: 0.0,
        accumulatedCredit: 0.0,
        codeRegion: '',
      ),
      permissions: null,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ClientImagesPage(tradingPoint: tp),
      ),
    );

    // At minimum the page should build a Scaffold.
    expect(find.byType(Scaffold), findsOneWidget);

    // RefreshIndicator is used for reload/sync.
    expect(find.byType(RefreshIndicator), findsOneWidget);
  });
}
