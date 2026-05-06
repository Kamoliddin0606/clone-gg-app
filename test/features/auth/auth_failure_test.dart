import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/features/auth/data/models/auth_failure.dart';

Map<String, dynamic> _envelope(String code, {Map<String, dynamic>? details}) {
  return {
    'error': {'code': code, 'message': 'msg', 'details': details},
    'request_id': null,
  };
}

void main() {
  group('AuthFailure.fromErrorEnvelope', () {
    test('authentication_failed → InvalidCredentialsFailure', () {
      final f = AuthFailure.fromErrorEnvelope(_envelope('authentication_failed'), 401);
      expect(f, isA<InvalidCredentialsFailure>());
      expect(f.messageKey, 'invalidCredentials');
    });

    test('user_inactive → UserInactiveFailure', () {
      final f = AuthFailure.fromErrorEnvelope(_envelope('user_inactive'), 403);
      expect(f, isA<UserInactiveFailure>());
      expect(f.messageKey, 'userInactive');
    });

    test('user_outside_active_window parses dates from details', () {
      final f = AuthFailure.fromErrorEnvelope(
        _envelope('user_outside_active_window', details: {
          'active_start': '2026-09-01T08:00:00Z',
          'active_end': '2026-09-01T18:00:00Z',
          'server_time': '2026-09-01T20:00:00Z',
        }),
        403,
      );
      expect(f, isA<UserOutsideActiveWindowFailure>());
      final w = f as UserOutsideActiveWindowFailure;
      expect(w.activeStart, DateTime.utc(2026, 9, 1, 8));
      expect(w.activeEnd, DateTime.utc(2026, 9, 1, 18));
      expect(w.serverTime, DateTime.utc(2026, 9, 1, 20));
    });

    test('license_missing → LicenseMissingFailure', () {
      final f = AuthFailure.fromErrorEnvelope(_envelope('license_missing'), 403);
      expect(f, isA<LicenseMissingFailure>());
      expect(f.messageKey, 'licenseMissing');
    });

    test('license_expired → LicenseExpiredFailure', () {
      final f = AuthFailure.fromErrorEnvelope(_envelope('license_expired'), 403);
      expect(f, isA<LicenseExpiredFailure>());
    });

    test('license_seat_exceeded parses seat / rank from details', () {
      final f = AuthFailure.fromErrorEnvelope(
        _envelope('license_seat_exceeded', details: {
          'seat_count': 5,
          'active_user_count': 7,
          'user_rank': 6,
        }),
        409,
      );
      expect(f, isA<LicenseSeatExceededFailure>());
      final s = f as LicenseSeatExceededFailure;
      expect(s.seatCount, 5);
      expect(s.activeUserCount, 7);
      expect(s.userRank, 6);
      expect(s.messageArgs['rank'], 6);
      expect(s.messageArgs['seatCount'], 5);
    });

    test('unknown code → UnknownAuthFailure with rawCode', () {
      final f = AuthFailure.fromErrorEnvelope(_envelope('something_new'), 500);
      expect(f, isA<UnknownAuthFailure>());
      expect((f as UnknownAuthFailure).rawCode, 'something_new');
    });

    test('malformed envelope → UnknownAuthFailure(malformed_envelope)', () {
      final f = AuthFailure.fromErrorEnvelope({'no_error_field': true}, 500);
      expect(f, isA<UnknownAuthFailure>());
      expect((f as UnknownAuthFailure).rawCode, 'malformed_envelope');
    });

    test('null code + 401 → InvalidCredentialsFailure', () {
      final f = AuthFailure.fromErrorEnvelope(
        <String, dynamic>{'error': <String, dynamic>{}},
        401,
      );
      expect(f, isA<InvalidCredentialsFailure>());
    });

    test('NetworkFailure has the right messageKey', () {
      const f = NetworkFailure();
      expect(f.messageKey, 'networkError');
    });
  });
}
