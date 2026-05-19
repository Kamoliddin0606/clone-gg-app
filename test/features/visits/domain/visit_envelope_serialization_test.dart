import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/features/visits/domain/entities/device_info.dart';
import 'package:gloria_marketing_flutter/src/features/visits/domain/entities/task.dart';
import 'package:gloria_marketing_flutter/src/features/visits/domain/entities/visit_envelope.dart';
import 'package:gloria_marketing_flutter/src/features/visits/domain/entities/visit_location.dart';

VisitLocation _loc() => VisitLocation(
      lat: 41.311081,
      lng: 69.279729,
      accuracyM: 14.2,
      source: 'gps',
      mocked: false,
      providerTs: DateTime.utc(2026, 5, 16, 8, 14, 21),
    );

VisitDeviceInfo _device() => const VisitDeviceInfo(
      deviceId: 'device-uuid',
      platform: 'android',
      osVersion: '14',
      appVersion: '2.5.0+318',
      model: 'SM-G990B',
      batteryLevel: 0.83,
      networkType: 'wifi',
      isJailbroken: false,
      timezone: 'Asia/Tashkent',
      locale: 'uz_UZ',
    );

void main() {
  test('VisitEnvelope.toJson emits the contracted wire shape', () {
    final envelope = VisitEnvelope(
      envelopeId: 'env-1',
      visitId: 'visit-1',
      customerId: 'customer-1',
      clientUuid: 'device-uuid',
      idempotencyKey: 'idem-1',
      plannedFlag: true,
      startedAt: DateTime.utc(2026, 5, 16, 8, 14, 22, 103),
      finishedAt: DateTime.utc(2026, 5, 16, 8, 47, 55, 221),
      totalDurationMs: 2033118,
      outcome: 'completed',
      startLocation: _loc(),
      finishLocation: _loc(),
      device: _device(),
      clientClockDriftMs: 1820,
      networkFlags: const {'was_offline': false, 'outbox_attempts': 0},
      tasks: [
        EnvelopeTask(
          taskId: 'task-1',
          taskCode: 'PHOTO_BEFORE',
          startedAt: DateTime.utc(2026, 5, 16, 8, 14, 30),
          endedAt: DateTime.utc(2026, 5, 16, 8, 16, 2),
          durationMs: 92000,
          status: TaskRunStatus.completed,
          payload: const {'photo_asset_ids': ['asset-1']},
          payloadSchemaVersion: 1,
        ),
      ],
    );

    final json = envelope.toJson();

    expect(json['client_uuid'], 'device-uuid');
    expect(json['idempotency_key'], 'idem-1');
    expect(json['visit_id'], 'visit-1');
    expect(json['planned_flag'], isTrue);
    expect(json['outcome'], 'completed');
    expect(json['client_clock_drift_ms'], 1820);
    expect(json['network_flags'], {
      'was_offline': false,
      'outbox_attempts': 0,
    });
    expect(json['tasks'], hasLength(1));
    final firstTask = (json['tasks'] as List).first as Map<String, dynamic>;
    expect(firstTask['task_code'], 'PHOTO_BEFORE');
    expect(firstTask['status'], 'completed');
    expect(firstTask['duration_ms'], 92000);
    expect(firstTask['payload_schema_version'], 1);
    expect(firstTask['started_at'], '2026-05-16T08:14:30.000Z');
  });
}
