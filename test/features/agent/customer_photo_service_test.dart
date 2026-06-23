import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gloria_marketing_flutter/src/core/services/images/unified_image.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/repositories/customer_photo_repository.dart';
import 'package:gloria_marketing_flutter/src/features/agent/services/customer_photo_service.dart';

UnifiedImage _row(String id, {bool ready = true}) {
  return UnifiedImage(
    id: id,
    targetType: 'customer',
    targetId: 'cust-1',
    targetOrganizationId: 'org-1',
    targetCode1c: '',
    smallUrl: ready ? 'https://x/$id-s.webp' : null,
    mediumUrl: ready ? 'https://x/$id-m.webp' : null,
    largeUrl: ready ? 'https://x/$id-l.webp' : null,
    blurhash: '',
    width: 100,
    height: 100,
    isPrimary: false,
    alt: '',
    order: 0,
  );
}

class _PollingFakeRepo implements CustomerPhotoRepository {
  /// Number of retrieve() calls to make before flipping to 'ready'.
  int callsUntilReady;
  int retrieveCalls = 0;

  _PollingFakeRepo({this.callsUntilReady = 2});

  @override
  Future<UnifiedImage> retrieve(String customerId, String photoId) async {
    retrieveCalls++;
    if (retrieveCalls < callsUntilReady) {
      return _row(photoId, ready: false);
    }
    return _row(photoId, ready: true);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _CapFailingRepo implements CustomerPhotoRepository {
  @override
  Future<UnifiedImage> uploadOne({
    required String customerId,
    required File image,
    String alt = '',
    int order = 0,
    bool isPrimary = false,
    String? projectOverride,
  }) async {
    throw const CustomerPhotoException(
      code: 'customer_photo_limit_exceeded',
      message: 'cap',
      details: <String, dynamic>{
        'max': 10,
        'current': 10,
        'available': 0,
        'requested': 1,
      },
      statusCode: 409,
    );
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ReprocessRepo implements CustomerPhotoRepository {
  @override
  Future<void> reprocess({
    required String customerId,
    required String photoId,
  }) async {
    throw const CustomerPhotoException(
      code: 'image_reprocess_not_supported',
      message: 'nope',
      statusCode: 400,
    );
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('CustomerPhotoService.waitForReady', () {
    test('polls until the row has a URL (ready state)', () async {
      final repo = _PollingFakeRepo(callsUntilReady: 3);
      final svc = CustomerPhotoService(repo: repo);
      final result = await svc.waitForReady(
        customerId: 'cust-1',
        photoId: 'p',
        interval: const Duration(milliseconds: 1),
        timeout: const Duration(seconds: 5),
      );
      expect(result.hasUrl, isTrue);
      expect(repo.retrieveCalls, greaterThanOrEqualTo(3));
    });

    test('returns the last row when the timeout expires', () async {
      final repo = _PollingFakeRepo(callsUntilReady: 1000);
      final svc = CustomerPhotoService(repo: repo);
      final result = await svc.waitForReady(
        customerId: 'cust-1',
        photoId: 'p',
        interval: const Duration(milliseconds: 1),
        timeout: const Duration(milliseconds: 5),
      );
      // Even on timeout we always return *some* row (the last one
      // observed or one final fetch).
      expect(result.id, 'p');
    });
  });

  group('CustomerPhotoService.addOne', () {
    test('translates the limit-exceeded code into the typed exception',
        () async {
      final svc = CustomerPhotoService(repo: _CapFailingRepo());
      await expectLater(
        svc.addOne(customerId: 'cust-1', image: File('/tmp/x.jpg')),
        throwsA(isA<CustomerPhotoCapExceeded>()
            .having((e) => e.max, 'max', 10)
            .having((e) => e.current, 'current', 10)
            .having((e) => e.available, 'available', 0)),
      );
    });
  });

  group('CustomerPhotoService.reprocess', () {
    test('surfaces image_reprocess_not_supported as the typed exception',
        () async {
      final svc = CustomerPhotoService(repo: _ReprocessRepo());
      await expectLater(
        svc.reprocess(customerId: 'cust-1', photoId: 'p'),
        throwsA(isA<CustomerPhotoReprocessUnsupported>()),
      );
    });
  });
}
