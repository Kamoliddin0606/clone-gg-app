/// =============================================================================
/// AgentLocationRecord Model Test
/// =============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/core/services/background_location/models/agent_location_record.dart';

void main() {
  group('AgentLocationRecord', () {
    // =========================================================================
    // TEST DATA
    // =========================================================================
    
    late AgentLocationRecord testRecord;

    setUp(() {
      testRecord = AgentLocationRecord(
        agentCode: 'TEST_AGENT_001',
        latitude: '41.311081',
        longitude: '69.240562',
        agentName: 'Test Agent',
        agentPhone: '+998901234567',
        deviceId: 'test_device_123',
        deviceName: 'Test Device',
        deviceManufacturer: 'Samsung',
        deviceModel: 'Galaxy S21',
        platform: 'Android',
        osVersion: '14',
        appVersion: '1.0.0',
        batteryLevel: '85',
        isCharging: true,
        networkType: 'wifi',
      );
    });

    // =========================================================================
    // CONSTRUCTOR TESTS
    // =========================================================================

    group('Constructor', () {
      test('should create instance with required fields only', () {
        final record = AgentLocationRecord(
          agentCode: 'AGENT_001',
          latitude: '41.0',
          longitude: '69.0',
        );

        expect(record.agentCode, 'AGENT_001');
        expect(record.latitude, '41.0');
        expect(record.longitude, '69.0');
      });

      test('should create instance with all fields', () {
        expect(testRecord.agentCode, 'TEST_AGENT_001');
        expect(testRecord.latitude, '41.311081');
        expect(testRecord.longitude, '69.240562');
        expect(testRecord.agentName, 'Test Agent');
        expect(testRecord.deviceId, 'test_device_123');
        expect(testRecord.platform, 'Android');
        expect(testRecord.batteryLevel, '85');
        expect(testRecord.isCharging, true);
      });

      test('should have null default values for optional fields', () {
        final record = AgentLocationRecord(
          agentCode: 'AGENT_001',
          latitude: '41.0',
          longitude: '69.0',
        );

        expect(record.agentName, isNull);
        expect(record.deviceId, isNull);
        expect(record.batteryLevel, isNull);
        expect(record.isCharging, isNull);
      });
    });

    // =========================================================================
    // toJson() TESTS
    // =========================================================================

    group('toJson()', () {
      test('should convert to JSON with required fields', () {
        final record = AgentLocationRecord(
          agentCode: 'AGENT_001',
          latitude: '41.0',
          longitude: '69.0',
        );
        final json = record.toJson();

        expect(json['agent_code'], 'AGENT_001');
        expect(json['latitude'], '41.0');
        expect(json['longitude'], '69.0');
      });

      test('should convert to JSON with all fields', () {
        final json = testRecord.toJson();

        expect(json['agent_code'], 'TEST_AGENT_001');
        expect(json['latitude'], '41.311081');
        expect(json['longitude'], '69.240562');
        expect(json['agent_name'], 'Test Agent');
        expect(json['device_id'], 'test_device_123');
        expect(json['platform'], 'Android');
        expect(json['battery_level'], '85');
        expect(json['is_charging'], true);
      });

      test('should use snake_case for JSON keys', () {
        final json = testRecord.toJson();

        expect(json.containsKey('agent_code'), true);
        expect(json.containsKey('device_id'), true);
        expect(json.containsKey('device_name'), true);
        expect(json.containsKey('device_manufacturer'), true);
        expect(json.containsKey('device_model'), true);
        expect(json.containsKey('os_version'), true);
        expect(json.containsKey('app_version'), true);
        expect(json.containsKey('battery_level'), true);
        expect(json.containsKey('is_charging'), true);
        expect(json.containsKey('network_type'), true);
      });
    });

    // =========================================================================
    // fromJson() TESTS
    // =========================================================================

    group('fromJson()', () {
      test('should create instance from JSON with required fields', () {
        final json = {
          'agent_code': 'AGENT_001',
          'latitude': '41.0',
          'longitude': '69.0',
        };
        final record = AgentLocationRecord.fromJson(json);

        expect(record.agentCode, 'AGENT_001');
        expect(record.latitude, '41.0');
        expect(record.longitude, '69.0');
      });

      test('should create instance from JSON with all fields', () {
        final json = {
          'agent_code': 'TEST_AGENT_001',
          'latitude': '41.311081',
          'longitude': '69.240562',
          'agent_name': 'Test Agent',
          'device_id': 'test_device_123',
          'platform': 'Android',
          'battery_level': '85',
          'is_charging': true,
        };
        final record = AgentLocationRecord.fromJson(json);

        expect(record.agentCode, 'TEST_AGENT_001');
        expect(record.latitude, '41.311081');
        expect(record.agentName, 'Test Agent');
        expect(record.deviceId, 'test_device_123');
        expect(record.platform, 'Android');
        expect(record.batteryLevel, '85');
        expect(record.isCharging, true);
      });

      test('should handle null values in JSON', () {
        final json = {
          'agent_code': 'AGENT_001',
          'latitude': '41.0',
          'longitude': '69.0',
          'device_id': null,
          'battery_level': null,
        };
        final record = AgentLocationRecord.fromJson(json);

        expect(record.deviceId, isNull);
        expect(record.batteryLevel, isNull);
      });
    });

    // =========================================================================
    // copyWith() TESTS
    // =========================================================================

    group('copyWith()', () {
      test('should create copy with same values', () {
        final copy = testRecord.copyWith();

        expect(copy.agentCode, testRecord.agentCode);
        expect(copy.latitude, testRecord.latitude);
        expect(copy.longitude, testRecord.longitude);
        expect(copy.deviceId, testRecord.deviceId);
        expect(copy.batteryLevel, testRecord.batteryLevel);
      });

      test('should update specified fields', () {
        final copy = testRecord.copyWith(
          latitude: '42.0',
          longitude: '70.0',
          batteryLevel: '50',
        );

        expect(copy.latitude, '42.0');
        expect(copy.longitude, '70.0');
        expect(copy.batteryLevel, '50');
        // Other fields should remain unchanged
        expect(copy.agentCode, testRecord.agentCode);
        expect(copy.deviceId, testRecord.deviceId);
      });

      test('should not affect original instance', () {
        final originalLatitude = testRecord.latitude;
        testRecord.copyWith(latitude: '42.0');

        expect(testRecord.latitude, originalLatitude);
      });
    });

    // =========================================================================
    // ROUND-TRIP TESTS
    // =========================================================================

    group('Round-trip serialization', () {
      test('should preserve data through toJson and fromJson', () {
        final json = testRecord.toJson();
        final restored = AgentLocationRecord.fromJson(json);

        expect(restored.agentCode, testRecord.agentCode);
        expect(restored.latitude, testRecord.latitude);
        expect(restored.longitude, testRecord.longitude);
        expect(restored.deviceId, testRecord.deviceId);
        expect(restored.deviceName, testRecord.deviceName);
        expect(restored.platform, testRecord.platform);
        expect(restored.batteryLevel, testRecord.batteryLevel);
        expect(restored.isCharging, testRecord.isCharging);
      });
    });

    // =========================================================================
    // EDGE CASES
    // =========================================================================

    group('Edge cases', () {
      test('should handle extreme latitude/longitude values as strings', () {
        final record = AgentLocationRecord(
          agentCode: 'AGENT_001',
          latitude: '-90.000000', // South Pole
          longitude: '180.000000', // Date Line
        );

        expect(record.latitude, '-90.000000');
        expect(record.longitude, '180.000000');
      });

      test('should handle zero coordinates', () {
        final record = AgentLocationRecord(
          agentCode: 'AGENT_001',
          latitude: '0.0',
          longitude: '0.0',
        );

        expect(record.latitude, '0.0');
        expect(record.longitude, '0.0');
      });

      test('should handle empty agent code', () {
        // Note: This should normally be validated, but testing model behavior
        final record = AgentLocationRecord(
          agentCode: '',
          latitude: '41.0',
          longitude: '69.0',
        );

        expect(record.agentCode, '');
      });

      test('should handle special characters in string fields', () {
        final record = AgentLocationRecord(
          agentCode: 'AGENT_001',
          latitude: '41.0',
          longitude: '69.0',
          agentName: "Test Agent's Name",
          deviceName: 'Device "Special" Name',
        );

        expect(record.agentName, "Test Agent's Name");
        expect(record.deviceName, 'Device "Special" Name');
      });
    });
  });
}
