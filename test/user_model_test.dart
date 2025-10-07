import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/features/auth/data/models/user_model.dart';

void main() {
  group('UserModel', () {
    const validUserData = {
      'id': '123',
      'username': 'testuser',
      'fullName': 'Test User',
      'role': 'Agent',
      'code': '001',
      'name': 'Test User',
      'warehouseCode': 'W001',
      'codeProject': 'P001',
      'baseUrl': 'http://example.com/api',
    };

    test('fromJson creates UserModel with valid data', () {
      final user = UserModel.fromJson(validUserData);

      expect(user.id, '123');
      expect(user.username, 'testuser');
      expect(user.fullName, 'Test User');
      expect(user.role, 'Agent');
      expect(user.code, '001');
      expect(user.name, 'Test User');
      expect(user.warehouseCode, 'W001');
      expect(user.codeProject, 'P001');
      expect(user.baseUrl, 'http://example.com/api');
    });

    test('fromJson handles missing baseUrl with default empty string', () {
      final dataWithoutBaseUrl = Map<String, dynamic>.from(validUserData)
        ..remove('baseUrl');

      final user = UserModel.fromJson(dataWithoutBaseUrl);
      expect(user.baseUrl, '');
    });

    test('fromJson throws FormatException for invalid baseUrl', () {
      final invalidData = Map<String, dynamic>.from(validUserData)
        ..['baseUrl'] = 'invalid-url';

      expect(() => UserModel.fromJson(invalidData), throwsFormatException);
    });

    test('fromSoap creates UserModel with valid data', () {
      final soapData = {
        'Code': '001',
        'Name': 'Test User',
        'Type': '1',
        'CodeProject': 'P001',
        'WarehouseCode': 'W001',
      };

      final user = UserModel.fromSoap(soapData, baseUrl: 'http://example.com/api');

      expect(user.id, '001');
      expect(user.username, '');
      expect(user.fullName, 'Test User');
      expect(user.role, 'Agent');
      expect(user.code, '001');
      expect(user.name, 'Test User');
      expect(user.warehouseCode, 'W001');
      expect(user.codeProject, 'P001');
      expect(user.baseUrl, 'http://example.com/api');
    });

    test('fromSoap throws FormatException for invalid baseUrl', () {
      final soapData = {
        'Code': '001',
        'Name': 'Test User',
        'Type': '1',
      };

      expect(() => UserModel.fromSoap(soapData, baseUrl: 'invalid-url'), throwsFormatException);
    });

    test('toJson includes baseUrl', () {
      final user = UserModel.fromJson(validUserData);
      final json = user.toJson();

      expect(json['baseUrl'], 'http://example.com/api');
    });

    test('UserModel constructor creates instance with all required fields', () {
      final user = UserModel(
        id: '123',
        username: 'test',
        fullName: 'Test',
        role: 'Agent',
        code: '001',
        name: 'Test',
        warehouseCode: 'W001',
        codeProject: 'P001',
        baseUrl: 'http://example.com',
      );

      expect(user.baseUrl, 'http://example.com');
    });

    test('_mapUserType maps user types correctly', () {
      expect(UserModel.fromSoap({'Code': '001', 'Name': 'Test', 'Type': '1'}, baseUrl: 'http://example.com').role, 'Agent');
      expect(UserModel.fromSoap({'Code': '001', 'Name': 'Test', 'Type': '2'}, baseUrl: 'http://example.com').role, 'Forwarder');
      expect(UserModel.fromSoap({'Code': '001', 'Name': 'Test', 'Type': '3'}, baseUrl: 'http://example.com').role, 'Supervisor');
      expect(UserModel.fromSoap({'Code': '001', 'Name': 'Test', 'Type': '4'}, baseUrl: 'http://example.com').role, 'Boss');
      expect(UserModel.fromSoap({'Code': '001', 'Name': 'Test', 'Type': '5'}, baseUrl: 'http://example.com').role, 'Collector');
      expect(UserModel.fromSoap({'Code': '001', 'Name': 'Test', 'Type': '6'}, baseUrl: 'http://example.com').role, 'Packer');
      expect(UserModel.fromSoap({'Code': '001', 'Name': 'Test', 'Type': '7'}, baseUrl: 'http://example.com').role, 'WarehouseManager');
      expect(UserModel.fromSoap({'Code': '001', 'Name': 'Test', 'Type': '99'}, baseUrl: 'http://example.com').role, 'Unknown');
    });
  });
}