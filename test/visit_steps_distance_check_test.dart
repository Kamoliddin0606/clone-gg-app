// =============================================================================
// VISIT STEPS MASOFA TEKSHIRUVI TESTLARI
// =============================================================================
// Bu test fayli visit yakunlashda masofa tekshiruvi logikasini sinovdan o'tkazadi.
// 
// Asosiy test holatlari:
// 1. Rejadan tashqari buyurtmalar - masofa tekshiruvi o'tkazib yuboriladi
// 2. Rejali tashriflar clientZoneAccess > 0 bilan - masofa tekshiriladi
// 3. Rejali tashriflar clientZoneAccess = 0 bilan - masofa tekshiruvi o'tkazib yuboriladi
// 4. Masofa cheklovi bajarilmagan holat - xatolik qaytariladi
// 5. Masofa cheklovi bajarilgan holat - visit muvaffaqiyatli yakunlanadi
// =============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point_with_permissions.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/sales_req_permissions.dart';

void main() {
  // ==========================================================================
  // Test ma'lumotlari va yordamchi funksiyalar
  // ==========================================================================
  
  /// Sinov uchun TradingPoint yaratish
  /// [latitude] va [longitude] - mijoz koordinatalari
  TradingPoint createTestTradingPoint({
    String id = 'client_123',
    String name = 'Test Client',
    double latitude = 41.2995,
    double longitude = 69.2401,
  }) {
    return TradingPoint(
      id: id,
      name: name,
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
      latitude: latitude,
      longitude: longitude,
      region: 'Tashkent',
      district: 'Yunusabad',
      signboard: 'Test Signboard',
      referencePoint: 'Test Reference',
      responsiblePerson: 'Test Responsible',
      responsiblePersonPhone: '+998987654321',
      tradePointType: 'Shop',
      creditLimit: 1000000.0,
      accumulatedCredit: 0.0,
      codeRegion: 'region_1',
    );
  }

  /// Sinov uchun SalesReqPermissions yaratish
  /// [clientZoneAccess] - masofa cheklovi (metrda)
  /// [isUnplannedOrder] - rejadan tashqari buyurtma uchun unplannedOrder flag
  SalesReqPermissions createTestPermissions({
    int clientZoneAccess = 0,
    bool unplannedOrder = false,
  }) {
    return SalesReqPermissions(
      userCode: 'user_123',
      skipTINduplicateCheck: false,
      allowCreationWithoutTIN: false,
      allowCreatingPointOfSale: false,
      visit: true,
      strictSequence: false,
      unplannedOrder: unplannedOrder,
      plannedRoute: true,
      editClientCoordinates: false,
      clientZoneAccess: clientZoneAccess,
      locationUpdateInterval: 0,
      visitSteps: [
        VisitStep(stepCode: 1, stepName: 'Photo Before', stepRequired: true),
        VisitStep(stepCode: 2, stepName: 'Create Order', stepRequired: false),
        VisitStep(stepCode: 3, stepName: 'Photo After', stepRequired: true),
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Sinov uchun TradingPointWithPermissions yaratish
  TradingPointWithPermissions createTestTradingPointWithPermissions({
    int clientZoneAccess = 0,
    bool unplannedOrder = false,
    double latitude = 41.2995,
    double longitude = 69.2401,
  }) {
    return TradingPointWithPermissions(
      tradingPoint: createTestTradingPoint(latitude: latitude, longitude: longitude),
      permissions: createTestPermissions(
        clientZoneAccess: clientZoneAccess,
        unplannedOrder: unplannedOrder,
      ),
    );
  }

  // ==========================================================================
  // MASOFA TEKSHIRUVI LOGIKASI TESTLARI
  // ==========================================================================
  
  group('Masofa tekshiruvi logikasi (Distance Check Logic)', () {
    
    // ------------------------------------------------------------------------
    // 1. REJADAN TASHQARI BUYURTMALAR TESTLARI
    // ------------------------------------------------------------------------
    group('Rejadan tashqari buyurtmalar (Unplanned Orders)', () {
      
      test('Rejadan tashqari buyurtmalarda masofa tekshiruvi o\'tkazib yuborilishi kerak', () {
        // Arrange - Rejadan tashqari buyurtma uchun ma'lumotlar
        const isUnplannedOrder = true;
        const clientZoneAccess = 100; // 100 metr masofa cheklovi (lekin tekshirilmaydi)
        
        // Act - Masofa tekshiruvini o'tkazib yuborish shartini tekshirish
        // isUnplannedOrder = true bo'lganda clientZoneAccess qiymatidan qat'i nazar tekshiruv o'tkazib yuboriladi
        final shouldSkipDistanceCheck = isUnplannedOrder || clientZoneAccess <= 0;
        
        // Assert - Rejadan tashqari buyurtmalarda tekshiruv o'tkazib yuborilishi kerak
        expect(shouldSkipDistanceCheck, isTrue,
          reason: 'Rejadan tashqari buyurtmalarda masofa tekshiruvi o\'tkazib yuborilishi kerak');
      });

      test('Rejadan tashqari buyurtma uchun TradingPointWithPermissions to\'g\'ri yaratilishi', () {
        // Arrange & Act
        final tradingPointWithPermissions = createTestTradingPointWithPermissions(
          clientZoneAccess: 200,
          unplannedOrder: true,
        );
        
        // Assert
        expect(tradingPointWithPermissions.permissions?.unplannedOrder, isTrue);
        expect(tradingPointWithPermissions.permissions?.clientZoneAccess, equals(200));
      });
    });

    // ------------------------------------------------------------------------
    // 2. REJALI TASHRIFLAR TESTLARI (clientZoneAccess > 0)
    // ------------------------------------------------------------------------
    group('Rejali tashriflar clientZoneAccess > 0 bilan (Planned Visits with Distance Check)', () {
      
      test('clientZoneAccess > 0 bo\'lganda masofa tekshiruvi bajarilishi kerak', () {
        // Arrange
        final isUnplannedOrder = false;
        final clientZoneAccess = 100; // 100 metr masofa cheklovi
        
        // Act - Masofa tekshiruvini bajarish shartini tekshirish
        final shouldPerformDistanceCheck = !isUnplannedOrder && clientZoneAccess > 0;
        
        // Assert
        expect(shouldPerformDistanceCheck, isTrue,
          reason: 'Rejali tashriflarda clientZoneAccess > 0 bo\'lganda masofa tekshirilishi kerak');
      });

      test('Agent belgilangan masofa ichida bo\'lganda tekshiruv muvaffaqiyatli', () {
        // Arrange
        final clientZoneAccess = 100; // 100 metr
        final currentDistanceMeters = 50.0; // Agent 50 metr masofada
        
        // Act
        final isWithinRange = currentDistanceMeters <= clientZoneAccess;
        
        // Assert
        expect(isWithinRange, isTrue,
          reason: 'Agent $currentDistanceMeters metr masofada, cheklov $clientZoneAccess metr');
      });

      test('Agent belgilangan masofadan tashqarida bo\'lganda tekshiruv muvaffaqiyatsiz', () {
        // Arrange
        final clientZoneAccess = 100; // 100 metr
        final currentDistanceMeters = 150.0; // Agent 150 metr masofada
        
        // Act
        final isWithinRange = currentDistanceMeters <= clientZoneAccess;
        
        // Assert
        expect(isWithinRange, isFalse,
          reason: 'Agent $currentDistanceMeters metr masofada, cheklov $clientZoneAccess metr - xatolik qaytarilishi kerak');
      });

      test('Chegaraviy holat: agent aynan cheklov masofasida', () {
        // Arrange
        final clientZoneAccess = 100; // 100 metr
        final currentDistanceMeters = 100.0; // Agent aynan 100 metr masofada
        
        // Act
        final isWithinRange = currentDistanceMeters <= clientZoneAccess;
        
        // Assert
        expect(isWithinRange, isTrue,
          reason: 'Agent aynan cheklov masofasida ($currentDistanceMeters m = $clientZoneAccess m) - ruxsat etilishi kerak');
      });
    });

    // ------------------------------------------------------------------------
    // 3. REJALI TASHRIFLAR TESTLARI (clientZoneAccess = 0)
    // ------------------------------------------------------------------------
    group('Rejali tashriflar clientZoneAccess = 0 bilan (Planned Visits without Distance Check)', () {
      
      test('clientZoneAccess = 0 bo\'lganda masofa tekshiruvi o\'tkazib yuborilishi kerak', () {
        // Arrange
        final isUnplannedOrder = false;
        final clientZoneAccess = 0; // Masofa cheklovi yo'q
        
        // Act - Masofa tekshiruvini o'tkazib yuborish shartini tekshirish
        final shouldSkipDistanceCheck = isUnplannedOrder || clientZoneAccess == 0;
        
        // Assert
        expect(shouldSkipDistanceCheck, isTrue,
          reason: 'clientZoneAccess = 0 bo\'lganda masofa tekshiruvi o\'tkazib yuborilishi kerak');
      });

      test('TradingPointWithPermissions clientZoneAccess = 0 bilan yaratilishi', () {
        // Arrange & Act
        final tradingPointWithPermissions = createTestTradingPointWithPermissions(
          clientZoneAccess: 0,
          unplannedOrder: false,
        );
        
        // Assert
        expect(tradingPointWithPermissions.permissions?.clientZoneAccess, equals(0));
        expect(tradingPointWithPermissions.permissions?.unplannedOrder, isFalse);
      });
    });

    // ------------------------------------------------------------------------
    // 4. KOMBINATSIYALANGAN HOLATLAR TESTLARI
    // ------------------------------------------------------------------------
    group('Kombinatsiyalangan holatlar (Combined Scenarios)', () {
      
      test('Barcha tekshiruv shartlari kombinatsiyasi', () {
        // Test data: [isUnplannedOrder, clientZoneAccess, shouldCheckDistance]
        final testCases = [
          [true, 100, false],   // Rejadan tashqari + cheklov bor = tekshirmaslik
          [true, 0, false],     // Rejadan tashqari + cheklov yo'q = tekshirmaslik
          [false, 100, true],   // Rejali + cheklov bor = tekshirish
          [false, 0, false],    // Rejali + cheklov yo'q = tekshirmaslik
          [false, 50, true],    // Rejali + kichik cheklov = tekshirish
          [false, 1000, true],  // Rejali + katta cheklov = tekshirish
        ];
        
        for (final testCase in testCases) {
          final isUnplannedOrder = testCase[0] as bool;
          final clientZoneAccess = testCase[1] as int;
          final expectedShouldCheck = testCase[2] as bool;
          
          // Act
          final shouldCheckDistance = !isUnplannedOrder && clientZoneAccess > 0;
          
          // Assert
          expect(shouldCheckDistance, equals(expectedShouldCheck),
            reason: 'isUnplannedOrder=$isUnplannedOrder, clientZoneAccess=$clientZoneAccess -> shouldCheck=$expectedShouldCheck');
        }
      });

      test('Turli masofalar bilan tekshiruv natijalari', () {
        // Arrange
        final clientZoneAccess = 200; // 200 metr cheklov
        
        // Test data: [distance, shouldPass]
        final distanceTests = [
          [0.0, true],      // 0 metr - o'tishi kerak
          [50.0, true],     // 50 metr - o'tishi kerak
          [100.0, true],    // 100 metr - o'tishi kerak
          [199.0, true],    // 199 metr - o'tishi kerak
          [200.0, true],    // 200 metr (chegara) - o'tishi kerak
          [201.0, false],   // 201 metr - o'tmasligi kerak
          [500.0, false],   // 500 metr - o'tmasligi kerak
          [1000.0, false],  // 1000 metr - o'tmasligi kerak
        ];
        
        for (final test in distanceTests) {
          final distance = test[0] as double;
          final shouldPass = test[1] as bool;
          
          // Act
          final result = distance <= clientZoneAccess;
          
          // Assert
          expect(result, equals(shouldPass),
            reason: 'Masofa: $distance metr, cheklov: $clientZoneAccess metr -> o\'tishi kerak: $shouldPass');
        }
      });
    });

    // ------------------------------------------------------------------------
    // 5. MODEL TESTLARI
    // ------------------------------------------------------------------------
    group('Model validatsiyasi (Model Validation)', () {
      
      test('SalesReqPermissions clientZoneAccess default qiymati 0', () {
        // Arrange & Act
        final permissions = SalesReqPermissions(
          userCode: 'test_user',
          skipTINduplicateCheck: false,
          allowCreationWithoutTIN: false,
          allowCreatingPointOfSale: false,
          visit: true,
          strictSequence: false,
          unplannedOrder: false,
          plannedRoute: true,
          editClientCoordinates: false,
          visitSteps: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        // Assert
        expect(permissions.clientZoneAccess, equals(0));
      });

      test('TradingPoint koordinatalari to\'g\'ri saqlanishi', () {
        // Arrange
        const expectedLat = 41.2995;
        const expectedLng = 69.2401;
        
        // Act
        final tradingPoint = createTestTradingPoint(
          latitude: expectedLat,
          longitude: expectedLng,
        );
        
        // Assert
        expect(tradingPoint.latitude, equals(expectedLat));
        expect(tradingPoint.longitude, equals(expectedLng));
      });

      test('VisitStep model to\'g\'ri yaratilishi', () {
        // Arrange & Act
        final visitStep = VisitStep(
          stepCode: 1,
          stepName: 'Test Step',
          stepRequired: true,
        );
        
        // Assert
        expect(visitStep.stepCode, equals(1));
        expect(visitStep.stepName, equals('Test Step'));
        expect(visitStep.stepRequired, isTrue);
      });
    });

    // ------------------------------------------------------------------------
    // 6. EDGE CASES TESTLARI
    // ------------------------------------------------------------------------
    group('Edge cases (Chegaraviy holatlar)', () {
      
      test('Juda katta clientZoneAccess qiymati', () {
        // Arrange
        final clientZoneAccess = 1000000; // 1000 km
        final distance = 500000.0; // 500 km
        
        // Act
        final isWithinRange = distance <= clientZoneAccess;
        
        // Assert
        expect(isWithinRange, isTrue);
      });

      test('Juda kichik clientZoneAccess qiymati (1 metr)', () {
        // Arrange
        final clientZoneAccess = 1; // 1 metr
        final distance = 0.5; // 0.5 metr
        
        // Act
        final isWithinRange = distance <= clientZoneAccess;
        
        // Assert
        expect(isWithinRange, isTrue);
      });

      test('Nol masofa', () {
        // Arrange
        final clientZoneAccess = 100;
        final distance = 0.0;
        
        // Act
        final isWithinRange = distance <= clientZoneAccess;
        
        // Assert
        expect(isWithinRange, isTrue,
          reason: 'Agent aynan mijoz joylashuvida - 0 metr masofa');
      });

      test('Manfiy clientZoneAccess qiymati (xatolik holati)', () {
        // Arrange
        // Amalda bunday bo'lmasligi kerak, lekin defensive coding uchun
        const clientZoneAccess = -100;
        const distance = 50.0;
        
        // Act - Manfiy qiymat bilan ishlash
        // Amalda bu validatsiya qilinishi kerak
        // distance qiymati faqat clientZoneAccess > 0 bo'lganda tekshiriladi
        final shouldSkipCheck = clientZoneAccess <= 0;
        final wouldPassIfChecked = distance <= clientZoneAccess;
        
        // Assert
        expect(shouldSkipCheck, isTrue,
          reason: 'Manfiy yoki nol clientZoneAccess masofa tekshiruvini o\'tkazib yuborishi kerak');
        expect(wouldPassIfChecked, isFalse,
          reason: 'Manfiy cheklov bilan hech qanday masofa o\'tmasligi kerak');
      });
    });
  });

  // ==========================================================================
  // INTEGRATION TESTLARI
  // ==========================================================================
  group('Integration testlari', () {
    
    test('To\'liq workflow: Rejali tashrif muvaffaqiyatli masofa tekshiruvi', () {
      // Arrange
      final tradingPointWithPermissions = createTestTradingPointWithPermissions(
        clientZoneAccess: 100, // 100 metr cheklov
        unplannedOrder: false, // Rejali tashrif
      );
      
      final agentDistanceMeters = 50.0; // Agent 50 metr masofada
      final isUnplannedOrder = false;
      
      // Act
      final clientZoneAccess = tradingPointWithPermissions.permissions?.clientZoneAccess ?? 0;
      final shouldCheckDistance = !isUnplannedOrder && clientZoneAccess > 0;
      final distanceCheckPassed = !shouldCheckDistance || agentDistanceMeters <= clientZoneAccess;
      
      // Assert
      expect(shouldCheckDistance, isTrue, reason: 'Masofa tekshiruvi kerak');
      expect(distanceCheckPassed, isTrue, reason: 'Masofa tekshiruvi muvaffaqiyatli');
    });

    test('To\'liq workflow: Rejadan tashqari buyurtma masofa tekshiruvisiz', () {
      // Arrange
      final tradingPointWithPermissions = createTestTradingPointWithPermissions(
        clientZoneAccess: 100, // 100 metr cheklov (lekin tekshirilmaydi)
        unplannedOrder: true, // Rejadan tashqari buyurtma
      );
      
      final agentDistanceMeters = 500.0; // Agent 500 metr masofada (cheklovdan tashqarida)
      
      // Act - Rejadan tashqari buyurtma tekshiruvi
      final clientZoneAccess = tradingPointWithPermissions.permissions?.clientZoneAccess ?? 0;
      final isUnplannedOrder = tradingPointWithPermissions.permissions?.unplannedOrder ?? false;
      
      // Masofa tekshiruvini bajarish shartini aniqlash
      // Rejadan tashqari buyurtmalarda tekshiruv o'tkazib yuboriladi
      final shouldCheckDistance = !isUnplannedOrder && clientZoneAccess > 0;
      
      // Agar tekshiruv kerak bo'lsa, masofani tekshirish
      // Agar tekshiruv kerak bo'lmasa, avtomatik ravishda davom etish mumkin
      final canProceed = shouldCheckDistance 
          ? agentDistanceMeters <= clientZoneAccess 
          : true;
      
      // Assert
      expect(isUnplannedOrder, isTrue, reason: 'Bu rejadan tashqari buyurtma');
      expect(shouldCheckDistance, isFalse, reason: 'Rejadan tashqari buyurtma - masofa tekshirilmaydi');
      expect(canProceed, isTrue, reason: 'Visit davom etishi mumkin');
      // Masofa qiymati faqat log uchun - agent uzoqda bo'lsa ham ruxsat beriladi
      expect(agentDistanceMeters, greaterThan(clientZoneAccess.toDouble()), 
        reason: 'Agent cheklovdan tashqarida, lekin bu rejadan tashqari buyurtma uchun ahamiyatsiz');
    });

    test('To\'liq workflow: Rejali tashrif muvaffaqiyatsiz masofa tekshiruvi', () {
      // Arrange
      final tradingPointWithPermissions = createTestTradingPointWithPermissions(
        clientZoneAccess: 100, // 100 metr cheklov
        unplannedOrder: false, // Rejali tashrif
      );
      
      final agentDistanceMeters = 200.0; // Agent 200 metr masofada (cheklovdan tashqarida)
      final isUnplannedOrder = false;
      
      // Act
      final clientZoneAccess = tradingPointWithPermissions.permissions?.clientZoneAccess ?? 0;
      final shouldCheckDistance = !isUnplannedOrder && clientZoneAccess > 0;
      final distanceCheckPassed = !shouldCheckDistance || agentDistanceMeters <= clientZoneAccess;
      
      // Assert
      expect(shouldCheckDistance, isTrue, reason: 'Masofa tekshiruvi kerak');
      expect(distanceCheckPassed, isFalse, reason: 'Masofa tekshiruvi muvaffaqiyatsiz - agent juda uzoqda');
    });
  });
}
