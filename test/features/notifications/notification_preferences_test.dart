import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/models/notification_preferences.dart';
import 'package:gloria_marketing_flutter/src/features/notifications/data/services/notification_preferences_service.dart';

/// Phase 2 §1 — preferences model + service.
///
/// Coverage:
///   * JSON round-trip preserves every field, including the wrap-around
///     DND window (e.g. 22:00 → 06:00 must survive encode/decode).
///   * isInDnd respects normal-vs-wraparound semantics.
///   * Service hydrates from SharedPreferences, persists on update,
///     emits distinct values on the stream.
///   * Defaults: missing types are enabled, missing priorities pick the
///     passport §12 Q1 baseline.
void main() {
  group('NotificationPreferences model', () {
    test('default sound levels follow passport §12 Q1 baseline', () {
      const p = NotificationPreferences();
      expect(p.soundFor('urgent'), NotificationSoundLevel.vibrate);
      expect(p.soundFor('high'), NotificationSoundLevel.vibrate);
      expect(p.soundFor('normal'), NotificationSoundLevel.silent);
      expect(p.soundFor('low'), NotificationSoundLevel.silent);
    });

    test('missing type defaults to ENABLED (opt-out, not opt-in)', () {
      const p = NotificationPreferences();
      expect(p.isTypeEnabled('debt_alert'), isTrue);
      expect(p.isTypeEnabled('something_new_from_backend'), isTrue);
    });

    test('withTypeEnabled flips a single key without touching others',
        () {
      const p = NotificationPreferences();
      final updated =
          p.withTypeEnabled('debt_alert', false).withTypeEnabled('order_new', false);
      expect(updated.isTypeEnabled('debt_alert'), isFalse);
      expect(updated.isTypeEnabled('order_new'), isFalse);
      expect(updated.isTypeEnabled('system_announcement'), isTrue);
    });

    test('withSoundForPriority overrides only the chosen bucket', () {
      const p = NotificationPreferences();
      final updated = p.withSoundForPriority(
        'high',
        NotificationSoundLevel.sound,
      );
      expect(updated.soundFor('high'), NotificationSoundLevel.sound);
      // Untouched priorities keep their defaults.
      expect(updated.soundFor('normal'), NotificationSoundLevel.silent);
    });
  });

  group('DND window', () {
    test('disabled when start or end is null', () {
      expect(const NotificationPreferences().isInDnd(), isFalse);
      expect(
        NotificationPreferences(
          dndStart: const TimeOfDay(hour: 22, minute: 0),
        ).isInDnd(),
        isFalse,
      );
    });

    test('normal window — start before end', () {
      final p = NotificationPreferences(
        dndStart: const TimeOfDay(hour: 13, minute: 0),
        dndEnd: const TimeOfDay(hour: 14, minute: 0),
      );
      expect(p.isInDnd(DateTime(2026, 5, 13, 12, 59)), isFalse);
      expect(p.isInDnd(DateTime(2026, 5, 13, 13, 0)), isTrue);
      expect(p.isInDnd(DateTime(2026, 5, 13, 13, 30)), isTrue);
      // End is exclusive — keeps the math symmetric.
      expect(p.isInDnd(DateTime(2026, 5, 13, 14, 0)), isFalse);
      expect(p.isInDnd(DateTime(2026, 5, 13, 14, 1)), isFalse);
    });

    test('wrap-around window — start after end (overnight DND)', () {
      // 22:00 evening → 06:00 next morning.
      final p = NotificationPreferences(
        dndStart: const TimeOfDay(hour: 22, minute: 0),
        dndEnd: const TimeOfDay(hour: 6, minute: 0),
      );
      // Before midnight.
      expect(p.isInDnd(DateTime(2026, 5, 13, 23, 30)), isTrue);
      // After midnight, before end.
      expect(p.isInDnd(DateTime(2026, 5, 14, 5, 59)), isTrue);
      // Daytime.
      expect(p.isInDnd(DateTime(2026, 5, 13, 12, 0)), isFalse);
      // Exactly start.
      expect(p.isInDnd(DateTime(2026, 5, 13, 22, 0)), isTrue);
      // Exactly end (exclusive).
      expect(p.isInDnd(DateTime(2026, 5, 14, 6, 0)), isFalse);
    });

    test('empty window (start == end) is treated as disabled', () {
      final p = NotificationPreferences(
        dndStart: const TimeOfDay(hour: 12, minute: 0),
        dndEnd: const TimeOfDay(hour: 12, minute: 0),
      );
      expect(p.isInDnd(DateTime(2026, 5, 13, 12, 0)), isFalse);
    });
  });

  group('JSON round-trip', () {
    test('encodes + decodes every field including wrap-around DND', () {
      final original = NotificationPreferences(
        typeEnabled: const {'debt_alert': false, 'order_new': true},
        dndStart: const TimeOfDay(hour: 22, minute: 30),
        dndEnd: const TimeOfDay(hour: 6, minute: 15),
        soundByPriority: const {
          'urgent': NotificationSoundLevel.sound,
          'low': NotificationSoundLevel.silent,
        },
      );
      final restored = NotificationPreferences.decode(original.encode());
      expect(restored, original);
    });

    test('decoding garbage returns defaults instead of throwing', () {
      expect(NotificationPreferences.decode('{garbage'),
          NotificationPreferences.defaults);
      expect(
          NotificationPreferences.decode(''), NotificationPreferences.defaults);
    });

    test('decoding partial JSON keeps only the recognised fields', () {
      final p = NotificationPreferences.decode(
        '{"typeEnabled": {"debt_alert": false}, "dndStart": "22:00"}',
      );
      expect(p.isTypeEnabled('debt_alert'), isFalse);
      // dndStart alone (no end) → DND treated as disabled.
      expect(p.isDndEnabled, isFalse);
    });

    test('invalid time strings are discarded silently', () {
      final p = NotificationPreferences.decode(
        '{"dndStart": "25:99", "dndEnd": "abc"}',
      );
      expect(p.dndStart, isNull);
      expect(p.dndEnd, isNull);
    });
  });

  group('NotificationPreferencesService', () {
    late SharedPreferencesService prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferencesService.getInstance();
      await prefs.preferences.clear();
    });

    test('bootstrap on empty prefs yields defaults', () async {
      final svc = NotificationPreferencesService(prefs: prefs);
      await svc.bootstrap();
      expect(svc.value, NotificationPreferences.defaults);
    });

    test('update persists and re-bootstrap restores the same blob',
        () async {
      final svc = NotificationPreferencesService(prefs: prefs);
      await svc.bootstrap();

      final next = svc.value
          .withTypeEnabled('debt_alert', false)
          .withSoundForPriority('urgent', NotificationSoundLevel.sound)
          .copyWith(
            dndStart: const TimeOfDay(hour: 22, minute: 0),
            dndEnd: const TimeOfDay(hour: 6, minute: 0),
          );
      await svc.update(next);

      final svc2 = NotificationPreferencesService(prefs: prefs);
      await svc2.bootstrap();
      expect(svc2.value, next);
    });

    test('stream emits distinct values', () async {
      final svc = NotificationPreferencesService(prefs: prefs);
      await svc.bootstrap();

      final captured = <NotificationPreferences>[];
      final sub = svc.stream.listen(captured.add);

      // Same value twice → distinct filters one out.
      await svc.update(svc.value);
      await svc.update(svc.value.withTypeEnabled('debt_alert', false));
      await Future<void>.delayed(Duration.zero);

      await sub.cancel();
      // Initial defaults + one real change.
      expect(captured, hasLength(2));
      expect(captured.last.isTypeEnabled('debt_alert'), isFalse);
    });

    test('bootstrap is idempotent', () async {
      final svc = NotificationPreferencesService(prefs: prefs);
      await svc.bootstrap();
      await svc.bootstrap();
      // Should not throw; value remains defaults.
      expect(svc.value, NotificationPreferences.defaults);
    });
  });
}
