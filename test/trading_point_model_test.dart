import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart';

void main() {
  group('TradingPoint Model Tests', () {
    test('fromJson should parse thumbnailUrl correctly', () {
      final json = {
        'id': '1',
        'name': 'Test Client',
        'address': 'Test Address',
        'phone': '123456789',
        'ownerName': 'Owner',
        'contactPerson': 'Contact',
        'inn': '123456789',
        'status': 'active',
        'lastVisitDate': '',
        'hasOrders': false,
        'hasContracts': false,
        'isVisited': false,
        'hasContract': false,
        'latitude': 41.0,
        'longitude': 69.0,
        'region': 'Tashkent',
        'district': 'District',
        'signboard': '',
        'referencePoint': '',
        'responsiblePerson': '',
        'responsiblePersonPhone': '',
        'tradePointType': '',
        'creditLimit': 0.0,
        'accumulatedCredit': 0.0,
        'codeRegion': '01',
        'thumbnailUrl': 'http://example.com/thumb.jpg',
        'visitToday': false,
        'visitStepNumber': 0,
        'plannedWeekDay': null,
      };
      final tradingPoint = TradingPoint.fromJson(json);
      expect(tradingPoint.thumbnailUrl, 'http://example.com/thumb.jpg');
    });

    test('toJson should include thumbnailUrl', () {
      final tradingPoint = TradingPoint(
        id: '1',
        name: 'Test Client',
        address: 'Test Address',
        phone: '123456789',
        ownerName: 'Owner',
        contactPerson: 'Contact',
        inn: '123456789',
        status: 'active',
        lastVisitDate: '',
        hasOrders: false,
        hasContracts: false,
        isVisited: false,
        hasContract: false,
        latitude: 41.0,
        longitude: 69.0,
        region: 'Tashkent',
        district: 'District',
        signboard: '',
        referencePoint: '',
        responsiblePerson: '',
        responsiblePersonPhone: '',
        tradePointType: '',
        creditLimit: 0.0,
        accumulatedCredit: 0.0,
        codeRegion: '01',
        thumbnailUrl: 'http://example.com/thumb.jpg',
        visitToday: false,
        visitStepNumber: 0,
        plannedWeekDay: null,
      );
      final json = tradingPoint.toJson();
      expect(json['thumbnailUrl'], 'http://example.com/thumb.jpg');
    });

    test('copyWith should update thumbnailUrl', () {
      final original = TradingPoint(
        id: '1',
        name: 'Test Client',
        address: 'Test Address',
        phone: '123456789',
        ownerName: 'Owner',
        contactPerson: 'Contact',
        inn: '123456789',
        status: 'active',
        lastVisitDate: '',
        hasOrders: false,
        hasContracts: false,
        isVisited: false,
        hasContract: false,
        latitude: 41.0,
        longitude: 69.0,
        region: 'Tashkent',
        district: 'District',
        signboard: '',
        referencePoint: '',
        responsiblePerson: '',
        responsiblePersonPhone: '',
        tradePointType: '',
        creditLimit: 0.0,
        accumulatedCredit: 0.0,
        codeRegion: '01',
        thumbnailUrl: 'http://example.com/thumb.jpg',
        visitToday: false,
        visitStepNumber: 0,
        plannedWeekDay: null,
      );
      final copied = original.copyWith(thumbnailUrl: 'http://example.com/new_thumb.jpg');
      expect(copied.thumbnailUrl, 'http://example.com/new_thumb.jpg');
      expect(copied.id, original.id); // other fields unchanged
    });
  });
}